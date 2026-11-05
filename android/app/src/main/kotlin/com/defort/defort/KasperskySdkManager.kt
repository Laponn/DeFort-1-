package com.defort.defort

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.kavsdk.KavSdk
import com.kavsdk.antivirus.Antivirus
import com.kavsdk.antivirus.AntivirusInstance
import com.kavsdk.antivirus.ThreatInfo
import com.kavsdk.antivirus.ThreatType
import com.kavsdk.antivirus.SuspiciousThreatType
import com.kavsdk.antivirus.multithread.MultithreadedScanEventListener
import com.kavsdk.antivirus.multithread.ObjectInfo
import com.kavsdk.antivirus.multithread.ObjectStatus
import com.kavsdk.antivirus.multithread.ScanTarget
import com.kavsdk.license.SdkLicense
import com.kavsdk.license.SdkLicenseViolationException
import com.kavsdk.urlchecker.UrlCheckService
import com.kavsdk.urlchecker.UrlSourceEnum
import com.kavsdk.webfilter.PageInfo
import java.io.File
import java.io.IOException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Singleton terpusat untuk mengelola siklus hidup Kaspersky SDK di DeFort.
 * Memungkinkan pemindaian di latar belakang oleh Foreground Service,
 * BroadcastReceiver (instalasi aplikasi), dan AccessibilityService (anti-phishing)
 * bahkan saat Activity UI Flutter sedang ditutup.
 */
object KasperskySdkManager {
    private const val TAG = "KasperskySdkMgr"
    private const val LICENSE_KEY = "ZCY92-JYW1R-NKG9V-6TAMN"

    @Volatile
    private var antivirus: Antivirus? = null

    @Volatile
    private var urlCheckService: UrlCheckService? = null

    @Volatile
    private var isInitialized = false

    private val isInitializing = AtomicBoolean(false)

    // Penyimpanan ancaman yang terdeteksi secara real-time
    val detectedThreats = ConcurrentHashMap<String, ThreatInfo>()

    /**
     * Inisialisasi aman Kaspersky SDK. Thread-safe dan idempoten.
     */
    fun initSafe(context: Context): Boolean {
        if (isInitialized && antivirus != null) return true

        val appCtx = context.applicationContext
        synchronized(this) {
            if (isInitialized && antivirus != null) return true

            try {
                val basesDir = appCtx.getDir("bases", Context.MODE_PRIVATE)
                val nativeLibDir = appCtx.applicationInfo.nativeLibraryDir

                Log.i(TAG, "Inisialisasi KavSdk (basesDir=${basesDir.absolutePath})")
                KavSdk.initSafe(appCtx, basesDir, nativeLibDir)

                val license: SdkLicense = KavSdk.getLicense()
                if (!license.isValid) {
                    if (license.isClientUserIDRequired) {
                        try {
                            val androidId = Settings.Secure.getString(appCtx.contentResolver, Settings.Secure.ANDROID_ID)
                            license.sendClientUserID(androidId)
                        } catch (e: Exception) {
                            Log.w(TAG, "sendClientUserID gagal: ${e.message}")
                        }
                    }

                    for (attempt in 1..3) {
                        try {
                            Log.i(TAG, "Mencoba aktivasi lisensi SDK (percobaan $attempt)...")
                            license.activate(LICENSE_KEY)
                            if (license.isValid) {
                                Log.i(TAG, "Lisensi Kaspersky aktif!")
                                break
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Aktivasi lisensi gagal pada percobaan $attempt: ${e.message}")
                            if (attempt < 3) Thread.sleep(1500)
                        }
                    }
                }

                // Inisialisasi mesin Antivirus
                val scanTmpDir = appCtx.getDir("scan_tmp", Context.MODE_PRIVATE)
                val monitorTmpDir = appCtx.getDir("monitor_tmp", Context.MODE_PRIVATE)

                antivirus = AntivirusInstance.getInstance().also {
                    it.initAntivirus(appCtx, scanTmpDir.absolutePath, monitorTmpDir.absolutePath)
                }

                // Inisialisasi UrlCheckService untuk anti-phishing
                try {
                    urlCheckService = UrlCheckService(appCtx)
                    urlCheckService?.timeout = 5000
                    Log.i(TAG, "UrlCheckService siap untuk Anti-Phishing real-time")
                } catch (e: Exception) {
                    Log.w(TAG, "UrlCheckService init gagal: ${e.message}")
                }

                isInitialized = true
                Log.i(TAG, "KasperskySdkManager berhasil diinisialisasi penuh.")
                return true
            } catch (e: Exception) {
                Log.e(TAG, "Gagal inisialisasi KasperskySdkManager: ${e.message}", e)
                return false
            }
        }
    }

    fun getAntivirus(context: Context): Antivirus? {
        if (antivirus == null) {
            initSafe(context)
        }
        return antivirus
    }

    fun getUrlCheckService(context: Context): UrlCheckService? {
        if (urlCheckService == null) {
            initSafe(context)
        }
        return urlCheckService
    }

    /**
     * Periksa URL menggunakan Kaspersky WebFilter / UrlCheckService
     */
    fun checkUrl(context: Context, url: String): PageInfo? {
        return try {
            val service = getUrlCheckService(context) ?: return null
            service.checkPage(url, UrlSourceEnum.WebClient)
        } catch (e: Exception) {
            Log.w(TAG, "Pemeriksaan URL '$url' gagal: ${e.message}")
            null
        }
    }

    /**
     * Pindai paket aplikasi yang baru diinstal (APK) secara sinkron menggunakan MultithreadedScanner.
     */
    fun scanInstalledApp(context: Context, packageName: String): List<ThreatInfo> {
        val appCtx = context.applicationContext
        val av = getAntivirus(appCtx) ?: return emptyList()

        return try {
            val pm = appCtx.packageManager
            val appInfo: ApplicationInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getApplicationInfo(packageName, android.content.pm.PackageManager.ApplicationInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getApplicationInfo(packageName, 0)
            }

            val foundThreats = mutableListOf<ThreatInfo>()
            val scanner = av.createMultithreadedScanner(1, 1)
            val scanTarget = ScanTarget().apply {
                applications = listOf(appInfo)
            }

            val listener = object : MultithreadedScanEventListener {
                override fun onScanObjectBegin(info: ObjectInfo) {
                    try { info.release() } catch (_: Exception) {}
                }

                override fun onScanObjectEnd(info: ObjectInfo, status: ObjectStatus) {
                    try { info.release() } catch (_: Exception) {}
                }

                override fun onMalwareDetected(info: ObjectInfo, threatInfo: ThreatInfo, threatType: ThreatType) {
                    foundThreats.add(threatInfo)
                    val threatId = "threat_pkg_${System.currentTimeMillis()}_${threatInfo.virusName}"
                    detectedThreats[threatId] = threatInfo
                    MainActivity.detectedThreatsStore[threatId] = threatInfo
                    try { info.release() } catch (_: Exception) {}
                }

                override fun onSuspiciousDetected(
                    info: ObjectInfo,
                    threatInfo: ThreatInfo,
                    threatType: SuspiciousThreatType
                ) {
                    foundThreats.add(threatInfo)
                    val threatId = "threat_pkg_susp_${System.currentTimeMillis()}_${threatInfo.virusName}"
                    detectedThreats[threatId] = threatInfo
                    MainActivity.detectedThreatsStore[threatId] = threatInfo
                    try { info.release() } catch (_: Exception) {}
                }
            }

            scanner.scan(scanTarget, 0, listener)
            foundThreats
        } catch (e: Exception) {
            Log.e(TAG, "Gagal memindai aplikasi $packageName: ${e.message}", e)
            emptyList()
        }
    }

    /**
     * Pindai berkas tunggal (misal file yang baru diunduh di /Downloads).
     */
    fun scanSingleFile(context: Context, file: File): List<ThreatInfo> {
        val appCtx = context.applicationContext
        val av = getAntivirus(appCtx) ?: return emptyList()
        if (!file.exists() || !file.isFile) return emptyList()

        return try {
            val foundThreats = mutableListOf<ThreatInfo>()
            val scanner = av.createMultithreadedScanner(1, 1)
            val scanTarget = ScanTarget().apply {
                folder = file.parentFile ?: file
            }

            val listener = object : MultithreadedScanEventListener {
                override fun onScanObjectBegin(info: ObjectInfo) {
                    try { info.release() } catch (_: Exception) {}
                }

                override fun onScanObjectEnd(info: ObjectInfo, status: ObjectStatus) {
                    try { info.release() } catch (_: Exception) {}
                }

                override fun onMalwareDetected(info: ObjectInfo, threatInfo: ThreatInfo, threatType: ThreatType) {
                    val fullPath = try { threatInfo.fileFullPath ?: "" } catch (_: Exception) { "" }
                    if (fullPath.isEmpty() || fullPath == file.absolutePath) {
                        foundThreats.add(threatInfo)
                        val threatId = "threat_file_${System.currentTimeMillis()}_${threatInfo.virusName}"
                        detectedThreats[threatId] = threatInfo
                        MainActivity.detectedThreatsStore[threatId] = threatInfo
                    }
                    try { info.release() } catch (_: Exception) {}
                }

                override fun onSuspiciousDetected(
                    info: ObjectInfo,
                    threatInfo: ThreatInfo,
                    threatType: SuspiciousThreatType
                ) {
                    val fullPath = try { threatInfo.fileFullPath ?: "" } catch (_: Exception) { "" }
                    if (fullPath.isEmpty() || fullPath == file.absolutePath) {
                        foundThreats.add(threatInfo)
                        val threatId = "threat_file_susp_${System.currentTimeMillis()}_${threatInfo.virusName}"
                        detectedThreats[threatId] = threatInfo
                        MainActivity.detectedThreatsStore[threatId] = threatInfo
                    }
                    try { info.release() } catch (_: Exception) {}
                }
            }

            scanner.scan(scanTarget, 0, listener)
            foundThreats
        } catch (e: Exception) {
            Log.e(TAG, "Gagal memindai berkas ${file.absolutePath}: ${e.message}", e)
            emptyList()
        }
    }
}


package com.defort.defort

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import com.kavsdk.KavSdk
import com.kavsdk.antivirus.Antivirus
import com.kavsdk.antivirus.AntivirusInstance
import com.kavsdk.antivirus.SuspiciousThreatType
import com.kavsdk.antivirus.ThreatInfo
import com.kavsdk.antivirus.ThreatType
import com.kavsdk.antivirus.easyscanner.EasyListener
import com.kavsdk.antivirus.easyscanner.EasyMode
import com.kavsdk.antivirus.easyscanner.EasyObject
import com.kavsdk.antivirus.easyscanner.EasyStatus
import com.kavsdk.antivirus.multithread.MultithreadedScanEventListener
import com.kavsdk.antivirus.multithread.ObjectInfo
import com.kavsdk.antivirus.multithread.ObjectStatus
import com.kavsdk.antivirus.multithread.ScanTarget
import com.kavsdk.dnschecker.DnsCheckVerdict
import com.kavsdk.dnschecker.DnsChecker
import com.kavsdk.license.SdkLicense
import com.kavsdk.license.SdkLicenseViolationException
import com.kavsdk.secureconnection.SecureURL
import com.kavsdk.urlchecker.UrlCheckService
import com.kavsdk.urlchecker.UrlSourceEnum
import com.kavsdk.webfilter.PageInfo
import com.kavsdk.wifi.CloudState
import com.kavsdk.wifi.Verdict
import com.kavsdk.wifi.WifiReputation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.defort/native_sdk"
        private const val TAG = "DeFort"

        @Volatile
        private var antivirusComponent: Antivirus? = null

        @Volatile
        private var isSdkReady = false

        @Volatile
        private var isInitializingSdk = false

        @Volatile
        private var sdkInitError: String? = null

        @Volatile
        private var activeChannel: MethodChannel? = null

        @Volatile
        private var isFlutterAlive = false

        @Volatile
        private var currentScanInfo: Map<String, Any?>? = null

        private val uiThreadHandler = Handler(Looper.getMainLooper())

        private fun emitToFlutter(method: String, arguments: Any?) {
            uiThreadHandler.post {
                try {
                    if (isFlutterAlive) {
                        activeChannel?.invokeMethod(method, arguments)
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to emit $method to Flutter: ${e.message}")
                }
            }
        }

        private fun nowTimeStr(): String {
            return SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
        }

        private fun formatEta(remainingSeconds: Long): String {
            if (remainingSeconds <= 1L) return "Hampir selesai (< 2 dtk)"
            if (remainingSeconds < 60L) return "~$remainingSeconds detik lagi"
            val mins = remainingSeconds / 60L
            val secs = remainingSeconds % 60L
            return if (secs > 0L) "~$mins mnt $secs dtk lagi" else "~$mins menit lagi"
        }

        private fun shortTargetName(pkgName: String, objName: String, fullPath: String, fallbackIdx: Int): String {
            val cleanObj = objName.substringAfterLast('/').ifBlank { objName }
            val cleanPath = fullPath.substringAfterLast('/').ifBlank { fullPath }
            return when {
                pkgName.isNotBlank() && cleanObj.isNotBlank() && cleanObj != pkgName -> "$pkgName ($cleanObj)"
                pkgName.isNotBlank() -> pkgName
                cleanObj.isNotBlank() -> cleanObj
                cleanPath.isNotBlank() -> cleanPath
                else -> "Objek sistem #$fallbackIdx"
            }
        }
    }

    // Permintaan izin lokasi (untuk membaca nama Wi-Fi) & izin notifikasi (Android 13+)
    private val LOCATION_REQ_CODE = 4021
    private val NOTIFICATION_REQ_CODE = 4022
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun onDestroy() {
        isFlutterAlive = false
        activeChannel = null
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (ScanForegroundService.isScanning()) {
            moveTaskToBack(true)
            return
        }
        super.onBackPressed()
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= 33) {
            val perm = "android.permission.POST_NOTIFICATIONS"
            if (checkSelfPermission(perm) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(perm), NOTIFICATION_REQ_CODE)
            }
        }
    }

    private fun hasAllFilesAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val appCtx = applicationContext
        if (!isSdkReady && !isInitializingSdk) {
            isInitializingSdk = true
            thread { initializeSdk(appCtx) }
        }

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        activeChannel = channel
        isFlutterAlive = true

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeSdk" -> {
                    result.success(isSdkReady && antivirusComponent != null)
                }

                "getActiveScanState" -> {
                    result.success(currentScanInfo ?: mapOf("isScanning" to false))
                }

                "moveTaskToBack" -> {
                    val moved = moveTaskToBack(true)
                    result.success(moved)
                }

                "checkStoragePermission" -> {
                    result.success(hasAllFilesAccess())
                }

                "requestStoragePermission" -> {
                    if (hasAllFilesAccess()) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        } catch (_: Exception) {
                            startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
                        }
                        result.success(false)
                    } else {
                        requestPermissions(
                            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                            4025
                        )
                        result.success(false)
                    }
                }

                "startEasyScan" -> {
                    if (antivirusComponent == null) {
                        result.error(
                            "SDK_NOT_READY",
                            "Kaspersky SDK belum siap: ${sdkInitError ?: "Sedang inisialisasi..."}",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    val modeArg = call.argument<String>("mode") ?: "Quick"
                    val sourceArg = call.argument<String>("source") ?: "ScanTab"
                    val easyMode = if (modeArg.equals("Full", ignoreCase = true)) {
                        EasyMode.Full
                    } else {
                        EasyMode.Recommended
                    }
                    val scanTitle = if (modeArg.equals("Full", ignoreCase = true)) {
                        "Pindai Menyeluruh"
                    } else {
                        "Pindai Cepat"
                    }

                    requestNotificationPermissionIfNeeded()

                    val initialAppCount = try {
                        appCtx.packageManager.getInstalledApplications(0).size.coerceAtLeast(30)
                    } catch (_: Exception) {
                        60
                    }

                    ScanForegroundService.startScan(
                        appCtx,
                        "DeFort: $scanTitle (0%)",
                        "Menyiapkan engine Kaspersky & menghitung target..."
                    )

                    val startLog = "[${nowTimeStr()}] Memulai $scanTitle (Kaspersky Antivirus Engine)..."
                    val initialState = mapOf(
                        "isScanning" to true,
                        "scanType" to "MALWARE",
                        "mode" to modeArg,
                        "source" to sourceArg,
                        "label" to scanTitle,
                        "percent" to 0,
                        "filesScanned" to 0,
                        "objectsScanned" to 0,
                        "totalFiles" to initialAppCount,
                        "etaSeconds" to -1L,
                        "etaText" to "Menghitung estimasi waktu...",
                        "elapsedSeconds" to 0L,
                        "currentFile" to "Menghitung daftar paket & berkas...",
                        "logEntry" to startLog,
                        "isThreatLog" to false
                    )
                    currentScanInfo = initialState
                    emitToFlutter("onScanProgress", initialState)

                    thread {
                        val startTimeMs = System.currentTimeMillis()
                        try {
                            val scanner = antivirusComponent!!.createEasyScanner()
                            val topFilesCounter = AtomicInteger(0)
                            val objectsCounter = AtomicInteger(0)
                            val totalCounter = AtomicInteger(initialAppCount)
                            val threatsDetectedCounter = AtomicInteger(0)
                            var smoothedEtaSec = -1.0
                            var lastUiEmitMs = 0L

                            val listener = object : EasyListener {
                                override fun onFilesCountCalculated(filesCount: Int) {
                                    val resolvedTotal = if (filesCount > 0) filesCount else initialAppCount
                                    totalCounter.set(resolvedTotal)
                                    val countLog = "[${nowTimeStr()}] Total target terdeteksi: $resolvedTotal file/paket aplikasi."
                                    emitToFlutter(
                                        "onScanProgress",
                                        mapOf(
                                            "scanType" to "MALWARE",
                                            "source" to sourceArg,
                                            "percent" to 1,
                                            "filesScanned" to topFilesCounter.get(),
                                            "objectsScanned" to objectsCounter.get(),
                                            "totalFiles" to resolvedTotal,
                                            "etaSeconds" to -1L,
                                            "etaText" to "Menghitung estimasi waktu...",
                                            "elapsedSeconds" to ((System.currentTimeMillis() - startTimeMs) / 1000L),
                                            "currentFile" to "Memulai pemeriksaan objek...",
                                            "logEntry" to countLog,
                                            "isThreatLog" to false
                                        )
                                    )
                                }

                                override fun onObjectBegin(obj: EasyObject) {
                                    try { obj.release() } catch (_: Exception) {}
                                }

                                override fun onObjectEnd(obj: EasyObject, status: EasyStatus) {
                                    val fullPath = try { obj.fileFullPath ?: "" } catch (_: Exception) { "" }
                                    val objName = try { obj.objectName ?: "" } catch (_: Exception) { "" }
                                    val pkgName = try { obj.packageName ?: "" } catch (_: Exception) { "" }
                                    try { obj.release() } catch (_: Exception) {}

                                    val allObjs = objectsCounter.incrementAndGet()
                                    val isTopLevel = fullPath.isNotEmpty() && fullPath == objName
                                    val rawTopFiles = if (isTopLevel) topFilesCounter.incrementAndGet() else topFilesCounter.get()

                                    // Jika sedang memindai komponen internal APK, estimasikan file yang sudah diperiksa secara proporsional
                                    val effectiveFiles = if (rawTopFiles > 0) rawTopFiles else ((allObjs / 3).coerceAtLeast(1))
                                    var total = totalCounter.get().coerceAtLeast(1)
                                    if (effectiveFiles >= total) {
                                        total = effectiveFiles + 4
                                        totalCounter.set(total)
                                    }

                                    // Hitung persentase halus (1% s.d. 99% selama proses berjalan)
                                    val subStep = ((allObjs % 4) * 0.2).coerceIn(0.0, 0.8)
                                    val rawRatio = ((effectiveFiles.toDouble() + subStep) / total.toDouble()).coerceIn(0.01, 0.99)
                                    val percent = (rawRatio * 100.0).roundToInt().coerceIn(1, 99)

                                    val now = System.currentTimeMillis()
                                    val elapsedSec = ((now - startTimeMs) / 1000.0).coerceAtLeast(0.5)
                                    val rawEta = ((elapsedSec * (1.0 - rawRatio)) / rawRatio).coerceIn(1.0, 3600.0)
                                    smoothedEtaSec = if (smoothedEtaSec < 0.0) rawEta else (smoothedEtaSec * 0.75 + rawEta * 0.25)
                                    val etaSecLong = smoothedEtaSec.roundToInt().toLong().coerceAtLeast(1L)
                                    val etaText = formatEta(etaSecLong)

                                    val targetLabel = shortTargetName(pkgName, objName, fullPath, allObjs)

                                    ScanForegroundService.updateProgress(
                                        appCtx,
                                        "DeFort: $scanTitle ($percent%)",
                                        "$effectiveFiles / $total file dipindai • Estimasi $etaText\nMemeriksa: $targetLabel",
                                        percent,
                                        100
                                    )

                                    if (isTopLevel || now - lastUiEmitMs >= 180L) {
                                        lastUiEmitMs = now
                                        val logLine = "[${nowTimeStr()}] [#$effectiveFiles/$total] [OK] $targetLabel"
                                        val progressPayload = mapOf(
                                            "isScanning" to true,
                                            "scanType" to "MALWARE",
                                            "mode" to modeArg,
                                            "source" to sourceArg,
                                            "label" to scanTitle,
                                            "percent" to percent,
                                            "filesScanned" to effectiveFiles,
                                            "objectsScanned" to allObjs,
                                            "totalFiles" to total,
                                            "threatsFound" to threatsDetectedCounter.get(),
                                            "etaSeconds" to etaSecLong,
                                            "etaText" to etaText,
                                            "elapsedSeconds" to elapsedSec.toLong(),
                                            "currentFile" to targetLabel,
                                            "logEntry" to logLine,
                                            "isThreatLog" to false
                                        )
                                        currentScanInfo = progressPayload
                                        emitToFlutter("onScanProgress", progressPayload)
                                    }
                                }

                                override fun onMalwareDetected(obj: EasyObject, threatInfo: ThreatInfo) {
                                    val pkgName = try { obj.packageName ?: "" } catch (_: Exception) { "" }
                                    val objName = try { obj.objectName ?: "" } catch (_: Exception) { "" }
                                    val fullPath = try { obj.fileFullPath ?: "" } catch (_: Exception) { "" }
                                    val virus = threatInfo.virusName ?: "Malware"
                                    try { obj.release() } catch (_: Exception) {}
                                    val threatsNow = threatsDetectedCounter.incrementAndGet()
                                    val targetLabel = shortTargetName(pkgName, objName, fullPath, objectsCounter.get())
                                    emitToFlutter(
                                        "onScanProgress",
                                        mapOf(
                                            "scanType" to "MALWARE",
                                            "source" to sourceArg,
                                            "threatsFound" to threatsNow,
                                            "currentFile" to targetLabel,
                                            "logEntry" to "[${nowTimeStr()}] ⚠️ [MALWARE] $targetLabel -> $virus",
                                            "isThreatLog" to true
                                        )
                                    )
                                }

                                override fun onRiskwareDetected(obj: EasyObject, threatInfo: ThreatInfo) {
                                    val pkgName = try { obj.packageName ?: "" } catch (_: Exception) { "" }
                                    val objName = try { obj.objectName ?: "" } catch (_: Exception) { "" }
                                    val fullPath = try { obj.fileFullPath ?: "" } catch (_: Exception) { "" }
                                    val virus = threatInfo.virusName ?: "Riskware"
                                    try { obj.release() } catch (_: Exception) {}
                                    val threatsNow = threatsDetectedCounter.incrementAndGet()
                                    val targetLabel = shortTargetName(pkgName, objName, fullPath, objectsCounter.get())
                                    emitToFlutter(
                                        "onScanProgress",
                                        mapOf(
                                            "scanType" to "MALWARE",
                                            "source" to sourceArg,
                                            "threatsFound" to threatsNow,
                                            "currentFile" to targetLabel,
                                            "logEntry" to "[${nowTimeStr()}] ⚠️ [RISKWARE] $targetLabel -> $virus",
                                            "isThreatLog" to true
                                        )
                                    )
                                }

                                override fun onRooted() {
                                    emitToFlutter(
                                        "onScanProgress",
                                        mapOf(
                                            "scanType" to "MALWARE",
                                            "source" to sourceArg,
                                            "logEntry" to "[${nowTimeStr()}] ⚠️ [PERINGATAN] Akses ROOT terdeteksi pada sistem!",
                                            "isThreatLog" to true
                                        )
                                    )
                                }
                            }

                            scanner.scan(easyMode, listener)
                            val scanResult = scanner.result

                            val isRooted = scanResult?.isRooted ?: false
                            val malwareList = scanResult?.malwareList ?: emptyList()
                            val riskwareList = scanResult?.riskwareList ?: emptyList()
                            val rawFilesScanned = scanResult?.filesScanned ?: 0
                            val rawObjectsScanned = scanResult?.objectsScanned ?: 0
                            val filesScanned = when {
                                rawFilesScanned > 0 -> rawFilesScanned
                                topFilesCounter.get() > 0 -> topFilesCounter.get()
                                rawObjectsScanned > 0 -> rawObjectsScanned
                                else -> objectsCounter.get()
                            }
                            val totalObjectsScanned = if (rawObjectsScanned > 0) rawObjectsScanned else objectsCounter.get()
                            val malwareCount = malwareList.size + riskwareList.size
                            val allThreatNames = (malwareList + riskwareList).map { it.virusName ?: "Unknown Threat" }
                            val hasThreat = malwareCount > 0 || isRooted
                            val totalElapsedSec = ((System.currentTimeMillis() - startTimeMs) / 1000L).coerceAtLeast(1L)

                            emitToFlutter(
                                "onScanProgress",
                                mapOf(
                                    "scanType" to "MALWARE",
                                    "source" to sourceArg,
                                    "percent" to 100,
                                    "filesScanned" to filesScanned,
                                    "objectsScanned" to totalObjectsScanned,
                                    "totalFiles" to filesScanned,
                                    "threatsFound" to malwareCount,
                                    "etaSeconds" to 0L,
                                    "etaText" to "Selesai (0 detik)",
                                    "elapsedSeconds" to totalElapsedSec,
                                    "currentFile" to "Pemindaian Selesai",
                                    "logEntry" to "[${nowTimeStr()}] ✅ Selesai 100%: $filesScanned file ($totalObjectsScanned objek) dipindai dalam ${totalElapsedSec} dtk.",
                                    "isThreatLog" to false
                                )
                            )

                            val notifTitle = if (hasThreat) {
                                "⚠️ Ancaman Ditemukan ($scanTitle)"
                            } else {
                                "✅ $scanTitle Selesai (100%) — Aman"
                            }
                            val notifBody = if (hasThreat) {
                                "$filesScanned file dipindai (${totalElapsedSec} dtk). Ditemukan $malwareCount ancaman${if (isRooted) " & perangkat ROOT" else ""}."
                            } else {
                                "$filesScanned file dipindai dalam ${totalElapsedSec} detik. Tidak ada ancaman ditemukan."
                            }
                            ScanForegroundService.completeScan(appCtx, notifTitle, notifBody, isDanger = hasThreat)

                            val response = mapOf(
                                "isDeviceRooted" to isRooted,
                                "malwareCount" to malwareCount,
                                "filesScanned" to filesScanned,
                                "objectsScanned" to totalObjectsScanned,
                                "elapsedSeconds" to totalElapsedSec,
                                "malwareList" to allThreatNames,
                                "scanMode" to modeArg
                            )

                            currentScanInfo = null

                            if (!isFlutterAlive) {
                                val detailsJson = JSONObject().apply {
                                    put("folder", "Seluruh Perangkat ($scanTitle)")
                                    put("files_scanned", filesScanned)
                                    put("malware_count", malwareCount)
                                    put("is_rooted", isRooted)
                                    put("reasons", JSONArray(allThreatNames))
                                }.toString()
                                ScanForegroundService.saveHistoryToSqlite(
                                    appCtx,
                                    "MALWARE",
                                    if (hasThreat) "DANGER" else "SAFE",
                                    if (hasThreat) "Ditemukan $malwareCount ancaman" else "Aman",
                                    detailsJson
                                )
                            } else {
                                emitToFlutter("onScanCompleted", mapOf("scanType" to "MALWARE", "source" to sourceArg, "result" to response))
                                uiThreadHandler.post {
                                    try { result.success(response) } catch (_: Exception) {}
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "EasyScan error: ${e.message}", e)
                            currentScanInfo = null
                            ScanForegroundService.completeScan(
                                appCtx,
                                "Pemindaian Gagal",
                                e.message ?: "Terjadi kesalahan saat memindai perangkat.",
                                isDanger = true
                            )
                            uiThreadHandler.post {
                                try { result.error("SCAN_ERROR", e.message, null) } catch (_: Exception) {}
                            }
                        }
                    }
                }

                "scanFolder" -> {
                    val folderPath = call.argument<String>("path") ?: ""
                    if (antivirusComponent == null) {
                        result.error(
                            "SDK_NOT_READY",
                            "Kaspersky SDK belum siap: ${sdkInitError ?: "Sedang inisialisasi..."}",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    if (folderPath.isEmpty()) {
                        result.error("INVALID_PATH", "Path folder tidak valid", null)
                        return@setMethodCallHandler
                    }
                    val folder = java.io.File(folderPath)
                    if (!folder.exists() || !folder.isDirectory) {
                        result.error("INVALID_PATH", "Folder tidak ditemukan: $folderPath", null)
                        return@setMethodCallHandler
                    }

                    val folderName = folder.name.ifEmpty { folderPath }
                    requestNotificationPermissionIfNeeded()
                    ScanForegroundService.startScan(
                        appCtx,
                        "DeFort: Memindai Folder (0%)",
                        "Menghitung jumlah berkas di $folderName..."
                    )

                    val startLog = "[${nowTimeStr()}] Memulai pemindaian folder: $folderPath"
                    val initPayload = mapOf(
                        "isScanning" to true,
                        "scanType" to "FOLDER",
                        "source" to "ScanTab",
                        "label" to "Memindai $folderName",
                        "percent" to 0,
                        "filesScanned" to 0,
                        "objectsScanned" to 0,
                        "totalFiles" to 0,
                        "etaSeconds" to -1L,
                        "etaText" to "Menghitung estimasi waktu...",
                        "elapsedSeconds" to 0L,
                        "currentFile" to "Menghitung berkas di $folderName...",
                        "logEntry" to startLog,
                        "isThreatLog" to false
                    )
                    currentScanInfo = initPayload
                    emitToFlutter("onScanProgress", initPayload)

                    thread {
                        val startTimeMs = System.currentTimeMillis()
                        try {
                            val scanner = antivirusComponent!!.createMultithreadedScanner()
                            val scanTarget = ScanTarget()
                            scanTarget.setFolder(folder)

                            val sdkTotal = try { scanner.getFilesCount(scanTarget) } catch (_: Exception) { 0 }
                            val fallbackTotal = if (sdkTotal > 0) sdkTotal else {
                                try {
                                    folder.walkTopDown().take(20000).count { it.isFile }
                                } catch (_: Exception) {
                                    0
                                }
                            }
                            val totalCounter = AtomicInteger(fallbackTotal.coerceAtLeast(1))

                            emitToFlutter(
                                "onScanProgress",
                                mapOf(
                                    "scanType" to "FOLDER",
                                    "source" to "ScanTab",
                                    "percent" to 1,
                                    "filesScanned" to 0,
                                    "objectsScanned" to 0,
                                    "totalFiles" to totalCounter.get(),
                                    "etaSeconds" to -1L,
                                    "etaText" to "Menghitung estimasi waktu...",
                                    "elapsedSeconds" to 0L,
                                    "currentFile" to "Ditemukan ${totalCounter.get()} berkas di $folderName",
                                    "logEntry" to "[${nowTimeStr()}] Total berkas di folder '$folderName': ${totalCounter.get()} file.",
                                    "isThreatLog" to false
                                )
                            )

                            val topFilesCounter = AtomicInteger(0)
                            val objectsCounter = AtomicInteger(0)
                            val threats = java.util.Collections.synchronizedList(mutableListOf<String>())
                            var smoothedEtaSec = -1.0
                            var lastUiEmitMs = 0L

                            val listener = object : MultithreadedScanEventListener {
                                override fun onScanObjectBegin(info: ObjectInfo) {
                                    try { info.release() } catch (_: Exception) {}
                                }

                                override fun onScanObjectEnd(info: ObjectInfo, status: ObjectStatus) {
                                    val fullPath = try { info.fileFullPath ?: "" } catch (_: Exception) { "" }
                                    val objName = try { info.objectName ?: "" } catch (_: Exception) { "" }
                                    val pkgName = try { info.packageName ?: "" } catch (_: Exception) { "" }
                                    try { info.release() } catch (_: Exception) {}

                                    val allObjs = objectsCounter.incrementAndGet()
                                    val isTopLevel = fullPath.isNotEmpty() && fullPath == objName
                                    val rawTopFiles = if (isTopLevel) topFilesCounter.incrementAndGet() else topFilesCounter.get()
                                    val effectiveFiles = if (rawTopFiles > 0) rawTopFiles else allObjs

                                    var total = totalCounter.get().coerceAtLeast(1)
                                    if (effectiveFiles > total) {
                                        total = effectiveFiles + 2
                                        totalCounter.set(total)
                                    }

                                    val rawRatio = (effectiveFiles.toDouble() / total.toDouble()).coerceIn(0.01, 0.99)
                                    val percent = (rawRatio * 100.0).roundToInt().coerceIn(1, 99)

                                    val now = System.currentTimeMillis()
                                    val elapsedSec = ((now - startTimeMs) / 1000.0).coerceAtLeast(0.3)
                                    val rawEta = ((elapsedSec * (1.0 - rawRatio)) / rawRatio).coerceIn(1.0, 3600.0)
                                    smoothedEtaSec = if (smoothedEtaSec < 0.0) rawEta else (smoothedEtaSec * 0.7 + rawEta * 0.3)
                                    val etaSecLong = smoothedEtaSec.roundToInt().toLong().coerceAtLeast(1L)
                                    val etaText = formatEta(etaSecLong)

                                    val targetLabel = shortTargetName(pkgName, objName, fullPath, allObjs)

                                    ScanForegroundService.updateProgress(
                                        appCtx,
                                        "DeFort: Folder $folderName ($percent%)",
                                        "$effectiveFiles / $total file dipindai • Estimasi $etaText\nMemeriksa: $targetLabel",
                                        percent,
                                        100
                                    )

                                    if (isTopLevel || now - lastUiEmitMs >= 150L) {
                                        lastUiEmitMs = now
                                        val logLine = "[${nowTimeStr()}] [#$effectiveFiles/$total] [OK] $targetLabel"
                                        val progressPayload = mapOf(
                                            "isScanning" to true,
                                            "scanType" to "FOLDER",
                                            "source" to "ScanTab",
                                            "label" to "Memindai $folderName",
                                            "percent" to percent,
                                            "filesScanned" to effectiveFiles,
                                            "objectsScanned" to allObjs,
                                            "totalFiles" to total,
                                            "threatsFound" to threats.size,
                                            "etaSeconds" to etaSecLong,
                                            "etaText" to etaText,
                                            "elapsedSeconds" to elapsedSec.toLong(),
                                            "currentFile" to targetLabel,
                                            "logEntry" to logLine,
                                            "isThreatLog" to false
                                        )
                                        currentScanInfo = progressPayload
                                        emitToFlutter("onScanProgress", progressPayload)
                                    }
                                }

                                override fun onMalwareDetected(
                                    info: ObjectInfo,
                                    threatInfo: ThreatInfo,
                                    type: ThreatType
                                ) {
                                    val fullPath = try { info.fileFullPath ?: "" } catch (_: Exception) { "" }
                                    val objName = try { info.objectName ?: "" } catch (_: Exception) { "" }
                                    val pkgName = try { info.packageName ?: "" } catch (_: Exception) { "" }
                                    try { info.release() } catch (_: Exception) {}
                                    val virusName = threatInfo.virusName ?: "Unknown Malware"
                                    threats.add(virusName)
                                    val targetLabel = shortTargetName(pkgName, objName, fullPath, objectsCounter.get())
                                    emitToFlutter(
                                        "onScanProgress",
                                        mapOf(
                                            "scanType" to "FOLDER",
                                            "source" to "ScanTab",
                                            "threatsFound" to threats.size,
                                            "currentFile" to targetLabel,
                                            "logEntry" to "[${nowTimeStr()}] ⚠️ [MALWARE] $targetLabel -> $virusName",
                                            "isThreatLog" to true
                                        )
                                    )
                                }

                                override fun onSuspiciousDetected(
                                    info: ObjectInfo,
                                    threatInfo: ThreatInfo,
                                    type: SuspiciousThreatType
                                ) {
                                    val fullPath = try { info.fileFullPath ?: "" } catch (_: Exception) { "" }
                                    val objName = try { info.objectName ?: "" } catch (_: Exception) { "" }
                                    val pkgName = try { info.packageName ?: "" } catch (_: Exception) { "" }
                                    try { info.release() } catch (_: Exception) {}
                                    val virusName = threatInfo.virusName ?: "Unknown Suspicious"
                                    threats.add(virusName)
                                    val targetLabel = shortTargetName(pkgName, objName, fullPath, objectsCounter.get())
                                    emitToFlutter(
                                        "onScanProgress",
                                        mapOf(
                                            "scanType" to "FOLDER",
                                            "source" to "ScanTab",
                                            "threatsFound" to threats.size,
                                            "currentFile" to targetLabel,
                                            "logEntry" to "[${nowTimeStr()}] ⚠️ [MENCURIGAKAN] $targetLabel -> $virusName",
                                            "isThreatLog" to true
                                        )
                                    )
                                }
                            }

                            scanner.scan(scanTarget, 0, listener)

                            val filesScanned = if (topFilesCounter.get() > 0) topFilesCounter.get() else objectsCounter.get()
                            val totalObjects = objectsCounter.get()
                            val threatList = threats.toList()
                            val hasThreat = threatList.isNotEmpty()
                            val totalElapsedSec = ((System.currentTimeMillis() - startTimeMs) / 1000L).coerceAtLeast(1L)

                            emitToFlutter(
                                "onScanProgress",
                                mapOf(
                                    "scanType" to "FOLDER",
                                    "source" to "ScanTab",
                                    "percent" to 100,
                                    "filesScanned" to filesScanned,
                                    "objectsScanned" to totalObjects,
                                    "totalFiles" to filesScanned,
                                    "threatsFound" to threatList.size,
                                    "etaSeconds" to 0L,
                                    "etaText" to "Selesai (0 detik)",
                                    "elapsedSeconds" to totalElapsedSec,
                                    "currentFile" to "Pemindaian Folder Selesai",
                                    "logEntry" to "[${nowTimeStr()}] ✅ Selesai 100%: $filesScanned file di '$folderName' selesai dipindai dalam ${totalElapsedSec} dtk.",
                                    "isThreatLog" to false
                                )
                            )

                            val notifTitle = if (hasThreat) {
                                "⚠️ Ancaman Ditemukan di Folder $folderName"
                            } else {
                                "✅ Pindai Folder Selesai (100%) — Aman"
                            }
                            val notifBody = if (hasThreat) {
                                "$filesScanned file dipindai di $folderName. Ditemukan ${threatList.size} ancaman!"
                            } else {
                                "$filesScanned file dipindai di $folderName dalam ${totalElapsedSec} detik. Tidak ada ancaman."
                            }
                            ScanForegroundService.completeScan(appCtx, notifTitle, notifBody, isDanger = hasThreat)

                            val response = mapOf(
                                "folderPath" to folderPath,
                                "filesScanned" to filesScanned,
                                "objectsScanned" to totalObjects,
                                "elapsedSeconds" to totalElapsedSec,
                                "malwareCount" to threatList.size,
                                "malwareList" to threatList
                            )

                            currentScanInfo = null

                            if (!isFlutterAlive) {
                                val detailsJson = JSONObject().apply {
                                    put("folder", folderPath)
                                    put("files_scanned", filesScanned)
                                    put("malware_count", threatList.size)
                                    put("is_rooted", false)
                                    put("reasons", JSONArray(threatList))
                                }.toString()
                                ScanForegroundService.saveHistoryToSqlite(
                                    appCtx,
                                    "MALWARE",
                                    if (hasThreat) "DANGER" else "SAFE",
                                    if (hasThreat) "Ditemukan ${threatList.size} ancaman" else "Aman",
                                    detailsJson
                                )
                            } else {
                                emitToFlutter("onScanCompleted", mapOf("scanType" to "FOLDER", "source" to "ScanTab", "result" to response))
                                uiThreadHandler.post {
                                    try { result.success(response) } catch (_: Exception) {}
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Folder scan error: ${e.message}", e)
                            currentScanInfo = null
                            ScanForegroundService.completeScan(
                                appCtx,
                                "Pindai Folder Gagal",
                                e.message ?: "Terjadi kesalahan saat memindai folder.",
                                isDanger = true
                            )
                            uiThreadHandler.post {
                                try { result.error("SCAN_ERROR", e.message, null) } catch (_: Exception) {}
                            }
                        }
                    }
                }

                "checkUrlPhishing" -> {
                    val url = call.argument<String>("url")?.trim().orEmpty()
                    val showNotification = call.argument<Boolean>("showNotification") ?: true

                    if (url.isEmpty()) {
                        result.error("INVALID_URL", "URL kosong", null)
                        return@setMethodCallHandler
                    }
                    if (!isSdkReady) {
                        result.error("SDK_NOT_READY", "Kaspersky SDK masih melakukan inisialisasi", null)
                        return@setMethodCallHandler
                    }

                    if (showNotification) {
                        requestNotificationPermissionIfNeeded()
                        ScanForegroundService.startScan(
                            appCtx,
                            "DeFort: Memeriksa Tautan",
                            "Mengecek keamanan $url..."
                        )
                    }

                    thread {
                        try {
                            val service = UrlCheckService(appCtx)
                            val pageInfo = service.checkPage(url, UrlSourceEnum.WebClient)

                            val verdict = when (pageInfo.mVerdict) {
                                PageInfo.VERDICT_GOOD -> "GOOD"
                                PageInfo.VERDICT_BAD -> "BAD"
                                else -> "UNKNOWN"
                            }

                            val categories = (
                                (pageInfo.mCategories?.mapNotNull { it?.name } ?: emptyList()) +
                                (pageInfo.mCategoryExt?.mapNotNull { it?.name } ?: emptyList())
                            ).distinct()

                            Log.i(TAG, "URL check: url=$url verdict=$verdict(${pageInfo.mVerdict}) categories=$categories")

                            if (showNotification) {
                                val isBad = verdict == "BAD"
                                val notifTitle = when (verdict) {
                                    "BAD" -> "⚠️ Tautan Berbahaya Terdeteksi!"
                                    "GOOD" -> "✅ Tautan Aman"
                                    else -> "ℹ️ Pemeriksaan Tautan Selesai"
                                }
                                val notifBody = when (verdict) {
                                    "BAD" -> "JANGAN buka $url. Terdeteksi berbahaya oleh Kaspersky."
                                    "GOOD" -> "$url aman menurut Kaspersky Security Network."
                                    else -> "Reputasi $url belum dapat dipastikan oleh Kaspersky."
                                }
                                ScanForegroundService.completeScan(appCtx, notifTitle, notifBody, isDanger = isBad)
                            }

                            val response = mapOf(
                                "url" to url,
                                "verdict" to verdict,
                                "verdictCode" to pageInfo.mVerdict,
                                "categories" to categories,
                                "isSafe" to (verdict == "GOOD")
                            )
                            uiThreadHandler.post {
                                try { result.success(response) } catch (_: Exception) {}
                            }
                        } catch (e: SdkLicenseViolationException) {
                            Log.e(TAG, "URL check license error: ${e.message}", e)
                            if (showNotification) {
                                ScanForegroundService.completeScan(appCtx, "Pemeriksaan Tautan Gagal", "Lisensi Kaspersky tidak valid.", isDanger = true)
                            }
                            uiThreadHandler.post {
                                try { result.error("LICENSE_INVALID", e.message ?: "Lisensi Kaspersky tidak valid", null) } catch (_: Exception) {}
                            }
                        } catch (e: IOException) {
                            Log.e(TAG, "URL check network error: ${e.message}", e)
                            if (showNotification) {
                                ScanForegroundService.completeScan(appCtx, "Pemeriksaan Tautan Gagal", "Gagal terhubung ke server Kaspersky.", isDanger = true)
                            }
                            uiThreadHandler.post {
                                try { result.error("NETWORK_ERROR", e.message ?: "Gagal terhubung ke server Kaspersky", null) } catch (_: Exception) {}
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "URL check error: ${e.message}", e)
                            if (showNotification) {
                                ScanForegroundService.completeScan(appCtx, "Pemeriksaan Tautan Gagal", e.message ?: "Terjadi kesalahan.", isDanger = true)
                            }
                            uiThreadHandler.post {
                                try { result.error("URL_CHECK_ERROR", e.message, null) } catch (_: Exception) {}
                            }
                        }
                    }
                }

                "runFullNetworkScan" -> {
                    requestNotificationPermissionIfNeeded()
                    ScanForegroundService.startScan(
                        appCtx,
                        "DeFort: Menganalisis Jaringan (25%)",
                        "Memeriksa reputasi & enkripsi Wi-Fi (1/4)..."
                    )
                    currentScanInfo = mapOf(
                        "isScanning" to true,
                        "scanType" to "NETWORK",
                        "source" to "NetworkTab",
                        "label" to "Menganalisis Keamanan Jaringan"
                    )

                    thread {
                        try {
                            val wifiRes = runWifiSecurityCheckSafe(appCtx)
                            emitToFlutter("onNetworkScanStep", mapOf("step" to "wifi", "data" to wifiRes))

                            ScanForegroundService.updateProgress(
                                appCtx,
                                "DeFort: Menganalisis Jaringan (50%)",
                                "Memeriksa integritas DNS (2/4)...",
                                50,
                                100,
                                force = true
                            )
                            val dnsRes = runDnsCheckSafe("google.com")
                            emitToFlutter("onNetworkScanStep", mapOf("step" to "dns", "data" to dnsRes))

                            ScanForegroundService.updateProgress(
                                appCtx,
                                "DeFort: Menganalisis Jaringan (75%)",
                                "Memeriksa keamanan tautan (3/4)...",
                                75,
                                100,
                                force = true
                            )
                            val urlRes = runUrlNetworkCheckSafe(appCtx, "https://google.com")
                            emitToFlutter("onNetworkScanStep", mapOf("step" to "url", "data" to urlRes))

                            ScanForegroundService.updateProgress(
                                appCtx,
                                "DeFort: Menganalisis Jaringan (95%)",
                                "Memvalidasi sertifikat SSL (4/4)...",
                                95,
                                100,
                                force = true
                            )
                            val sslRes = runSslCheckSafe(appCtx, "https://google.com")
                            emitToFlutter("onNetworkScanStep", mapOf("step" to "ssl", "data" to sslRes))

                            val allLevels = listOf(
                                wifiRes["level"] as? String ?: "UNKNOWN",
                                dnsRes["level"] as? String ?: "UNKNOWN",
                                urlRes["level"] as? String ?: "UNKNOWN",
                                sslRes["level"] as? String ?: "UNKNOWN"
                            )
                            val overallStatus = when {
                                allLevels.contains("DANGER") -> "DANGER"
                                allLevels.any { it == "WARNING" || it == "ERROR" || it == "UNKNOWN" } -> "WARNING"
                                else -> "SAFE"
                            }

                            val notifTitle = when (overallStatus) {
                                "DANGER" -> "⚠️ Jaringan Berbahaya!"
                                "WARNING" -> "⚠️ Analisis Jaringan Selesai (Perlu Waspada)"
                                else -> "✅ Analisis Jaringan Selesai — Aman"
                            }
                            val notifBody = "Wi-Fi: ${wifiRes["summary"]} • DNS: ${dnsRes["summary"]} • SSL: ${sslRes["summary"]}"
                            ScanForegroundService.completeScan(
                                appCtx,
                                notifTitle,
                                notifBody,
                                isDanger = overallStatus != "SAFE"
                            )

                            val fullResponse = mapOf(
                                "wifi" to wifiRes,
                                "dns" to dnsRes,
                                "url" to urlRes,
                                "ssl" to sslRes,
                                "overallStatus" to overallStatus
                            )

                            currentScanInfo = null

                            if (!isFlutterAlive) {
                                val allReasons = mutableListOf<String>()
                                @Suppress("UNCHECKED_CAST")
                                listOf(wifiRes, dnsRes, sslRes, urlRes).forEach { r ->
                                    (r["reasons"] as? List<String>)?.let { allReasons.addAll(it) }
                                }
                                val detailsJson = JSONObject().apply {
                                    put("wifi", wifiRes["summary"] ?: "-")
                                    put("dns", dnsRes["summary"] ?: "-")
                                    put("ssl", sslRes["summary"] ?: "-")
                                    put("url", urlRes["summary"] ?: "-")
                                    put("reasons", JSONArray(allReasons))
                                }.toString()
                                ScanForegroundService.saveHistoryToSqlite(
                                    appCtx,
                                    "NETWORK",
                                    overallStatus,
                                    if (overallStatus == "SAFE") "Aman" else "Terdapat Isu Keamanan",
                                    detailsJson
                                )
                            } else {
                                uiThreadHandler.post {
                                    try { result.success(fullResponse) } catch (_: Exception) {}
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Full network scan error: ${e.message}", e)
                            currentScanInfo = null
                            ScanForegroundService.completeScan(
                                appCtx,
                                "Analisis Jaringan Gagal",
                                e.message ?: "Terjadi kesalahan saat menganalisis jaringan.",
                                isDanger = true
                            )
                            uiThreadHandler.post {
                                try { result.error("NETWORK_SCAN_ERROR", e.message, null) } catch (_: Exception) {}
                            }
                        }
                    }
                }

                "startFakeAppMonitor" -> {
                    thread {
                        try {
                            if (antivirusComponent != null) {
                                antivirusComponent!!.setMonitorState(true)
                                uiThreadHandler.post { result.success(true) }
                            } else {
                                uiThreadHandler.post { result.success(false) }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "FakeAppMonitor error: ${e.message}", e)
                            uiThreadHandler.post { result.success(false) }
                        }
                    }
                }

                "checkWifiSecurity" -> {
                    if (!isSdkReady) {
                        result.success(
                            report(
                                "ERROR",
                                "Tidak dapat diperiksa",
                                listOf("Kaspersky SDK masih melakukan inisialisasi. Coba lagi beberapa detik lagi.")
                            )
                        )
                        return@setMethodCallHandler
                    }
                    thread {
                        val response = runWifiSecurityCheckSafe(appCtx)
                        uiThreadHandler.post { result.success(response) }
                    }
                }

                "checkDns" -> {
                    val domain = call.argument<String>("domain") ?: "google.com"
                    thread {
                        val response = runDnsCheckSafe(domain)
                        uiThreadHandler.post { result.success(response) }
                    }
                }

                "validateSsl" -> {
                    val url = call.argument<String>("url") ?: "https://google.com"
                    thread {
                        val response = runSslCheckSafe(appCtx, url)
                        uiThreadHandler.post { result.success(response) }
                    }
                }

                "getWifiInfo" -> {
                    thread {
                        try {
                            val wifiManager = appCtx.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            val connectivityManager = appCtx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                            val wifiInfo = wifiManager.connectionInfo
                            val capabilities = connectivityManager.activeNetwork?.let { connectivityManager.getNetworkCapabilities(it) }
                            val isConnected = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true

                            val rawSsid = wifiInfo?.ssid?.removeSurrounding("\"").orEmpty()
                            val ssidAvailable = isConnected && rawSsid.isNotBlank() &&
                                    rawSsid != "<unknown ssid>" && rawSsid != "0x"
                            val ssidReason = when {
                                !isConnected -> "Perangkat tidak terhubung ke Wi-Fi."
                                ssidAvailable -> ""
                                else -> ssidBlockedReason(appCtx) ?: "Router menyembunyikan nama jaringan (hidden SSID)."
                            }

                            val rawBssid = wifiInfo?.bssid
                            val bssid = if (rawBssid == null || rawBssid == "02:00:00:00:00:00") "Tidak Diketahui" else rawBssid
                            val rssi = wifiInfo?.rssi ?: -127
                            val encryption = if (isConnected) detectEncryption(appCtx, wifiManager, wifiInfo) else "UNKNOWN"

                            val connectionType = when {
                                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "WiFi"
                                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "Seluler"
                                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true -> "Ethernet"
                                else -> "Tidak Terhubung"
                            }

                            val response = mapOf(
                                "isConnected" to isConnected,
                                "ssid" to (if (ssidAvailable) rawSsid else "Tidak Diketahui"),
                                "ssidAvailable" to ssidAvailable,
                                "ssidReason" to ssidReason,
                                "hasLocationPermission" to hasLocationPermission(appCtx),
                                "isLocationEnabled" to isLocationEnabled(appCtx),
                                "bssid" to bssid,
                                "encryption" to encryption,
                                "encryptionLabel" to encryptionLabel(encryption),
                                "linkSpeed" to (wifiInfo?.linkSpeed ?: -1),
                                "frequency" to (wifiInfo?.frequency ?: -1),
                                "rssi" to rssi,
                                "signalLevel" to WifiManager.calculateSignalLevel(rssi, 5),
                                "connectionType" to connectionType
                            )
                            uiThreadHandler.post { result.success(response) }
                        } catch (e: Exception) {
                            Log.e(TAG, "WiFi info error: ${e.message}", e)
                            uiThreadHandler.post {
                                result.success(
                                    mapOf(
                                        "isConnected" to false,
                                        "ssid" to "Error",
                                        "ssidAvailable" to false,
                                        "ssidReason" to "Gagal membaca info Wi-Fi: ${e.message}",
                                        "bssid" to "00:00:00:00:00:00",
                                        "linkSpeed" to -1,
                                        "frequency" to -1,
                                        "rssi" to -127,
                                        "signalLevel" to 0,
                                        "connectionType" to "Tidak Diketahui"
                                    )
                                )
                            }
                        }
                    }
                }

                "requestLocationPermission" -> {
                    if (hasLocationPermission(appCtx)) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    if (pendingPermissionResult != null) {
                        result.error("ALREADY_REQUESTING", "Permintaan izin sedang berlangsung", null)
                        return@setMethodCallHandler
                    }
                    pendingPermissionResult = result
                    requestPermissions(
                        arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                        LOCATION_REQ_CODE
                    )
                }

                "openLocationSettings" -> {
                    startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                    result.success(true)
                }

                "openAppSettings" -> {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                    result.success(true)
                }

                "toggleWebFilterVpn" -> {
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_REQ_CODE) {
            pendingPermissionResult?.success(hasLocationPermission(applicationContext))
            pendingPermissionResult = null
        }
    }

    // ================== HELPER JARINGAN ==================

    private fun runWifiSecurityCheckSafe(ctx: Context): Map<String, Any?> {
        if (!isSdkReady) {
            return report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Kaspersky SDK masih melakukan inisialisasi. Coba lagi beberapa detik lagi.")
            )
        }
        return try {
            buildWifiSecurityReport(ctx)
        } catch (e: SdkLicenseViolationException) {
            Log.e(TAG, "WiFi check license error: ${e.message}", e)
            report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Lisensi Kaspersky tidak valid / belum aktif. Pastikan internet aktif lalu buka ulang aplikasi.")
            )
        } catch (e: IOException) {
            Log.e(TAG, "WiFi check network error: ${e.message}", e)
            report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Gagal menghubungi server reputasi Kaspersky: ${e.message ?: "koneksi bermasalah"}.")
            )
        } catch (e: Exception) {
            Log.e(TAG, "WiFi check error: ${e.message}", e)
            report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Terjadi kesalahan: ${e.message ?: e.javaClass.simpleName}")
            )
        }
    }

    private fun runDnsCheckSafe(domain: String): Map<String, Any?> {
        return try {
            val dns = DnsChecker().checkURL(domain)
            val trustedIps = dns.trustedIpList?.joinToString(", ").orEmpty().ifEmpty { "-" }
            when (dns.verdict) {
                DnsCheckVerdict.Trusted -> report("SAFE", "Aman (Tidak ada Spoofing)")
                DnsCheckVerdict.Partial -> report(
                    "WARNING",
                    "Sebagian Cocok",
                    listOf("Hanya sebagian alamat IP untuk $domain yang cocok dengan data Kaspersky. Bisa karena CDN, tapi juga bisa tanda DNS dimanipulasi.")
                )
                DnsCheckVerdict.Untrusted -> report(
                    "DANGER",
                    "DNS Tidak Aman",
                    listOf(
                        "Alamat IP untuk $domain dari DNS jaringan ini TIDAK cocok dengan IP resmi ($trustedIps).",
                        "Kemungkinan DNS spoofing/hijacking — Anda bisa diarahkan ke situs palsu."
                    )
                )
                DnsCheckVerdict.CloudUnreachable -> report(
                    "WARNING",
                    "Tidak dapat diverifikasi",
                    listOf("Server Kaspersky tidak dapat dihubungi untuk membandingkan hasil DNS.")
                )
                else -> report(
                    "WARNING",
                    "Tidak dapat diverifikasi",
                    listOf("Kaspersky tidak dapat menentukan apakah DNS jaringan ini aman.")
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "DNS check error: ${e.message}", e)
            report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Pemeriksaan DNS gagal: ${e.message ?: e.javaClass.simpleName}")
            )
        }
    }

    private fun runUrlNetworkCheckSafe(ctx: Context, url: String): Map<String, Any?> {
        if (!isSdkReady) {
            return report("ERROR", "Tidak dapat diperiksa", listOf("Kaspersky SDK masih melakukan inisialisasi"))
        }
        return try {
            val service = UrlCheckService(ctx)
            val pageInfo = service.checkPage(url, UrlSourceEnum.WebClient)
            val isSafe = pageInfo.mVerdict == PageInfo.VERDICT_GOOD
            val isBad = pageInfo.mVerdict == PageInfo.VERDICT_BAD
            when {
                isSafe -> report("SAFE", "Aman (Tidak ada Phishing)")
                isBad -> report("DANGER", "Berbahaya", listOf("Terdeteksi sebagai situs Phishing"))
                else -> report("WARNING", "Tidak dapat diverifikasi", listOf("Status keamanan URL belum dapat dipastikan oleh Kaspersky."))
            }
        } catch (e: Exception) {
            Log.e(TAG, "URL network check error: ${e.message}", e)
            report("ERROR", "Tidak dapat diperiksa", listOf(e.message ?: "Gagal memeriksa URL"))
        }
    }

    private fun runSslCheckSafe(ctx: Context, url: String): Map<String, Any?> {
        return try {
            val conn = SecureURL(ctx, url).openConnection()
            conn.connect()
            conn.disconnect()
            report("SAFE", "Sertifikat Valid")
        } catch (e: javax.net.ssl.SSLPeerUnverifiedException) {
            report(
                "DANGER",
                "Sertifikat Invalid",
                listOf("Identitas server $url tidak bisa diverifikasi. Kemungkinan ada pihak yang mencegat koneksi (Man-in-the-Middle).")
            )
        } catch (e: javax.net.ssl.SSLHandshakeException) {
            report(
                "DANGER",
                "Sertifikat Invalid",
                listOf(
                    "Sertifikat SSL dari $url ditolak (tidak dipercaya / kedaluwarsa / palsu).",
                    "Biasanya terjadi karena captive portal (Wi-Fi yang minta login) atau serangan MITM.",
                    "Detail: ${e.message ?: "-"}"
                )
            )
        } catch (e: java.net.UnknownHostException) {
            report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Tidak ada koneksi internet atau DNS gagal menemukan server $url.")
            )
        } catch (e: java.net.SocketTimeoutException) {
            report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Koneksi ke $url timeout. Jaringan mungkin lambat atau memblokir HTTPS.")
            )
        } catch (e: Exception) {
            Log.e(TAG, "SSL validation error: ${e.message}", e)
            report(
                "ERROR",
                "Tidak dapat diperiksa",
                listOf("Validasi SSL gagal: ${e.message ?: e.javaClass.simpleName}")
            )
        }
    }

    private fun report(
        level: String,
        summary: String,
        reasons: List<String> = emptyList(),
        extra: Map<String, Any?> = emptyMap()
    ): Map<String, Any?> = mapOf("level" to level, "summary" to summary, "reasons" to reasons) + extra

    private fun hasLocationPermission(ctx: Context): Boolean =
        ctx.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun isLocationEnabled(ctx: Context): Boolean {
        val lm = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            lm.isLocationEnabled
        } else {
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER) || lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    private fun ssidBlockedReason(ctx: Context): String? = when {
        !hasLocationPermission(ctx) ->
            "Izin Lokasi (Akurat) belum diberikan. Android mewajibkan izin lokasi agar aplikasi bisa membaca nama Wi-Fi."
        !isLocationEnabled(ctx) ->
            "Layanan Lokasi (GPS) sedang mati. Nyalakan Lokasi agar nama Wi-Fi bisa dibaca."
        else -> null
    }

    private fun detectEncryption(ctx: Context, wifiManager: WifiManager, wifiInfo: WifiInfo?): String {
        if (wifiInfo == null) return "UNKNOWN"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return when (wifiInfo.currentSecurityType) {
                WifiInfo.SECURITY_TYPE_OPEN -> "OPEN"
                WifiInfo.SECURITY_TYPE_OWE -> "OWE"
                WifiInfo.SECURITY_TYPE_WEP -> "WEP"
                WifiInfo.SECURITY_TYPE_PSK -> "WPA2"
                WifiInfo.SECURITY_TYPE_SAE -> "WPA3"
                WifiInfo.SECURITY_TYPE_EAP,
                WifiInfo.SECURITY_TYPE_EAP_WPA3_ENTERPRISE,
                WifiInfo.SECURITY_TYPE_EAP_WPA3_ENTERPRISE_192_BIT -> "ENTERPRISE"
                else -> "UNKNOWN"
            }
        }

        if (!hasLocationPermission(ctx)) return "UNKNOWN"
        val scan = try { wifiManager.scanResults } catch (e: SecurityException) { null }
        val caps = scan?.firstOrNull { it.BSSID.equals(wifiInfo.bssid, ignoreCase = true) }?.capabilities
            ?: return "UNKNOWN"
        return when {
            caps.contains("SAE") -> "WPA3"
            caps.contains("OWE") -> "OWE"
            caps.contains("EAP") -> "ENTERPRISE"
            caps.contains("WPA2") || caps.contains("RSN") -> "WPA2"
            caps.contains("WPA") -> "WPA"
            caps.contains("WEP") -> "WEP"
            else -> "OPEN"
        }
    }

    private fun encryptionLabel(enc: String) = when (enc) {
        "OPEN" -> "Terbuka (tanpa password)"
        "OWE" -> "Enhanced Open (OWE)"
        "WEP" -> "WEP (usang)"
        "WPA" -> "WPA (lama)"
        "WPA2" -> "WPA2-Personal"
        "WPA3" -> "WPA3-Personal"
        "ENTERPRISE" -> "WPA2/WPA3-Enterprise"
        else -> "Tidak Diketahui"
    }

    private fun levelRank(level: String) = when (level) {
        "DANGER" -> 2
        "WARNING" -> 1
        else -> 0
    }

    private fun buildWifiSecurityReport(ctx: Context): Map<String, Any?> {
        val wifiManager = ctx.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val cm = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps = cm.activeNetwork?.let { cm.getNetworkCapabilities(it) }

        if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) != true) {
            return report(
                "UNKNOWN",
                "Tidak terhubung ke Wi-Fi",
                listOf("Perangkat tidak sedang terhubung ke Wi-Fi, jadi reputasi Wi-Fi tidak bisa diperiksa.")
            )
        }

        val reasons = mutableListOf<String>()
        var level = "SAFE"
        fun raise(newLevel: String) { if (levelRank(newLevel) > levelRank(level)) level = newLevel }

        val kav = WifiReputation(ctx).checkCurrentNetwork()
        when (kav.verdict) {
            Verdict.Unsafe -> {
                raise("DANGER")
                reasons += "Database reputasi Wi-Fi Kaspersky menandai jaringan ini sebagai TIDAK AMAN."
            }
            Verdict.Unknown -> {
                raise("WARNING")
                reasons += if (kav.cloudState == CloudState.NotAvailable)
                    "Server reputasi Kaspersky tidak dapat dihubungi, jadi reputasi jaringan belum bisa diverifikasi."
                else
                    "Jaringan ini belum memiliki data reputasi di Kaspersky (jaringan baru / jarang digunakan)."
            }
            else -> {}
        }

        val wifiInfo = wifiManager.connectionInfo
        val enc = detectEncryption(ctx, wifiManager, wifiInfo)
        when (enc) {
            "OPEN" -> {
                raise("DANGER")
                reasons += "Wi-Fi tidak memakai password/enkripsi. Data yang tidak memakai HTTPS bisa disadap orang lain di jaringan yang sama."
            }
            "WEP" -> {
                raise("DANGER")
                reasons += "Wi-Fi memakai enkripsi WEP yang sudah usang dan bisa dibobol dalam hitungan menit."
            }
            "WPA" -> {
                raise("WARNING")
                reasons += "Wi-Fi memakai WPA versi lama (TKIP) yang sudah tidak direkomendasikan. Sebaiknya router diganti ke WPA2/WPA3."
            }
            "UNKNOWN" -> ssidBlockedReason(ctx)?.let { reasons += "Jenis enkripsi tidak bisa dibaca: $it" }
        }

        val ssid = kav.ssid?.removeSurrounding("\"")?.takeIf { it.isNotBlank() && it != "<unknown ssid>" }
            ?: wifiInfo?.ssid?.removeSurrounding("\"")?.takeIf { it.isNotBlank() && it != "<unknown ssid>" }

        val summary = when (level) {
            "DANGER" -> "Berbahaya"
            "WARNING" -> "Perlu Waspada"
            else -> if (enc == "UNKNOWN") "Aman" else "Aman (${encryptionLabel(enc)})"
        }

        Log.i(TAG, "WiFi check: ssid=$ssid verdict=${kav.verdict} cloud=${kav.cloudState} enc=$enc level=$level")

        return report(
            level,
            summary,
            reasons,
            mapOf(
                "ssid" to ssid,
                "bssid" to kav.bssid,
                "verdict" to kav.verdict?.name,
                "cloudState" to kav.cloudState?.name,
                "encryption" to enc,
                "encryptionLabel" to encryptionLabel(enc)
            )
        )
    }

    private fun initializeSdk(appCtx: Context) {
        try {
            val basesPath = appCtx.getDir("bases", Context.MODE_PRIVATE)

            Log.i(TAG, "Initializing KavSdk with basesPath=${basesPath.absolutePath}, nativeLibDir=${appCtx.applicationInfo.nativeLibraryDir}")
            KavSdk.initSafe(appCtx, basesPath, appCtx.applicationInfo.nativeLibraryDir)
            Log.i(TAG, "KavSdk.initSafe completed")

            val license: SdkLicense = KavSdk.getLicense()
            Log.i(TAG, "License isValid=${license.isValid}, isClientUserIDRequired=${license.isClientUserIDRequired}")

            if (!license.isValid) {
                if (license.isClientUserIDRequired) {
                    try {
                        val androidId = Settings.Secure.getString(appCtx.contentResolver, Settings.Secure.ANDROID_ID)
                        license.sendClientUserID(androidId)
                        Log.i(TAG, "Client user ID sent: $androidId")
                    } catch (e: Exception) {
                        Log.e(TAG, "sendClientUserID failed: ${e.message}")
                    }
                }

                var activationSuccess = false
                for (attempt in 1..3) {
                    try {
                        Log.i(TAG, "License activation attempt $attempt...")
                        license.activate("ZCY92-JYW1R-NKG9V-6TAMN")
                        activationSuccess = true
                        Log.i(TAG, "License activated successfully on attempt $attempt")
                        break
                    } catch (e: Exception) {
                        Log.e(TAG, "License activation attempt $attempt failed: ${e.message}")
                        if (attempt < 3) {
                            Thread.sleep(2000)
                        }
                    }
                }

                if (!activationSuccess) {
                    Log.w(TAG, "All license activation attempts failed, continuing with limited functionality")
                }
            }

            Log.i(TAG, "License isValid after activation attempt: ${license.isValid}")

            try {
                val scanTmpDir = appCtx.getDir("scan_tmp", Context.MODE_PRIVATE)
                val monitorTmpDir = appCtx.getDir("monitor_tmp", Context.MODE_PRIVATE)

                antivirusComponent = AntivirusInstance.getInstance().also {
                    it.initAntivirus(appCtx, scanTmpDir.absolutePath, monitorTmpDir.absolutePath)
                }
                Log.i(TAG, "Antivirus initialized successfully, isInitialized=${antivirusComponent?.isInitialized()}")
                sdkInitError = null
            } catch (e: Exception) {
                Log.e(TAG, "Antivirus init failed: ${e.message}", e)
                sdkInitError = "Lisensi tidak valid. Pastikan perangkat terhubung ke internet untuk aktivasi lisensi SDK."
                antivirusComponent = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "SDK init failed: ${e.message}", e)
            sdkInitError = "Gagal inisialisasi SDK: ${e.message}"
            antivirusComponent = null
        } finally {
            isSdkReady = true
            isInitializingSdk = false
        }
    }
}

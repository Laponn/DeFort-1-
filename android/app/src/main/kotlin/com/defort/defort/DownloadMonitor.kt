package com.defort.defort

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Environment
import android.os.FileObserver
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.kavsdk.antivirus.ThreatInfo
import com.kavsdk.antivirus.ThreatType
import com.kavsdk.antivirus.foldermonitor.FolderMonitor
import com.kavsdk.antivirus.foldermonitor.FolderMonitorBuilder
import com.kavsdk.antivirus.foldermonitor.FolderMonitorListener
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * Langkah 2: Background Download Watcher.
 * Memantau folder Unduhan (DIRECTORY_DOWNLOADS) secara real-time.
 * Mengombinasikan Kaspersky FolderMonitor dan Android inotify FileObserver
 * untuk mendeteksi berkas baru yang selesai diunduh dari browser/aplikasi lain,
 * lalu langsung memindainya dan mengkarantina/memperingatkan jika berbahaya.
 */
object DownloadMonitor {
    private const val TAG = "DownloadMonitor"
    private const val NOTIF_CHANNEL_ID = "defort_scan_result"

    private val isRunning = AtomicBoolean(false)
    private var folderMonitor: FolderMonitor? = null
    private var fileObserver: FileObserver? = null
    private val recentlyScanned = ConcurrentHashMap<String, Long>()
    private val handler = Handler(Looper.getMainLooper())

    fun isMonitoring(): Boolean = isRunning.get()

    fun start(context: Context) {
        if (isRunning.getAndSet(true)) {
            Log.i(TAG, "DownloadMonitor sudah berjalan.")
            return
        }

        val appCtx = context.applicationContext
        thread {
            try {
                KasperskySdkManager.initSafe(appCtx)

                val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                if (!downloadDir.exists()) {
                    downloadDir.mkdirs()
                }

                Log.i(TAG, "Memulai DownloadMonitor pada folder: ${downloadDir.absolutePath}")

                // 1. Inisialisasi Kaspersky FolderMonitor
                try {
                    folderMonitor = FolderMonitorBuilder(downloadDir.absolutePath)
                        .setCureInfectedFiles(false)
                        .setFolderMonitorListener(object : FolderMonitorListener {
                            override fun onVirusDetected(threatInfo: ThreatInfo, threatType: ThreatType): Boolean {
                                val virusName = threatInfo.virusName ?: "Malware"
                                val filePath = threatInfo.fileFullPath ?: ""
                                Log.w(TAG, "Kaspersky FolderMonitor mendeteksi ancaman: $virusName di $filePath")
                                handleThreatDetected(appCtx, threatInfo, File(filePath))
                                return false
                            }

                            override fun onMonitorStop(monitor: FolderMonitor) {
                                Log.i(TAG, "Kaspersky FolderMonitor dihentikan.")
                            }
                        })
                        .create()

                    folderMonitor?.start()
                    Log.i(TAG, "Kaspersky FolderMonitor aktif.")
                } catch (e: Exception) {
                    Log.w(TAG, "FolderMonitorBuilder init gagal (fallback ke FileObserver): ${e.message}")
                }

                // 2. Inisialisasi Android FileObserver (inotify) untuk memantau CLOSE_WRITE & MOVED_TO
                val mask = FileObserver.CLOSE_WRITE or FileObserver.MOVED_TO
                val observer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    object : FileObserver(downloadDir, mask) {
                        override fun onEvent(event: Int, path: String?) {
                            processFileEvent(appCtx, downloadDir, path)
                        }
                    }
                } else {
                    @Suppress("DEPRECATION")
                    object : FileObserver(downloadDir.absolutePath, mask) {
                        override fun onEvent(event: Int, path: String?) {
                            processFileEvent(appCtx, downloadDir, path)
                        }
                    }
                }

                fileObserver = observer
                observer.startWatching()
                Log.i(TAG, "FileObserver aktif memantau berkas unduhan.")

            } catch (e: Exception) {
                Log.e(TAG, "Gagal memulai DownloadMonitor: ${e.message}", e)
                isRunning.set(false)
            }
        }
    }

    fun stop() {
        if (!isRunning.getAndSet(false)) return
        try {
            folderMonitor?.stop()
            folderMonitor = null
            fileObserver?.stopWatching()
            fileObserver = null
            recentlyScanned.clear()
            Log.i(TAG, "DownloadMonitor berhasil dihentikan.")
        } catch (e: Exception) {
            Log.w(TAG, "Error saat menghentikan DownloadMonitor: ${e.message}")
        }
    }

    private fun processFileEvent(context: Context, downloadDir: File, path: String?) {
        if (path.isNullOrBlank()) return

        val lower = path.lowercase()
        // Abaikan file sementara unduhan yang belum selesai
        if (lower.endsWith(".tmp") ||
            lower.endsWith(".crdownload") ||
            lower.endsWith(".part") ||
            lower.endsWith(".download") ||
            lower.startsWith(".")
        ) {
            return
        }

        val targetFile = File(downloadDir, path)
        val now = System.currentTimeMillis()
        val lastScan = recentlyScanned[targetFile.absolutePath] ?: 0L

        // Debounce 3 detik untuk berkas yang sama
        if (now - lastScan < 3000L) {
            return
        }
        recentlyScanned[targetFile.absolutePath] = now

        // Tunggu 500ms agar file selesai dilepaskan oleh proses download browser
        handler.postDelayed({
            thread {
                if (targetFile.exists() && targetFile.isFile && targetFile.length() > 0L) {
                    Log.i(TAG, "Berkas unduhan baru siap dipindai: ${targetFile.name} (${targetFile.length()} bytes)")
                    val threats = KasperskySdkManager.scanSingleFile(context, targetFile)

                    if (threats.isNotEmpty()) {
                        val threat = threats.first()
                        handleThreatDetected(context, threat, targetFile)
                    } else {
                        Log.i(TAG, "✅ Berkas unduhan aman: ${targetFile.name}")
                    }
                }
            }
        }, 500L)
    }

    private fun handleThreatDetected(context: Context, threatInfo: ThreatInfo, file: File) {
        val virusName = threatInfo.virusName ?: "Berkas Berbahaya / Trojan"
        val fileName = if (file.exists()) file.name else (threatInfo.objectName ?: "Berkas Unduhan")

        Log.w(TAG, "⚠️ ANCAMAN UNDUHAN: '$fileName' terinfeksi $virusName!")

        // Amankan dan isolasi berkas berbahaya ke direktori karantina DeFort
        var quarantined = false
        try {
            if (file.exists() && file.isFile) {
                val qDir = File(context.filesDir, "quarantine").apply { mkdirs() }
                val dest = File(qDir, "${file.name}.quarantined_${System.currentTimeMillis()}")
                file.copyTo(dest, overwrite = true)
                file.delete()
                dest.setReadable(false, false)
                dest.setExecutable(false, false)
                quarantined = true
                Log.i(TAG, "Berkas berbahaya berhasil diisolasi ke karantina: ${dest.absolutePath}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Gagal mengkarantina file unduhan: ${e.message}")
        }

        postThreatNotification(context, fileName, virusName, quarantined)

        ScanForegroundService.saveHistoryToSqlite(
            context,
            scanType = "Pemantau Unduhan",
            statusLevel = "DANGER",
            summary = "Unduhan berbahaya dicegah: $fileName ($virusName)",
            detailsJson = """{"fileName":"$fileName","virus":"$virusName","quarantined":$quarantined,"path":"${file.absolutePath}"}"""
        )
    }

    private fun postThreatNotification(
        context: Context,
        fileName: String,
        threatName: String,
        quarantined: Boolean
    ) {
        try {
            ScanForegroundService.ensureChannels(context)
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val actionStatus = if (quarantined) {
                "Berkas telah otomatis diisolasi ke Karantina DeFort untuk melindungi sistem."
            } else {
                "Segera hapus berkas ini dari folder Unduhan Anda!"
            }

            val notif = Notification.Builder(context, ScanForegroundService.CHANNEL_PHISHING_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("⚠️ Berkas Unduhan Berbahaya Dicegah!")
                .setContentText("'$fileName' mengandung $threatName")
                .setStyle(
                    Notification.BigTextStyle().bigText(
                        "PERINGATAN DEFORT DOWNLOAD SHIELD:\n" +
                        "Berkas yang baru saja diunduh terdeteksi berbahaya oleh mesin Kaspersky.\n\n" +
                        "• Nama Berkas: $fileName\n" +
                        "• Jenis Ancaman: $threatName\n" +
                        "• Status: $actionStatus"
                    )
                )
                .setAutoCancel(true)
                .setColor(Color.rgb(220, 38, 38))
                .setContentIntent(openAppPendingIntent)
                .build()

            nm.notify(fileName.hashCode(), notif)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal menampilkan notifikasi unduhan berbahaya: ${e.message}")
        }
    }
}


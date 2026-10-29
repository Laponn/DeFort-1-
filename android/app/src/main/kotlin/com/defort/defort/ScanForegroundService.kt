package com.defort.defort

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.database.sqlite.SQLiteDatabase
import android.graphics.Color
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import java.util.concurrent.atomic.AtomicInteger

class ScanForegroundService : Service() {

    companion object {
        private const val TAG = "DeFortScanService"

        private const val CHANNEL_PROGRESS_ID = "defort_scan_progress"
        private const val CHANNEL_RESULT_ID = "defort_scan_result"

        private const val NOTIF_ID_PROGRESS = 9001
        private val resultNotifCounter = AtomicInteger(9100)

        const val ACTION_START_SCAN = "com.defort.defort.ACTION_START_SCAN"
        const val ACTION_UPDATE_SCAN = "com.defort.defort.ACTION_UPDATE_SCAN"
        const val ACTION_STOP_SCAN = "com.defort.defort.ACTION_STOP_SCAN"

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_SUBTITLE = "extra_subtitle"
        const val EXTRA_PROGRESS = "extra_progress"
        const val EXTRA_MAX_PROGRESS = "extra_max_progress"

        @Volatile
        private var lastProgressUpdateMs: Long = 0L

        private val activeScanCount = AtomicInteger(0)

        fun isScanning(): Boolean = activeScanCount.get() > 0

        fun startScan(context: Context, title: String, subtitle: String) {
            activeScanCount.incrementAndGet()
            ensureChannels(context)
            val intent = Intent(context.applicationContext, ScanForegroundService::class.java).apply {
                action = ACTION_START_SCAN
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_SUBTITLE, subtitle)
            }
            try {
                context.applicationContext.startForegroundService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to startForegroundService: ${e.message}", e)
                try {
                    context.applicationContext.startService(intent)
                } catch (_: Exception) {}
            }
        }

        fun updateProgress(
            context: Context,
            title: String,
            subtitle: String,
            progress: Int = -1,
            maxProgress: Int = 0,
            force: Boolean = false
        ) {
            val now = System.currentTimeMillis()
            if (!force && now - lastProgressUpdateMs < 300L) return
            lastProgressUpdateMs = now

            try {
                ensureChannels(context)
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val notif = buildProgressNotification(context.applicationContext, title, subtitle, progress, maxProgress)
                nm.notify(NOTIF_ID_PROGRESS, notif)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update progress notification: ${e.message}")
            }
        }

        fun completeScan(
            context: Context,
            resultTitle: String,
            resultBody: String,
            isDanger: Boolean = false
        ) {
            val remaining = activeScanCount.decrementAndGet().coerceAtLeast(0)
            if (remaining == 0) {
                activeScanCount.set(0)
                val stopIntent = Intent(context.applicationContext, ScanForegroundService::class.java).apply {
                    action = ACTION_STOP_SCAN
                }
                try {
                    context.applicationContext.startService(stopIntent)
                } catch (e: Exception) {
                    try {
                        context.applicationContext.stopService(Intent(context.applicationContext, ScanForegroundService::class.java))
                    } catch (_: Exception) {}
                }
            }

            // Tampilkan notifikasi hasil akhir di status bar
            try {
                ensureChannels(context)
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val resultNotif = buildResultNotification(context.applicationContext, resultTitle, resultBody, isDanger)
                val notifId = resultNotifCounter.incrementAndGet()
                nm.notify(notifId, resultNotif)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to post result notification: ${e.message}")
            }
        }

        /**
         * Menyimpan hasil pemindaian langsung ke database SQLite (defort_history.db)
         * jika proses pemindaian selesai ketika UI Flutter sudah ditutup/di-destroy.
         */
        fun saveHistoryToSqlite(
            context: Context,
            scanType: String,
            statusLevel: String,
            summary: String,
            detailsJson: String
        ) {
            var db: SQLiteDatabase? = null
            try {
                val dbFile = context.applicationContext.getDatabasePath("defort_history.db")
                dbFile.parentFile?.mkdirs()
                db = SQLiteDatabase.openOrCreateDatabase(dbFile, null)
                db.execSQL(
                    """
                    CREATE TABLE IF NOT EXISTS scan_history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        scan_type TEXT NOT NULL,
                        timestamp INTEGER NOT NULL,
                        status TEXT NOT NULL,
                        summary TEXT NOT NULL,
                        details TEXT NOT NULL
                    )
                    """.trimIndent()
                )
                val values = ContentValues().apply {
                    put("scan_type", scanType)
                    put("timestamp", System.currentTimeMillis())
                    put("status", statusLevel)
                    put("summary", summary)
                    put("details", detailsJson)
                }
                db.insert("scan_history", null, values)
                Log.i(TAG, "Saved background scan result to SQLite: type=$scanType status=$statusLevel")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to save scan history in native SQLite: ${e.message}", e)
            } finally {
                try {
                    db?.close()
                } catch (_: Exception) {}
            }
        }

        fun ensureChannels(context: Context) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val progressChannel = NotificationChannel(
                CHANNEL_PROGRESS_ID,
                "Proses Pemindaian DeFort",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Menampilkan progres pemindaian keamanan yang berjalan di latar belakang"
                setShowBadge(false)
            }

            val resultChannel = NotificationChannel(
                CHANNEL_RESULT_ID,
                "Hasil Pemindaian DeFort",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Menampilkan hasil akhir pemindaian malware, folder, dan jaringan"
                enableVibration(true)
                enableLights(true)
                lightColor = Color.BLUE
            }

            nm.createNotificationChannel(progressChannel)
            nm.createNotificationChannel(resultChannel)
        }

        private fun createLaunchPendingIntent(context: Context): PendingIntent {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getActivity(context, 0, launchIntent, flags)
        }

        fun buildProgressNotification(
            context: Context,
            title: String,
            subtitle: String,
            progress: Int = -1,
            maxProgress: Int = 0
        ): Notification {
            val builder = Notification.Builder(context, CHANNEL_PROGRESS_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(subtitle)
                .setStyle(Notification.BigTextStyle().bigText(subtitle))
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setCategory(Notification.CATEGORY_PROGRESS)
                .setContentIntent(createLaunchPendingIntent(context))

            if (maxProgress > 0 && progress >= 0) {
                builder.setProgress(maxProgress, progress.coerceAtMost(maxProgress), false)
            } else {
                builder.setProgress(100, 0, true)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }

            return builder.build()
        }

        fun buildResultNotification(
            context: Context,
            title: String,
            body: String,
            isDanger: Boolean
        ): Notification {
            val accentColor = if (isDanger) Color.rgb(220, 38, 38) else Color.rgb(22, 163, 74)
            return Notification.Builder(context, CHANNEL_RESULT_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setAutoCancel(true)
                .setColor(accentColor)
                .setCategory(Notification.CATEGORY_STATUS)
                .setContentIntent(createLaunchPendingIntent(context))
                .build()
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannels(this)
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_SCAN -> {
                releaseWakeLock()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                val title = intent?.getStringExtra(EXTRA_TITLE) ?: "DeFort Sedang Memindai..."
                val subtitle = intent?.getStringExtra(EXTRA_SUBTITLE)
                    ?: "Pemindaian keamanan tetap berjalan di latar belakang."
                val progress = intent?.getIntExtra(EXTRA_PROGRESS, -1) ?: -1
                val maxProgress = intent?.getIntExtra(EXTRA_MAX_PROGRESS, 0) ?: 0

                acquireWakeLock()
                val notification = buildProgressNotification(this, title, subtitle, progress, maxProgress)
                startForegroundCompat(notification)
                return START_STICKY
            }
        }
    }

    private fun startForegroundCompat(notification: Notification) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIF_ID_PROGRESS,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIF_ID_PROGRESS, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground with type failed, falling back: ${e.message}")
            try {
                startForeground(NOTIF_ID_PROGRESS, notification)
            } catch (e2: Exception) {
                Log.e(TAG, "startForeground fallback failed: ${e2.message}")
            }
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Jangan hentikan service jika masih ada pemindaian yang sedang berlangsung
        if (isScanning()) {
            Log.i(TAG, "Task removed while scanning; keeping ScanForegroundService alive until scan completes")
        } else {
            releaseWakeLock()
            stopSelf()
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun acquireWakeLock() {
        try {
            if (wakeLock?.isHeld == true) return
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "DeFort::BackgroundScanWakeLock"
            ).apply {
                setReferenceCounted(false)
                // Timeout maksimal 30 menit agar baterai tetap aman
                acquire(30 * 60 * 1000L)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to acquire WakeLock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.w(TAG, "Failed to release WakeLock: ${e.message}")
        }
    }
}

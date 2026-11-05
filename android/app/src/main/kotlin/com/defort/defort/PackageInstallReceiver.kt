package com.defort.defort

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.util.Log
import kotlin.concurrent.thread

/**
 * Langkah 1: Auto-Scan Aplikasi Baru.
 * Berjalan secara otomatis saat aplikasi baru dipasang di perangkat (Google Play, browser, APK lokal),
 * bahkan jika DeFort sedang tidak dibuka atau dalam keadaan mati.
 */
class PackageInstallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PackageInstallReceiver"
        private const val NOTIF_CHANNEL_ID = "defort_scan_result"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_PACKAGE_ADDED && action != Intent.ACTION_PACKAGE_REPLACED) {
            return
        }

        val packageName = intent.data?.schemeSpecificPart ?: return

        // Jangan pindai diri sendiri
        if (packageName == context.packageName) {
            return
        }

        Log.i(TAG, "Aplikasi baru/pembaruan terdeteksi: $packageName (action=$action)")

        // Periksa preferensi perlindungan latar belakang
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isAutoScanEnabled = prefs.getBoolean("flutter.backgroundProtectionEnabled", true)
        if (!isAutoScanEnabled) {
            Log.i(TAG, "Perlindungan latar belakang dinonaktifkan oleh pengguna. Melewati pemindaian.")
            return
        }

        val pendingResult = goAsync()

        thread {
            try {
                // Pastikan SDK siap
                KasperskySdkManager.initSafe(context)

                val pm = context.packageManager
                val appName = try {
                    val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(0))
                    } else {
                        @Suppress("DEPRECATION")
                        pm.getApplicationInfo(packageName, 0)
                    }
                    pm.getApplicationLabel(info).toString()
                } catch (_: Exception) {
                    packageName
                }

                Log.i(TAG, "Memulai pemindaian otomatis aplikasi '$appName' ($packageName)...")
                val threats = KasperskySdkManager.scanInstalledApp(context, packageName)

                if (threats.isNotEmpty()) {
                    val threat = threats.first()
                    val virusName = threat.virusName ?: "Malware Berbahaya"
                    Log.w(TAG, "⚠️ BAHAYA: Aplikasi '$appName' terinfeksi $virusName!")

                    postInfectionAlert(context, appName, packageName, virusName)

                    ScanForegroundService.saveHistoryToSqlite(
                        context,
                        scanType = "Auto-Scan Instalasi",
                        statusLevel = "DANGER",
                        summary = "Aplikasi '$appName' terdeteksi berbahaya: $virusName",
                        detailsJson = """{"packageName":"$packageName","appName":"$appName","threat":"$virusName","action":"ALERT_UNINSTALL"}"""
                    )
                } else {
                    Log.i(TAG, "✅ Aplikasi '$appName' aman dan bersih.")
                    postCleanNotification(context, appName, packageName)

                    ScanForegroundService.saveHistoryToSqlite(
                        context,
                        scanType = "Auto-Scan Instalasi",
                        statusLevel = "SAFE",
                        summary = "Aplikasi '$appName' diverifikasi aman oleh Kaspersky",
                        detailsJson = """{"packageName":"$packageName","appName":"$appName","status":"CLEAN"}"""
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Gagal menjalankan auto-scan pada $packageName: ${e.message}", e)
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun postInfectionAlert(
        context: Context,
        appName: String,
        packageName: String,
        threatName: String
    ) {
        try {
            ScanForegroundService.ensureChannels(context)
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val uninstallIntent = Intent(Intent.ACTION_DELETE).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val uninstallPendingIntent = PendingIntent.getActivity(
                context,
                packageName.hashCode(),
                uninstallIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notif = Notification.Builder(context, ScanForegroundService.CHANNEL_PHISHING_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("⚠️ Aplikasi Berbahaya Terdeteksi: $appName")
                .setContentText("Mengandung $threatName! Segera copot pemasangan aplikasi ini.")
                .setStyle(
                    Notification.BigTextStyle().bigText(
                        "PERINGATAN KEAMANAN DEFORT:\n" +
                        "Aplikasi baru '$appName' ($packageName) terdeteksi membawa ancaman berbahaya oleh mesin Kaspersky.\n\n" +
                        "• Nama Ancaman: $threatName\n" +
                        "• Tindakan: Ketuk notifikasi ini untuk mencopot pemasangan aplikasi berbahaya sekarang!"
                    )
                )
                .setAutoCancel(true)
                .setColor(Color.rgb(220, 38, 38))
                .setContentIntent(uninstallPendingIntent)
                .addAction(
                    android.R.drawable.ic_menu_delete,
                    "Copot Pemasangan",
                    uninstallPendingIntent
                )
                .build()

            nm.notify(packageName.hashCode(), notif)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal mengirim notifikasi infeksi: ${e.message}")
        }
    }

    private fun postCleanNotification(
        context: Context,
        appName: String,
        packageName: String
    ) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val scanCompletionAlerts = prefs.getBoolean("flutter.scanCompletionAlerts", true)
            if (!scanCompletionAlerts) return

            ScanForegroundService.ensureChannels(context)
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notif = Notification.Builder(context, NOTIF_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("✅ Aplikasi Aman: $appName")
                .setContentText("Aplikasi baru terverifikasi bersih dan aman dari malware.")
                .setAutoCancel(true)
                .setColor(Color.rgb(22, 163, 74))
                .setContentIntent(openPendingIntent)
                .build()

            nm.notify(packageName.hashCode(), notif)
        } catch (e: Exception) {
            Log.e(TAG, "Gagal mengirim notifikasi aman: ${e.message}")
        }
    }
}


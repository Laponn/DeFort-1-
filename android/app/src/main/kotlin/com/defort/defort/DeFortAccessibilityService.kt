package com.defort.defort

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.kavsdk.webfilter.PageInfo
import java.util.concurrent.ConcurrentHashMap
import java.util.regex.Pattern
import kotlin.concurrent.thread

/**
 * Langkah 3: Layanan Aksesibilitas Anti-Phishing Real-time.
 * Memantau tautan (URL) di address bar browser secara langsung.
 * Jika pengguna tidak sengaja membuka situs/link phishing atau penipuan,
 * DeFort langsung menekan tombol kembali (BACK) secara otomatis,
 * memblokir akses, membunyikan notifikasi darurat, dan mengamankan data pengguna.
 */
class DeFortAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "DeFortAccessibility"

        @Volatile
        var isServiceRunning: Boolean = false
            private set

        // Daftar paket peramban web (browser) populer di Android
        private val BROWSER_PACKAGES = setOf(
            "com.android.chrome",
            "com.chrome.beta",
            "com.chrome.dev",
            "com.chrome.canary",
            "org.mozilla.firefox",
            "org.mozilla.firefox_beta",
            "org.mozilla.fenix",
            "com.sec.android.app.sbrowser",
            "com.sec.android.app.sbrowser.beta",
            "com.microsoft.emmx",
            "com.opera.browser",
            "com.opera.mini.native",
            "com.opera.gx",
            "com.brave.browser",
            "com.duckduckgo.mobile.android",
            "com.ucmobile.intl",
            "com.mi.globalbrowser",
            "com.coloros.browser",
            "com.vivo.browser"
        )

        // Pola domain web valid (misal: domain.com, sub.domain.org/path)
        private val DOMAIN_PATTERN = Pattern.compile(
            "^(https?://)?([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}(/.*)?$",
            Pattern.CASE_INSENSITIVE
        )

        /**
         * Memeriksa apakah Layanan Aksesibilitas DeFort sudah aktif di pengaturan Android
         */
        fun isEnabled(context: Context): Boolean {
            val expectedComponentName = "${context.packageName}/${DeFortAccessibilityService::class.java.canonicalName}"
            val enabledServicesSetting = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServicesSetting)

            while (colonSplitter.hasNext()) {
                val componentName = colonSplitter.next()
                if (componentName.equals(expectedComponentName, ignoreCase = true) ||
                    componentName.contains("DeFortAccessibilityService", ignoreCase = true)
                ) {
                    return true
                }
            }
            return false
        }
    }

    private val checkedUrlCache = ConcurrentHashMap<String, Long>()
    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        Log.i(TAG, "DeFort Anti-Phishing AccessibilityService terhubung & aktif!")

        // Pastikan Kaspersky SDK terinisialisasi
        thread {
            KasperskySdkManager.initSafe(this)
        }
    }

    override fun onDestroy() {
        isServiceRunning = false
        checkedUrlCache.clear()
        Log.i(TAG, "DeFort Anti-Phishing AccessibilityService dinonaktifkan.")
        super.onDestroy()
    }

    override fun onInterrupt() {
        Log.w(TAG, "DeFort AccessibilityService diinterupsi oleh sistem.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val pkgName = event.packageName?.toString() ?: return
        if (!BROWSER_PACKAGES.contains(pkgName)) return

        // Hanya periksa perubahan status jendela atau konten
        val eventType = event.eventType
        if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) {
            return
        }

        // Periksa preferensi apakah Anti-Phishing diaktifkan pengguna
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isPhishingProtectionActive = prefs.getBoolean("flutter.realTimePhishingProtection", true)
        if (!isPhishingProtectionActive) return

        val rootNode = try { rootInActiveWindow ?: event.source } catch (_: Exception) { null } ?: return

        try {
            val detectedUrl = extractUrlFromNode(rootNode)
            if (!detectedUrl.isNullOrBlank()) {
                handleInspectUrl(detectedUrl)
            }
        } finally {
            try { rootNode.recycle() } catch (_: Exception) {}
        }
    }

    /**
     * Mencari teks URL di bilah alamat peramban (address bar)
     */
    private fun extractUrlFromNode(root: AccessibilityNodeInfo): String? {
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)

        var count = 0
        while (queue.isNotEmpty() && count < 60) {
            count++
            val node = queue.removeFirst()

            val viewId = node.viewIdResourceName?.lowercase() ?: ""
            val text = node.text?.toString()?.trim() ?: ""

            // Cek jika ID elemen adalah bilah URL browser
            val isUrlBarId = viewId.contains("url_bar") ||
                    viewId.contains("location_bar") ||
                    viewId.contains("search_box") ||
                    viewId.contains("address_bar") ||
                    viewId.contains("toolbar_text") ||
                    viewId.contains("url_field")

            if (isUrlBarId && text.isNotBlank()) {
                val cleaned = cleanCandidateUrl(text)
                if (cleaned != null) return cleaned
            }

            // Jika teks diawali dengan protokol web http:// atau https://
            if (text.startsWith("http://", ignoreCase = true) || text.startsWith("https://", ignoreCase = true)) {
                val cleaned = cleanCandidateUrl(text)
                if (cleaned != null) return cleaned
            }

            // Cek jika teks berformat nama domain web (misal: "evil-phish.net/login")
            if (DOMAIN_PATTERN.matcher(text).matches() && !text.contains(" ")) {
                val cleaned = cleanCandidateUrl(text)
                if (cleaned != null) return cleaned
            }

            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return null
    }

    private fun cleanCandidateUrl(rawText: String): String? {
        var trimmed = rawText.trim()
        if (trimmed.isBlank() || trimmed.contains(" ")) return null

        // Abaikan skema internal browser
        val lower = trimmed.lowercase()
        if (lower.startsWith("chrome://") ||
            lower.startsWith("about:") ||
            lower.startsWith("content://") ||
            lower.startsWith("file://")
        ) {
            return null
        }

        if (!lower.startsWith("http://") && !lower.startsWith("https://")) {
            trimmed = "https://$trimmed"
        }

        return try {
            val uri = android.net.Uri.parse(trimmed)
            val host = uri.host
            if (host.isNullOrBlank() || !host.contains(".")) return null
            trimmed
        } catch (_: Exception) {
            null
        }
    }

    private fun handleInspectUrl(url: String) {
        val now = System.currentTimeMillis()
        val lastChecked = checkedUrlCache[url] ?: 0L

        // Debounce 10 detik agar tidak membebani pemindaian pada URL yang sama
        if (now - lastChecked < 10000L) {
            return
        }
        checkedUrlCache[url] = now

        thread {
            try {
                Log.i(TAG, "Memeriksa reputasi URL via Kaspersky WebFilter: $url")
                val pageInfo = KasperskySdkManager.checkUrl(this, url)

                if (pageInfo != null && pageInfo.mVerdict == PageInfo.VERDICT_BAD) {
                    val categories = pageInfo.mCategories?.joinToString(", ") { it.name } ?: "Phishing / Malicious Site"
                    Log.w(TAG, "🚨 TAUTAN PHISHING TERDETEKSI: $url ($categories)! Mencegah dan menyelamatkan pengguna...")

                    // 1. Eksekusi tindakan darurat di UI thread: Tekan BACK secara otomatis untuk menutup halaman
                    handler.post {
                        try {
                            performGlobalAction(GLOBAL_ACTION_BACK)
                            Log.i(TAG, "Eksekusi GLOBAL_ACTION_BACK berhasil dijalankan untuk menutup situs phishing.")
                        } catch (e: Exception) {
                            Log.e(TAG, "Gagal menekan tombol kembali: ${e.message}")
                        }
                    }

                    // 2. Kirim notifikasi darurat merah (Heads-Up Alert)
                    ScanForegroundService.postPhishingAlert(
                        this,
                        url,
                        reason = "Situs phishing berbahaya terdeteksi dan diblokir ($categories)"
                    )
                } else {
                    Log.i(TAG, "URL diverifikasi aman: $url")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error saat memeriksa URL: ${e.message}", e)
            }
        }
    }
}


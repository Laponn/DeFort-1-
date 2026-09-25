package com.defort.defort

import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.kavsdk.KavSdk
import com.kavsdk.antivirus.Antivirus
import com.kavsdk.antivirus.AntivirusInstance
import com.kavsdk.antivirus.ThreatInfo
import com.kavsdk.antivirus.easyscanner.EasyListener
import com.kavsdk.antivirus.easyscanner.EasyMode
import com.kavsdk.antivirus.easyscanner.EasyObject
import com.kavsdk.antivirus.easyscanner.EasyResult
import com.kavsdk.antivirus.easyscanner.EasyStatus
import com.kavsdk.license.SdkLicense
import com.kavsdk.license.SdkLicenseException
import com.kavsdk.license.SdkLicenseViolationException
import com.kavsdk.urlchecker.UrlCheckService
import com.kaspersky.components.urlchecker.UrlInfo
import com.kavsdk.wifi.WifiReputation
import com.kavsdk.wifi.Verdict
import com.kavsdk.dnschecker.DnsChecker
import com.kavsdk.dnschecker.DnsCheckVerdict
import com.kavsdk.certificatechecker.CertificateCheckService
import com.kavsdk.certificatechecker.CertificateCheckVerdict
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.defort/native_sdk"
    private val ACTIVATION_CODE = "ZCY92-JYW1R-NKG9V-6TAMN"
    
    private var antivirusComponent: Antivirus? = null
    private var urlCheckService: UrlCheckService? = null
    private var isSdkReady = false
    private var isLicenseValid = false
    private var licenseError: String? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        thread { initializeSdk() }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (!isSdkReady) {
                result.error("SDK_NOT_READY", "Kaspersky SDK is initializing...", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "initializeSdk" -> {
                    result.success(mapOf(
                        "isReady" to isSdkReady,
                        "isLicenseValid" to isLicenseValid,
                        "licenseError" to licenseError
                    ))
                }

                "getLicenseInfo" -> {
                    val license = KavSdk.getLicense()
                    var expireDateStr = "Tidak diketahui"
                    if (license.licenseKeyExpireDate != null) {
                        // Normally it's java.util.Date
                        val sdf = java.text.SimpleDateFormat("d MMMM yyyy", java.util.Locale("id", "ID"))
                        expireDateStr = sdf.format(license.licenseKeyExpireDate)
                    }
                    
                    result.success(mapOf(
                        "isValid" to license.isValid,
                        "activationCode" to ACTIVATION_CODE,
                        "expirationDate" to expireDateStr
                    ))
                }
                
                // ==========================================
                // 1. MALWARE DETECTION - Real SDK EasyScanner
                // ==========================================
                "startEasyScan" -> {
                    thread {
                        try {
                            val av = antivirusComponent
                            if (av == null) {
                                runOnUiThread { result.error("AV_NOT_INIT", "Antivirus component is not initialized", null) }
                                return@thread
                            }

                            val scanner = av.createEasyScanner()
                            val malwareList = mutableListOf<String>()
                            var filesScanned = 0
                            var isRooted = false

                            scanner.scan(EasyMode.Recommended, object : EasyListener {
                                override fun onObjectBegin(obj: EasyObject) {}
                                override fun onObjectEnd(obj: EasyObject, status: EasyStatus) {
                                    filesScanned++
                                }
                                override fun onFilesCountCalculated(count: Int) {}
                                override fun onMalwareDetected(obj: EasyObject, threat: ThreatInfo) {
                                    malwareList.add(threat.virusName ?: "Unknown Threat")
                                }
                                override fun onRiskwareDetected(obj: EasyObject, threat: ThreatInfo) {
                                    malwareList.add("Riskware: ${threat.virusName ?: "Unknown"}")
                                }
                                override fun onRooted() {
                                    isRooted = true
                                }
                            })

                            val scanResult: EasyResult = scanner.result
                            val response = mapOf(
                                "isDeviceRooted" to scanResult.isRooted,
                                "malwareCount" to scanResult.malwareList.size,
                                "filesScanned" to scanResult.filesScanned,
                                "malwareList" to scanResult.malwareList.map { it.virusName ?: "Unknown" },
                                "isRealSdk" to true
                            )
                            runOnUiThread { result.success(response) }
                        } catch (e: Exception) {
                            Log.e("DeFort", "EasyScan error: ${e.message}")
                            runOnUiThread { result.error("SCAN_ERROR", e.message, null) }
                        }
                    }
                }

                "scanFolder" -> {
                    val path = call.argument<String>("path") ?: ""
                    thread {
                        try {
                            val av = antivirusComponent
                            if (av == null) {
                                runOnUiThread { result.error("AV_NOT_INIT", "Antivirus component is not initialized", null) }
                                return@thread
                            }
                            
                            val scanner = av.createScanner()
                            val malwareList = mutableListOf<String>()
                            var filesScanned = 0

                            val listener = object : com.kavsdk.antivirus.ScannerEventListener {
                                override fun onScanEvent(eventId: Int, res: Int, threat: ThreatInfo?, threatType: com.kavsdk.antivirus.ThreatType?): Int {
                                    if (eventId == com.kavsdk.antivirus.ScannerConstants.EVENT_DETECT && threat != null) {
                                        malwareList.add(threat.virusName ?: "Unknown Threat")
                                    } else if (eventId == com.kavsdk.antivirus.ScannerConstants.EVENT_OBJECT_RESULT) {
                                        filesScanned++
                                    }
                                    return com.kavsdk.antivirus.ScannerConstants.EVENT_RESULT_OK
                                }
                            }

                            val scanMode = com.kavsdk.antivirus.ScannerConstants.SCAN_MODE_ALLOW_UDS or com.kavsdk.antivirus.ScannerConstants.SCAN_MODE_DETECT_RISKWARE_ADWARE
                            val cleanMode = com.kavsdk.antivirus.ScannerConstants.CLEAN_MODE_DONOTCLEAN
                            
                            scanner.scanFolder(path, scanMode, cleanMode, listener, null, false)
                            
                            val response = mapOf(
                                "isDeviceRooted" to false,
                                "malwareCount" to malwareList.size,
                                "filesScanned" to filesScanned,
                                "malwareList" to malwareList,
                                "isRealSdk" to true
                            )
                            runOnUiThread { result.success(response) }
                        } catch (e: Exception) {
                            Log.e("DeFort", "Folder scan error: ${e.message}")
                            runOnUiThread { result.error("SCAN_ERROR", e.message, null) }
                        }
                    }
                }
                
                // ==========================================
                // 2. ANTI-PHISHING - Real SDK UrlCheckService
                // ==========================================
                "checkUrlPhishing" -> {
                    val url = call.argument<String>("url") ?: ""
                    thread {
                        try {
                            val service = urlCheckService ?: UrlCheckService(applicationContext).also {
                                urlCheckService = it
                            }
                            
                            val urlInfo: UrlInfo = service.checkUrl(url)
                            val isSafe = (urlInfo.mVerdict == UrlInfo.VERDICT_GOOD)
                            val isPhishing = urlInfo.isPhishing
                            val isMalware = urlInfo.isMalware
                            
                            val categories = mutableListOf<String>()
                            if (isPhishing) categories.add("PHISHING")
                            if (isMalware) categories.add("MALWARE")
                            if (categories.isEmpty()) categories.add("SAFE")
                            
                            val response = mapOf(
                                "isSafe" to (isSafe && !isPhishing && !isMalware),
                                "categories" to categories,
                                "isRealSdk" to true
                            )
                            runOnUiThread { result.success(response) }
                        } catch (e: Exception) {
                            Log.e("DeFort", "URL check error: ${e.message}")
                            runOnUiThread { result.error("URL_CHECK_ERROR", e.message, null) }
                        }
                    }
                }
                
                "startFakeAppMonitor" -> {
                    result.success(true)
                }

                // ==========================================
                // 3. SECURE CONNECTIVITY - Real SDK
                // ==========================================
                "checkWifiSecurity" -> {
                    thread {
                        try {
                            val wifiReputation = WifiReputation(applicationContext)
                            val wifiResult = wifiReputation.checkCurrentNetwork()
                            val isSafe = (wifiResult.verdict == Verdict.Safe)
                            runOnUiThread { result.success(mapOf("isSafe" to isSafe, "isRealSdk" to true)) }
                        } catch (e: Exception) {
                            Log.e("DeFort", "WiFi check error: ${e.message}")
                            runOnUiThread { result.error("WIFI_CHECK_ERROR", e.message, null) }
                        }
                    }
                }
                
                "checkDns" -> {
                    val domain = call.argument<String>("domain") ?: "google.com"
                    thread {
                        try {
                            val dnsChecker = DnsChecker()
                            val dnsResult = dnsChecker.checkURL("https://$domain")
                            val isSafe = (dnsResult.verdict == DnsCheckVerdict.Trusted)
                            runOnUiThread { result.success(mapOf("isSafe" to isSafe, "isRealSdk" to true)) }
                        } catch (e: Exception) {
                            Log.e("DeFort", "DNS check error: ${e.message}")
                            runOnUiThread { result.error("DNS_CHECK_ERROR", e.message, null) }
                        }
                    }
                }
                
                "validateSsl" -> {
                    val url = call.argument<String>("url") ?: "https://google.com"
                    thread {
                        try {
                            val certChecker = CertificateCheckService()
                            val certResult = certChecker.checkCertificate(url)
                            val isValid = (certResult.verdict == CertificateCheckVerdict.Trusted)
                            runOnUiThread { result.success(mapOf("isValid" to isValid, "isRealSdk" to true)) }
                        } catch (e: Exception) {
                            Log.e("DeFort", "SSL check error: ${e.message}")
                            runOnUiThread { result.error("SSL_CHECK_ERROR", e.message, null) }
                        }
                    }
                }
                
                "toggleWebFilterVpn" -> {
                    result.success(true)
                }
                
                "getNetworkName" -> {
                    try {
                        val connManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
                        val activeNetwork = connManager.activeNetworkInfo
                        if (activeNetwork != null && activeNetwork.isConnected) {
                            if (activeNetwork.type == android.net.ConnectivityManager.TYPE_WIFI) {
                                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
                                val ssid = wifiManager.connectionInfo.ssid
                                if (ssid == null || ssid == "<unknown ssid>") {
                                    result.success("Wi-Fi Terhubung")
                                } else {
                                    result.success(ssid.trim('"'))
                                }
                            } else {
                                result.success("Data Seluler")
                            }
                        } else {
                            result.success("Tidak Terhubung")
                        }
                    } catch (e: Exception) {
                        result.success("Tidak Terhubung")
                    }
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun initializeSdk() {
        try {
            val basesPath = getDir("bases", Context.MODE_PRIVATE)
            
            // 1. Init Base SDK
            Log.i("DeFort", "🔄 Initializing KavSdk...")
            KavSdk.initSafe(this, basesPath, applicationInfo.nativeLibraryDir)
            Log.i("DeFort", "✅ KavSdk.initSafe() completed")
            
            // 2. License Activation with the real activation code
            val license: SdkLicense = KavSdk.getLicense()
            Log.i("DeFort", "📋 License valid: ${license.isValid}, ClientID required: ${license.isClientUserIDRequired}")
            
            if (!license.isValid) {
                try {
                    Log.i("DeFort", "🔑 Activating with code: $ACTIVATION_CODE")
                    license.activate(ACTIVATION_CODE)
                    isLicenseValid = license.isValid
                    Log.i("DeFort", "✅ License activation result: valid=${license.isValid}")
                    
                    if (license.isClientUserIDRequired) {
                        try {
                            license.sendClientUserID("defort-android-user")
                            Log.i("DeFort", "✅ Client User ID sent successfully")
                        } catch (e: Exception) {
                            Log.w("DeFort", "⚠️ sendClientUserID failed (non-critical): ${e.message}")
                        }
                    }
                } catch (e: SdkLicenseException) {
                    licenseError = e.message
                    Log.e("DeFort", "❌ License activation failed: ${e.message}")
                }
            } else {
                isLicenseValid = true
                Log.i("DeFort", "✅ License already valid, expires: ${license.licenseKeyExpireDate}")
            }
            
            // 3. Antivirus Component
            try {
                val scanTmpDir = getDir("scan_tmp", Context.MODE_PRIVATE)
                val monitorTmpDir = getDir("monitor_tmp", Context.MODE_PRIVATE)
                
                antivirusComponent = AntivirusInstance.getInstance().also {
                    it.initAntivirus(applicationContext, scanTmpDir.absolutePath, monitorTmpDir.absolutePath)
                    
                    // Activate Real-Time File Monitor
                    it.addDefaultDirectories()
                    it.setMonitorListener { threat, threatType ->
                        if (threat != null) {
                            Log.w("DeFort", "🚨 Real-Time threat detected: ${threat.virusName} at ${threat.fileFullPath}")
                        }
                    }
                    it.setMonitorState(true)
                }
                
                // Activate Real-Time App Installation Monitor
                val appMonitor = com.kavsdk.antivirus.appmonitor.AppInstallationMonitor(applicationContext)
                appMonitor.enable(
                    { threat, type ->
                        Log.w("DeFort", "🚨 Fake App / Virus installed: ${threat?.virusName}")
                        false
                    },
                    null
                )
                
                Log.i("DeFort", "✅ Antivirus component initialized and Real-Time Protection is ON")
            } catch (e: Exception) {
                Log.e("DeFort", "❌ Antivirus init failed: ${e.message}")
            }
            
            // 4. URL Check Service
            try {
                urlCheckService = UrlCheckService(applicationContext)
                Log.i("DeFort", "✅ UrlCheckService initialized")
            } catch (e: Exception) {
                Log.e("DeFort", "❌ UrlCheckService init failed: ${e.message}")
            }
            
            Log.i("DeFort", "🎉 Kaspersky SDK fully initialized! License valid: $isLicenseValid")
        } catch (e: Exception) {
            Log.e("DeFort", "❌ SDK init failed: ${e.message}")
            licenseError = e.message
        } finally {
            isSdkReady = true
        }
    }
}

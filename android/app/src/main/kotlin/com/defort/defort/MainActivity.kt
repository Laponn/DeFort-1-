package com.defort.defort

import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.kavsdk.KavSdk
import com.kavsdk.antivirus.Antivirus
import com.kavsdk.antivirus.AntivirusInstance
import com.kavsdk.antivirus.easyscanner.EasyScanner
import com.kavsdk.antivirus.easyscanner.EasyMode
import com.kavsdk.antivirus.easyscanner.EasyListener
import com.kavsdk.antivirus.easyscanner.EasyObject
import com.kavsdk.antivirus.easyscanner.EasyStatus
import com.kavsdk.antivirus.ThreatInfo
import com.kavsdk.license.SdkLicense
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.defort/native_sdk"
    
    private var antivirusComponent: Antivirus? = null
    private var isSdkReady = false
    
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
                    result.success(isSdkReady)
                }
                
                // 1. MALWARE DETECTION (MOCK to bypass License Violation in Demo)
                "startEasyScan" -> {
                    thread {
                        try {
                            Thread.sleep(2000) // Simulate scan delay
                            val response = mapOf(
                                "isDeviceRooted" to false,
                                "malwareCount" to 0,
                                "filesScanned" to 1245,
                                "malwareList" to emptyList<String>()
                            )
                            runOnUiThread { result.success(response) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("SCAN_ERROR", e.message, null) }
                        }
                    }
                }
                
                // 2. ANTI-PHISHING & FAKE APPS (MOCK until correct Javadoc is found)
                "checkUrlPhishing" -> {
                    val url = call.argument<String>("url") ?: ""
                    thread {
                        try {
                            Thread.sleep(1500) // Simulate network delay
                            val isSafe = !url.contains("phishing") && !url.contains("malware")
                            val categories = if (isSafe) listOf("SAFE") else listOf("PHISHING", "MALWARE")
                            
                            val response = mapOf(
                                "isSafe" to isSafe,
                                "categories" to categories
                            )
                            runOnUiThread { result.success(response) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("URL_CHECK_ERROR", e.message, null) }
                        }
                    }
                }
                "startFakeAppMonitor" -> {
                    result.success(true)
                }

                // 3. SECURE CONNECTIVITY (MOCK until correct Javadoc is found)
                "checkWifiSecurity" -> {
                    thread {
                        Thread.sleep(1000)
                        runOnUiThread { result.success(mapOf("isSafe" to true)) }
                    }
                }
                "checkDns" -> {
                    thread {
                        Thread.sleep(800)
                        runOnUiThread { result.success(true) }
                    }
                }
                "validateSsl" -> {
                    thread {
                        Thread.sleep(1200)
                        runOnUiThread { result.success(true) }
                    }
                }
                
                // IOS ONLY
                "toggleWebFilterVpn" -> {
                    result.success(true)
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
            KavSdk.initSafe(this, basesPath, applicationInfo.nativeLibraryDir)
            
            // 2. License Activation
            val license: SdkLicense = KavSdk.getLicense()
            if (!license.isValid && !license.isClientUserIDRequired) {
                try {
                    license.activate(null)
                } catch (e: Exception) {
                    Log.e("DeFort", "License activation failed: ${e.message}")
                }
            }
            
            // 3. Antivirus Component
            val scanTmpDir = getDir("scan_tmp", Context.MODE_PRIVATE)
            val monitorTmpDir = getDir("monitor_tmp", Context.MODE_PRIVATE)
            
            antivirusComponent = AntivirusInstance.getInstance().also {
                it.initAntivirus(applicationContext, scanTmpDir.absolutePath, monitorTmpDir.absolutePath)
            }
            
            Log.i("DeFort", "✅ Kaspersky SDK initialized successfully")
        } catch (e: Exception) {
            Log.e("DeFort", "❌ SDK init failed: ${e.message}")
        } finally {
            // ALWAYS set to true for the UI Mock demo to work even without a valid license
            isSdkReady = true
        }
    }
}

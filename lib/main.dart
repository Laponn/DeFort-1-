import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'ui/android/android_main.dart';
import 'ui/android/screens/login_screen.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(prefs)),
      ],
      child: DeFortSecurityApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;

  AppState(this.prefs) {
    _loadFromPrefs();
  }

  bool isPremium = false;
  String language = 'id';
  bool isDarkMode = false;
  
  // User Profile
  String userName = 'User Simulator';
  String userEmail = 'user.simulator@example.com';
  String userPhone = '+62 812-3456-7890';
  bool is2FAEnabled = false;
  
  // Toggles
  bool realTimeProtection = true;
  bool puaDetection = false;
  bool webFilterVpn = true;
  bool autoUpdate = true;
  bool selfDefense = true;

  // Notifications preferences
  bool notificationsEnabled = true;
  bool threatAlerts = true;
  bool phishingAlerts = true;
  bool scanCompletionAlerts = true;

  // Background Security & Protection
  bool backgroundProtectionEnabled = true;
  bool realTimePhishingProtection = true;

  void reloadFromPrefs() => _loadFromPrefs();

  void _loadFromPrefs() {
    userName = prefs.getString('userName') ?? 'User Simulator';
    userEmail = prefs.getString('userEmail') ?? 'user.simulator@example.com';
    userPhone = prefs.getString('userPhone') ?? '+62 812-3456-7890';
    is2FAEnabled = prefs.getBool('is2FAEnabled') ?? false;
    isPremium = prefs.getBool('isPremium') ?? false;
    language = prefs.getString('language') ?? 'id';
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    threatAlerts = prefs.getBool('threatAlerts') ?? true;
    phishingAlerts = prefs.getBool('phishingAlerts') ?? true;
    scanCompletionAlerts = prefs.getBool('scanCompletionAlerts') ?? true;
    backgroundProtectionEnabled = prefs.getBool('backgroundProtectionEnabled') ?? true;
    realTimePhishingProtection = prefs.getBool('realTimePhishingProtection') ?? true;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email, String phone) async {
    userName = name;
    userEmail = email;
    userPhone = phone;
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userPhone', phone);
    notifyListeners();
  }

  Future<void> toggle2FA() async {
    is2FAEnabled = !is2FAEnabled;
    await prefs.setBool('is2FAEnabled', is2FAEnabled);
    notifyListeners();
  }

  Future<void> togglePremium() async {
    isPremium = !isPremium;
    await prefs.setBool('isPremium', isPremium);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    language = lang;
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }

  Future<void> toggleNotificationSetting(String key) async {
    switch (key) {
      case 'master':
        notificationsEnabled = !notificationsEnabled;
        await prefs.setBool('notificationsEnabled', notificationsEnabled);
        break;
      case 'threat':
        threatAlerts = !threatAlerts;
        await prefs.setBool('threatAlerts', threatAlerts);
        break;
      case 'phishing':
        phishingAlerts = !phishingAlerts;
        await prefs.setBool('phishingAlerts', phishingAlerts);
        break;
      case 'scanComplete':
        scanCompletionAlerts = !scanCompletionAlerts;
        await prefs.setBool('scanCompletionAlerts', scanCompletionAlerts);
        break;
    }
    notifyListeners();
  }

  Future<void> setBackgroundProtection(bool val) async {
    backgroundProtectionEnabled = val;
    await prefs.setBool('backgroundProtectionEnabled', val);
    notifyListeners();
  }

  Future<void> setPhishingProtection(bool val) async {
    realTimePhishingProtection = val;
    await prefs.setBool('realTimePhishingProtection', val);
    notifyListeners();
  }

  void toggleSetting(String key) {
    switch (key) {
      case 'realTime':
        realTimeProtection = !realTimeProtection;
        break;
      case 'pua':
        puaDetection = !puaDetection;
        break;
      case 'webFilterVpn':
        webFilterVpn = !webFilterVpn;
        break;
      case 'autoUpdate':
        autoUpdate = !autoUpdate;
        break;
      case 'selfDefense':
        selfDefense = !selfDefense;
        break;
    }
    notifyListeners();
  }
}

class DeFortSecurityApp extends StatelessWidget {
  final bool isLoggedIn;
  const DeFortSecurityApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'DeFort Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF111827),
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: isLoggedIn ? const AndroidMainScreen() : const LoginScreen(),
    );
  }
}

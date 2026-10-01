import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants.dart';
import '../../../core/native_channel.dart';
import '../../../core/permissions.dart';
import '../android_main.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  
  String _statusText = 'Memulai DeFort Security...';
  double _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.5)),
    );

    _logoController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Check Permissions
      _updateStatus('Memeriksa izin aplikasi...', 0.15);
      await Future.delayed(const Duration(milliseconds: 500));
      await PermissionService.requestAllPermissions();

      // Step 2: Initialize SDK
      _updateStatus('Menginisialisasi Kaspersky SDK...', 0.35);
      await Future.delayed(const Duration(milliseconds: 300));
      
      final sdkResult = await KasperskyChannel.initSdk();
      final bool isReady = sdkResult['isReady'] == true;
      
      if (!isReady) {
        // SDK might still be initializing, wait a bit and continue
        _updateStatus('Menunggu SDK siap...', 0.5);
        await Future.delayed(const Duration(seconds: 2));
      }

      // Step 3: Verify License
      _updateStatus('Memverifikasi lisensi...', 0.65);
      await Future.delayed(const Duration(milliseconds: 500));
      
      try {
        final licenseInfo = await KasperskyChannel.getLicenseInfo();
        final bool isValid = licenseInfo['isValid'] == true;
        if (isValid) {
          _updateStatus('Lisensi terverifikasi ✓', 0.8);
        } else {
          _updateStatus('Lisensi sedang diaktifkan...', 0.8);
        }
      } catch (_) {
        // License check may fail if SDK is still loading, continue anyway
        _updateStatus('Melanjutkan inisialisasi...', 0.8);
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Check login status
      _updateStatus('Menyiapkan aplikasi...', 0.95);
      await Future.delayed(const Duration(milliseconds: 400));
      
      _updateStatus('Siap!', 1.0);
      await Future.delayed(const Duration(milliseconds: 600));

      // Navigate
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final bool hasOnboarded = prefs.getBool('hasOnboarded') ?? false;

      if (!mounted) return;

      Widget destination;
      if (!hasOnboarded) {
        destination = const OnboardingScreen();
      } else if (isLoggedIn) {
        destination = const AndroidMainScreen();
      } else {
        destination = const LoginScreen();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _statusText = 'Gagal menginisialisasi';
      });
    }
  }

  void _updateStatus(String text, double progress) {
    if (!mounted) return;
    setState(() {
      _statusText = text;
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -100, left: -80, child: _buildBlob(AppColors.blobBlue, 300)),
          Positioned(bottom: -50, right: -60, child: _buildBlob(AppColors.blobPurple, 250)),
          Positioned(top: 200, right: -100, child: _buildBlob(AppColors.blobGreen, 200)),

          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 64),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'DeFort Security',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary(isDark),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Powered by Kaspersky SDK',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Progress
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: isDark ? Colors.white12 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _hasError ? AppColors.error : AppColors.primaryAdaptive(isDark),
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 13,
                            color: _hasError
                                ? AppColors.error
                                : AppColors.textSecondary(isDark),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  if (_hasError) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(fontSize: 12, color: AppColors.error.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = '';
                          _progress = 0;
                        });
                        _initializeApp();
                      },
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Version at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(isDark).withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.4), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

/// Onboarding screen for first-time users
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: LucideIcons.shieldCheck,
      title: 'Anti-Malware',
      subtitle: 'Pindai dan lindungi perangkat Anda dari malware, virus, dan ancaman lainnya secara real-time.',
      color: Colors.indigo,
    ),
    _OnboardingPage(
      icon: LucideIcons.globe,
      title: 'Anti-Phishing',
      subtitle: 'Blokir tautan phishing dan situs web berbahaya secara otomatis dengan teknologi Kaspersky.',
      color: Colors.orange,
    ),
    _OnboardingPage(
      icon: LucideIcons.wifi,
      title: 'Keamanan Jaringan',
      subtitle: 'Analisis keamanan koneksi Wi-Fi, DNS, dan sertifikat SSL untuk memastikan koneksi Anda aman.',
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Lewati',
                  style: TextStyle(
                    color: AppColors.primaryAdaptive(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 80, color: page.color),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + Button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primaryAdaptive(isDark)
                              : AppColors.textSecondary(isDark).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAdaptive(isDark),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Selanjutnya' : 'Mulai Sekarang',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasOnboarded', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

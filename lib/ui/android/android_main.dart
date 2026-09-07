import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../core/localization.dart';

import 'tabs/dashboard_tab.dart';
import 'tabs/scan_tab.dart';
import 'tabs/identity_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/menu_tab.dart';

class AndroidMainScreen extends StatefulWidget {
  const AndroidMainScreen({super.key});

  @override
  State<AndroidMainScreen> createState() => _AndroidMainScreenState();
}

class _AndroidMainScreenState extends State<AndroidMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const ScanTab(),
    const IdentityTab(),
    const NetworkTab(),
    const MenuTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // Set to extend body so the bottom nav bar overlays the scrollable content
      extendBody: true,
      body: _tabs[_currentIndex],
      bottomNavigationBar: _buildFloatingNavBar(context),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: isDark ? Colors.white24 : Colors.white.withOpacity(0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, 0, LucideIcons.shield, AppLoc.tr(context, 'Beranda')),
                _buildNavItem(context, 1, LucideIcons.search, AppLoc.tr(context, 'Pindai')),
                _buildNavItem(context, 2, LucideIcons.userCheck, AppLoc.tr(context, 'Identitas')),
                _buildNavItem(context, 3, LucideIcons.wifi, AppLoc.tr(context, 'Jaringan')),
                _buildNavItem(context, 4, LucideIcons.settings, AppLoc.tr(context, 'Menu')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.indigoAccent : Colors.indigo;
    final unselectedColor = isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : unselectedColor,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/constants.dart';

/// Shared Glass Morphism Widgets used across the entire app
/// Extracted to avoid code duplication in 9+ files

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppRadius.xxl,
    this.blurSigma = 16,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.glass(isDark),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassBorder(isDark)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class BackgroundBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double blurSigma;

  const BackgroundBlob({
    super.key,
    required this.color,
    required this.size,
    this.blurSigma = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

/// A scaffold with blob background decorations
class BlobScaffold extends StatelessWidget {
  final Widget child;
  final List<BlobPosition> blobs;
  final PreferredSizeWidget? appBar;

  const BlobScaffold({
    super.key,
    required this.child,
    required this.blobs,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: appBar,
      body: Stack(
        children: [
          ...blobs.map((b) => Positioned(
            top: b.top,
            bottom: b.bottom,
            left: b.left,
            right: b.right,
            child: BackgroundBlob(color: b.color, size: b.size),
          )),
          child,
        ],
      ),
    );
  }
}

class BlobPosition {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Color color;
  final double size;

  const BlobPosition({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.color,
    required this.size,
  });
}

/// Status badge (used in account, dashboard, etc.)
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Bottom sheet handle bar
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

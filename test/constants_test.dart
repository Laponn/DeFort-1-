import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:defort/core/constants.dart';

void main() {
  group('AppColors', () {
    test('bg returns correct color for light mode', () {
      expect(AppColors.bg(false), AppColors.bgLight);
    });

    test('bg returns correct color for dark mode', () {
      expect(AppColors.bg(true), AppColors.bgDark);
    });

    test('textPrimary returns correct color', () {
      expect(AppColors.textPrimary(false), AppColors.textPrimaryLight);
      expect(AppColors.textPrimary(true), AppColors.textPrimaryDark);
    });

    test('textSecondary returns correct color', () {
      expect(AppColors.textSecondary(false), AppColors.textSecondaryLight);
      expect(AppColors.textSecondary(true), AppColors.textSecondaryDark);
    });

    test('primaryAdaptive returns correct color', () {
      expect(AppColors.primaryAdaptive(false), AppColors.primary);
      expect(AppColors.primaryAdaptive(true), AppColors.primaryLight);
    });

    test('glass returns correct color', () {
      expect(AppColors.glass(false), isA<Color>());
      expect(AppColors.glass(true), isA<Color>());
    });

    test('all blob colors are defined', () {
      expect(AppColors.blobBlue, isA<Color>());
      expect(AppColors.blobPurple, isA<Color>());
      expect(AppColors.blobGreen, isA<Color>());
      expect(AppColors.blobRed, isA<Color>());
      expect(AppColors.blobOrange, isA<Color>());
      expect(AppColors.blobIndigo, isA<Color>());
      expect(AppColors.blobTeal, isA<Color>());
      expect(AppColors.blobYellow, isA<Color>());
      expect(AppColors.blobEmerald, isA<Color>());
    });
  });

  group('AppSpacing', () {
    test('spacing values are increasing', () {
      expect(AppSpacing.xs < AppSpacing.sm, true);
      expect(AppSpacing.sm < AppSpacing.md, true);
      expect(AppSpacing.md < AppSpacing.lg, true);
      expect(AppSpacing.lg < AppSpacing.xl, true);
      expect(AppSpacing.xl < AppSpacing.xxl, true);
    });
  });

  group('AppRadius', () {
    test('radius values are increasing', () {
      expect(AppRadius.sm < AppRadius.md, true);
      expect(AppRadius.md < AppRadius.lg, true);
      expect(AppRadius.lg < AppRadius.xl, true);
      expect(AppRadius.xl < AppRadius.xxl, true);
      expect(AppRadius.xxl < AppRadius.pill, true);
    });
  });
}

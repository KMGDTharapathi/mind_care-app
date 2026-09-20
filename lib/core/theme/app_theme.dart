import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryLight,
          primaryContainer: AppColors.primaryContainerLight,
          surface: AppColors.surfaceLight,
          onPrimary: AppColors.textDark,
          onSurface: AppColors.textDark,
          onPrimaryContainer: AppColors.textDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge.copyWith(
            color: AppColors.textDark,
          ),
          titleLarge: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textDark,
          ),
          titleMedium: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textDark,
          ),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textDark,
          ),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark,
          ),
          labelLarge: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textDark,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryDark,
          primaryContainer: AppColors.primaryContainerDark,
          surface: AppColors.surfaceDark,
          onPrimary: AppColors.textLight,
          onSurface: AppColors.textLight,
          onPrimaryContainer: AppColors.textLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge.copyWith(
            color: AppColors.textLight,
          ),
          titleLarge: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textLight,
          ),
          titleMedium: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textLight,
          ),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textLight,
          ),
          bodyMedium: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textLight,
          ),
          labelLarge: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textLight,
          ),
        ),
      );
}

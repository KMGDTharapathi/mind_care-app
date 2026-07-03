import 'package:flutter/material.dart';
import 'app_strings.dart';

/// Holds the current language and provides [AppStrings] to the widget tree.
class LanguageProvider extends InheritedWidget {
  final AppStrings strings;

  const LanguageProvider({
    super.key,
    required this.strings,
    required super.child,
  });

  static AppStrings of(BuildContext context) {
    if (!context.mounted) return AppStrings.en;
    final provider =
        context.dependOnInheritedWidgetOfExactType<LanguageProvider>();
    return provider?.strings ?? AppStrings.en;
  }

  /// Read-only access — does NOT register a rebuild dependency.
  /// Use this inside dialog builders and callbacks to avoid stale-context crashes.
  static AppStrings read(BuildContext context) {
    if (!context.mounted) return AppStrings.en;
    final provider =
        context.getInheritedWidgetOfExactType<LanguageProvider>();
    return provider?.strings ?? AppStrings.en;
  }

  @override
  bool updateShouldNotify(LanguageProvider oldWidget) =>
      strings.languageCode != oldWidget.strings.languageCode;
}

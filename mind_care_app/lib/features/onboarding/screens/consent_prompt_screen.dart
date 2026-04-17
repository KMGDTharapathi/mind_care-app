import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/core/theme/app_theme.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/main.dart' show appLanguage;
import 'package:mind_care_app/services/consent/consent_service.dart';

/// Shown on first launch to ask the user whether they consent to analytics.
/// After a choice is made the normal [MindCareApp] is launched.
class ConsentPromptScreen extends StatefulWidget {
  const ConsentPromptScreen({super.key});

  @override
  State<ConsentPromptScreen> createState() => _ConsentPromptScreenState();
}

class _ConsentPromptScreenState extends State<ConsentPromptScreen> {
  bool _saving = false;

  Future<void> _handleChoice(bool consent) async {
    if (_saving) return;
    setState(() => _saving = true);
    await ConsentService().setAnalyticsConsent(consent);

    bool onboardingComplete = false;
    try {
      onboardingComplete = await PreferencesService.isOnboardingComplete();
    } catch (_) {}

    runApp(_MindCareAppWrapper(onboardingComplete: onboardingComplete));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, size: 64, color: AppColors.primaryLight),
                const SizedBox(height: 24),
                const Text(
                  'Help us improve MindCare',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'d like to collect anonymous usage data to understand how the app is used and improve your experience. No personal information is ever shared.',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondaryDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _handleChoice(true),
                    child: const Text('Allow'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _handleChoice(false),
                    child: const Text('No thanks'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin wrapper that boots the real app after consent is stored.
class _MindCareAppWrapper extends StatefulWidget {
  final bool onboardingComplete;
  const _MindCareAppWrapper({required this.onboardingComplete});

  @override
  State<_MindCareAppWrapper> createState() => _MindCareAppWrapperState();
}

class _MindCareAppWrapperState extends State<_MindCareAppWrapper> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.onboardingComplete);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit()..loadSettings(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (prev, next) => prev.themeMode != next.themeMode,
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'MindCare',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            routerConfig: _router,
            builder: (context, child) => ValueListenableBuilder<AppStrings>(
              valueListenable: appLanguage,
              builder: (context, strings, _) => LanguageProvider(
                strings: strings,
                child: child!,
              ),
            ),
          );
        },
      ),
    );
  }
}

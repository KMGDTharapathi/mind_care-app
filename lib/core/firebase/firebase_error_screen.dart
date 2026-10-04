import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/core/firebase/firebase_initializer.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/core/theme/app_theme.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/onboarding/screens/consent_prompt_screen.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'package:mind_care_app/services/consent/consent_service.dart';

/// Non-dismissible full-screen error shown when Firebase fails to initialise.
/// The retry button re-runs [FirebaseInitializer.init()] and, on success,
/// restarts the normal app flow.
class FirebaseErrorScreen extends StatefulWidget {
  const FirebaseErrorScreen({super.key});

  @override
  State<FirebaseErrorScreen> createState() => _FirebaseErrorScreenState();
}

class _FirebaseErrorScreenState extends State<FirebaseErrorScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    final result = await FirebaseInitializer.init();
    if (!mounted) return;

    if (result.success) {
      final consentDecided = await ConsentService().hasConsentBeenDecided();
      if (!mounted) return;

      if (!consentDecided) {
        runApp(const ConsentPromptScreen());
        return;
      }

      bool onboardingComplete = false;
      try {
        onboardingComplete = await PreferencesService.isOnboardingComplete();
      } catch (_) {}

      runApp(_MindCareAppWrapper(onboardingComplete: onboardingComplete));
    } else {
      setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 72, color: AppColors.primaryLight),
                  const SizedBox(height: 24),
                  const Text(
                    'Unable to connect',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MindCare could not initialise its services. Please check your connection and try again.',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondaryDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _retrying ? null : _retry,
                      child: _retrying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Try again'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin wrapper that boots the real app after a successful Firebase retry.
class _MindCareAppWrapper extends StatelessWidget {
  final bool onboardingComplete;
  const _MindCareAppWrapper({required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit()..loadSettings(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'MindCare',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            routerConfig: AppRouter.createRouter(onboardingComplete),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}

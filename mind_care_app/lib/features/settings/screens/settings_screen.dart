import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/auth/bloc/auth_bloc.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'package:mind_care_app/main.dart' show appUserName;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Read directly from the global notifier — always in sync with home screen
  String? get _userName => appUserName.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthBloc>().add(AuthStarted());
    });
    // Ensure notifier is populated if not already set
    if (appUserName.value == null) {
      PreferencesService.getUserName().then((name) {
        if (mounted) appUserName.value = name;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _changeName(BuildContext context) async {
    final controller = TextEditingController(text: _userName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.person_outline_rounded,
              color: Color(0xFF5BA8A0), size: 22),
          SizedBox(width: 10),
          Text('Change Name'),
        ]),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5BA8A0), width: 1.5),
            ),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0)),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    // Guard: widget may have been disposed while dialog was open
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      await PreferencesService.setUserName(result);
      if (!mounted) return;
      // Update global notifier — _onNameChanged listener will trigger setState
      appUserName.value = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        final cubit = context.read<SettingsCubit>();
        if (authState is AuthAuthenticated) {
          cubit.updateAuthState(authState.user);
        } else if (authState is AuthAnonymous) {
          cubit.updateAuthState(authState.user);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Builder(
          builder: (ctx) => Text(LanguageProvider.of(ctx).settingsTitle),
        )),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final s = LanguageProvider.of(context);
            final cubit = context.read<SettingsCubit>();
            return ListView(
              children: [
                // ── Profile ────────────────────────────────────────────────
                _SectionHeader(title: 'Profile'),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Your Name'),
                  subtitle: ValueListenableBuilder<String?>(
                    valueListenable: appUserName,
                    builder: (_, name, __) => Text(
                      name != null && name.isNotEmpty ? name : 'Not set',
                      style: TextStyle(
                        color: name != null && name.isNotEmpty ? null : Colors.grey,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF5BA8A0)),
                  onTap: () => _changeName(context),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined,
                      color: Color(0xFFE57373)),
                  title: const Text('Log as New User',
                      style: TextStyle(color: Color(0xFFE57373))),
                  subtitle: const Text('Clear your name and restart onboarding'),
                  onTap: () => _confirmNewUser(context),
                ),
                const Divider(),

                // ── Account ────────────────────────────────────────────────
                _SectionHeader(title: s.sectionAccount),
                if (state.isAuthenticated) ...[
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: Text(s.signedInAs),
                    subtitle: Text(state.userEmail ?? ''),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(s.signOut),
                    onTap: () => context.read<AuthBloc>().add(AuthSignOut()),
                  ),
                ] else
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: Text(s.signIn),
                    subtitle: Text(s.signInSubtitle),
                    onTap: () => context.push('/sign-in'),
                  ),
                const Divider(),

                // ── Appearance ─────────────────────────────────────────────
                _SectionHeader(title: s.sectionAppearance),
                SwitchListTile(
                  title: Text(s.darkMode),
                  subtitle: Text(s.darkModeSubtitle),
                  value: state.themeMode == ThemeMode.dark,
                  onChanged: (isDark) => cubit.setThemeMode(
                    isDark ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
                const Divider(),

                // ── Notifications ──────────────────────────────────────────
                _SectionHeader(title: s.sectionNotifications),
                SwitchListTile(
                  title: Text(s.dailyRemindersTitle),
                  subtitle: Text(s.dailyRemindersSubtitle),
                  value: state.notificationsEnabled,
                  onChanged: (enabled) =>
                      _handleNotificationToggle(context, cubit, enabled, s),
                ),
                if (state.notificationsEnabled)
                  ListTile(
                    title: Text(s.reminderTime),
                    subtitle: Text(
                      state.notificationTime != null
                          ? state.notificationTime!.format(context)
                          : '9:00 AM',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(context, cubit, state),
                  ),
                const Divider(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleNotificationToggle(
    BuildContext context,
    SettingsCubit cubit,
    bool enabled,
    AppStrings s,
  ) async {
    if (!enabled) {
      await cubit.setNotificationsEnabled(false);
      return;
    }
    await cubit.setNotificationsEnabled(
      true,
      onShowExplanation: () => _showPermissionExplanation(context, s),
    );
  }

  Future<bool> _showPermissionExplanation(
      BuildContext context, AppStrings s) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.enableNotifications),
        content: Text(s.notificationExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.allow),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickTime(
    BuildContext context,
    SettingsCubit cubit,
    SettingsState state,
  ) async {
    final initial =
        state.notificationTime ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      await cubit.setNotificationTime(picked);
    }
  }

  Future<void> _confirmNewUser(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.person_add_outlined, color: Color(0xFFE57373), size: 22),
          SizedBox(width: 10),
          Text('Log as New User'),
        ]),
        content: const Text(
          'This will clear your name and take you back to the welcome screen. Your other data will be kept.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE57373)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // Clear name and language
      await PreferencesService.setUserName('');
      await PreferencesService.setAppLanguage('');
      // Reset notifier AFTER prefs are cleared
      appUserName.value = null;
      // Small delay to ensure prefs are flushed before splash reads them
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) context.go('/splash');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

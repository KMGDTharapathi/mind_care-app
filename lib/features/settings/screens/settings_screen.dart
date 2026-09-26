import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/auth/bloc/auth_bloc.dart';
import 'package:mind_care_app/features/settings/bloc/settings_cubit.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mind_care_app/main.dart' show appUserName, appLanguage;

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
      builder: (ctx) {
        final s = LanguageProvider.read(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.person_outline_rounded,
                color: Color(0xFF5BA8A0), size: 22),
            const SizedBox(width: 10),
            Text(s.changeName),
          ]),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: s.enterYourName,
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
              child: Text(s.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5BA8A0)),
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(s.save),
            ),
          ],
        );
      },
    );
    controller.dispose();
    // Guard: widget may have been disposed while dialog was open
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      await PreferencesService.setUserName(result);
      if (!mounted) return;
      // Defer notifier update to next frame to avoid InheritedWidget assertion
      // when dialog is still in the process of being dismissed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appUserName.value = result;
      });
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
                const SizedBox(height: 16),
                const _ProfileAvatarSection(),
                const SizedBox(height: 16),
                // ── Profile ────────────────────────────────────────────────
                _SectionHeader(title: s.sectionProfile),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(s.yourName),
                  subtitle: ValueListenableBuilder<String?>(
                    valueListenable: appUserName,
                    builder: (_, name, __) => Text(
                      name != null && name.isNotEmpty ? name : s.nameNotSet,
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
                  title: Text(s.logAsNewUser,
                      style: const TextStyle(color: Color(0xFFE57373))),
                  subtitle: Text(s.logAsNewUserSubtitle),
                  onTap: () => _confirmNewUser(context),
                ),
                const Divider(),

                // ── Language ───────────────────────────────────────────────
                _SectionHeader(title: s.sectionLanguage),
                const _LanguageSwitcher(),
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
      builder: (ctx) {
        final s = LanguageProvider.read(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.person_add_outlined, color: Color(0xFFE57373), size: 22),
            const SizedBox(width: 10),
            Text(s.logAsNewUser),
          ]),
          content: Text(
            s.logAsNewUserContent,
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE57373)),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(s.continueBtn),
            ),
          ],
        );
      },
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

// ── Language Switcher ──────────────────────────────────────────────────────

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppStrings>(
      valueListenable: appLanguage,
      builder: (context, strings, _) {
        final s = LanguageProvider.of(context);
        return ListTile(
          leading: const Icon(Icons.language_rounded),
          title: Text(s.sectionLanguage),
          subtitle: Text(
            strings.languageCode == 'en' ? s.languageEnglish : s.languageSinhala,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguageSheet(context, strings.languageCode),
        );
      },
    );
  }
}

void _showLanguageSheet(BuildContext context, String currentCode) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _LanguagePickerSheet(
      currentCode: currentCode,
      onSelected: (code) => _onLanguageSelected(context, code, currentCode),
    ),
  );
}

class _LanguagePickerSheet extends StatelessWidget {
  final String currentCode;
  final void Function(String code) onSelected;

  const _LanguagePickerSheet({
    required this.currentCode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.sectionLanguage,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(s.languageEnglish),
            trailing: currentCode == 'en'
                ? const Icon(Icons.check_rounded, color: Color(0xFF5BA8A0))
                : null,
            onTap: () {
              Navigator.pop(context);
              onSelected('en');
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text(s.languageSinhala),
            trailing: currentCode == 'si'
                ? const Icon(Icons.check_rounded, color: Color(0xFF5BA8A0))
                : null,
            onTap: () {
              Navigator.pop(context);
              onSelected('si');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> _onLanguageSelected(
  BuildContext context,
  String newCode,
  String previousCode,
) async {
  try {
    // Persist first, then update notifier (Requirement 8.3)
    await PreferencesService.setAppLanguage(newCode);
    appLanguage.value = newCode == 'si' ? AppStrings.si : AppStrings.en;
  } catch (_) {
    // Revert on failure (Requirement 8.5)
    appLanguage.value = previousCode == 'si' ? AppStrings.si : AppStrings.en;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageProvider.of(context).languageSaveError),
        ),
      );
    }
  }
}

// ── Profile Picture Avatar Section ───────────────────────────────────────────

class _ProfileAvatarSection extends StatefulWidget {
  const _ProfileAvatarSection();

  @override
  State<_ProfileAvatarSection> createState() => _ProfileAvatarSectionState();
}

class _ProfileAvatarSectionState extends State<_ProfileAvatarSection> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _cachedUrl;
  Uint8List? _localBytes;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  Reference get _storageRef =>
      FirebaseStorage.instance.ref('users/$_uid/profile.jpg');

  Future<String?> _loadProfilePicture() async {
    if (_cachedUrl != null) return _cachedUrl;
    try {
      final url = await _storageRef.getDownloadURL();
      _cachedUrl = url;
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      // Read file bytes for cross-platform support (Web & Mobile)
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _localBytes = bytes;
        _uploading = true;
      });

      // Upload bytes to storage
      await _storageRef.putData(bytes);

      // Fetch new download URL
      final url = await _storageRef.getDownloadURL();

      setState(() {
        _cachedUrl = url;
        _uploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          FutureBuilder<String?>(
            future: _loadProfilePicture(),
            builder: (context, snapshot) {
              final imageUrl = snapshot.data;
              final hasImage = imageUrl != null && imageUrl.isNotEmpty;

              return Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF5BA8A0),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _uploading
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF5BA8A0),
                          ),
                        )
                      : _localBytes != null
                          ? Image.memory(
                              _localBytes!,
                              fit: BoxFit.cover,
                            )
                          : hasImage
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 60, color: Colors.grey),
                                )
                              : const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _uploading ? null : _pickAndUploadImage,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF5BA8A0),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

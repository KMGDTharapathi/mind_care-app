import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/core/widgets/gradient_scaffold.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/features/onboarding/bloc/onboarding_cubit.dart';
import 'package:mind_care_app/main.dart' show appUserName, splashSavedLang;

class OnboardingScreen extends StatefulWidget {
  final bool returning;
  const OnboardingScreen({super.key, this.returning = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.returning) {
      return GradientScaffold(
        body: LeafBackground(child: SafeArea(child: const _WelcomeBackPage())),
      );
    }

    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: BlocBuilder<OnboardingCubit, int>(
        builder: (context, currentPage) {
          return GradientScaffold(
            body: LeafBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        // Disable swipe — navigation is button-driven
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) => context
                            .read<OnboardingCubit>()
                            .onPageChanged(index),
                        children: [
                          const _WelcomePage(),
                          _NameInputPage(pageController: _pageController),
                          const _FindCalmPage(),
                        ],
                      ),
                    ),
                    _BottomSection(
                      currentPage: currentPage,
                      pageController: _pageController,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Page 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 56,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'MindCare',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your safe space for mental wellness',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Name Input ───────────────────────────────────────────────────────

class _NameInputPage extends StatefulWidget {
  final PageController pageController;
  const _NameInputPage({required this.pageController});

  @override
  State<_NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<_NameInputPage> {
  final _controller = TextEditingController();
  bool _hasName = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasName) {
        setState(() {
          _hasName = hasText;
          if (hasText) _showError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }

    // Save name locally
    PreferencesService.setUserName(name);
    // Keep global notifier in sync so returning-user detection works immediately
    appUserName.value = name;

    widget.pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 36,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Hi there! 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Who am I chatting with?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Type your name here...',
              hintStyle: TextStyle(
                color: AppColors.textSecondaryDark.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _onSubmit(),
          ),
          // Cute error message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showError
                ? Padding(
                    key: const ValueKey('error'),
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🌸 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Psst… I need your name to say hello!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB05A7A),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(key: ValueKey('no-error'), height: 10),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _hasName ? _onSubmit : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasName
                    ? AppColors.primaryDark
                    : AppColors.primaryDark.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: _hasName ? 2 : 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Find Your Calm ───────────────────────────────────────────────────

class _FindCalmPage extends StatelessWidget {
  const _FindCalmPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              size: 56,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Find Your Calm',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Guided breathing exercises and meditations to help you relax and restore your inner peace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom section: dots + buttons ───────────────────────────────────────────

class _BottomSection extends StatelessWidget {
  const _BottomSection({
    required this.currentPage,
    required this.pageController,
  });

  final int currentPage;
  final PageController pageController;

  static const int _totalPages = 3;

  void _onGetStarted(BuildContext context) {
    // Fire and forget — don't block navigation on a disk write
    PreferencesService.setOnboardingComplete(true).catchError((_) {});
    GoRouter.of(context).go(AppRouter.languageSelect);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pagination dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              final isActive = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.textDark
                      : AppColors.textDark.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          // Page 1: "Next" button
          if (currentPage == 0)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          // Page 3: "Get Started" button
          if (currentPage == _totalPages - 1)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.textDark.withValues(alpha: 0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Let's get started",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.textDark.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _onGetStarted(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Welcome Back page (returning users) ─────────────────────────────────────

class _WelcomeBackPage extends StatefulWidget {
  const _WelcomeBackPage();

  @override
  State<_WelcomeBackPage> createState() => _WelcomeBackPageState();
}

class _WelcomeBackPageState extends State<_WelcomeBackPage> {
  String? _name;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    // Read from globals first (zero platform calls — already pre-fetched by _heavyInit)
    _name = appUserName.value;
    _lang = (splashSavedLang != null && splashSavedLang!.isNotEmpty)
        ? splashSavedLang!
        : 'en';

    // Defensive async fallbacks — only if globals weren't populated
    // Use Future.microtask to avoid blocking initState
    if (_name == null || _name!.isEmpty) {
      Future.microtask(() async {
        try {
          final n = await PreferencesService.getUserName().timeout(
            const Duration(seconds: 2),
          );
          if (mounted && n != null && n.isNotEmpty) {
            setState(() => _name = n);
          }
        } catch (_) {}
      });
    }
    if (_lang == 'en') {
      Future.microtask(() async {
        try {
          final l = await PreferencesService.getAppLanguage().timeout(
            const Duration(seconds: 2),
          );
          if (mounted && l != null && l.isNotEmpty) {
            setState(() => _lang = l);
          }
        } catch (_) {}
      });
    }
  }

  void _onContinue() {
    context.go('${AppRouter.moodCheckin}?lang=$_lang');
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (_name != null && _name!.isNotEmpty) ? _name! : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              size: 52,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            displayName.isNotEmpty
                ? 'Welcome back, $displayName! 👋'
                : 'Welcome back! 👋',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Great to see you again.\nHow are you feeling today?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

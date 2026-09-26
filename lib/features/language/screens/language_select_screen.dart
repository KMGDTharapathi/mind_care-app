import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/main.dart' show appLanguage;

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  String? _selected; // 'si' or 'en'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD4EDE8), Color(0xFFB2DFDB), Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Willow avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5BA8A0),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Face
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Eye(),
                                SizedBox(width: 16),
                                _Eye(),
                              ],
                            ),
                            SizedBox(height: 8),
                            _Smile(),
                          ],
                        ),
                        // Leaf on top
                        Positioned(
                          top: -8,
                          right: 14,
                          child: Transform.rotate(
                            angle: 0.4,
                            child: const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFF2E7D32),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A4A4A),
                      ),
                      children: [
                        TextSpan(text: 'Chat with Willow '),
                        TextSpan(text: '🌿'),
                        TextSpan(text: ' 🤖'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please choose your language',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5A7A7A),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Sinhala option
                  _LanguageCard(
                    isSelected: _selected == 'si',
                    onTap: () => setState(() => _selected = 'si'),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'LK',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A4A4A),
                          ),
                        ),
                      ),
                    ),
                    title: 'සිංහල',
                    subtitle: 'Sinhala',
                    titleStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A4A4A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // English option
                  _LanguageCard(
                    isSelected: _selected == 'en',
                    onTap: () => setState(() => _selected = 'en'),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('🌍', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    title: 'English',
                    subtitle: 'EN',
                    titleStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A4A4A),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Continue button
                  GestureDetector(
                    onTap: _selected == null
                        ? null
                        : () async {
                            await PreferencesService.setAppLanguage(_selected!);
                            // Update global language notifier
                            appLanguage.value = _selected == 'si'
                                ? AppStrings.si
                                : AppStrings.en;
                            if (context.mounted) {
                              context.go('${AppRouter.moodCheckin}?lang=$_selected');
                            }
                          },
                    child: Text(
                      'Continue →',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selected == null
                            ? const Color(0xFFAACCCC)
                            : const Color(0xFF5A7A7A),
                        fontWeight: FontWeight.w500,
                      ),
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

class _LanguageCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final TextStyle titleStyle;

  const _LanguageCard({
    required this.isSelected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5BA8A0)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7A9A9A),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5BA8A0)
                      : const Color(0xFFCCDDDD),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF5BA8A0)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF1A4A4A),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Smile extends StatelessWidget {
  const _Smile();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 12),
      painter: _SmilePainter(),
    );
  }
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A4A4A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

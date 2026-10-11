import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';

/// Branded first-run loading view.
///
/// Used by both the pre-frame placeholder in `main()` and the `/splash` route so
/// the app shows one continuous, identical surface while Firebase, Hive and
/// Preferences warm up — there is no visible jump between the two.
///
/// This widget is purely presentational: it never gates navigation. The caller
/// stays in charge of when to leave the loading state.
class AppLoadingView extends StatefulWidget {
  const AppLoadingView({
    super.key,
    this.appName = 'MindCare',
    this.tagline = 'Your safe space for mental wellness',
    this.logoAsset = 'assets/images/app_logo.png',
  });

  final String appName;
  final String tagline;

  /// App logo (`assets/images/app_logo.png`). It is centre-cropped into a
  /// circular badge. Falls back to the leaf mark if the asset is missing.
  final String logoAsset;

  @override
  State<AppLoadingView> createState() => _AppLoadingViewState();
}

class _AppLoadingViewState extends State<AppLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0, 1, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientStart,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: LeafBackground(
          child: SafeArea(
            // SingleChildScrollView keeps the layout intact when the system
            // font scale is large or the device is short.
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical,
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LogoBadge(asset: widget.logoAsset, size: 132),
                            const SizedBox(height: 28),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.appName,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.tagline,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondaryDark.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 44),
                            const _BrandSpinner(),
                            const SizedBox(height: 16),
                            Text(
                              'Preparing your space…',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 0.2,
                                color: AppColors.textSecondaryDark.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular app-logo badge with a white keyline and a soft elevation shadow.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.94),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 26,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        // The source logo is landscape, so cover-crop it to a square badge.
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.eco_rounded,
            size: size * 0.5,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

/// Continuously sweeping two-tone ring used as the loading indicator.
///
/// Replaces the stock [CircularProgressIndicator] so the spinner matches the
/// app palette rather than defaulting to the theme accent.
class _BrandSpinner extends StatefulWidget {
  const _BrandSpinner();

  @override
  State<_BrandSpinner> createState() => _BrandSpinnerState();
}

class _BrandSpinnerState extends State<_BrandSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SweepPainter(
            // One full turn per loop keeps the motion seamless.
            turn: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter({required this.turn});

  /// 0..1 through one rotation.
  final double turn;

  static const double _trackWidth = 3.5;
  static const double _sweep = math.pi * 0.72; // ~130°

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _trackWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = turn * 2 * math.pi;

    // Faint full-circle track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _trackWidth
        ..color = AppColors.primaryDark.withValues(alpha: 0.16),
    );

    // Brand-coloured arc that sweeps around once per loop.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _trackWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        // Rotate the gradient with the arc so the colour leads the motion.
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(start),
        colors: const [
          AppColors.primaryLight,
          AppColors.primaryDark,
          AppColors.primaryLight,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, start, _sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.turn != turn;
}

import 'package:flutter/material.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';

class AnimatedBreathCircle extends StatefulWidget {
  final String phaseLabel;
  final bool isInhale;
  final bool isHold;
  final int durationSeconds;
  final bool isPaused;

  const AnimatedBreathCircle({
    super.key,
    required this.phaseLabel,
    required this.isInhale,
    required this.isHold,
    required this.durationSeconds,
    this.isPaused = false,
  });

  @override
  State<AnimatedBreathCircle> createState() => _AnimatedBreathCircleState();
}

class _AnimatedBreathCircleState extends State<AnimatedBreathCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;

  static const double _minSize = 80.0;
  static const double _maxSize = 180.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );
    _setupAnimation();
    _startAnimation();
  }

  void _setupAnimation() {
    if (widget.isHold) {
      final holdSize = widget.isInhale ? _minSize : _maxSize;
      _sizeAnimation = Tween<double>(begin: holdSize, end: holdSize)
          .animate(_controller);
    } else if (widget.isInhale) {
      _sizeAnimation =
          Tween<double>(begin: _minSize, end: _maxSize).animate(_controller);
    } else {
      // exhale
      _sizeAnimation =
          Tween<double>(begin: _maxSize, end: _minSize).animate(_controller);
    }
  }

  void _startAnimation() {
    if (widget.isHold || widget.isPaused) {
      // no movement for hold or while paused
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedBreathCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phaseLabel != widget.phaseLabel ||
        oldWidget.durationSeconds != widget.durationSeconds) {
      _controller.duration = Duration(seconds: widget.durationSeconds);
      _controller.reset();
      _setupAnimation();
      _startAnimation();
    } else if (oldWidget.isPaused != widget.isPaused) {
      if (widget.isPaused) {
        // Freeze the circle exactly where it is
        _controller.stop();
      } else {
        // Resume from the frozen position (hold phase never moves anyway)
        if (!widget.isHold) _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sizeAnimation,
      builder: (context, child) {
        final size = _sizeAnimation.value;
        return SizedBox(
          width: _maxSize + 20,
          height: _maxSize + 20,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.phaseLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

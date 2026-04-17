import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  String? _emailError;
  bool _emailSent = false;
  bool _pendingReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendReset() {
    setState(() => _emailError = null);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      return;
    }

    _pendingReset = true;
    context.read<AuthBloc>().add(AuthSendPasswordReset(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _pendingReset = false;
          setState(() => _emailError = state.message);
        } else if (_pendingReset && state is! AuthLoading) {
          // The bloc emits no dedicated success state for password reset —
          // success is inferred when a non-error state follows our dispatch.
          _pendingReset = false;
          setState(() => _emailSent = true);
        }
      },
      child: GradientScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _Header(),
                const SizedBox(height: 36),
                if (_emailSent)
                  _SuccessBanner(email: _emailController.text.trim())
                else ...[
                  _EmailField(
                    controller: _emailController,
                    errorText: _emailError,
                    onChanged: (_) => setState(() => _emailError = null),
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return _SendButton(
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _onSendReset,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 28),
                _BackToSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 44,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Reset password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Enter your email and we'll send you a reset link",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondaryDark,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Email field ───────────────────────────────────────────────────────────────

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'you@example.com',
        errorText: errorText,
        prefixIcon:
            const Icon(Icons.email_outlined, color: AppColors.primaryDark),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
      ),
    );
  }
}

// ── Success banner ────────────────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 48,
            color: AppColors.primaryDark,
          ),
          const SizedBox(height: 16),
          const Text(
            'Check your inbox',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a password reset link to\n$email',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Send Reset Link',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// ── Back to sign-in link ──────────────────────────────────────────────────────

class _BackToSignInLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back_rounded,
          size: 16, color: AppColors.primaryDark),
      label: const Text(
        'Back to sign in',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

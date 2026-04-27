import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crisis_connect/core/theme/app_theme.dart';
import 'package:crisis_connect/providers/providers.dart';
import 'package:crisis_connect/presentation/shared/widgets/shared_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .sendPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) ErrorSnackBar.show(context, 'Could not send reset email. Check the address and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: _isLoading,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Back button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    Text('Reset Password',
                        style: Theme.of(context).textTheme.headlineLarge),
                  ],
                ),
                const SizedBox(height: 32),

                if (_emailSent) ...[
                  // Success state
                  GlassCard(
                    borderColor: AppColors.success,
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_rounded,
                            size: 56, color: AppColors.successLight),
                        const SizedBox(height: 16),
                        Text('Email Sent!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(color: AppColors.successLight)),
                        const SizedBox(height: 10),
                        Text(
                          'We sent a password reset link to\n${_emailCtrl.text.trim()}\n\nCheck your inbox and spam folder.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Back to Sign In',
                          icon: Icons.login_rounded,
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Input state
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_reset_rounded,
                            size: 40, color: AppColors.accent),
                        const SizedBox(height: 12),
                        Text('Forgot your password?',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the email address associated with your account. We\'ll send you a link to reset your password.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: AppColors.accent, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.border, width: 1.5)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 2)),
                        labelStyle:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send Reset Link',
                    icon: Icons.send_rounded,
                    onPressed: _submit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

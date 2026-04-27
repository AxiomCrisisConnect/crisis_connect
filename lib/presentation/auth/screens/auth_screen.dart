import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crisis_connect/core/theme/app_theme.dart';
import 'package:crisis_connect/core/router/app_router.dart';
import 'package:crisis_connect/providers/providers.dart';
import 'package:crisis_connect/data/models/user_model.dart';
import 'package:crisis_connect/presentation/shared/widgets/shared_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _isLoading = v);
  }

  // ─── Google Sign-In (shared by both tabs) ─────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);
    try {
      final result =
          await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      if (result.user != null) {
        // Returning user: the notifier already set state = AsyncData(user)
        // which triggers router.refresh() → the router redirects to home.
        // Do NOT call _routeAfterAuth here — that would double-navigate.
        return;
      } else if (result.isNewUser && result.googleAccount != null) {
        // New user — push to profile completion screen.
        // The auth screen is still mounted here because we no longer set
        // AsyncLoading at the start of signInWithGoogle.
        context.push(
          AppRoutes.completeProfile,
          extra: {
            'name': (result.googleAccount as GoogleSignInAccount).displayName ?? '',
            'email': (result.googleAccount as GoogleSignInAccount).email,
          },
        );
      }
      // else: user cancelled — do nothing
    } on Exception catch (e) {
      if (mounted) ErrorSnackBar.show(context, _friendlyError(e));
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  void _routeAfterAuth(UserModel user) {
    if (user.role == UserRole.volunteer) {
      final repo = ref.read(authRepositoryProvider);
      if (!repo.isOnboardingComplete) {
        context.go(AppRoutes.onboardingStep1);
      } else {
        context.go(AppRoutes.volunteerHome);
      }
    } else {
      context.go(AppRoutes.civilianHome);
    }
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('email-already-in-use')) {
      return 'An account already exists with that email. Try signing in instead.';
    }
    if (msg.contains('wrong-password') || msg.contains('invalid-credential') || msg.contains('invalid-login-credentials')) {
      return 'Wrong password. Please check and try again.';
    }
    if (msg.contains('user-not-found') || msg.contains('no user record')) {
      return 'No account found with that email. Please sign up first.';
    }
    if (msg.contains('weak-password')) {
      return 'Password must be at least 8 characters long.';
    }
    if (msg.contains('network-request-failed') || msg.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ambient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020510), Color(0xFF050C1A), Color(0xFF030814)],
                stops: [0.0, 0.6, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Ambient top-left glow orb
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Ambient bottom-right glow orb
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: LoadingOverlay(
              isLoading: _isLoading,
              child: Column(
                children: [
                  // ── Branding ──────────────────────────────────────────
                  const SizedBox(height: 28),
                  FadeSlideIn(child: _Logo()),
                  const SizedBox(height: 28),

                  // ── Tab bar ───────────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.border, width: 1.5),
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicator: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.glowAccent(
                                intensity: 0.3, blur: 12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          // Visible cyan ripple on tap
                          overlayColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.pressed)) {
                              return AppColors.accent.withValues(alpha: 0.15);
                            }
                            if (states.contains(WidgetState.hovered)) {
                              return AppColors.accent.withValues(alpha: 0.08);
                            }
                            return Colors.transparent;
                          }),
                          splashBorderRadius: BorderRadius.circular(12),
                          labelStyle: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                          unselectedLabelStyle: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Tab contents ──────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _SignInForm(
                          onGoogleTap: _handleGoogleSignIn,
                          onSuccess: _routeAfterAuth,
                          setLoading: _setLoading,
                          friendlyError: _friendlyError,
                        ),
                        _SignUpForm(
                          onGoogleTap: _handleGoogleSignIn,
                          onSuccess: _routeAfterAuth,
                          setLoading: _setLoading,
                          friendlyError: _friendlyError,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo Widget ─────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glow ring behind icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.crisis_alert_rounded,
                color: Colors.white, size: 42),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.accentGradient.createShader(bounds),
          child: Text(
            'CRISISCONNECT',
            style: GoogleFonts.rajdhani(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Crisis Response & Volunteer Coordination',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textHint,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ─── Google Button ────────────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        _ctrl.reverse();
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        _ctrl.reverse();
        setState(() => _pressed = false);
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceVariant.withValues(alpha: 0.8)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleIcon(),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // Simple coloured "G" since we have no SVG asset
    return const Text(
      'G',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: AppColors.divider,
                thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or',
              style: GoogleFonts.dmSans(
                  color: AppColors.textHint, fontSize: 13)),
        ),
        Expanded(
            child: Divider(
                color: AppColors.divider,
                thickness: 1)),
      ],
    );
  }
}

// ─── Sign In Form ─────────────────────────────────────────────────────────────

class _SignInForm extends ConsumerStatefulWidget {
  final VoidCallback onGoogleTap;
  final void Function(UserModel) onSuccess;
  final void Function(bool) setLoading;
  final String Function(dynamic) friendlyError;

  const _SignInForm({
    required this.onGoogleTap,
    required this.onSuccess,
    required this.setLoading,
    required this.friendlyError,
  });

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  // Keep this tab alive so FadeSlideIn only plays once
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.setLoading(true);
    try {
      final user = await ref.read(authNotifierProvider.notifier).signInWithEmail(
            email: _emailCtrl.text,
            password: _passCtrl.text,
          );
      if (mounted) widget.onSuccess(user);
    } catch (e) {
      if (mounted) ErrorSnackBar.show(context, widget.friendlyError(e));
    } finally {
      widget.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _GoogleButton(onTap: widget.onGoogleTap),
            ),
            const SizedBox(height: 20),
            _OrDivider(),
            const SizedBox(height: 20),

            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: _AuthField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _AuthField(
                controller: _passCtrl,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePass,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Forgot Password?',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 20),

            FadeSlideIn(
              delay: const Duration(milliseconds: 250),
              child: PrimaryButton(
                label: 'Sign In',
                icon: Icons.login_rounded,
                gradient: AppColors.accentGradient,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Up Form ─────────────────────────────────────────────────────────────

class _SignUpForm extends ConsumerStatefulWidget {
  final VoidCallback onGoogleTap;
  final void Function(UserModel) onSuccess;
  final void Function(bool) setLoading;
  final String Function(dynamic) friendlyError;

  const _SignUpForm({
    required this.onGoogleTap,
    required this.onSuccess,
    required this.setLoading,
    required this.friendlyError,
  });

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  UserRole? _selectedRole;

  // Keep this tab alive so FadeSlideIn only plays once
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRole == null) {
      ErrorSnackBar.show(context, 'Please select your role to continue.');
      return;
    }
    widget.setLoading(true);
    try {
      final user = await ref
          .read(authNotifierProvider.notifier)
          .signUpWithEmail(
            name: _nameCtrl.text,
            email: _emailCtrl.text,
            password: _passCtrl.text,
            role: _selectedRole!,
          );
      if (mounted) widget.onSuccess(user);
    } catch (e) {
      if (mounted) ErrorSnackBar.show(context, widget.friendlyError(e));
    } finally {
      widget.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Google button
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _GoogleButton(onTap: widget.onGoogleTap),
            ),
            const SizedBox(height: 20),
            _OrDivider(),
            const SizedBox(height: 20),

            // Full Name
            FadeSlideIn(
              delay: const Duration(milliseconds: 130),
              child: _AuthField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Enter your full name';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            // Email
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _AuthField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$')
                      .hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            // Password
            FadeSlideIn(
              delay: const Duration(milliseconds: 230),
              child: _AuthField(
                controller: _passCtrl,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePass,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            // Confirm Password
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: _AuthField(
                controller: _confirmPassCtrl,
                label: 'Confirm Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),

            // Role Selector
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I am a…',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          role: UserRole.volunteer,
                          icon: Icons.volunteer_activism_rounded,
                          label: 'Volunteer',
                          subtitle: 'Respond to\nemergencies',
                          selected: _selectedRole == UserRole.volunteer,
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.volunteer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          role: UserRole.civilian,
                          icon: Icons.people_rounded,
                          label: 'Civilian',
                          subtitle: 'Request help\nwhen in need',
                          selected: _selectedRole == UserRole.civilian,
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.civilian),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            FadeSlideIn(
              delay: const Duration(milliseconds: 370),
              child: PrimaryButton(
                label: 'Create Account',
                icon: Icons.person_add_rounded,
                gradient: AppColors.accentGradient,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role Card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: selected ? Colors.white : AppColors.accent),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? Colors.white70
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Auth Field ───────────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sos, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sos, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.sos),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

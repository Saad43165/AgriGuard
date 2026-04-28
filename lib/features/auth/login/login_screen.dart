import 'package:agriguard_fyp/features/auth/login/services/guest_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agriguard_fyp/core/constants/app_routes.dart';
import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'package:agriguard_fyp/core/widgets/app_logo.dart';
import 'package:agriguard_fyp/features/auth/services/auth_service.dart';
import 'widgets/login_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscure = true;
  final _guestService = GuestService();

  @override
  void initState() {
    super.initState();
    _guestService.initialize();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await authService.value.signInWithEmailAndPassword(
        _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (cred != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          _snack('Please verify your email first.', isError: true);
          await user.sendEmailVerification();
          return;
        }
        await _guestService.disableGuestMode();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      _snack(_authError(e.code), isError: true);
    } catch (e) {
      _snack('Login failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    if (_isGoogleLoading || _isLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final user = await authService.value.signInWithGoogle();
      if (user != null) {
        await _guestService.disableGuestMode();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
      }
    } catch (e) {
      _snack('Google sign-in failed.', isError: true);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _guestLogin() async {
    HapticFeedback.mediumImpact();
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const GuestModeDialog(),
    );

    if (proceed != true) return;

    setState(() => _isLoading = true);
    try {
      await _guestService.enableGuestMode();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      _snack('Failed to enter guest mode.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try later.';
      default: return 'Login failed. Please try again.';
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo + title
                Center(
                  child: Column(
                    children: [
                      const AppLogo(size: 80),
                      const SizedBox(height: 16),
                      const Text('Welcome back',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                              color: Color(0xFF1B2B1E), letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      const Text('Sign in to your AgriGuard account',
                          style: TextStyle(fontSize: 14, color: Color(0xFF718096))),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                const LoginLabel('Email'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF1B2B1E), fontSize: 14),
                  decoration: buildLoginInputDeco('Enter your email', Icons.email_outlined),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                // Password
                const LoginLabel('Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Color(0xFF1B2B1E), fontSize: 14),
                  decoration: buildLoginInputDeco('Enter your password', Icons.lock_outline_rounded).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF9E9E9E), size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Password must be 6+ characters' : null,
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(children: [
                  const Expanded(child: Divider(color: Color(0xFFE8E8E8))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE8E8E8))),
                ]),
                const SizedBox(height: 16),

                // Google button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: (_isLoading || _isGoogleLoading) ? null : _googleLogin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      backgroundColor: Colors.white,
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/google_g.png', width: 20, height: 20),
                              const SizedBox(width: 10),
                              const Text('Continue with Google',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B2B1E))),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Guest button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _guestLogin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF718096)),
                        SizedBox(width: 10),
                        Text('Continue as Guest (5 free scans)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: Color(0xFF718096))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text('Sign Up',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/services/translation_service.dart';
import '../../auth/services/auth_service.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleUser = false;
  bool _canChangePassword = false;

  @override
  void initState() {
    super.initState();
    _checkUserProvider();
  }

  void _checkUserProvider() {
    _isGoogleUser = _authService.isGoogleSignIn();
    _canChangePassword = _authService.canChangePassword();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isChangingPassword) return;

    setState(() => _isChangingPassword = true);

    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translate('password_changed')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError('${_translate('error')}: $e');
      }
    }

    if (mounted) setState(() => _isChangingPassword = false);
  }

  Future<void> _sendPasswordResetLink() async {
    final user = _authService.currentUser;
    if (user?.email == null) {
      _showError(_translate('no_email'));
      return;
    }

    try {
      await _authService.resetPassword(user!.email!);
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translate('reset_link_sent')),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError('${_translate('error')}: $e');
      }
    }
  }

  String _translate(String key) {
    final t = Provider.of<TranslationService>(context, listen: false);
    switch (key) {
      case 'password_changed':
        return t.isUrdu ? 'پاسورڈ کامیابی سے تبدیل ہوگیا' : 'Password changed successfully';
      case 'error':
        return t.isUrdu ? 'خرابی' : 'Error';
      case 'no_email':
        return t.isUrdu ? 'ای میل دستیاب نہیں - گوگل لاگن سے سائن ان کیا ہے' : 'No email - you signed in with Google';
      case 'reset_link_sent':
        return t.isUrdu ? 'ری سیٹ لنک بھیج دیا گیا' : 'Password reset link sent';
      case 'current_password':
        return t.isUrdu ? 'موجودہ پاسورڈ' : 'Current Password';
      case 'new_password':
        return t.isUrdu ? 'نیا پاسورڈ' : 'New Password';
      case 'confirm_password':
        return t.isUrdu ? 'تصدیق پاسورڈ' : 'Confirm Password';
      case 'enter_current':
        return t.isUrdu ? 'موجودہ پاسورڈ درج کریں' : 'Enter current password';
      case 'enter_new':
        return t.isUrdu ? 'نیا پاسورڈ درج کریں' : 'Enter new password';
      case 'confirm_new':
        return t.isUrdu ? 'نے پاسورڈ کی تصدیق کریں' : 'Confirm new password';
      case 'mismatch':
        return t.isUrdu ? 'پاسورڈ مماثل نہیں ہیں' : 'Passwords do not match';
      case 'too_short':
        return t.isUrdu ? 'پاسورڈ کم از کم 6 حروف کا ہونا چاہیے' : 'Password must be at least 6 characters';
      case 'change_password':
        return t.isUrdu ? 'پاسورڈ تبدیل کریں' : 'Change Password';
      case 'change_not_available':
        return t.isUrdu ? 'پاسورڈ تبدیل نہیں کر سکتے' : 'Cannot change password';
      case 'google_no_password':
        return t.isUrdu ? 'گوگل سے لاگن کیا - پاسورڈ تبدیل نہیں کر سکتے' : 'Signed in with Google - cannot change password';
      case 'forgot_password':
        return t.isUrdu ? 'پاسورڈ بھول گیے؟' : 'Forgot Password?';
      case 'send_reset_link':
        return t.isUrdu ? 'ری سیٹ لنک بھیجیں' : 'Send Reset Link';
      case 'privacy_security':
        return t.isUrdu ? 'رازداری اور سیکیورٹی' : 'Privacy & Security';
      case 'password_section':
        return t.isUrdu ? 'پاسورڈ' : 'PASSWORD';
      case 'password_hint':
        return t.isUrdu ? 'موجودہ پاسورڈ درج کریں اور نیا پاسورڈ انتخاب کریں' : 'Enter current password and choose a new one';
      case 'forgot_hint':
        return t.isUrdu ? 'اپنا پاسورڈ ری سیٹ کرنے کے لیے لنک حاصل کریں' : 'Get a link to reset your password';
      case 'required':
        return t.isUrdu ? 'یہ فیلڈ ضروری ہے' : 'This field is required';
      default:
        return key;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _translate('privacy_security'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(_translate('password_section'), captionColor),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _translate('change_password'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translate('password_hint'),
                      style: TextStyle(fontSize: 12, color: captionColor),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: _translate('current_password'),
                      hint: _translate('enter_current'),
                      isDark: isDark,
                      textColor: textColor,
                      captionColor: captionColor,
                      borderColor: borderColor,
                      cardBg: cardBg,
                      obscure: _obscureCurrentPassword,
                      onToggle: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) return _translate('required');
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: _translate('new_password'),
                      hint: _translate('enter_new'),
                      isDark: isDark,
                      textColor: textColor,
                      captionColor: captionColor,
                      borderColor: borderColor,
                      cardBg: cardBg,
                      obscure: _obscureNewPassword,
                      onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) return _translate('required');
                        if (v.length < 6) return _translate('too_short');
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: _translate('confirm_password'),
                      hint: _translate('confirm_new'),
                      isDark: isDark,
                      textColor: textColor,
                      captionColor: captionColor,
                      borderColor: borderColor,
                      cardBg: cardBg,
                      obscure: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      validator: (v) {
                        if (v == null || v.isEmpty) return _translate('required');
                        if (v != _newPasswordController.text) return _translate('mismatch');
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_canChangePassword && !_isChangingPassword) ? _changePassword : null,
                        child: _isChangingPassword
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_canChangePassword ? _translate('change_password') : _translate('change_not_available')),
                      ),
                    ),
                    if (!_canChangePassword)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _isGoogleUser ? _translate('google_no_password') : _translate('change_not_available'),
                          style: TextStyle(fontSize: 11, color: captionColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_isGoogleUser) ...[
                _sectionLabel(_translate('forgot_password'), captionColor),
                const SizedBox(height: 12),
                _buildForgotPasswordCard(isDark, textColor, captionColor, cardBg, borderColor),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.0),
    );
  }

  Widget _buildForgotPasswordCard(bool isDark, Color textColor, Color captionColor, Color cardBg, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('forgot_password'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  _translate('forgot_hint'),
                  style: TextStyle(fontSize: 12, color: captionColor),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _sendPasswordResetLink,
            child: Text(_translate('send_reset_link'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color textColor,
    required Color captionColor,
    required Color borderColor,
    required Color cardBg,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: captionColor.withValues(alpha: 0.6)),
        labelStyle: TextStyle(color: captionColor),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: captionColor, size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_themes.dart';
import '../../profile/utils/profile_image_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  File? _imageFile;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked != null && mounted) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      final user = cred.user;
      if (user == null) throw Exception('User creation failed');

      String? imageUrl;
      if (_imageFile != null && await _imageFile!.exists()) {
        final bytes = await _imageFile!.readAsBytes();
        imageUrl = base64Encode(bytes);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'profileImageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': user.uid,
      });

      await user.sendEmailVerification();

      if (mounted) {
        if (_imageFile != null) ProfileImageManager.setPendingImage(_imageFile!);
        _showSuccess();
      }
    } on FirebaseAuthException catch (e) {
      _snack(_authError(e.code), isError: true);
    } catch (e) {
      _snack('Registration failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
        title: 'Account Created!',
        content: Text(
          'Verification email sent to ${_emailCtrl.text.trim()}',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          AppDialogActions.primary(
            ctx,
            label: 'Go to Login',
            icon: Icons.login_rounded,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'weak-password': return 'Password is too weak. Use 6+ characters.';
      default: return 'Registration failed. Please try again.';
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.lightOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightOnSurface)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.lightBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Profile photo
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.person_outline_rounded,
                                size: 40, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Add photo (optional)',
                    style: TextStyle(fontSize: 12, color: AppColors.lightCaption)),
              ),
              const SizedBox(height: 24),

              _label('Full Name'),
              const SizedBox(height: 6),
              _field(_nameCtrl, 'Enter your full name', Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
              const SizedBox(height: 16),

              _label('Email'),
              const SizedBox(height: 6),
              _field(_emailCtrl, 'Enter your email', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
              const SizedBox(height: 16),

              _label('Location (optional)'),
              const SizedBox(height: 6),
              _field(_locationCtrl, 'City, Country', Icons.location_on_outlined),
              const SizedBox(height: 16),

              _label('Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: _inputDeco('Create a password', Icons.lock_outline_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF9E9E9E), size: 20),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Password must be 6+ characters' : null,
              ),
              const SizedBox(height: 16),

              _label('Confirm Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: _inputDeco('Confirm your password', Icons.lock_outline_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF9E9E9E), size: 20),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(color: AppColors.lightCaption, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Sign In',
                          style: TextStyle(color: AppColors.primary,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightOnSurface));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDeco(hint, icon),
      validator: validator,
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.lightCaption, fontSize: 14),
    prefixIcon: Icon(icon, color: AppColors.lightCaption, size: 20),
    filled: true,
    fillColor: AppColors.lightBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lightBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

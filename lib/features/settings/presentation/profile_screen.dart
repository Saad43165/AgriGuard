import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/services/translation_service.dart';
import '../../auth/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.getCurrentUserData();
      if (mounted && data != null) {
        _userData = data;
        _nameController.text = data['fullName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _locationController.text = data['location'] ?? '';
        _farmSizeController.text = data['farmSize'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to load profile: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        farmSize: _farmSizeController.text.trim(),
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save profile: $e');
      }
    }
    if (mounted) setState(() => _isSaving = false);
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
    final t = Provider.of<TranslationService>(context);
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
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.get('profile_title') ?? 'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    t.get('save') ?? 'Save',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileImage(isDark, cardBg, textColor),
                    const SizedBox(height: 24),
                    _sectionLabel(t.get('personal_info') ?? 'Personal Information', captionColor),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: t.get('full_name') ?? 'Full Name',
                      hint: t.get('enter_full_name') ?? 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      textColor: textColor,
                      captionColor: captionColor,
                      borderColor: borderColor,
                      cardBg: cardBg,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t.get('name_required') ?? 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: t.get('phone_number') ?? 'Phone Number',
                      hint: t.get('enter_phone') ?? 'Enter phone number',
                      icon: Icons.phone_outlined,
                      isDark: isDark,
                      textColor: textColor,
                      captionColor: captionColor,
                      borderColor: borderColor,
                      cardBg: cardBg,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: t.get('location') ?? 'Location',
                      hint: t.get('enter_location') ?? 'Enter your location',
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                      textColor: textColor,
                      captionColor: captionColor,
                      borderColor: borderColor,
                      cardBg: cardBg,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _farmSizeController,
                      label: t.get('farm_size') ?? 'Farm Size',
                      hint: t.get('enter_farm_size') ?? 'e.g., 5 acres',
                      icon: Icons.landscape_outlined,
                      isDark: isDark,
                      textColor: textColor,
                      captionColor: captionColor,
                      borderColor: borderColor,
                      cardBg: cardBg,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImage(bool isDark, Color cardBg, Color textColor) {
    final imageUrl = _userData?['profileImageUrl'] as String?;
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(textColor),
                        )
                      : _buildDefaultAvatar(textColor),
                ),
              ),
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 2),
                  ),
                  child: IconButton(tooltip: 'Take photo', 
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photo upload coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_userData?['email'] != null)
            Text(
              _userData!['email']!,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(Color textColor) {
    return Center(
      child: Icon(Icons.person, size: 50, color: textColor.withValues(alpha: 0.5)),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color captionColor,
    required Color borderColor,
    required Color cardBg,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: captionColor.withValues(alpha: 0.6)),
        labelStyle: TextStyle(color: captionColor),
        filled: true,
        fillColor: cardBg,
        prefixIcon: Icon(icon, color: captionColor, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
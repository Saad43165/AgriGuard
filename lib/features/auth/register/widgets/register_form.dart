import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';

class RegisterForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController farmSizeController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onConfirmPasswordVisibilityChanged;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.locationController,
    required this.farmSizeController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final Map<String, bool> _focusStates = {
    'name': false,
    'email': false,
    'phone': false,
    'location': false,
    'farmSize': false,
    'password': false,
    'confirmPassword': false,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            context,
            label: 'Full Name',
            controller: widget.nameController,
            icon: Icons.person_rounded,
            isDark: isDark,
            key: 'name',
          ),

          _buildTextField(
            context,
            label: 'Email Address',
            controller: widget.emailController,
            icon: AppIcons.email,
            isDark: isDark,
            key: 'email',
            keyboardType: TextInputType.emailAddress,
          ),

          _buildTextField(
            context,
            label: 'Phone Number',
            controller: widget.phoneController,
            icon: Icons.phone_rounded,
            isDark: isDark,
            key: 'phone',
            keyboardType: TextInputType.phone,
            isOptional: true,
          ),

          _buildTextField(
            context,
            label: 'Location',
            controller: widget.locationController,
            icon: Icons.location_on_rounded,
            isDark: isDark,
            key: 'location',
            isOptional: true,
          ),

          _buildTextField(
            context,
            label: 'Farm Size',
            controller: widget.farmSizeController,
            icon: Icons.agriculture_rounded,
            isDark: isDark,
            key: 'farmSize',
            keyboardType: TextInputType.number,
            isOptional: true,
          ),

          _buildPasswordField(
            context,
            label: 'Password',
            controller: widget.passwordController,
            obscureText: widget.obscurePassword,
            onVisibilityChanged: widget.onPasswordVisibilityChanged,
            isDark: isDark,
            key: 'password',
          ),

          _buildPasswordField(
            context,
            label: 'Confirm Password',
            controller: widget.confirmPasswordController,
            obscureText: widget.obscureConfirmPassword,
            onVisibilityChanged: widget.onConfirmPasswordVisibilityChanged,
            isDark: isDark,
            key: 'confirmPassword',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required IconData icon,
        required bool isDark,
        required String key,
        TextInputType? keyboardType,
        bool isOptional = false,
      }) {
    final isFocused = _focusStates[key] ?? false;
    final hasText = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label, isFocused || hasText, isOptional),
        const SizedBox(height: 12),
        Focus(
          onFocusChange: (hasFocus) => setState(() => _focusStates[key] = hasFocus),
          child: _buildInputContainer(
            isDark: isDark,
            isFocused: isFocused,
            child: Row(
              children: [
                // Icon with background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isFocused
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildIcon(icon, isFocused),
                ),

                const SizedBox(width: 12),

                // Vertical Divider
                Container(
                  height: 40,
                  width: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),

                const SizedBox(width: 16),

                // Text Field
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: _inputTextStyle(context),
                    decoration: InputDecoration(
                      hintText: _getHintText(label),
                      hintStyle: _hintStyle(context),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      filled: false,
                    ),
                    cursorColor: Theme.of(context).colorScheme.primary,
                    cursorWidth: 2,
                    cursorHeight: 22,
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                // Clear Button
                if (hasText)
                  _buildClearButton(() => setState(() => controller.clear())),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required bool obscureText,
        required VoidCallback onVisibilityChanged,
        required bool isDark,
        required String key,
      }) {
    final isFocused = _focusStates[key] ?? false;
    final hasText = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label, isFocused || hasText, false),
        const SizedBox(height: 12),
        Focus(
          onFocusChange: (hasFocus) => setState(() => _focusStates[key] = hasFocus),
          child: _buildInputContainer(
            isDark: isDark,
            isFocused: isFocused,
            child: Row(
              children: [
                // Icon with background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isFocused
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildIcon(Icons.lock_rounded, isFocused),
                ),

                const SizedBox(width: 12),

                // Vertical Divider
                Container(
                  height: 40,
                  width: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),

                const SizedBox(width: 16),

                // Text Field
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    obscureText: obscureText,
                    style: _inputTextStyle(context),
                    decoration: InputDecoration(
                      hintText: _getHintText(label),
                      hintStyle: _hintStyle(context),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      filled: false,
                    ),
                    cursorColor: Theme.of(context).colorScheme.primary,
                    cursorWidth: 2,
                    cursorHeight: 22,
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                // Visibility Toggle
                GestureDetector(
                  onTap: onVisibilityChanged,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label, bool show, bool isOptional) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 6),
              Text(
                '(OPTIONAL)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer({
    required bool isDark,
    required bool isFocused,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused
              ? Theme.of(context).colorScheme.primary
              : isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildIcon(IconData icon, bool isFocused) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: isFocused
            ? [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ]
            : [
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ],
      ).createShader(bounds),
      child: Icon(icon, size: 22),
    );
  }

  Widget _buildClearButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  TextStyle _inputTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      letterSpacing: 0.2,
      height: 1.5,
    );
  }

  TextStyle _hintStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
      fontWeight: FontWeight.w400,
      fontSize: 15,
      letterSpacing: 0.2,
    );
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Full Name':
        return 'XYZ';
      case 'Email Address':
        return 'yourname@example.com';
      case 'Phone Number':
        return '+92 300 1234567';
      case 'Location':
        return 'Punjab, Pakistan';
      case 'Farm Size':
        return '5.0 acres';
      case 'Password':
        return 'Enter your password';
      case 'Confirm Password':
        return 'Confirm your password';
      default:
        return '';
    }
  }
}
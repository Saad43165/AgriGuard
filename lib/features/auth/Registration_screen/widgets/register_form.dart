import 'package:flutter/material.dart';

class RegisterForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: theme.colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormField(
                context,
                label: 'Full Name *',
                controller: nameController,
                icon: Icons.person_rounded,
                semanticsLabel: 'Full Name',
              ),
              const SizedBox(height: 16),
              _buildFormField(
                context,
                label: 'Email Address *',
                controller: emailController,
                icon: Icons.email_rounded,
                semanticsLabel: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                context,
                label: 'Phone Number',
                controller: phoneController,
                icon: Icons.phone_rounded,
                semanticsLabel: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                context,
                label: 'Location',
                controller: locationController,
                icon: Icons.location_on_rounded,
                semanticsLabel: 'Location',
              ),
              const SizedBox(height: 16),
              _buildFormField(
                context,
                label: 'Farm Size (acres)',
                controller: farmSizeController,
                icon: Icons.agriculture_rounded,
                semanticsLabel: 'Farm Size',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                context,
                label: 'Password *',
                controller: passwordController,
                obscureText: obscurePassword,
                semanticsLabel: 'Password',
                onVisibilityChanged: onPasswordVisibilityChanged,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                context,
                label: 'Confirm Password *',
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                semanticsLabel: 'Confirm Password',
                onVisibilityChanged: onConfirmPasswordVisibilityChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required IconData icon,
        required String semanticsLabel,
        TextInputType? keyboardType,
      }) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: _getHintText(label),
            prefixIcon: Icon(icon, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: borderRadius),
            filled: true,
            fillColor: theme.colorScheme.surface.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // No manual validator - Firebase will handle validation
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        required bool obscureText,
        required String semanticsLabel,
        required VoidCallback onVisibilityChanged,
      }) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: _getHintText(label),
            prefixIcon: Icon(Icons.lock_rounded, color: theme.colorScheme.primary),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: onVisibilityChanged,
            ),
            border: OutlineInputBorder(borderRadius: borderRadius),
            filled: true,
            fillColor: theme.colorScheme.surface.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // No manual validator - Firebase will handle validation
        ),
      ],
    );
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Full Name *':
        return 'Enter your full name';
      case 'Email Address *':
        return 'your@email.com';
      case 'Phone Number':
        return '+92 300 1234567';
      case 'Location':
        return 'e.g., Punjab, Pakistan';
      case 'Farm Size (acres)':
        return 'e.g., 5';
      case 'Password *':
        return 'Enter your password';
      case 'Confirm Password *':
        return 'Confirm your password';
      default:
        return '';
    }
  }
}
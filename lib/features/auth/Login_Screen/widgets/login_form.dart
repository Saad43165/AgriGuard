import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_strings.dart';

/// A form widget for email and password input.
class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onForgotPassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onForgotPassword,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Email Address',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
            ),
          ),
          const SizedBox(height: AppMeasurements.smallPadding),
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
            decoration: InputDecoration(
              hintText: AppStrings.emailHint,
              hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
              prefixIcon: Icon(
                AppIcons.email,
                color: Theme.of(context).colorScheme.primary,
                size: AppMeasurements.iconSizeMedium,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            autofillHints: const [AutofillHints.email],
            // Removed manual validator - Firebase will handle validation
          ),
          const SizedBox(height: AppMeasurements.defaultPadding),
          Text(
            'Password',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
            ),
          ),
          const SizedBox(height: AppMeasurements.smallPadding),
          TextFormField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
            ),
            decoration: InputDecoration(
              hintText: AppStrings.passwordHint,
              hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
              prefixIcon: Icon(
                AppIcons.password,
                color: Theme.of(context).colorScheme.primary,
                size: AppMeasurements.iconSizeMedium,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? AppIcons.visibilityOff : AppIcons.visibilityOn,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppMeasurements.iconSizeMedium,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            autofillHints: const [AutofillHints.password],
            // Removed manual validator - Firebase will handle validation
          ),
          const SizedBox(height: AppMeasurements.smallPadding),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
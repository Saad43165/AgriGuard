import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_strings.dart';

/// A form widget for email input.
class EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;

  const EmailForm({
    super.key,
    required this.formKey,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
            controller: emailController,
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
            // No manual validator - Firebase will handle validation
            autofillHints: const [AutofillHints.email],
          ),
        ],
      ),
    );
  }
}
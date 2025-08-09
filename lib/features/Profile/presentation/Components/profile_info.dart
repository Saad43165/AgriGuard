import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_measurements.dart';
import '../components/glass_card.dart';

class ProfileInfo extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final EdgeInsets cardPadding;
  final double itemSpacing;

  const ProfileInfo({
    super.key,
    required this.userProfile,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.cardPadding,
    required this.itemSpacing,
  });

  factory ProfileInfo.fromRegistration({
    Key? key,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController phoneController,
    required TextEditingController locationController,
    required TextEditingController farmSizeController,
    required bool isEditing,
    required EdgeInsets cardPadding,
    required double itemSpacing,
  }) {
    return ProfileInfo(
      key: key,
      userProfile: {
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'location': locationController.text,
        'farmSize': farmSizeController.text,
      },
      isEditing: isEditing,
      nameController: nameController,
      emailController: emailController,
      phoneController: phoneController,
      cardPadding: cardPadding,
      itemSpacing: itemSpacing,
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
    required BuildContext context,
  }) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    return Semantics(
      label: 'Editable field for $label',
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(smallPadding),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ],
              ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: AppMeasurements.getResponsiveIconSizeSmall(context),
            ),
          ),
          SizedBox(width: smallPadding),
          Expanded(
            child: isEditing
                ? TextFormField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: smallPadding,
                  vertical: AppMeasurements.getResponsiveSmallPadding(context) * 0.5,
                ),
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppMeasurements.getResponsiveBorderRadius(context)),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 2,
                  ),
                ),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    final smallPadding = AppMeasurements.getResponsiveSmallPadding(context);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(smallPadding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: AppMeasurements.getResponsiveIconSizeSmall(context),
          ),
        ),
        SizedBox(width: smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not provided' : value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: value.isEmpty
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: cardPadding,
        child: Column(
          children: [
            _buildEditableField(
              label: 'Full Name',
              value: userProfile['name'] ?? '',
              controller: nameController,
              icon: Icons.person_rounded,
              context: context,
            ),
            SizedBox(height: itemSpacing),
            _buildEditableField(
              label: 'Email',
              value: userProfile['email'] ?? '',
              controller: emailController,
              icon: Icons.email_rounded,
              context: context,
            ),
            SizedBox(height: itemSpacing),
            _buildEditableField(
              label: 'Phone',
              value: userProfile['phone'] ?? '',
              controller: phoneController,
              icon: Icons.phone_rounded,
              context: context,
            ),
            SizedBox(height: itemSpacing),
            _buildInfoTile(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: userProfile['location'] ?? '',
              context: context,
            ),
            SizedBox(height: itemSpacing),
            _buildInfoTile(
              icon: Icons.agriculture_rounded,
              label: 'Farm Size',
              value: userProfile['farmSize']?.isEmpty ?? true ? 'Not provided' : userProfile['farmSize']!,
              context: context,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/glass_card.dart';

class ProfileInfo extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController locationController; // ADD THIS
  final TextEditingController farmSizeController; // ADD THIS
  final EdgeInsets cardPadding;
  final double itemSpacing;

  const ProfileInfo({
    super.key,
    required this.userProfile,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.locationController, // ADD THIS
    required this.farmSizeController, // ADD THIS
    required this.cardPadding,
    required this.itemSpacing,
  });

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    widget.locationController.text = widget.userProfile['location'] ?? '';
    widget.farmSizeController.text = widget.userProfile['farmSize']?.toString() ?? '';
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
    required BuildContext context,
    bool enabled = true,
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
            child: widget.isEditing && enabled
                ? TextFormField(
              controller: controller,
              enabled: enabled,
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

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: widget.cardPadding,
        child: Column(
          children: [
            _buildEditableField(
              label: 'Full Name',
              value: widget.userProfile['name'] ?? '',
              controller: widget.nameController,
              icon: Icons.person_rounded,
              context: context,
            ),
            SizedBox(height: widget.itemSpacing),
            _buildEditableField(
              label: 'Email',
              value: widget.userProfile['email'] ?? '',
              controller: widget.emailController,
              icon: Icons.email_rounded,
              context: context,
              enabled: false, // Email is not editable
            ),
            SizedBox(height: widget.itemSpacing),
            _buildEditableField(
              label: 'Phone',
              value: widget.userProfile['phone'] ?? '',
              controller: widget.phoneController,
              icon: Icons.phone_rounded,
              context: context,
            ),
            SizedBox(height: widget.itemSpacing),
            _buildEditableField(
              label: 'Location',
              value: widget.userProfile['location'] ?? '',
              controller: widget.locationController, // USE THE NEW CONTROLLER
              icon: Icons.location_on_rounded,
              context: context,
            ),
            SizedBox(height: widget.itemSpacing),
            _buildEditableField(
              label: 'Farm Size (acres)',
              value: widget.userProfile['farmSize']?.toString() ?? '',
              controller: widget.farmSizeController, // USE THE NEW CONTROLLER
              icon: Icons.agriculture_rounded,
              context: context,
            ),
          ],
        ),
      ),
    );
  }
}
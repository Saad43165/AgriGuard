import 'package:flutter/material.dart';
import '../../../../core/constants/app_measurements.dart';

class ProfileInfo extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController farmSizeController;
  final EdgeInsets cardPadding;
  final double itemSpacing;

  const ProfileInfo({
    super.key,
    required this.userProfile,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.locationController,
    required this.farmSizeController,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: widget.itemSpacing),
      padding: EdgeInsets.all(AppMeasurements.smallPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        border: Border.all(
          color: widget.isEditing && enabled
              ? theme.colorScheme.primary.withOpacity(0.45)
              : theme.colorScheme.outline.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.secondary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: AppMeasurements.getResponsiveIconSizeSmall(context),
            ),
          ),

          SizedBox(width: AppMeasurements.getResponsiveSmallPadding(context)),

          // Content
          Expanded(
            child: widget.isEditing && enabled
                ? TextFormField(
              controller: controller,
              enabled: enabled,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 14),
                  fontWeight: FontWeight.w600,
                ),
                // **clean underline when editing**
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 12),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : theme.colorScheme.onSurface,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Lock icon for disabled fields
          if (!enabled && !widget.isEditing)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // REMOVED horizontal margin - now uses full width
      padding: widget.cardPadding, // Use the provided cardPadding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.03),
            Theme.of(context).colorScheme.secondary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context) * 1.5,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(
              bottom: AppMeasurements.smallPadding,
              left: 4,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: AppMeasurements.getResponsiveFontSize(context, baseSize: 16),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Fields
          _buildEditableField(
            label: 'Full Name',
            value: widget.userProfile['name'] ?? '',
            controller: widget.nameController,
            icon: Icons.person_rounded,
            context: context,
          ),

          _buildEditableField(
            label: 'Email Address',
            value: widget.userProfile['email'] ?? '',
            controller: widget.emailController,
            icon: Icons.email_rounded,
            context: context,
            enabled: false,
          ),

          _buildEditableField(
            label: 'Phone Number',
            value: widget.userProfile['phone'] ?? '',
            controller: widget.phoneController,
            icon: Icons.phone_rounded,
            context: context,
          ),

          _buildEditableField(
            label: 'Location',
            value: widget.userProfile['location'] ?? '',
            controller: widget.locationController,
            icon: Icons.location_on_rounded,
            context: context,
          ),

          _buildEditableField(
            label: 'Farm Size (acres)',
            value: widget.userProfile['farmSize']?.toString() ?? '',
            controller: widget.farmSizeController,
            icon: Icons.agriculture_rounded,
            context: context,
          ),
        ],
      ),
    );
  }
}
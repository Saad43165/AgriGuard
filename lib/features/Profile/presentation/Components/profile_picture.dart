import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../../core/constants/app_measurements.dart';

class ProfilePicture extends StatelessWidget {
  final XFile? profileImage;
  final bool isEditing;
  final VoidCallback onPickImage;
  final double maxWidth;
  final Animation<double> scaleAnimation;

  const ProfilePicture({
    super.key,
    required this.profileImage,
    required this.isEditing,
    required this.onPickImage,
    required this.maxWidth,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final profileSize = _calculateProfileSize(context);
    final innerSize = profileSize - AppMeasurements.getResponsiveSmallPadding(context) * 2;

    return ScaleTransition(
      scale: scaleAnimation,
      child: Semantics(
        label: 'Profile picture',
        button: isEditing,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildBackgroundCircle(context, profileSize),
            _buildProfileImage(context, innerSize),
            if (isEditing) _buildEditButton(context),
          ],
        ),
      ),
    );
  }

  double _calculateProfileSize(BuildContext context) {
    return AppMeasurements.getResponsiveSize(
      context,
      baseSize: maxWidth * 0.3 > 150 ? 150.0 : maxWidth * 0.3,
    );
  }

  Widget _buildBackgroundCircle(BuildContext context, double size) {
    return Container(
      width: size,
      height: size * 1.07,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, double size) {
    return Container(
      width: size,
      height: size * 1.08,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: profileImage != null
            ? Image.file(
          File(profileImage!.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const CircleAvatar(
      radius: 58,
      backgroundImage: AssetImage('assets/images/saad.png'),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Tooltip(
        message: 'Change profile picture',
        child: Semantics(
          label: 'Change profile picture',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPickImage,
                child: Padding(
                  padding: EdgeInsets.all(
                    AppMeasurements.getResponsiveSmallPadding(context),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: AppMeasurements.getResponsiveIconSizeSmall(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
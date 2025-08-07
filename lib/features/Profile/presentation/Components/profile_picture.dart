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
    final profileSize = AppMeasurements.getResponsiveSize(context, baseSize: maxWidth * 0.3 > 150 ? 150.0 : maxWidth * 0.3);
    return ScaleTransition(
      scale: scaleAnimation,
      child: Semantics(
        label: 'Profile picture with edit option',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: profileSize,
              height: profileSize * 1.07,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            Container(
              width: profileSize - AppMeasurements.getResponsiveSmallPadding(context) * 2,
              height: (profileSize - AppMeasurements.getResponsiveSmallPadding(context) * 2) * 1.08,
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
                  width: profileSize - AppMeasurements.getResponsiveSmallPadding(context) * 2,
                  height: (profileSize - AppMeasurements.getResponsiveSmallPadding(context) * 2) * 1.08,
                  errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                    radius: 58,
                    backgroundImage: AssetImage('assets/images/saad.png'),
                  ),
                )
                    : const CircleAvatar(
                  radius: 58,
                  backgroundImage: AssetImage('assets/images/saad.png'),
                ),
              ),
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
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
                          padding: EdgeInsets.all(AppMeasurements.getResponsiveSmallPadding(context)),
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
          ],
        ),
      ),
    );
  }
}
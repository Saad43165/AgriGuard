import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<String?> _getProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();

    // First check Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null &&
            data['profileImageUrl'] != null &&
            data['profileImageUrl'] is String &&
            data['profileImageUrl'].isNotEmpty) {
          final url = data['profileImageUrl'] as String;
          // Only return valid HTTP URLs
          if (url.startsWith('http')) {
            return url;
          }
        }
      }
    }

    // Check local storage
    final localImage = prefs.getString('user_image');
    if (localImage != null && localImage.isNotEmpty) {
      return localImage;
    }

    return null; // Return null if no valid image
  }
  @override
  Widget build(BuildContext context) {
    final profileSize = _calculateProfileSize(context);
    final innerSize = profileSize - AppMeasurements.getResponsiveSmallPadding(context) * 2;

    return FutureBuilder<String?>(
      future: _getProfileImageUrl(),
      builder: (context, snapshot) {
        final imagePath = snapshot.data;

        return ScaleTransition(
          scale: scaleAnimation,
          child: Semantics(
            label: 'Profile picture',
            button: isEditing,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildBackgroundCircle(context, profileSize),
                _buildProfileImage(context, innerSize, imagePath),
                if (isEditing) _buildEditButton(context),
              ],
            ),
          ),
        );
      },
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

  Widget _buildProfileImage(BuildContext context, double size, String? imagePath) {
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
        child: imagePath != null && imagePath.isNotEmpty
            ? (imagePath.startsWith('http') || imagePath.startsWith('https')
            ? Image.network(
          imagePath,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(context),
        )
            : File(File(imagePath).path).existsSync()
            ? Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(context),
        )
            : _buildDefaultAvatar(context))
            : _buildDefaultAvatar(context),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 40,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
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
              color: Theme.of(context).colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPickImage,
                child: Padding(
                  padding: EdgeInsets.all(
                    AppMeasurements.getResponsiveSmallPadding(context) * 0.8,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: AppMeasurements.getResponsiveIconSizeSmall(context) * 0.9,
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
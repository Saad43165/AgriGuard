import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../../../core/constants/app_measurements.dart';

class ProfilePicture extends StatefulWidget {
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
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _hasInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(ProfilePicture oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload if profileImage changes (new image selected)
    if (widget.profileImage != oldWidget.profileImage) {
      if (widget.profileImage != null) {
        _currentImageUrl = widget.profileImage!.path;
        _isLoading = false;
        setState(() {});
      }
    }

    // Reload if editing mode changes and we haven't loaded yet
    if (!_hasInitialLoad) {
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    if (_hasInitialLoad) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (snapshot.exists) {
          final data = snapshot.data();
          final firebaseImageUrl = data?['profileImageUrl'] as String?;

          if (firebaseImageUrl != null && firebaseImageUrl.isNotEmpty) {
            _currentImageUrl = firebaseImageUrl;
          }
        }
      }

      // If we have a new image from widget, use that instead
      if (widget.profileImage != null) {
        _currentImageUrl = widget.profileImage!.path;
      }

      _hasInitialLoad = true;
    } catch (e) {
      print('Error loading profile image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileSize = _calculateProfileSize(context);

    return ScaleTransition(
      scale: widget.scaleAnimation,
      child: Semantics(
        label: 'Profile picture',
        button: widget.isEditing,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer Glow Ring
              Container(
                width: profileSize + 20,
                height: profileSize + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

              // Middle Ring
              Container(
                width: profileSize + 8,
                height: profileSize + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),

              // Profile Image Container
              _buildProfileImage(context, profileSize),

              // Edit Button
              if (widget.isEditing) _buildEditButton(context),

              // Status Badge (Online indicator)
              if (!widget.isEditing)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateProfileSize(BuildContext context) {
    return AppMeasurements.getResponsiveSize(
      context,
      baseSize: widget.maxWidth * 0.35 > 140 ? 140.0 : widget.maxWidth * 0.35,
    );
  }

  Widget _buildProfileImage(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        )
            : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
            ? _buildImageContent()
            : _buildDefaultAvatar(context),
      ),
    );
  }

  Widget _buildImageContent() {
    final imageUrl = _currentImageUrl!;

    // Check if it's a network URL (from Firebase)
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return _buildDefaultAvatar(context);
        },
      );
    }
    // Check if it's a local file path (newly selected image)
    else {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading local image: $error');
            return _buildDefaultAvatar(context);
          },
        );
      } else {
        return _buildDefaultAvatar(context);
      }
    }
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 50,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 3,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
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
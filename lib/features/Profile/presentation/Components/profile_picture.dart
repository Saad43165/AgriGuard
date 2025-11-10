import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../core/constants/app_measurements.dart';

class ProfilePicture extends StatefulWidget {
  final File? profileImageFile;
  final String? profileImageBase64;
  final bool isEditing;
  final VoidCallback onPickImage;
  final double maxWidth;
  final Animation<double> scaleAnimation;

  const ProfilePicture({
    super.key,
    this.profileImageFile,
    this.profileImageBase64,
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

    // Reload if profile image changes
    if (widget.profileImageFile != oldWidget.profileImageFile ||
        widget.profileImageBase64 != oldWidget.profileImageBase64) {
      _updateCurrentImage();
    }

    if (!_hasInitialLoad) {
      _loadProfileImage();
    }
  }

  void _updateCurrentImage() {
    // Priority 1: Newly selected local file
    if (widget.profileImageFile != null) {
      _currentImageUrl = widget.profileImageFile!.path;
      _isLoading = false;
      if (mounted) setState(() {});
    }
    // Priority 2: Base64 image from Firestore
    else if (widget.profileImageBase64 != null &&
        widget.profileImageBase64!.isNotEmpty) {
      _currentImageUrl = 'base64:${widget.profileImageBase64}';
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadProfileImage() async {
    if (_hasInitialLoad) return;

    if (mounted) setState(() => _isLoading = true);

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

          // Check if it's a Base64 string (not a URL)
          if (firebaseImageUrl != null &&
              firebaseImageUrl.isNotEmpty &&
              !firebaseImageUrl.startsWith('http')) {
            _currentImageUrl = 'base64:$firebaseImageUrl';
            debugPrint('📥 Loaded Base64 image from Firestore');
          } else if (firebaseImageUrl != null && firebaseImageUrl.isNotEmpty) {
            // It's a URL (legacy support)
            _currentImageUrl = firebaseImageUrl;
          }
        }
      }

      // If we have a new image from widget, use that instead
      _updateCurrentImage();
      _hasInitialLoad = true;
    } catch (e) {
      debugPrint('❌ Error loading profile image: $e');
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
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
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
            valueColor: AlwaysStoppedAnimation(
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

    // Check if it's a Base64 image
    if (imageUrl.startsWith('base64:')) {
      final base64String = imageUrl.substring(7); // Remove 'base64:' prefix
      try {
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error decoding Base64 image: $error');
            return _buildDefaultAvatar(context);
          },
        );
      } catch (e) {
        debugPrint('❌ Base64 decode error: $e');
        return _buildDefaultAvatar(context);
      }
    }
    // Check if it's a network URL (from Firebase Storage - legacy)
    else if (imageUrl.startsWith('http')) {
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
          debugPrint('❌ Error loading network image: $error');
          return _buildDefaultAvatar(context);
        },
      );
    }
    // Check if it's a local file path (newly selected image)
    else {
      try {
        final file = File(imageUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Error loading local image: $error');
              return _buildDefaultAvatar(context);
            },
          );
        } else {
          debugPrint('❌ Local file does not exist: $imageUrl');
          return _buildDefaultAvatar(context);
        }
      } catch (e) {
        debugPrint('❌ Error creating file from path: $e');
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
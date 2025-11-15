import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/utils/profile_image_manager.dart';

class CustomHomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomHomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<CustomHomeAppBar> createState() => _CustomHomeAppBarState();
}

class _CustomHomeAppBarState extends State<CustomHomeAppBar> {
  File? _profileImageFile;
  String? _profileImageBase64;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(covariant CustomHomeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    if (!mounted) return;

    setState(() => _isLoadingImage = true);

    try {
      // Priority 1: Check for pending image from ProfileImageManager (newly uploaded)
      final pendingImage = ProfileImageManager.getPendingImage();
      if (pendingImage != null && await pendingImage.exists()) {
        debugPrint('🖼️ AppBar: Loading pending image from manager');
        if (mounted) {
          setState(() {
            _profileImageFile = pendingImage;
            _profileImageBase64 = null; // Clear Base64 when we have local file
            _isLoadingImage = false;
          });
        }
        return;
      }

      // Priority 2: Load Base64 image from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists && mounted) {
          final data = snapshot.data() as Map<String, dynamic>;
          final imageUrl = data['profileImageUrl'] as String?;

          if (imageUrl != null && imageUrl.isNotEmpty) {
            // Check if it's Base64 (not starting with http)
            if (!imageUrl.startsWith('http')) {
              debugPrint('📥 AppBar: Loaded Base64 image from Firestore');
              setState(() {
                _profileImageBase64 = imageUrl;
                _profileImageFile = null;
                _isLoadingImage = false;
              });
            } else {
              // Legacy URL support (if you had URLs before)
              debugPrint('🌐 AppBar: Found URL (legacy), consider migrating to Base64');
              setState(() {
                _profileImageBase64 = imageUrl; // Store URL as is
                _profileImageFile = null;
                _isLoadingImage = false;
              });
            }
            return;
          }
        }
      }

      // No image found
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    } catch (e) {
      debugPrint('❌ AppBar: Error loading profile image: $e');
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  Stream<String> _userNameStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value('User');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fullName'] ?? 'User';
      }
      return 'User';
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildProfileAvatar() {
    if (_isLoadingImage) {
      return _buildLoadingAvatar();
    }

    // Priority 1: Local file (newly selected image)
    if (_profileImageFile != null) {
      return _buildAvatarContainer(
        child: ClipOval(
          child: Image.file(
            _profileImageFile!,
            fit: BoxFit.cover,
            width: 44,
            height: 44,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ AppBar: Error loading local file');
              return _buildDefaultAvatar();
            },
          ),
        ),
      );
    }

    // Priority 2: Base64 image from Firestore
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      // Check if it's a URL (legacy support)
      if (_profileImageBase64!.startsWith('http')) {
        return _buildAvatarContainer(
          child: ClipOval(
            child: Image.network(
              _profileImageBase64!,
              fit: BoxFit.cover,
              width: 44,
              height: 44,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingAvatar();
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ AppBar: Error loading network image');
                return _buildDefaultAvatar();
              },
            ),
          ),
        );
      }

      // It's Base64
      try {
        final Uint8List imageBytes = base64Decode(_profileImageBase64!);
        return _buildAvatarContainer(
          child: ClipOval(
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              width: 44,
              height: 44,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ AppBar: Error decoding Base64 image');
                return _buildDefaultAvatar();
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('❌ AppBar: Base64 decode error: $e');
        return _buildDefaultAvatar();
      }
    }

    // Default avatar if no image
    return _buildDefaultAvatar();
  }

  Widget _buildAvatarContainer({required Widget child}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.person_rounded,
        size: 24,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _userNameStream(),
      builder: (context, snapshot) {
        final fullName = snapshot.data ?? 'User';
        final firstName = fullName.split(' ').first;

        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 70,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                  const Color(0xFF0F0F23).withOpacity(0.95),
                  const Color(0xFF16213E).withOpacity(0.9),
                ]
                    : [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context)
                      .colorScheme
                      .background
                      .withOpacity(0.95),
                ],
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                // User Avatar with Profile Image
                _buildProfileAvatar(),

                const SizedBox(width: 12),

                // Greeting & Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getGreeting()} 👋',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: AppMeasurements.getResponsiveFontSize(
                            context,
                            baseSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          firstName,
                          style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize:
                            AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 18,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Notification Button (placeholder)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
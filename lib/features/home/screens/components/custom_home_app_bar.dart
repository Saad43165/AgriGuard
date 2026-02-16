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
      // Check for pending image
      final pendingImage = ProfileImageManager.getPendingImage();
      if (pendingImage != null && await pendingImage.exists()) {
        if (mounted) {
          setState(() {
            _profileImageFile = pendingImage;
            _profileImageBase64 = null;
            _isLoadingImage = false;
          });
        }
        return;
      }

      // Load from Firestore
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
            setState(() {
              _profileImageBase64 = imageUrl;
              _profileImageFile = null;
              _isLoadingImage = false;
            });
            return;
          }
        }
      }

      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
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

    // Local file
    if (_profileImageFile != null) {
      return _buildAvatarContainer(
        child: ClipOval(
          child: Image.file(
            _profileImageFile!,
            fit: BoxFit.cover,
            width: 48,
            height: 48,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          ),
        ),
      );
    }

    // Base64 or URL
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      if (_profileImageBase64!.startsWith('http')) {
        return _buildAvatarContainer(
          child: ClipOval(
            child: Image.network(
              _profileImageBase64!,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingAvatar();
              },
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
            ),
          ),
        );
      }

      try {
        final Uint8List imageBytes = base64Decode(_profileImageBase64!);
        return _buildAvatarContainer(
          child: ClipOval(
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
            ),
          ),
        );
      } catch (e) {
        return _buildDefaultAvatar();
      }
    }

    return _buildDefaultAvatar();
  }

  Widget _buildAvatarContainer({required Widget child}) {
    return Container(
      width: 48,
      height: 48,
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: child,
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
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
      width: 48,
      height: 48,
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.person_rounded,
        size: 26,
        color: Colors.white,
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                colors: isDark
                    ? [
                  const Color(0xFF0F0F23).withOpacity(0.95),
                  const Color(0xFF16213E).withOpacity(0.9),
                ]
                    : [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                // Clickable Profile Avatar
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToProfile,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _buildProfileAvatar(),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Greeting & Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: AppMeasurements.getResponsiveFontSize(
                            context,
                            baseSize: 12,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: AppMeasurements.getResponsiveFontSize(
                              context,
                              baseSize: 19,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
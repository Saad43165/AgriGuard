import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/widgets/app_themes.dart';
import '../../../Profile/utils/profile_image_manager.dart';
import '../../../chatbot/chatbot_screen.dart';

class CustomHomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomHomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(68);

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

  Future<void> _loadProfileImage() async {
    if (!mounted) return;
    setState(() => _isLoadingImage = true);
    try {
      final pending = ProfileImageManager.getPendingImage();
      if (pending != null && await pending.exists()) {
        if (mounted) setState(() { _profileImageFile = pending; _isLoadingImage = false; });
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First try Firestore (covers both email and Google users)
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snap.exists && mounted) {
          final url = (snap.data() as Map<String, dynamic>)['profileImageUrl'] as String?;
          if (url != null && url.isNotEmpty) {
            setState(() { _profileImageBase64 = url; _isLoadingImage = false; });
            return;
          }
        }
        // Fallback: use Firebase Auth photoURL (Google profile picture)
        if (user.photoURL != null && user.photoURL!.isNotEmpty && mounted) {
          setState(() { _profileImageBase64 = user.photoURL; _isLoadingImage = false; });
          return;
        }
      }
      if (mounted) setState(() => _isLoadingImage = false);
    } catch (_) {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  Stream<String> _userNameStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value('User');
    return FirebaseFirestore.instance
        .collection('users').doc(user.uid).snapshots()
        .map((d) => d.exists ? ((d.data() as Map)['fullName'] ?? 'User') : 'User');
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildAvatar() {
    Widget inner;
    if (_isLoadingImage) {
      inner = Center(
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      );
    } else if (_profileImageFile != null) {
      inner = ClipOval(child: Image.file(_profileImageFile!, fit: BoxFit.cover, width: 40, height: 40,
          errorBuilder: (_, __, ___) => _defaultIcon()));
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      if (_profileImageBase64!.startsWith('http')) {
        inner = ClipOval(child: Image.network(_profileImageBase64!, fit: BoxFit.cover, width: 40, height: 40,
            loadingBuilder: (_, child, progress) => progress == null ? child : _defaultIcon(),
            errorBuilder: (_, __, ___) => _defaultIcon()));
      } else {
        try {
          final bytes = base64Decode(_profileImageBase64!);
          inner = ClipOval(child: Image.memory(bytes, fit: BoxFit.cover, width: 40, height: 40,
              errorBuilder: (_, __, ___) => _defaultIcon()));
        } catch (_) { inner = _defaultIcon(); }
      }
    } else {
      inner = _defaultIcon();
    }

    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: inner,
      ),
    );
  }

  Widget _defaultIcon() => const Icon(Icons.person_rounded, size: 22, color: AppColors.primary);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<String>(
              stream: _userNameStream(),
              builder: (context, snap) {
                final firstName = (snap.data ?? 'User').split(' ').first;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: _buildAvatar(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // AI Chat — labeled feature button
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 5),
                            Text('AI Chat', style: TextStyle(
                              color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.w800, letterSpacing: 0.2,
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Analytics — labeled feature button
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 16),
                            SizedBox(width: 5),
                            Text('Analytics', style: TextStyle(
                              color: AppColors.primary, fontSize: 12,
                              fontWeight: FontWeight.w800, letterSpacing: 0.2,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

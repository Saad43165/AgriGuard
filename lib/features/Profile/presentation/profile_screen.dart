import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/floating_orb.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import '../Components/actions.dart';
import '../Components/edit_profile_sheet.dart';
import '../Components/guest_restriction_view.dart';
import '../Components/logout_confirmation_dialog_content.dart';
import '../Components/profile_appbar.dart';
import '../Components/profile_header.dart';
import '../Components/profile_image_helper.dart';
import '../Components/profile_info.dart';
import '../Components/profile_picture_option_sheet.dart';
import '../Components/statistics.dart';
import '../utils/profile_image_manager.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  // State variables
  Map<String, dynamic> _userProfile = {
    'name': 'Loading...',
    'email': '',
    'phone': '',
    'location': '',
    'farmSize': '',
    'crops': [],
    'joinDate': '',
    'scanCount': 0,
    'reportCount': 0,
    'lastUpdated': '',
    'profileImageUrl': null,
  };

  bool _isLoading = true;
  bool _hasLoaded = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();

  // Image state
  File? _profileImageFile;
  String? _profileImageBase64;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final ValueNotifier<bool> _profileChangedNotifier = ValueNotifier(false);
  final GuestService _guestService = GuestService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGuestService();
  }

  Future<void> _initializeGuestService() async {
    await _guestService.initialize();
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      if (!_guestService.isGuestMode) {
        _loadProfile();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _farmSizeController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _profileChangedNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        _userProfile = {
          'name': data['fullName'] ?? data['name'] ?? 'User',
          'email': data['email'] ?? '',
          'phone': data['phoneNumber'] ?? data['phone'] ?? '',
          'location': data['location'] ?? '',
          'farmSize': data['farmSize']?.toString() ?? '',
          'crops': data['crops'] ?? [],
          'joinDate': data['createdAt']?.toString() ?? data['joinDate'] ?? '',
          'scanCount': data['scanCount'] ?? 0,
          'reportCount': data['reportCount'] ?? 0,
          'lastUpdated': data['lastUpdated']?.toString() ?? '',
          'profileImageUrl': data['profileImageUrl'],
        };

        if (data['profileImageUrl'] != null &&
            data['profileImageUrl'] is String &&
            data['profileImageUrl'].toString().isNotEmpty) {
          _profileImageBase64 = data['profileImageUrl'];
          _syncImageToManager();
        }
      }

      _nameController.text = _userProfile['name'];
      _emailController.text = _userProfile['email'];
      _phoneController.text = _userProfile['phone'];
      _locationController.text = _userProfile['location'] ?? '';
      _farmSizeController.text = _userProfile['farmSize']?.toString() ?? '';

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load profile', isError: true);
      }
    }
  }

  Future<void> _syncImageToManager() async {
    if (_profileImageBase64 == null || _profileImageBase64!.isEmpty) return;

    try {
      if (_profileImageBase64!.startsWith('http')) return;

      final bytes = base64Decode(_profileImageBase64!);
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);

      ProfileImageManager.setPendingImage(tempFile);
      _profileImageFile = tempFile;
    } catch (e) {
      debugPrint('❌ Error syncing image: $e');
    }
  }

  Future<void> _saveProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      if (_nameController.text.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      final updateData = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'farmSize': _farmSizeController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        updateData['profileImageUrl'] = _profileImageBase64;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      setState(() {
        _userProfile['name'] = _nameController.text.trim();
        _userProfile['phone'] = _phoneController.text.trim();
        _userProfile['location'] = _locationController.text.trim();
        _userProfile['farmSize'] = _farmSizeController.text.trim();
        _userProfile['profileImageUrl'] = _profileImageBase64;
      });

      _profileChangedNotifier.value = !_profileChangedNotifier.value;
      _showSnackBar('Profile saved successfully!', isError: false);
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      _showSnackBar('Failed to save: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final result = await ProfileImageHelper.pickAndProcessImage();

      if (result != null) {
        setState(() {
          _profileImageFile = result['file'];
          _profileImageBase64 = result['base64'];
        });

        ProfileImageManager.setPendingImage(result['file']);
        _profileChangedNotifier.value = !_profileChangedNotifier.value;

        await _saveProfile();
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      _showSnackBar('Error updating image: $e', isError: true);
    }
  }

  Future<void> _logout() async {
    try {
      ProfileImageManager.clearPendingImage();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (mounted) {
        _showSnackBar('Logout failed: $e', isError: true);
      }
    }
  }

  void _showEditProfileSheet() {
    showEditProfileSheet(
      context: context,
      nameController: _nameController,
      phoneController: _phoneController,
      locationController: _locationController,
      farmSizeController: _farmSizeController,
      onSave: () {
        _saveProfile();
        Navigator.pop(context);
      },
    );
  }

  void _showLogoutDialog() {
    showLogoutConfirmationDialog(
      context: context,
      onConfirm: _logout,
    );
  }

  void _showProfilePictureOptions() {
    showProfilePictureOptionsSheet(
      context: context,
      profileImageFile: _profileImageFile,
      profileImageBase64: _profileImageBase64,
      onChangeImage: _pickProfileImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _guestService.isGuestMode
          ? null
          : ProfileAppBar(onLogoutPressed: _showLogoutDialog),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_guestService.isGuestMode) {
            return GuestRestrictionView(
              maxWidth: constraints.maxWidth,
              fadeController: _fadeController,
              scaleAnimation: _scaleAnimation,
              guestService: _guestService,
            );
          }

          if (_isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return _buildBody(context, constraints.maxWidth);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, double maxWidth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                const Color(0xFF0A0E27),
                const Color(0xFF1A1F3A),
                const Color(0xFF0F1419),
              ]
                  : [
                const Color(0xFFF8FAFB),
                const Color(0xFFE8F5E9),
                const Color(0xFFF1F8F4),
              ],
            ),
          ),
        ),

        // Floating Orbs
        ...List.generate(
          8,
              (i) => FloatingOrb(
            index: i,
            maxWidth: maxWidth,
            fadeController: _fadeController,
            scaleAnimation: _scaleAnimation,
          ),
        ),

        // Main content
        ValueListenableBuilder<bool>(
          valueListenable: _profileChangedNotifier,
          builder: (context, _, __) {
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Compact Profile Header
                      CompactProfileHeader(
                        userProfile: _userProfile,
                        profileImageFile: _profileImageFile,
                        profileImageBase64: _profileImageBase64,
                        isDark: isDark,
                        onEditPressed: _showEditProfileSheet,
                        onImageTap: _showProfilePictureOptions,
                      ),

                      const SizedBox(height: 20),

                      // Compact Statistics
                      CompactStatistics(
                        userProfile: _userProfile,
                        isDark: isDark,
                        fadeAnimation: _fadeAnimation,
                      ),

                      const SizedBox(height: 20),

                      // Profile Information
                      SlideTransition(
                        position: _slideAnimation,
                        child: ProfileInfo(
                          userProfile: _userProfile,
                          isEditing: false,
                          nameController: _nameController,
                          emailController: _emailController,
                          phoneController: _phoneController,
                          locationController: _locationController,
                          farmSizeController: _farmSizeController,
                          onSave: _saveProfile,
                          onCancel: () {},
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Profile Actions
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const ProfileActions(
                          padding: EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
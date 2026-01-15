import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/floating_orb.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import '../utils/profile_image_manager.dart';
import 'Components/actions.dart';
import 'Components/profile_info.dart';
import 'Components/profile_picture.dart' show ProfilePicture;
import 'Components/statistics.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({
    super.key,
    this.userData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
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
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();

  File? _profileImageFile;
  String? _profileImageBase64;

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
    if (mounted) {
      setState(() {});
    }
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

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

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
        setState(() {
          _userProfile = {
            'name': 'Error loading profile',
            'email': '',
            'phone': '',
            'location': '',
            'farmSize': '',
            'crops': [],
            'joinDate': '',
            'scanCount': 0,
            'reportCount': 0,
            'lastUpdated': 'Error: $e',
            'profileImageUrl': null,
          };
          _isLoading = false;
        });
        _showSnackBar('Failed to load profile: $e', isError: true);
      }
    }
  }

  Future<void> _syncImageToManager() async {
    if (_profileImageBase64 == null || _profileImageBase64!.isEmpty) return;

    try {
      if (_profileImageBase64!.startsWith('http')) return;

      final bytes = base64Decode(_profileImageBase64!);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);

      ProfileImageManager.setPendingImage(tempFile);
      _profileImageFile = tempFile;
    } catch (e) {
      debugPrint('❌ Error syncing image to manager: $e');
    }
  }

  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      Uint8List compressedBytes = bytes;
      if (bytes.length > 500000) {
        compressedBytes = await _compressImage(bytes);
      }

      final base64String = base64Encode(compressedBytes);
      return base64String;
    } catch (e) {
      debugPrint('❌ Base64 conversion error: $e');
      return null;
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final codec = await instantiateImageCodec(
        bytes,
        targetWidth: 300,
        targetHeight: 300,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      return bytes;
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

  Future<void> _saveProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

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
        _isEditing = false;
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
    if (!_isEditing) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        final base64String = await _convertImageToBase64(file);
        if (base64String != null) {
          setState(() {
            _profileImageFile = file;
            _profileImageBase64 = base64String;
          });

          ProfileImageManager.setPendingImage(file);
          _profileChangedNotifier.value = !_profileChangedNotifier.value;
        } else {
          _showSnackBar('Failed to process image', isError: true);
        }
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

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values
        _nameController.text = _userProfile['name'];
        _phoneController.text = _userProfile['phone'];
        _locationController.text = _userProfile['location'] ?? '';
        _farmSizeController.text = _userProfile['farmSize']?.toString() ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_guestService.isGuestMode) {
            return _buildGuestRestrictionScreen(constraints.maxWidth);
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

  Widget _buildGuestRestrictionScreen(double maxWidth) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
            const Color(0xFF0F0F23),
            const Color(0xFF16213E),
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F23),
          ]
              : [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Profile Not Available',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _guestService.getRestrictionMessage('view_profile'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In / Sign Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double maxWidth) {
    return Stack(
      children: [
        // Floating Orbs in background
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
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                    const Color(0xFF0F0F23).withOpacity(0.95),
                    const Color(0xFF16213E).withOpacity(0.9),
                    const Color(0xFF1A1A2E).withOpacity(0.95),
                    const Color(0xFF0F0F23).withOpacity(0.95),
                  ]
                      : [
                    const Color(0xFFF5F5F5).withOpacity(0.95),
                    const Color(0xFFE8E8E8).withOpacity(0.9),
                    const Color(0xFFEAEAEA).withOpacity(0.95),
                    const Color(0xFFF0F0F0).withOpacity(0.95),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        // Back and Menu buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _showLogoutConfirmation(context),
                              icon: Icon(
                                Icons.logout_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Profile Picture with edit overlay
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _isEditing ? _pickProfileImage : null,
                              child: ProfilePicture(
                                profileImageFile: _profileImageFile,
                                profileImageBase64: _profileImageBase64,
                                isEditing: _isEditing,
                                scaleAnimation: _scaleAnimation,
                              ),
                            ),
                            if (!_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _toggleEditMode,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.8),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Name and email
                        SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Text(
                                _userProfile['name'] ?? 'User',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userProfile['email'] ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Statistics Cards
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Statistics(
                            cardPadding: const EdgeInsets.all(16),
                            itemSpacing: 12,
                            userId: FirebaseAuth.instance.currentUser?.uid, // NEW: real-time data
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Profile Information Section
                        SlideTransition(
                          position: _slideAnimation,
                          child: ProfileInfo(
                            userProfile: _userProfile,
                            isEditing: _isEditing,
                            nameController: _nameController,
                            emailController: _emailController,
                            phoneController: _phoneController,
                            locationController: _locationController,
                            farmSizeController: _farmSizeController,
                            onSave: _saveProfile,
                            onCancel: _toggleEditMode,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Profile Actions
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ProfileActions(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                'Logout Confirmation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
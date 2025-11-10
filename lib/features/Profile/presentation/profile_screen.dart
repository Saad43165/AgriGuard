import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth_services.dart';
import '../../Navbar/presentation/nav_bar.dart';
import '../../Settings/presentation/components/floating_orb.dart';
import '../../home/presentation/screens/components/custom_home_app_bar.dart';
import 'Components/profile_info.dart';
import 'components/profile_header.dart';
import 'components/profile_picture.dart';
import 'components/statistics.dart';
import 'components/actions.dart' as profile_actions;

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({
    super.key,
    this.userData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  Map<String, dynamic> _userProfile = {
    'name': 'Loading...',
    'email': '',
    'phone': '',
    'location': '',
    'farmSize': '',
    'crops': [],
    'joinDate': '',
    'scanCount': 0,
    'lastUpdated': '',
  };

  bool _isEditing = false;
  bool _isLoading = true;
  bool _hasLoaded = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _farmSizeController = TextEditingController();

  XFile? _profileImage;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _navTapInProgress = false;

  // NEW: Force UI rebuild after save
  final ValueNotifier<bool> _profileChangedNotifier = ValueNotifier(false);

  Future<void> _debouncedNavTap(int index) async {
    if (_navTapInProgress) return;
    _navTapInProgress = true;

    HapticFeedback.lightImpact();

    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.scan,
            (r) => r.settings.name == AppRoutes.home,
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _navTapInProgress = false;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.isNotEmpty) {
        _userProfile = {
          'name': args['fullName'] ?? args['name'] ?? 'Loading...',
          'email': args['email'] ?? '',
          'phone': args['phoneNumber'] ?? args['phone'] ?? '',
          'location': args['location'] ?? '',
          'farmSize': args['farmSize']?.toString() ?? '',
          'crops': args['crops'] ?? [],
          'joinDate': args['createdAt']?.toString() ?? args['joinDate'] ?? '',
          'scanCount': args['scanCount'] ?? 0,
          'lastUpdated': args['lastUpdated'] ?? '',
        };
        _profileImage = args['profileImageUrl'] != null ? XFile(args['profileImageUrl']) : null;
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (snapshot.exists) {
            final data = snapshot.data()!;
            _userProfile = {
              'name': data['fullName'] ?? data['name'] ?? 'Loading...',
              'email': data['email'] ?? '',
              'phone': data['phoneNumber'] ?? data['phone'] ?? '',
              'location': data['location'] ?? '',
              'farmSize': data['farmSize']?.toString() ?? '',
              'crops': data['crops'] ?? [],
              'joinDate': data['createdAt']?.toString() ?? data['joinDate'] ?? '',
              'scanCount': data['scanCount'] ?? 0,
              'lastUpdated': data['lastUpdated']?.toString() ?? '',
            };
            if (data['profileImageUrl'] != null && data['profileImageUrl'].isNotEmpty) {
              _profileImage = XFile(data['profileImageUrl']);
            }
          }
        }
      }

      _nameController.text = _userProfile['name'];
      _emailController.text = _userProfile['email'];
      _phoneController.text = _userProfile['phone'];
      _locationController.text = _userProfile['location'] ?? '';
      _farmSizeController.text = _userProfile['farmSize']?.toString() ?? '';

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
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
            'lastUpdated': 'Error: $e',
          };
          _isLoading = false;
        });
      }
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

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
    _profileChangedNotifier.dispose(); // <-- NEW
    super.dispose();
  }

  void _toggleEditMode() {
    if (_isSaving) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _isSaving = true;
        _saveProfileWithFeedback();
      }
    });
  }

  Future<void> _saveProfileWithFeedback() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await authService.value.updateProfile(
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          farmSize: _farmSizeController.text.trim(),
        );

        // NEW: Trigger Home AppBar refresh

        // NEW: Force UI rebuild
        _profileChangedNotifier.value = !_profileChangedNotifier.value;
      }

      _showSingleSnackBar('Profile updated successfully', isError: false);
    } catch (e) {
      _showSingleSnackBar('Error saving profile: $e', isError: true);
    } finally {
      _isSaving = false;
    }
  }

  void _showSingleSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

// In your ProfileScreen class, update the _pickProfileImage method:

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 300,
          maxHeight: 300,
          imageQuality: 85
      );

      if (pickedFile != null) {
        setState(() => _profileImage = pickedFile);

        // Upload to Firebase Storage and get download URL
        final String? downloadUrl = await _uploadProfileImageToFirebase(pickedFile);

        if (downloadUrl != null) {
          // Update Firestore with the new image URL
          await _updateProfileImageInFirestore(downloadUrl);

          // Update local state
          setState(() {
            _profileImage = XFile(downloadUrl);
          });

          // Force UI refresh
          _profileChangedNotifier.value = !_profileChangedNotifier.value;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated!'),
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _uploadProfileImageToFirebase(XFile imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Upload to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      final UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProfileImageInFirestore(String imageUrl) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'profileImageUrl': imageUrl,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating Firestore: $e');
      rethrow;
    }
  }
  Future<void> _uploadProfileImage(XFile imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'lastUpdated': DateTime.now()});
      }
    } catch (e) {
      print('Error handling profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final fromScan = args?['fromScan'] == true;

        if (fromScan) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.scan, (r) => r.settings.name == AppRoutes.home);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (_isLoading) return const Center(child: CircularProgressIndicator());
            final isTablet = MediaQuery.of(context).size.width > 600;
            return _buildBody(context, isTablet, constraints.maxWidth);
          },
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: 2,
          onTap: _debouncedNavTap,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isTablet, double maxWidth) {
    final sectionSpacing = AppMeasurements.smallPadding * 1.5;

    return ValueListenableBuilder<bool>(
      valueListenable: _profileChangedNotifier,
      builder: (context, _, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0F0F23), const Color(0xFF16213E), const Color(0xFF1A1A2E), const Color(0xFF0F0F23)]
                  : [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withOpacity(0.9), Theme.of(context).colorScheme.surface.withOpacity(0.8), Theme.of(context).colorScheme.surface],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(6, (i) => FloatingOrb(index: i, maxWidth: maxWidth, fadeController: _fadeController, scaleAnimation: _scaleAnimation)),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    slivers: [
                      ProfileHeader(onToggleEdit: _toggleEditMode, isEditing: _isEditing),

                      SliverToBoxAdapter(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
                          child: Column(
                            children: [
                              SizedBox(height: sectionSpacing),
                              ProfilePicture(
                                profileImage: _profileImage,
                                isEditing: _isEditing,
                                onPickImage: _pickProfileImage,
                                maxWidth: maxWidth,
                                scaleAnimation: _scaleAnimation,
                              ),
                              SizedBox(height: sectionSpacing),
                              if (isTablet)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppMeasurements.defaultPadding),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        child: ProfileInfo(
                                          userProfile: _userProfile,
                                          isEditing: _isEditing,
                                          nameController: _nameController,
                                          emailController: _emailController,
                                          phoneController: _phoneController,
                                          locationController: _locationController,
                                          farmSizeController: _farmSizeController,
                                          cardPadding: EdgeInsets.all(AppMeasurements.smallPadding),
                                          itemSpacing: AppMeasurements.smallPadding,
                                        ),
                                      ),
                                      SizedBox(width: sectionSpacing),
                                      Flexible(
                                        flex: 1,
                                        child: Statistics(
                                          userProfile: _userProfile,
                                          cardPadding: EdgeInsets.all(AppMeasurements.smallPadding),
                                          itemSpacing: AppMeasurements.smallPadding,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    ProfileInfo(
                                      userProfile: _userProfile,
                                      isEditing: _isEditing,
                                      nameController: _nameController,
                                      emailController: _emailController,
                                      phoneController: _phoneController,
                                      locationController: _locationController,
                                      farmSizeController: _farmSizeController,
                                      cardPadding: EdgeInsets.all(AppMeasurements.smallPadding),
                                      itemSpacing: AppMeasurements.smallPadding,
                                    ),
                                    SizedBox(height: sectionSpacing),
                                    Statistics(
                                      userProfile: _userProfile,
                                      cardPadding: EdgeInsets.all(AppMeasurements.smallPadding),
                                      itemSpacing: AppMeasurements.smallPadding,
                                    ),
                                  ],
                                ),
                              SizedBox(height: sectionSpacing),
                              profile_actions.ProfileActions(
                                padding: EdgeInsets.all(AppMeasurements.smallPadding),
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
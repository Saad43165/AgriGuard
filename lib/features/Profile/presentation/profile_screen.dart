import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../Settings/presentation/components/floating_orb.dart';
import '../utils/profile_image_manager.dart';
import 'Components/profile_info.dart';
import 'Components/profile_picture.dart' show ProfilePicture;
import 'components/profile_header.dart';
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
    'lastUpdated': '',
    'profileImageUrl': null,
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

  File? _profileImageFile;
  String? _profileImageBase64;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final ValueNotifier<bool> _profileChangedNotifier = ValueNotifier(false);

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
          'lastUpdated': data['lastUpdated']?.toString() ?? '',
          'profileImageUrl': data['profileImageUrl'],
        };

        if (data['profileImageUrl'] != null &&
            data['profileImageUrl'] is String &&
            data['profileImageUrl'].toString().isNotEmpty) {
          _profileImageBase64 = data['profileImageUrl'];
          debugPrint('📥 Profile loaded from Firestore (Image: ${_profileImageBase64!.length} chars)');
          _syncImageToManager();
        }
      }

      _nameController.text = _userProfile['name'];
      _emailController.text = _userProfile['email'];
      _phoneController.text = _userProfile['phone'];
      _locationController.text = _userProfile['location'] ?? '';
      _farmSizeController.text = _userProfile['farmSize']?.toString() ?? '';

      if (mounted) setState(() => _isLoading = false);

      debugPrint('✅ Profile loaded successfully');
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

      debugPrint('🔄 Synced Base64 to ProfileImageManager for home screen');
    } catch (e) {
      debugPrint('❌ Error syncing image to manager: $e');
    }
  }

  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('❌ Image file does not exist');
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      debugPrint('📊 Converting image to Base64 (${bytes.length} bytes)');

      Uint8List compressedBytes = bytes;
      if (bytes.length > 500000) {
        debugPrint('⚡ Compressing image...');
        compressedBytes = await _compressImage(bytes);
      }

      final base64String = base64Encode(compressedBytes);
      debugPrint('✅ Base64 conversion successful (${base64String.length} chars)');
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
      debugPrint('❌ Compression failed, using original: $e');
      return bytes;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _scaleController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

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
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('💾 Saving profile data...');

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
        debugPrint('💾 Including profile image in update');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      debugPrint('✅ Profile saved to Firestore successfully');

      setState(() {
        _userProfile['name'] = _nameController.text.trim();
        _userProfile['phone'] = _phoneController.text.trim();
        _userProfile['location'] = _locationController.text.trim();
        _userProfile['farmSize'] = _farmSizeController.text.trim();
        _userProfile['profileImageUrl'] = _profileImageBase64;
      });

      _profileChangedNotifier.value = !_profileChangedNotifier.value;

      _showSnackBar(
        'Profile Changed Successfully!',
        isError: false,
      );
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      _showSnackBar('❌ Failed to save: $e', isError: true);
      setState(() => _isEditing = true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
        action: isError
            ? null
            : SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
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

        debugPrint('🖼️ Image picked: ${file.path}');

        final base64String = await _convertImageToBase64(file);
        if (base64String != null) {
          setState(() {
            _profileImageFile = file;
            _profileImageBase64 = base64String;
          });

          ProfileImageManager.setPendingImage(file);

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({
              'profileImageUrl': _profileImageBase64,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            debugPrint('💾 Profile image saved to Firestore immediately');
          }

          _profileChangedNotifier.value = !_profileChangedNotifier.value;
        } else {
          _showSnackBar('❌ Failed to process image', isError: true);
        }
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      _showSnackBar('❌ Error updating image: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
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

          final isTablet = MediaQuery.of(context).size.width > 600;
          return _buildBody(context, isTablet, constraints.maxWidth);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isTablet, double maxWidth) {
    final padding = AppMeasurements.getResponsivePadding(context);
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
                  ? [
                const Color(0xFF0F0F23),
                const Color(0xFF16213E),
                const Color(0xFF1A1A2E),
                const Color(0xFF0F0F23)
              ]
                  : [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.9),
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
                Theme.of(context).colorScheme.surface
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              ...List.generate(
                  6,
                      (i) => FloatingOrb(
                      index: i,
                      maxWidth: maxWidth,
                      fadeController: _fadeController,
                      scaleAnimation: _scaleAnimation)),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    slivers: [
                      ProfileHeader(
                        onToggleEdit: _toggleEditMode,
                        isEditing: _isEditing,
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: padding * 0.4),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: isTablet ? 600 : double.infinity),
                            child: Column(
                              children: [
                                SizedBox(height: sectionSpacing),
                                ProfilePicture(
                                  profileImageFile: _profileImageFile,
                                  profileImageBase64: _profileImageBase64,
                                  isEditing: _isEditing,
                                  onPickImage: _pickProfileImage,
                                  maxWidth: maxWidth,
                                  scaleAnimation: _scaleAnimation,
                                ),
                                SizedBox(height: sectionSpacing),
                                if (isTablet)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppMeasurements.defaultPadding),
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
                                            cardPadding: EdgeInsets.all(
                                                AppMeasurements.smallPadding),
                                            itemSpacing: AppMeasurements.smallPadding,
                                          ),
                                        ),
                                        SizedBox(width: sectionSpacing),
                                        Flexible(
                                          flex: 1,
                                          child: Statistics(
                                            userProfile: _userProfile,
                                            cardPadding: EdgeInsets.all(
                                                AppMeasurements.smallPadding),
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
                                        cardPadding: EdgeInsets.all(
                                            AppMeasurements.smallPadding),
                                        itemSpacing: AppMeasurements.smallPadding,
                                      ),
                                      SizedBox(height: sectionSpacing),
                                      Statistics(
                                        userProfile: _userProfile,
                                        cardPadding: EdgeInsets.all(
                                            AppMeasurements.smallPadding),
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
                      ),
                    ],
                  ),
                ),
              ),

              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Saving profile...',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
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
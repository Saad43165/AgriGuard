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
  bool _hasLoaded = false; // ADD THIS FLAG

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // REMOVE _loadProfile() from here
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

      // Debug logging
      print('Route arguments: ${ModalRoute.of(context)?.settings.arguments}');
      print('Widget userData: ${widget.userData}');

      // Prioritize navigation arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.isNotEmpty) {
        print('Loading from route arguments: $args');
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
      }
      // If no args, try to load from Firestore
      else {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          print('Loading from Firestore for uid: $uid');
          final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (snapshot.exists) {
            final data = snapshot.data()!;
            print('Firestore data: $data');

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

            // Check for profile image URL
            if (data['profileImageUrl'] != null && data['profileImageUrl'].isNotEmpty) {
              _profileImage = XFile(data['profileImageUrl']);
            }
          } else {
            print('No Firestore document found for uid: $uid');
          }
        } else {
          print('No user is currently logged in');
        }
      }

      // Update controllers with loaded data
      _nameController.text = _userProfile['name'];
      _emailController.text = _userProfile['email'];
      _phoneController.text = _userProfile['phone'];
      _locationController.text = _userProfile['location'] ?? '';
      _farmSizeController.text = _userProfile['farmSize']?.toString() ?? '';

      // Debug logging
      print('Final userProfile: $_userProfile');

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');

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
            'lastUpdated': 'Error: ${e.toString()}',
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Use the AuthService to update profile
        await authService.value.updateProfile(
          fullName: _userProfile['name'],
          phoneNumber: _userProfile['phone'],
          location: _userProfile['location'],
          farmSize: _userProfile['farmSize'],
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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
    super.dispose();
  }

  void _toggleEditMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save all editable fields
        _userProfile['name'] = _nameController.text;
        _userProfile['phone'] = _phoneController.text;
        _userProfile['location'] = _locationController.text;
        _userProfile['farmSize'] = _farmSizeController.text;
        _userProfile['lastUpdated'] = DateTime.now().toString();

        _saveProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          ),
        );
      }
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
      await _uploadProfileImage(pickedFile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated!'),
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
        ),
      );
    }
  }

  Future<void> _uploadProfileImage(XFile imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // For now, just update the timestamp to trigger a refresh
        // You'll need to implement Firebase Storage upload separately
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'lastUpdated': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error handling profile image: $e');
    }
  }

  // Function to save scan results to Firebase
  Future<void> saveScanResult(String cropType, Map<String, dynamic> scanData) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Save scan to user's scan history
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('scans')
            .add({
          'cropType': cropType,
          'scanData': scanData,
          'timestamp': DateTime.now(),
        });

        // Update user's scan count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'scanCount': FieldValue.increment(1),
          'lastScan': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error saving scan: $e');
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth > 600;

          return _buildBody(context, isTablet, constraints.maxWidth);
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (index == 0) Navigator.pushNamed(context, AppRoutes.home);
          if (index == 1) Navigator.pushNamed(context, AppRoutes.scan);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isTablet, double maxWidth) {
    final padding = EdgeInsets.symmetric(
      horizontal: AppMeasurements.getResponsivePadding(context),
      vertical: AppMeasurements.getResponsivePadding(context),
    );
    final cardPadding = EdgeInsets.all(
      AppMeasurements.getResponsivePadding(context) * 0.75,
    );
    final sectionSpacing = AppMeasurements.getResponsivePadding(context) * 1.5;

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
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(
            6,
                (index) => FloatingOrb(
              index: index,
              maxWidth: maxWidth,
              fadeController: _fadeController,
              scaleAnimation: _scaleAnimation,
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        ProfileHeader(
                          onToggleEdit: _toggleEditMode,
                          isEditing: _isEditing,
                        ),
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
                          Row(
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
                                  cardPadding: cardPadding,
                                  itemSpacing: AppMeasurements.getResponsiveSmallPadding(context) * 1.5,
                                ),
                              ),
                              SizedBox(width: sectionSpacing),
                              Flexible(
                                flex: 1,
                                child: GestureDetector(
                                  child: Statistics(
                                    userProfile: _userProfile,
                                    cardPadding: cardPadding,
                                    itemSpacing: AppMeasurements.getResponsiveSmallPadding(context) * 1.5,
                                  ),
                                ),
                              ),
                            ],
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
                                cardPadding: cardPadding,
                                itemSpacing: AppMeasurements.getResponsiveSmallPadding(context) * 1.5,
                              ),
                              SizedBox(height: sectionSpacing),
                              GestureDetector(
                                child: Statistics(
                                  userProfile: _userProfile,
                                  cardPadding: cardPadding,
                                  itemSpacing: AppMeasurements.getResponsiveSmallPadding(context) * 1.5,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: sectionSpacing),
                        profile_actions.ProfileActions(padding: cardPadding),
                        SizedBox(height: sectionSpacing),
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
  }
}
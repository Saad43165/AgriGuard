import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../Navbar/presentation/nav_bar.dart';
import '../../Settings/presentation/components/floating_orb.dart';
import 'Components/actions.dart';
import 'Components/actions.dart' as profile_actions;
import 'components/profile_header.dart';
import 'components/profile_info.dart';
import 'components/profile_picture.dart';
import 'components/statistics.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final TextEditingController? registrationNameController;
  final TextEditingController? registrationEmailController;
  final TextEditingController? registrationPhoneController;
  final TextEditingController? registrationLocationController;
  final TextEditingController? registrationFarmSizeController;

  const ProfileScreen({
    super.key,
    this.userData,
    this.registrationNameController,
    this.registrationEmailController,
    this.registrationPhoneController,
    this.registrationLocationController,
    this.registrationFarmSizeController,
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
  };

  bool _isEditing = false;
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String name, email, phone, location, farmSize;

      if (widget.registrationNameController != null &&
          widget.registrationNameController!.text.isNotEmpty) {
        name = widget.registrationNameController!.text;
        email = widget.registrationEmailController?.text ?? '';
        phone = widget.registrationPhoneController?.text ?? '';
        location = widget.registrationLocationController?.text ?? '';
        farmSize = widget.registrationFarmSizeController?.text ?? '';
      } else if (widget.userData != null) {
        name = widget.userData!['name'] ?? '';
        email = widget.userData!['email'] ?? '';
        phone = widget.userData!['phone'] ?? '';
        location = widget.userData!['location'] ?? '';
        farmSize = widget.userData!['farmSize'] ?? '';
      } else {
        name = prefs.getString('name') ?? 'Saad Ikram';
        email = prefs.getString('email') ?? 'saad@agriguard.com';
        phone = prefs.getString('phone') ?? '+92 300 2455578';
        location = prefs.getString('location') ?? 'Punjab, Pakistan';
        farmSize = prefs.getString('farmSize') ?? '5';
      }

      if (mounted) {
        setState(() {
          _userProfile = {
            'name': name,
            'email': email,
            'phone': phone,
            'location': location,
            'farmSize': farmSize,
            'crops': prefs.getStringList('crops') ?? ['Wheat', 'Cotton', 'Rice'],
            'joinDate': prefs.getString('joinDate') ?? 'Joined: July 01, 2025',
            'scanCount': prefs.getInt('scanCount') ?? 24,
            'lastUpdated': prefs.getString('lastUpdated') ??
                'Last Updated: 05:20 PM PKT, July 01, 2025',
          };

          _nameController.text = _userProfile['name'];
          _emailController.text = _userProfile['email'];
          _phoneController.text = _userProfile['phone'];

          if (prefs.getString('profileImage') != null) {
            _profileImage = XFile(prefs.getString('profileImage')!);
          }
          _isLoading = false;
        });
      }

      if (widget.registrationNameController != null &&
          widget.registrationNameController!.text.isNotEmpty) {
        await _saveProfile();
      }
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
            'lastUpdated': 'Error: ${e.toString()}',
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _userProfile['name']);
    await prefs.setString('email', _userProfile['email']);
    await prefs.setString('phone', _userProfile['phone']);
    await prefs.setString('location', _userProfile['location']);
    await prefs.setString('farmSize', _userProfile['farmSize']);
    await prefs.setStringList('crops', _userProfile['crops'].cast<String>());
    await prefs.setString('joinDate', _userProfile['joinDate']);
    await prefs.setInt('scanCount', _userProfile['scanCount']);
    await prefs.setString('lastUpdated', _userProfile['lastUpdated']);
    if (_profileImage != null) {
      await prefs.setString('profileImage', _profileImage!.path);
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
        _userProfile['name'] = _nameController.text;
        _userProfile['email'] = _emailController.text;
        _userProfile['phone'] = _phoneController.text;
        _userProfile['lastUpdated'] =
        'Last Updated: ${DateTime.now().toString().substring(0, 19)}';
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
      await _saveProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated!'),
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
        ),
      );
    }
  }

  void _showStatisticsDialog() {
    final Map<String, int> scansPerCrop = {
      'Wheat': 10,
      'Cotton': 8,
      'Rice': 6,
    };
    final DateTime lastScanDate = DateTime.now().subtract(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatisticsDialogContent(
        scansPerCrop: scansPerCrop,
        lastScanDate: lastScanDate,
        userProfile: _userProfile,
      ),
    );
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
                                  cardPadding: cardPadding,
                                  itemSpacing: AppMeasurements.getResponsiveSmallPadding(context) * 1.5,
                                ),
                              ),
                              SizedBox(width: sectionSpacing),
                              Flexible(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: _showStatisticsDialog,
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
                                cardPadding: cardPadding,
                                itemSpacing: AppMeasurements.getResponsiveSmallPadding(context) * 1.5,
                              ),
                              SizedBox(height: sectionSpacing),
                              GestureDetector(
                                onTap: _showStatisticsDialog,
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
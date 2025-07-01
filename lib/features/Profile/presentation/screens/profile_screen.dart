import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/constants/app_measurements.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../home/presentation/widgets/nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late Map<String, dynamic> _userProfile;
  bool _isEditing = false;
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

    _userProfile = widget.userData ?? {
      'name': 'Saad Ikram',
      'email': 'saad@agriguard.com',
      'phone': '+92 300 2455578',
      'location': 'Punjab, Pakistan',
      'farmSize': '5 acres',
      'crops': ['Wheat', 'Cotton', 'Rice'],
      'joinDate': 'Joined: July 01, 2025',
      'scanCount': 24,
      'lastUpdated': 'Last Updated: 05:20 PM PKT, July 01, 2025',
    };

    _nameController.text = _userProfile['name'];
    _emailController.text = _userProfile['email'];
    _phoneController.text = _userProfile['phone'];

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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

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
        _userProfile['lastUpdated'] = 'Last Updated: ${TimeOfDay.now().format(context)}, July 01, 2025';
      }
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Profile picture updated!'), backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth > 600;

          return _buildBody(context, isTablet, constraints.maxWidth);
        },
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildBody(BuildContext context, bool isTablet, double maxWidth) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = EdgeInsets.symmetric(
      horizontal: maxWidth * 0.05, // 5% of screen width
      vertical: AppMeasurements.defaultPadding,
    );
    final cardPadding = EdgeInsets.all(maxWidth * 0.03); // 3% of screen width
    final sectionSpacing = maxWidth * 0.04; // 4% of screen width
    final itemSpacing = maxWidth * 0.02; // 2% of screen width

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
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.background.withOpacity(0.9),
            Theme.of(context).colorScheme.background.withOpacity(0.8),
            Theme.of(context).colorScheme.background,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(6, (index) => _buildFloatingOrb(index, maxWidth)),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: padding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
                    child: Column(
                      children: [
                        _buildHeader(),
                        SizedBox(height: sectionSpacing),
                        _buildProfilePicture(maxWidth),
                        SizedBox(height: sectionSpacing),
                        if (isTablet)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                flex: 1,
                                child: _buildProfileInfo(cardPadding, itemSpacing),
                              ),
                              SizedBox(width: sectionSpacing),
                              Flexible(
                                flex: 1,
                                child: _buildStatistics(cardPadding, itemSpacing),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildProfileInfo(cardPadding, itemSpacing),
                              SizedBox(height: sectionSpacing),
                              _buildStatistics(cardPadding, itemSpacing),
                            ],
                          ),
                        SizedBox(height: sectionSpacing),
                        _buildActions(cardPadding),
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

  Widget _buildFloatingOrb(int index, double maxWidth) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Positioned(
          top: (index * 150.0) % MediaQuery.of(context).size.height,
          left: (index * 100.0) % maxWidth,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 80 + (index * 20.0),
              height: 80 + (index * 20.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Semantics(
      label: 'Profile header with edit toggle',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ).createShader(bounds),
            child: Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _toggleEditMode,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Semantics(
                    label: _isEditing ? 'Save profile changes' : 'Edit profile',
                    child: Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
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

  Widget _buildProfilePicture(double maxWidth) {
    final profileSize = maxWidth * 0.3 > 150 ? 150.0 : maxWidth * 0.3;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Semantics(
        label: 'Profile picture with edit option',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: profileSize,
              height: profileSize * 1.07,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            Container(
              width: profileSize - 20,
              height: (profileSize - 20) * 1.08,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(
                  File(_profileImage!.path),
                  fit: BoxFit.cover,
                  width: profileSize - 20,
                  height: (profileSize - 20) * 1.08,
                  errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                    radius: 58,
                    backgroundImage: AssetImage('assets/images/saad.png'),
                  ),
                )
                    : const CircleAvatar(
                  radius: 58,
                  backgroundImage: AssetImage('assets/images/saad.png'),
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Semantics(
                  label: 'Change profile picture',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickProfileImage,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileInfo(EdgeInsets cardPadding, double itemSpacing) {
    return _buildGlassCard(
      child: Padding(
        padding: cardPadding,
        child: Column(
          children: [
            _buildEditableField(
              label: 'Full Name',
              value: _userProfile['name'],
              controller: _nameController,
              icon: Icons.person_rounded,
            ),
            SizedBox(height: itemSpacing),
            _buildEditableField(
              label: 'Email',
              value: _userProfile['email'],
              controller: _emailController,
              icon: Icons.email_rounded,
            ),
            SizedBox(height: itemSpacing),
            _buildEditableField(
              label: 'Phone',
              value: _userProfile['phone'],
              controller: _phoneController,
              icon: Icons.phone_rounded,
            ),
            SizedBox(height: itemSpacing),
            _buildInfoTile(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: _userProfile['location'],
            ),
            SizedBox(height: itemSpacing),
            _buildInfoTile(
              icon: Icons.agriculture_rounded,
              label: 'Farm Size',
              value: _userProfile['farmSize'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Semantics(
      label: 'Editable field for $label',
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                ],
              ),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          Expanded(
            child: _isEditing
                ? TextFormField(
              controller: controller,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 16,
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 2,
                  ),
                ),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(EdgeInsets cardPadding, double itemSpacing) {
    return _buildGlassCard(
      child: Padding(
        padding: cardPadding,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _userProfile['lastUpdated'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: itemSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  value: _userProfile['scanCount'].toString(),
                  label: 'Scans',
                  icon: Icons.camera_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: MediaQuery.of(context).size.height * 0.08,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                ),
                _buildStatItem(
                  value: _userProfile['crops'].length.toString(),
                  label: 'Crops',
                  icon: Icons.eco_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.02),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(EdgeInsets cardPadding) {
    final actions = [
      {
        'icon': Icons.history_rounded,
        'title': 'Scan History',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.history),
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.help),
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.settings),
      },
      {
        'icon': Icons.logout_rounded,
        'title': 'Logout',
        'color': Theme.of(context).colorScheme.error,
        'onTap': () => Navigator.pushReplacementNamed(context, AppRoutes.login),
      },
    ];

    return _buildGlassCard(
      child: Column(
        children: actions.map((action) => _buildActionTile(action, cardPadding)).toList(),
      ),
    );
  }

  Widget _buildActionTile(Map<String, dynamic> action, EdgeInsets cardPadding) {
    final isLast = action['title'] == 'Logout';
    final color = action['color'] as Color? ?? Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: 'Action: ${action['title']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            action['onTap']();
          },
          child: Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(
                    action['icon'],
                    color: color,
                    size: 20,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                Expanded(
                  child: Text(
                    action['title'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
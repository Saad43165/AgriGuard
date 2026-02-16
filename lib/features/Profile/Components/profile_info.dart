import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileInfo extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController farmSizeController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ProfileInfo({
    super.key,
    required this.userProfile,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.locationController,
    required this.farmSizeController,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header (Always visible)
            _buildHeader(context),

            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Column(
                children: [
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  _buildContent(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                Theme.of(context).colorScheme.primary.withOpacity(0.06),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isExpanded ? 'Tap to collapse' : 'Tap to view details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: _iconRotation,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildReadOnlyField(
            context,
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFFE8F5E9),
            label: 'Full Name',
            value: widget.userProfile['name'] ?? 'Not provided',
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            icon: Icons.email_rounded,
            iconColor: const Color(0xFF2196F3),
            iconBgColor: const Color(0xFFE3F2FD),
            label: 'Email Address',
            value: widget.userProfile['email'] ?? 'Not provided',
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            icon: Icons.phone_rounded,
            iconColor: const Color(0xFF9C27B0),
            iconBgColor: const Color(0xFFF3E5F5),
            label: 'Phone Number',
            value: widget.userProfile['phone']?.isEmpty ?? true
                ? 'Not provided'
                : widget.userProfile['phone'],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFFF9800),
            iconBgColor: const Color(0xFFFFF3E0),
            label: 'Location',
            value: widget.userProfile['location']?.isEmpty ?? true
                ? 'Not provided'
                : widget.userProfile['location'],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            icon: Icons.agriculture_rounded,
            iconColor: const Color(0xFF795548),
            iconBgColor: const Color(0xFFEFEBE9),
            label: 'Farm Size',
            value: widget.userProfile['farmSize']?.toString().isEmpty ?? true
                ? 'Not provided'
                : '${widget.userProfile['farmSize']} acres',
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required Color iconBgColor,
        required String label,
        required String value,
      }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
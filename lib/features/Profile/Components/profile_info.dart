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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header (Always visible)
            _buildHeader(context, isDark, colorScheme),

            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Column(
                children: [
                  Container(
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          colorScheme.primary.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  _buildContent(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ColorScheme colorScheme) {
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
              colors: isDark
                  ? [
                colorScheme.primary.withValues(alpha: 0.15),
                colorScheme.secondary.withValues(alpha: 0.15),
              ]
                  : [
                colorScheme.primary.withValues(alpha: 0.08),
                colorScheme.secondary.withValues(alpha: 0.08),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isExpanded ? 'Tap to collapse' : 'Tap to view details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.15),
                        colorScheme.secondary.withValues(alpha: 0.15),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.primary,
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

  Widget _buildContent(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildReadOnlyField(
            context,
            isDark: isDark,
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: isDark
                ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                : const Color(0xFFE8F5E9),
            label: 'Full Name',
            value: widget.userProfile['name'] ?? 'Not provided',
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            isDark: isDark,
            icon: Icons.email_rounded,
            iconColor: const Color(0xFF2196F3),
            iconBgColor: isDark
                ? const Color(0xFF2196F3).withValues(alpha: 0.15)
                : const Color(0xFFE3F2FD),
            label: 'Email Address',
            value: widget.userProfile['email'] ?? 'Not provided',
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            isDark: isDark,
            icon: Icons.phone_rounded,
            iconColor: const Color(0xFF9C27B0),
            iconBgColor: isDark
                ? const Color(0xFF9C27B0).withValues(alpha: 0.15)
                : const Color(0xFFF3E5F5),
            label: 'Phone Number',
            value: widget.userProfile['phone']?.isEmpty ?? true
                ? 'Not provided'
                : widget.userProfile['phone'],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            isDark: isDark,
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFFF9800),
            iconBgColor: isDark
                ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                : const Color(0xFFFFF3E0),
            label: 'Location',
            value: widget.userProfile['location']?.isEmpty ?? true
                ? 'Not provided'
                : widget.userProfile['location'],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField(
            context,
            isDark: isDark,
            icon: Icons.agriculture_rounded,
            iconColor: const Color(0xFF795548),
            iconBgColor: isDark
                ? const Color(0xFF795548).withValues(alpha: 0.15)
                : const Color(0xFFEFEBE9),
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
        required bool isDark,
        required IconData icon,
        required Color iconColor,
        required Color iconBgColor,
        required String label,
        required String value,
      }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
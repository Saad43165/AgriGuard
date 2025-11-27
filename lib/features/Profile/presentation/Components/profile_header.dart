// lib/features/Profile/presentation/components/profile_header.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/constants/app_measurements.dart';

class ProfileHeader extends StatefulWidget {
  final VoidCallback onToggleEdit;
  final bool isEditing;

  const ProfileHeader({
    super.key,
    required this.onToggleEdit,
    required this.isEditing,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // SOLID background color - no transparency!
    final backgroundColor = isDark
        ? const Color(0xFF0F0F23)
        : theme.colorScheme.surface;

    return SliverAppBar(
      expandedHeight: 100,
      collapsedHeight: 56,
      floating: false,
      pinned: true,
      snap: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.2),
      stretch: false,
      forceElevated: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate collapse state
          final totalHeight = 100.0;
          final collapsedHeight = 56.0;
          final isCollapsed = constraints.maxHeight <= (collapsedHeight + 5);

          // Calculate smooth progress (0.0 = fully expanded, 1.0 = fully collapsed)
          final scrollProgress = ((totalHeight - constraints.maxHeight) /
              (totalHeight - collapsedHeight)).clamp(0.0, 1.0);

          // Update state
          if (_isCollapsed != isCollapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isCollapsed = isCollapsed);
              }
            });
          }

          return Container(
            // CRITICAL: Solid color background to block content
            color: backgroundColor,
            child: Stack(
              children: [
                // Optional subtle gradient overlay
                if (!isCollapsed)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                              ? [
                            backgroundColor,
                            const Color(0xFF16213E).withOpacity(0.3),
                          ]
                              : [
                            backgroundColor,
                            backgroundColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                // FlexibleSpaceBar with title
                FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(
                    left: AppMeasurements.defaultPadding,
                    right: 120,
                    bottom: 12,
                  ),
                  title: Opacity(
                    opacity: isCollapsed ? 0.0 : (1.0 - scrollProgress),
                    child: Transform.scale(
                      scale: 1.0 - (scrollProgress * 0.1),
                      alignment: Alignment.centerLeft,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'My Profile',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  background: Container(color: backgroundColor),
                ),
              ],
            ),
          );
        },
      ),
      // Collapsed title
      title: _isCollapsed ? _buildCollapsedTitle(theme) : null,
      actions: [
        Padding(
          padding: EdgeInsets.only(
            right: AppMeasurements.defaultPadding,
          ),
          child: Center(
            child: _DebouncedEditButton(
              isEditing: widget.isEditing,
              onPressed: widget.onToggleEdit,
            ),
          ),
        ),
      ],
      // Add a more prominent divider when collapsed
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isCollapsed ? 1 : 0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.0),
                theme.colorScheme.primary.withOpacity(0.3),
                theme.colorScheme.secondary.withOpacity(0.3),
                theme.colorScheme.secondary.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedTitle(ThemeData theme) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.secondary,
        ],
      ).createShader(bounds),
      child: Text(
        'My Profile',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DebouncedEditButton extends StatefulWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const _DebouncedEditButton({
    required this.isEditing,
    required this.onPressed,
  });

  @override
  State<_DebouncedEditButton> createState() => _DebouncedEditButtonState();
}

class _DebouncedEditButtonState extends State<_DebouncedEditButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Tooltip(
        message: widget.isEditing ? 'Save changes' : 'Edit profile',
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: widget.isEditing
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            )
                : LinearGradient(
              colors: isDark
                  ? [
                const Color(0xFF1A1A2E).withOpacity(0.8),
                const Color(0xFF16213E).withOpacity(0.8),
              ]
                  : [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: widget.isEditing
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isEditing
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: widget.isEditing ? 8 : 4,
                offset: Offset(0, widget.isEditing ? 2 : 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isPressed ? null : _handleTap,
              splashColor: widget.isEditing
                  ? Colors.white.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.1),
              highlightColor: widget.isEditing
                  ? Colors.white.withOpacity(0.1)
                  : theme.colorScheme.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: widget.isEditing ? 0 : 0,
                      child: Icon(
                        widget.isEditing
                            ? Icons.check_circle_rounded
                            : Icons.edit_rounded,
                        color: widget.isEditing
                            ? Colors.white
                            : theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isEditing
                            ? Colors.white
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ) ??
                          const TextStyle(),
                      child: Text(widget.isEditing ? 'Save' : 'Edit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    if (_isPressed) return;

    setState(() => _isPressed = true);
    _scaleController.forward();

    HapticFeedback.mediumImpact();
    widget.onPressed();

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      _scaleController.reverse();
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _isPressed = false);
    }
  }
}
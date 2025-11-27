import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_measurements.dart';

class AppBarContent extends StatefulWidget {
  final XFile? imageFile;
  final VoidCallback? onRetake;

  const AppBarContent({
    super.key,
    required this.imageFile,
    this.onRetake,
  });

  @override
  State<AppBarContent> createState() => _AppBarContentState();
}

class _AppBarContentState extends State<AppBarContent> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _statusController;

  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _statusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    if (widget.imageFile != null) {
      _statusController.forward();
    }
  }

  @override
  void didUpdateWidget(AppBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFile != null && oldWidget.imageFile == null) {
      _statusController.forward();
    } else if (widget.imageFile == null && oldWidget.imageFile != null) {
      _statusController.reverse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // SOLID background color - consistent with Profile
    final backgroundColor = isDark
        ? const Color(0xFF0F0F23)
        : theme.colorScheme.surface;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.2),
      expandedHeight: 100,
      collapsedHeight: 56,
      pinned: true,
      floating: false,
      snap: false,
      stretch: false,
      forceElevated: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = 100.0;
          final collapsedHeight = 56.0;
          final isCollapsed = constraints.maxHeight <= (collapsedHeight + 5);

          final scrollProgress = ((totalHeight - constraints.maxHeight) /
              (totalHeight - collapsedHeight)).clamp(0.0, 1.0);

          if (_isCollapsed != isCollapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isCollapsed = isCollapsed);
              }
            });
          }

          return Container(
            color: backgroundColor,
            child: Stack(
              children: [
                // Subtle gradient overlay when expanded
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

                FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(
                    left: AppMeasurements.defaultPadding,
                    right: widget.imageFile != null ? 120 : 16,
                    bottom: 12,
                  ),
                  title: Opacity(
                    opacity: isCollapsed ? 0.0 : (1.0 - scrollProgress),
                    child: Transform.scale(
                      scale: 1.0 - (scrollProgress * 0.1),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Scan Leaf',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 22,
                                letterSpacing: 0.5,
                                height: 1.0,
                              ),
                            ),
                          ),

                          // Subtitle when no image
                          if (widget.imageFile == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Neural vision ready',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),

                          // Status badge when image exists
                          if (widget.imageFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary.withOpacity(0.15),
                                          theme.colorScheme.secondary.withOpacity(0.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.primary.withOpacity(
                                          0.3 + (_pulseController.value * 0.2),
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(0.5),
                                                blurRadius: 3,
                                                spreadRadius: 0.5,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Analysis Ready',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
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
        if (widget.imageFile != null && widget.onRetake != null)
          Padding(
            padding: EdgeInsets.only(
              right: AppMeasurements.defaultPadding,
            ),
            child: Center(
              child: _RetakeButton(
                onPressed: widget.onRetake!,
              ),
            ),
          ),
      ],

      // Gradient divider when collapsed
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
        'Scan Leaf',
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

class _RetakeButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _RetakeButton({
    required this.onPressed,
  });

  @override
  State<_RetakeButton> createState() => _RetakeButtonState();
}

class _RetakeButtonState extends State<_RetakeButton>
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
        message: 'Retake photo',
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
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
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isPressed ? null : _handleTap,
              splashColor: theme.colorScheme.primary.withOpacity(0.1),
              highlightColor: theme.colorScheme.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Retake',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
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
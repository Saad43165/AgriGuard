import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../../core/constants/app_measurements.dart';
import '../../../home/presentation/widgets/nav_bar.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  _HelpAndSupportScreenState createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Slide from left
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
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth > 600;

          return _buildBody(context, isTablet, constraints.maxWidth);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ).createShader(bounds),
        child: Text(
          'Help & Support',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.only(right: AppMeasurements.smallPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
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
              borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
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
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactFormCard(context, theme, cardPadding, itemSpacing),
                      SizedBox(height: sectionSpacing),
                      _buildContactInfoCard(context, theme, cardPadding, itemSpacing),
                      SizedBox(height: sectionSpacing),
                      _buildFaqCard(context, theme, cardPadding, itemSpacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
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
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.background.withOpacity(0.3),
            blurRadius: screenWidth * 0.03, // 3% of screen width
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildContactFormCard(BuildContext context, ThemeData theme, EdgeInsets cardPadding, double itemSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title: 'Contact Us', icon: Icons.contact_support_rounded),
        SizedBox(height: itemSpacing),
        _buildGlassCard(
          context,
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send us your query',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: itemSpacing),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                ),
                SizedBox(height: itemSpacing),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                ),
                SizedBox(height: itemSpacing),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: itemSpacing),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Message sent successfully'),
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: cardPadding.vertical * 0.5, horizontal: cardPadding.horizontal * 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                    ),
                    elevation: 0,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shadowColor: Colors.transparent,
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                    overlayColor: MaterialStateProperty.all<Color>(Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                    ),
                    padding: EdgeInsets.symmetric(vertical: cardPadding.vertical * 0.5, horizontal: cardPadding.horizontal * 0.8),
                    child: Text(
                      'Submit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoCard(BuildContext context, ThemeData theme, EdgeInsets cardPadding, double itemSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title: 'Contact Information', icon: Icons.info_rounded),
        SizedBox(height: itemSpacing),
        _buildGlassCard(
          context,
          child: Padding(
            padding: cardPadding,
            child: Column(
              children: [
                _buildContactRow(context, label: 'Email', value: 'agriguardsupport@gmail.com', icon: Icons.email_rounded),
                SizedBox(height: itemSpacing),
                _buildContactRow(context, label: 'Phone', value: '03414279749', icon: Icons.phone_rounded),
                SizedBox(height: itemSpacing),
                _buildContactRow(context, label: 'Website', value: 'Under Development....', icon: Icons.web_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqCard(BuildContext context, ThemeData theme, EdgeInsets cardPadding, double itemSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title: 'Frequently Asked Questions', icon: Icons.question_answer_rounded),
        SizedBox(height: itemSpacing),
        _buildGlassCard(
          context,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening FAQ...'),
                    backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                  ),
                );
              },
              child: Padding(
                padding: cardPadding,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(itemSpacing),
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
                        Icons.question_answer_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: itemSpacing),
                    Expanded(
                      child: Text(
                        'Visit our FAQ page for quick answers',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02), // 2% of screen width
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
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(BuildContext context, {required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
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
        SizedBox(width: MediaQuery.of(context).size.width * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.width * 0.01),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
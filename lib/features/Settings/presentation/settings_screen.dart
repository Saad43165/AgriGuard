import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_measurements.dart';
import '../../../../core/widgets/app_themes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/translation_service.dart';
import 'Tiles/app_version_tile.dart';
import 'Tiles/clear_history_tile.dart';
import 'Tiles/delete_acount_tile.dart';
import 'components/floating_orb.dart';
import 'components/notification_schedule_sheet.dart';
import 'components/settings_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('hapticsEnabled', _hapticsEnabled);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final isLargeScreen = AppMeasurements.isLargeScreen(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0D1117)
            : const Color(0xFFF0F7FF),
        child: Stack(
          children: [
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding * 0.6,
                      vertical: padding * 0.5,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isLargeScreen ? 700.0 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SettingsHeader(title: 'Settings'),
                            SizedBox(height: padding * 1.5),

                            // Preferences Section
                            _buildSectionHeader(
                              context,
                              'Preferences',
                              Icons.tune_rounded,
                            ),
                            SizedBox(height: padding * 0.8),
                            _buildPreferencesSection(),
                            SizedBox(height: padding * 2),

                            // Data & Storage
                            _buildSectionHeader(
                              context,
                              'Data & Storage',
                              Icons.storage_rounded,
                            ),
                            SizedBox(height: padding * 0.8),
                            _buildStorageSection(),
                            SizedBox(height: padding * 2),

                            // Account Section
                            _buildSectionHeader(
                              context,
                              'Account',
                              Icons.person_rounded,
                            ),
                            SizedBox(height: padding * 0.8),
                            _buildAccountSection(),
                            SizedBox(height: padding * 2),

                            // Developer / Diagnostics — debug only
                            if (kDebugMode) ...[
                              _buildSectionHeader(
                                context,
                                'Diagnostics',
                                Icons.monitor_heart_rounded,
                              ),
                              SizedBox(height: padding * 0.8),
                              _buildUtilitiesSection(),
                              SizedBox(height: padding * 2),
                            ],

                            // About Section
                            _buildSectionHeader(
                              context,
                              'About',
                              Icons.info_rounded,
                            ),
                            SizedBox(height: padding * 0.8),
                            _buildAboutSection(),
                            SizedBox(height: padding * 2),
                          ],
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildThemeSegmentedControl(),
              _buildDivider(),
              _buildModernToggleTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Receive alerts and updates',
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  await _saveSettings();

                  await NotificationService().setNotificationsEnabled(value);

                  HapticFeedback.mediumImpact();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              value ? Icons.notifications_active : Icons.notifications_off,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              value ? 'Notifications enabled' : 'Notifications disabled',
                            ),
                          ],
                        ),
                        backgroundColor: value ? const Color(0xFF10B981) : Colors.grey.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              _buildDivider(),
              _buildLanguageTile(),
              _buildDivider(),
              _buildModernToggleTile(
                icon: Icons.vibration_rounded,
                title: 'Haptics',
                subtitle: 'Small vibrations for taps and actions',
                value: _hapticsEnabled,
                onChanged: (value) async {
                  setState(() => _hapticsEnabled = value);
                  await _saveSettings();
                  if (value) HapticFeedback.mediumImpact();
                },
              ),
              _buildDivider(),
              _buildScanReminderTile(),
              // FCM TOKEN VIEWER — debug only
              if (kDebugMode) ...[
                _buildDivider(),
                _buildFCMTokenTile(),
                _buildDivider(),
                // TEST NOTIFICATION — debug only
                _buildTestNotificationTile(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanReminderTile() {
    return _buildNavTile(
      icon: Icons.alarm_rounded,
      title: 'Scan Reminder',
      subtitle: 'Schedule weekly plant scan reminders',
      gradient: [AppColors.primary, AppColors.secondary],
      onTap: () {
        if (_hapticsEnabled) HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const NotificationScheduleSheet(),
        );
      },
    );
  }

  Widget _buildUtilitiesSection() {
    return const SizedBox.shrink();
  }

  Widget _buildStorageSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildNavTile(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear temporary cache',
                subtitle: _isClearingCache ? 'Clearing…' : 'Frees space and fixes stale images',
                gradient: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                onTap: _isClearingCache
                    ? () {}
                    : () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _isClearingCache = true);
                        try {
                          imageCache.clear();
                          imageCache.clearLiveImages();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Cache cleared'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isClearingCache = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    final t = Provider.of<TranslationService>(context, listen: false);
    final isUrdu = t.isUrdu;
    return _buildNavTile(
      icon: Icons.language_rounded,
      title: 'Language',
      subtitle: isUrdu ? 'اردو' : 'English',
      gradient: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      onTap: () async {
        if (_hapticsEnabled) HapticFeedback.selectionClick();
        await t.toggleLanguage();
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                gradient[0].withValues(alpha: 0.15),
                gradient[1].withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Icon(icon, color: gradient[0], size: 24),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFCMTokenTile() {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.15),
                Colors.deepPurple.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: const Icon(
            Icons.key_rounded,
            color: Colors.purple,
            size: 24,
          ),
        ),
        title: Text(
          'FCM Token',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Copy device token for testing',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(Icons.content_copy_rounded),
        onTap: () async {
          final token = NotificationService().fcmToken;

          if (token != null && token.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: token));

            if (mounted) {
              // Show token in dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.key_rounded,
                          color: Colors.purple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('FCM Token'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SelectableText(
                          token,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Token copied to clipboard!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text('No FCM token available yet'),
                    ],
                  ),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildTestNotificationTile() {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.15),
                Colors.deepOrange.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: const Icon(
            Icons.bug_report_rounded,
            color: Colors.orange,
            size: 24,
          ),
        ),
        title: Text(
          'Test Notification',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Send a local test notification',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(Icons.send_rounded),
        onTap: () async {
          HapticFeedback.mediumImpact();

          await NotificationService().showTestNotification();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Test notification sent!'),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAccountSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              const ClearHistoryTile(padding: EdgeInsets.all(0)),
              _buildDivider(),
              const DeleteAccountTile(padding: EdgeInsets.all(0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C2333) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const AppVersionTile(padding: EdgeInsets.all(0)),
        ),
      ),
    );
  }

  Widget _buildThemeSegmentedControl() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentMode = themeProvider.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      ('light', Icons.light_mode_rounded, 'Light'),
      ('system', Icons.brightness_auto_rounded, 'System'),
      ('dark', Icons.dark_mode_rounded, 'Dark'),
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Icon(Icons.brightness_6_rounded,
                color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                const SizedBox(height: 8),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: options.map((opt) {
                      final isSelected = currentMode == opt.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isDarkMode = opt.$1 == 'dark');
                            ThemeProvider.of(context).setThemeMode(opt.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(opt.$2, size: 13,
                                    color: isSelected ? Colors.white
                                        : (isDark ? AppColors.darkCaption : AppColors.lightCaption)),
                                const SizedBox(width: 3),
                                Text(opt.$3, style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white
                                      : (isDark ? AppColors.darkCaption : AppColors.lightCaption),
                                )),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }
}
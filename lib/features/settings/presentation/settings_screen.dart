import 'package:flutter/material.dart';
import '../../../core/constants/app_routes.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/translation_service.dart';
import 'tiles/app_version_tile.dart';
import 'tiles/clear_history_tile.dart';
import 'tiles/delete_account_tile.dart';
import 'components/notification_schedule_sheet.dart';
import 'privacy_security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _hapticsEnabled = true;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
    });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('hapticsEnabled', _hapticsEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final t = Provider.of<TranslationService>(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AgriAppBar(title: t.get('settings_title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('PREFERENCES', isDark),
          _card(isDark, [
            _themeTile(isDark, t),
            _divider(isDark),
            _toggleTile(Icons.notifications_outlined, 'Notifications',
                'Receive alerts and updates', _notificationsEnabled, isDark, (v) async {
              setState(() => _notificationsEnabled = v);
              await _save();
              await NotificationService().setNotificationsEnabled(v);
              if (_hapticsEnabled) HapticFeedback.mediumImpact();
            }),
            _divider(isDark),
            _languageTile(isDark, t),
            _divider(isDark),
            _toggleTile(Icons.vibration_outlined, 'Haptics',
                'Vibrations for taps and actions', _hapticsEnabled, isDark, (v) async {
              setState(() => _hapticsEnabled = v);
              await _save();
              if (v) HapticFeedback.mediumImpact();
            }),
            _divider(isDark),
            _arrowTile(Icons.alarm_outlined, 'Scan Reminder',
                'Schedule weekly reminders', isDark, () {
              showModalBottomSheet(
                context: context, isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const NotificationScheduleSheet(),
              );
            }),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('DATA & STORAGE', isDark),
          _card(isDark, [
            _arrowTile(Icons.delete_sweep_outlined, 'Clear Cache',
                _isClearingCache ? 'Clearing…' : 'Free up storage space', isDark, () async {
              if (_isClearingCache) return;
              setState(() => _isClearingCache = true);
              imageCache.clear();
              imageCache.clearLiveImages();
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted && context.mounted) {
                setState(() => _isClearingCache = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Cache cleared'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ));
              }
            }),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('ACCOUNT', isDark),
          _card(isDark, [
            _arrowTile(Icons.lock_outline_rounded, 'Privacy & Security',
                'Change password, reset link', isDark, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
              );
            }),
            _divider(isDark),
            const ClearHistoryTile(padding: EdgeInsets.zero),
            _divider(isDark),
            const DeleteAccountTile(padding: EdgeInsets.zero),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('SUPPORT', isDark),
          _card(isDark, [
            _arrowTile(Icons.help_outline_rounded, 'Help & Support',
                'FAQs, contact, bug report', isDark, () {
              Navigator.pushNamed(context, AppRoutes.help);
            }),
            _divider(isDark),
            _arrowTile(Icons.bug_report_outlined, 'Report a Bug',
                'Help us improve AgriGuard', isDark, () {
              Navigator.pushNamed(context, AppRoutes.bugReport);
            }),
          ]),          const SizedBox(height: 20),
          _sectionLabel('ABOUT', isDark),
          _card(isDark, [
            const AppVersionTile(padding: EdgeInsets.zero),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
        letterSpacing: 1.0,
      )),
    );
  }

  Widget _card(bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1, thickness: 1, indent: 56,
    color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0),
  );

  Widget _themeTile(bool isDark, TranslationService t) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final current = themeProvider.themeMode;
    final options = [
      ('light', Icons.light_mode_outlined, 'Light'),
      ('system', Icons.brightness_auto_outlined, 'Auto'),
      ('dark', Icons.dark_mode_outlined, 'Dark'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.brightness_6_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
                )),
                const SizedBox(height: 8),
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8)),
                  ),
                  child: Row(
                    children: options.map((opt) {
                      final sel = current == opt.$1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ThemeProvider.of(context).setThemeMode(opt.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(opt.$2, size: 12,
                                    color: sel ? Colors.white
                                        : (isDark ? AppColors.darkCaption : AppColors.lightCaption)),
                                const SizedBox(width: 3),
                                Text(opt.$3, style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white
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

  Widget _toggleTile(IconData icon, String title, String subtitle,
      bool value, bool isDark, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      )),
      subtitle: Text(subtitle, style: TextStyle(
        fontSize: 12, color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
      )),
      trailing: Switch(
        value: value, onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _arrowTile(IconData icon, String title, String subtitle,
      bool isDark, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      )),
      subtitle: Text(subtitle, style: TextStyle(
        fontSize: 12, color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
      )),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? AppColors.darkCaption : AppColors.lightCaption, size: 20),
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
    );
  }

  Widget _languageTile(bool isDark, TranslationService t) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.language_outlined, color: AppColors.primary, size: 20),
      ),
      title: Text('Language', style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      )),
      subtitle: Text(t.isUrdu ? 'اردو' : 'English', style: TextStyle(
        fontSize: 12, color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
      )),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t.isUrdu ? 'EN' : 'اردو',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      onTap: () async {
        HapticFeedback.lightImpact();
        await t.toggleLanguage();
        if (mounted) setState(() {});
      },
    );
  }
}



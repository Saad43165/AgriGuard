import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_themes.dart';
import '../../../../core/database/scan_database.dart';
import '../../auth/Login_Screen/services/guest_service.dart';
import '../Components/edit_profile_sheet.dart';
import '../Components/guest_restriction_view.dart';
import '../Components/logout_confirmation_dialog_content.dart';
import '../Components/profile_image_helper.dart';
import '../Components/profile_picture_option_sheet.dart';
import '../utils/profile_image_manager.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ProfileScreen({super.key, this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  Map<String, dynamic> _profile = {
    'name': '', 'email': '', 'phone': '', 'location': '',
    'farmSize': '', 'crops': [], 'joinDate': '', 'scanCount': 0,
    'profileImageUrl': null,
  };

  bool _isLoading = true;
  bool _hasLoaded = false;
  int _totalScans = 0;
  int _healthyScans = 0;
  int _diseasedScans = 0;

  File? _profileImageFile;
  String? _profileImageBase64;

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _farmCtrl     = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final GuestService _guestService = GuestService();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _guestService.initialize().then((_) { if (mounted) setState(() {}); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      if (!_guestService.isGuestMode) _loadAll();
      else setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _locationCtrl.dispose(); _farmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadProfile(), _loadStats()]);
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists) return;
      final d = snap.data()!;
      _profile = {
        'name': d['fullName'] ?? d['name'] ?? 'User',
        'email': d['email'] ?? '',
        'phone': d['phoneNumber'] ?? d['phone'] ?? '',
        'location': d['location'] ?? '',
        'farmSize': d['farmSize']?.toString() ?? '',
        'crops': d['crops'] ?? [],
        'joinDate': d['createdAt']?.toString() ?? '',
        'scanCount': d['scanCount'] ?? 0,
        'profileImageUrl': d['profileImageUrl'],
      };
      final imgUrl = d['profileImageUrl'] as String?;
      if (imgUrl != null && imgUrl.isNotEmpty) {
        _profileImageBase64 = imgUrl;
      } else {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser?.photoURL?.isNotEmpty == true) _profileImageBase64 = authUser!.photoURL;
      }
      _nameCtrl.text     = _profile['name'];
      _emailCtrl.text    = _profile['email'];
      _phoneCtrl.text    = _profile['phone'];
      _locationCtrl.text = _profile['location'] ?? '';
      _farmCtrl.text     = _profile['farmSize']?.toString() ?? '';
    } catch (e) { debugPrint('Profile load error: $e'); }
  }

  Future<void> _loadStats() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final db = ScanDatabase.instance;
      final counts = await db.getScanCounts(uid);
      _totalScans = counts['total'] ?? 0;
      final all = await db.getAllScans(uid);
      int h = 0, d = 0;
      for (final s in all) {
        final diag = (s['diagnosis']?.toString() ?? s['diseaseName']?.toString() ?? '').toLowerCase();
        if (diag.contains('healthy') || diag.isEmpty) h++; else d++;
      }
      _healthyScans = h; _diseasedScans = d;
    } catch (e) { debugPrint('Stats load error: $e'); }
  }

  Future<void> _saveProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      if (_nameCtrl.text.trim().isEmpty) { _snack('Name cannot be empty', error: true); return; }
      final data = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'farmSize': _farmCtrl.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        data['profileImageUrl'] = _profileImageBase64;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
      setState(() {
        _profile['name']     = _nameCtrl.text.trim();
        _profile['phone']    = _phoneCtrl.text.trim();
        _profile['location'] = _locationCtrl.text.trim();
        _profile['farmSize'] = _farmCtrl.text.trim();
      });
      _snack('Profile updated');
    } catch (e) { _snack('Failed to save: $e', error: true); }
  }

  Future<void> _pickImage() async {
    try {
      final result = await ProfileImageHelper.pickAndProcessImage();
      if (result != null) {
        setState(() { _profileImageFile = result['file']; _profileImageBase64 = result['base64']; });
        ProfileImageManager.setPendingImage(result['file']);
        await _saveProfile();
      }
    } catch (e) { _snack('Error updating image: $e', error: true); }
  }

  Future<void> _logout() async {
    ProfileImageManager.clearPendingImage();
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_guestService.isGuestMode) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F7FF),
        body: GuestRestrictionView(
          maxWidth: MediaQuery.of(context).size.width,
          fadeController: _fadeCtrl..forward(),
          scaleAnimation: const AlwaysStoppedAnimation(1.0),
          guestService: _guestService,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F6F9),
      body: _isLoading ? _buildLoading(isDark) : _buildBody(isDark),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text('Loading profile...', style: TextStyle(color: isDark ? AppColors.darkCaption : AppColors.lightCaption, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F6F9);
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textSub = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: TextButton.icon(
                  onPressed: () => showLogoutConfirmationDialog(context: context, onConfirm: _logout),
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                  label: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHero(isDark, cardBg, border, textPrimary, textSub),
            ),
          ),

          // ── Stats ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildStats(isDark, cardBg, border)),
          ),

          // ── Info Fields ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildInfoSection(isDark, cardBg, border, textPrimary, textSub)),
          ),

          // ── Quick Actions ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildActions(isDark, cardBg, border, textPrimary, textSub)),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // ── Profile Hero (avatar + name + email + edit) ──────────────────────
  Widget _buildProfileHero(bool isDark, Color cardBg, Color border, Color textPrimary, Color textSub) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: () => showProfilePictureOptionsSheet(
                  context: context,
                  profileImageFile: _profileImageFile,
                  profileImageBase64: _profileImageBase64,
                  onChangeImage: _pickImage,
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? AppColors.darkCard : Colors.white),
                        child: ClipOval(child: _buildAvatarImage()),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Name + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_profile['name']?.toString().isNotEmpty == true ? _profile['name'] : 'User',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(_profile['email'] ?? '',
                      style: TextStyle(fontSize: 13, color: textSub, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    if ((_profile['location'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Flexible(child: Text(_profile['location'], style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: () => showEditProfileSheet(
                          context: context,
                          nameController: _nameCtrl,
                          phoneController: _phoneCtrl,
                          locationController: _locationCtrl,
                          farmSizeController: _farmCtrl,
                          onSave: () { _saveProfile(); Navigator.pop(context); },
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Edit Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_profileImageFile != null) {
      return Image.file(_profileImageFile!, fit: BoxFit.cover, width: 76, height: 76, errorBuilder: (_, __, ___) => _defaultAvatar());
    }
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      if (_profileImageBase64!.startsWith('http')) {
        return Image.network(_profileImageBase64!, fit: BoxFit.cover, width: 76, height: 76,
          loadingBuilder: (_, child, p) => p == null ? child : _defaultAvatar(),
          errorBuilder: (_, __, ___) => _defaultAvatar());
      }
      try {
        return Image.memory(base64Decode(_profileImageBase64!), fit: BoxFit.cover, width: 76, height: 76, errorBuilder: (_, __, ___) => _defaultAvatar());
      } catch (_) {}
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() => const Icon(Icons.person_rounded, size: 36, color: AppColors.primary);

  // ── Stats row ─────────────────────────────────────────────────────────
  Widget _buildStats(bool isDark, Color cardBg, Color border) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '$_totalScans', label: 'Total Scans', icon: Icons.qr_code_scanner_rounded, color: AppColors.primary, isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '$_healthyScans', label: 'Healthy', icon: Icons.check_circle_rounded, color: AppColors.success, isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '$_diseasedScans', label: 'Diseased', icon: Icons.warning_rounded, color: AppColors.warning, isDark: isDark)),
      ],
    );
  }

  // ── Info section ──────────────────────────────────────────────────────
  Widget _buildInfoSection(bool isDark, Color cardBg, Color border, Color textPrimary, Color textSub) {
    final fields = [
      {'icon': Icons.person_rounded, 'label': 'Full Name', 'value': _profile['name'] ?? '', 'color': AppColors.primary},
      {'icon': Icons.email_rounded, 'label': 'Email', 'value': _profile['email'] ?? '', 'color': AppColors.info},
      {'icon': Icons.phone_rounded, 'label': 'Phone', 'value': _profile['phone']?.toString().isNotEmpty == true ? _profile['phone'] : 'Not set', 'color': AppColors.secondary},
      {'icon': Icons.location_on_rounded, 'label': 'Location', 'value': _profile['location']?.toString().isNotEmpty == true ? _profile['location'] : 'Not set', 'color': AppColors.warning},
      {'icon': Icons.agriculture_rounded, 'label': 'Farm Size', 'value': _profile['farmSize']?.toString().isNotEmpty == true ? '${_profile['farmSize']} acres' : 'Not set', 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Profile Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
                const Spacer(),
                GestureDetector(
                  onTap: () => showEditProfileSheet(
                    context: context,
                    nameController: _nameCtrl,
                    phoneController: _phoneCtrl,
                    locationController: _locationCtrl,
                    farmSizeController: _farmCtrl,
                    onSave: () { _saveProfile(); Navigator.pop(context); },
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          ...fields.asMap().entries.map((e) {
            final f = e.value;
            final isLast = e.key == fields.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: (f['color'] as Color).withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f['icon'] as IconData, size: 18, color: f['color'] as Color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['label'] as String, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkCaption : AppColors.lightCaption, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(f['value'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, indent: 64, color: border),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────
  Widget _buildActions(bool isDark, Color cardBg, Color border, Color textPrimary, Color textSub) {
    final items = [
      {'icon': Icons.history_rounded, 'label': 'Scan History', 'sub': 'View all past scans', 'color': AppColors.primary, 'route': AppRoutes.history},
      {'icon': Icons.settings_rounded, 'label': 'Settings', 'sub': 'App preferences', 'color': AppColors.secondary, 'route': AppRoutes.settings},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Support', 'sub': 'FAQs and contact', 'color': AppColors.info, 'route': AppRoutes.help},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.apps_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          ...items.asMap().entries.map((e) {
            final item = e.value;
            final isLast = e.key == items.length - 1;
            final color = item['color'] as Color;
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.pushNamed(context, item['route'] as String); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(item['icon'] as IconData, size: 20, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                                Text(item['sub'] as String, style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? AppColors.darkCaption : AppColors.lightCaption),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast) Divider(height: 1, indent: 66, color: border),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Stat card widget ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({required this.value, required this.label, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkCaption : AppColors.lightCaption), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_themes.dart';
import '../../../core/database/scan_database.dart';
import '../auth/login/services/guest_service.dart';
import 'components/edit_profile_sheet.dart';
import 'components/guest_restriction_view.dart';
import 'components/logout_confirmation_dialog_content.dart';
import 'components/profile_image_helper.dart';
import 'components/profile_hero.dart';
import 'components/profile_picture_option_sheet.dart';
import 'utils/profile_image_manager.dart';

// ─── Design constants ────────────────────────────────────────────────────────
const _kAvatarRadius = 48.0;

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
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _guestService.initialize().then((_) { if (mounted) setState(() {}); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      if (!_guestService.isGuestMode) {
        _loadAll();
      } else {
        setState(() => _isLoading = false);
      }
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
    if (mounted) { setState(() => _isLoading = false); _fadeCtrl.forward(); }
  }

  Future<void> _loadProfile() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) return;
      final uid = authUser.uid;

      // Always seed from Firebase Auth first (works for Google, email, etc.)
      final authName  = authUser.displayName ?? '';
      final authEmail = authUser.email ?? '';
      final authPhoto = authUser.photoURL ?? '';

      // Try to get Firestore doc — may not exist for Google sign-in users
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (snap.exists) {
        final d = snap.data()!;
        _profile = {
          // Prefer Firestore data, fall back to Auth data
          'name':     (d['fullName'] ?? d['name'] ?? authName).toString().isNotEmpty
                          ? (d['fullName'] ?? d['name'] ?? authName)
                          : authName,
          'email':    (d['email'] ?? authEmail).toString().isNotEmpty
                          ? (d['email'] ?? authEmail)
                          : authEmail,
          'phone':    d['phoneNumber'] ?? d['phone'] ?? '',
          'location': d['location'] ?? '',
          'farmSize': d['farmSize']?.toString() ?? '',
          'crops':    d['crops'] ?? [],
          'joinDate': d['createdAt']?.toString() ?? '',
          'scanCount': d['scanCount'] ?? 0,
          'profileImageUrl': d['profileImageUrl'],
        };

        // Image priority: Firestore stored image > Google photoURL
        final storedImg = d['profileImageUrl'] as String?;
        if (storedImg != null && storedImg.isNotEmpty) {
          _profileImageBase64 = storedImg;
        } else if (authPhoto.isNotEmpty) {
          _profileImageBase64 = authPhoto;
        }
      } else {
        // No Firestore doc — use Auth data directly (common for Google sign-in)
        _profile = {
          'name':     authName.isNotEmpty ? authName : 'User',
          'email':    authEmail,
          'phone':    '',
          'location': '',
          'farmSize': '',
          'crops':    [],
          'joinDate': '',
          'scanCount': 0,
          'profileImageUrl': authPhoto.isNotEmpty ? authPhoto : null,
        };

        if (authPhoto.isNotEmpty) _profileImageBase64 = authPhoto;

        // Create Firestore doc so future edits work
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fullName': authName,
            'email':    authEmail,
            'profileImageUrl': authPhoto,
            'createdAt': FieldValue.serverTimestamp(),
            'provider': authUser.providerData.isNotEmpty
                ? authUser.providerData.first.providerId
                : 'unknown',
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Could not create Firestore doc: $e');
        }
      }

      _nameCtrl.text     = _profile['name']?.toString() ?? '';
      _emailCtrl.text    = _profile['email']?.toString() ?? '';
      _phoneCtrl.text    = _profile['phone']?.toString() ?? '';
      _locationCtrl.text = _profile['location']?.toString() ?? '';
      _farmCtrl.text     = _profile['farmSize']?.toString() ?? '';
    } catch (e) {
      debugPrint('Profile load error: $e');
      // Last resort — use Auth data
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        _profile['name']  = authUser.displayName ?? 'User';
        _profile['email'] = authUser.email ?? '';
        if (authUser.photoURL?.isNotEmpty == true) {
          _profileImageBase64 = authUser.photoURL;
        }
        _nameCtrl.text  = _profile['name'];
        _emailCtrl.text = _profile['email'];
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final db = ScanDatabase.instance;
      
      // Get counts from each scan type separately - most reliable
      final onDevice = await db.getOnDeviceScans(uid);
      final advanced = await db.getAdvancedScans(uid);
      
      // Sum across all scan sources
      _totalScans = onDevice.length + advanced.length;
      
      int h = 0, d = 0;
      
      // Get all scans from SQLite to compute healthy/diseased  
      final all = await db.getAllScans(uid);
      for (final s in all) {
        final diag = (s['diagnosis']?.toString() ?? s['diseaseName']?.toString() ?? s['disease']?.toString() ?? '').toLowerCase();
        if (diag.contains('healthy') || diag.isEmpty) {
          h++;
        } else {
          d++;
        }
      }
      _healthyScans = h; 
      _diseasedScans = d;
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
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: GuestRestrictionView(
          maxWidth: MediaQuery.of(context).size.width,
          fadeController: _fadeCtrl..forward(),
          scaleAnimation: const AlwaysStoppedAnimation(1.0),
          guestService: _guestService,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3))
          : FadeTransition(opacity: _fadeAnim, child: _buildBody(isDark)),
    );
  }

  Widget _buildBody(bool isDark) {
    final t = Provider.of<TranslationService>(context, listen: false);
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    void openEdit() => showEditProfileSheet(
      context: context,
      nameController: _nameCtrl,
      phoneController: _phoneCtrl,
      locationController: _locationCtrl,
      farmSizeController: _farmCtrl,
      onSave: () { _saveProfile(); Navigator.pop(context); },
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [

        // ── Hero header with cover gradient + floating avatar ─────────────
        SliverToBoxAdapter(
          child: ProfileHeroSection(
            isDark: isDark,
            profile: _profile,
            totalScans: _totalScans,
            healthyScans: _healthyScans,
            diseasedScans: _diseasedScans,
            onAvatarTap: () => showProfilePictureOptionsSheet(
              context: context,
              profileImageFile: _profileImageFile,
              profileImageBase64: _profileImageBase64,
              onChangeImage: _pickImage,
            ),
            onEditTap: openEdit,
            buildAvatarImage: _buildAvatarImage,
            t: t,
          ),
        ),

        // ── Quick links row ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverToBoxAdapter(
            child: QuickLinksRow(isDark: isDark, t: t),
          ),
        ),

        // ── Account section ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionLabel(label: t.isUrdu ? 'اکاؤنٹ' : 'Account', isDark: isDark),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _MenuCard(isDark: isDark, items: [
              _MenuItem(
                icon: CupertinoIcons.person_crop_circle,
                label: t.isUrdu ? 'ذاتی معلومات' : 'Personal Info',
                subtitle: _profile['name']?.toString().isNotEmpty == true
                    ? _profile['name'] : 'Tap to fill in',
                onTap: openEdit,
              ),
              _MenuItem(
                icon: CupertinoIcons.phone,
                label: t.isUrdu ? 'فون' : 'Phone',
                subtitle: _profile['phone']?.toString().isNotEmpty == true
                    ? _profile['phone'] : 'Not set',
                onTap: openEdit,
              ),
              _MenuItem(
                icon: CupertinoIcons.location,
                label: t.isUrdu ? 'مقام' : 'Location',
                subtitle: _profile['location']?.toString().isNotEmpty == true
                    ? _profile['location'] : 'Not set',
                onTap: openEdit,
              ),
              _MenuItem(
                icon: CupertinoIcons.tree,
                label: t.isUrdu ? 'فارم کا سائز' : 'Farm Size',
                subtitle: _profile['farmSize']?.toString().isNotEmpty == true
                    ? '${_profile['farmSize']} acres' : 'Not set',
                onTap: openEdit,
              ),
            ]),
          ),
        ),

        // ── Account actions ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionLabel(label: t.isUrdu ? 'اکاؤنٹ اقدامات' : 'Account Actions', isDark: isDark),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _MenuCard(isDark: isDark, items: [
              _MenuItem(
                icon: CupertinoIcons.square_arrow_right,
                label: t.isUrdu ? 'لاگ آؤٹ' : 'Log Out',
                subtitle: t.isUrdu ? 'اپنے اکاؤنٹ سے سائن آؤٹ کریں' : 'Sign out of your account',
                labelColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => showLogoutConfirmationDialog(
                    context: context, onConfirm: _logout),
              ),
            ]),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      if (_profileImageBase64!.startsWith('http')) {
        return Image.network(
          _profileImageBase64!,
          fit: BoxFit.cover, width: _kAvatarRadius * 2, height: _kAvatarRadius * 2,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _defaultAvatar(),
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        );
      }
      if (_profileImageFile != null) {
        return Image.file(
          _profileImageFile!,
          fit: BoxFit.cover, width: _kAvatarRadius * 2, height: _kAvatarRadius * 2,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        );
      }
      try {
        return Image.memory(
          base64Decode(_profileImageBase64!),
          fit: BoxFit.cover, width: _kAvatarRadius * 2, height: _kAvatarRadius * 2,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        );
      } catch (_) {}
    }
    if (_profileImageFile != null) {
      return Image.file(
        _profileImageFile!,
        fit: BoxFit.cover, width: _kAvatarRadius * 2, height: _kAvatarRadius * 2,
        errorBuilder: (_, __, ___) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: const Icon(CupertinoIcons.person_fill, size: 44, color: AppColors.primary),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final bool isDark;
  final List<_MenuItem> items;
  const _MenuCard({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              _MenuRow(item: item, isDark: isDark),
              if (!isLast) Divider(
                height: 1,
                indent: 56,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });
}

class _MenuRow extends StatelessWidget {
  final _MenuItem item;
  final bool isDark;
  const _MenuRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = item.labelColor ?? (isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E));
    final iconColor = item.iconColor ?? AppColors.primary;
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); item.onTap(); },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    Text(item.subtitle,
                        style: TextStyle(fontSize: 11, color: captionColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 14, color: captionColor),
            ],
          ),
        ),
      ),
    );
  }
}



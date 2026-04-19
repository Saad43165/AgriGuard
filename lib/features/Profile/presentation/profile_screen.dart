import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/translation_service.dart';
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
      final counts = await db.getScanCounts(uid);
      _totalScans = counts['total'] ?? 0;
      final all = await db.getAllScans(uid);
      int h = 0, d = 0;
      for (final s in all) {
        final diag = (s['diagnosis']?.toString() ?? s['diseaseName']?.toString() ?? '').toLowerCase();
        if (diag.contains('healthy') || diag.isEmpty) {
          h++;
        } else {
          d++;
        }
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
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E);
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    final surfaceBg = isDark ? AppColors.darkSurface : Colors.white;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Top bar: title only (no settings icon — it's in the App section below) ──
        SliverAppBar(
          pinned: true,
          backgroundColor: surfaceBg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(t.isUrdu ? 'پروفائل' : 'Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: border),
          ),
        ),

        // ── Avatar + name + stats ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: surfaceBg,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
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
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2.5),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(child: _buildAvatarImage()),
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: surfaceBg, width: 2),
                          ),
                          child: const Icon(CupertinoIcons.camera_fill, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  _profile['name']?.toString().isNotEmpty == true ? _profile['name'] : 'User',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: textColor, letterSpacing: -0.3),
                ),
                const SizedBox(height: 3),
                Text(
                  _profile['email'] ?? '',
                  style: TextStyle(fontSize: 13, color: captionColor),
                ),
                if ((_profile['location'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(CupertinoIcons.location_fill, size: 11, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(_profile['location'],
                        style: const TextStyle(fontSize: 12, color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
                const SizedBox(height: 16),

                // Edit profile button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showEditProfileSheet(
                      context: context,
                      nameController: _nameCtrl,
                      phoneController: _phoneCtrl,
                      locationController: _locationCtrl,
                      farmSizeController: _farmCtrl,
                      onSave: () { _saveProfile(); Navigator.pop(context); },
                    ),
                    icon: const Icon(CupertinoIcons.pencil, size: 15),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F8F8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stats row ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                _StatItem(value: '$_totalScans', label: t.isUrdu ? 'کل اسکینز' : 'Total Scans', isDark: isDark),
                _Divider(isDark: isDark),
                _StatItem(value: '$_healthyScans', label: t.isUrdu ? 'صحت مند' : 'Healthy', isDark: isDark, color: AppColors.primary),
                _Divider(isDark: isDark),
                _StatItem(value: '$_diseasedScans', label: t.isUrdu ? 'بیمار' : 'Diseased', isDark: isDark, color: AppColors.error),
              ],
            ),
          ),
        ),

        // ── Account section ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                onTap: () => showEditProfileSheet(
                  context: context,
                  nameController: _nameCtrl,
                  phoneController: _phoneCtrl,
                  locationController: _locationCtrl,
                  farmSizeController: _farmCtrl,
                  onSave: () { _saveProfile(); Navigator.pop(context); },
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.phone,
                label: t.isUrdu ? 'فون' : 'Phone',
                subtitle: _profile['phone']?.toString().isNotEmpty == true
                    ? _profile['phone'] : 'Not set',
                onTap: () => showEditProfileSheet(
                  context: context,
                  nameController: _nameCtrl,
                  phoneController: _phoneCtrl,
                  locationController: _locationCtrl,
                  farmSizeController: _farmCtrl,
                  onSave: () { _saveProfile(); Navigator.pop(context); },
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.location,
                label: t.isUrdu ? 'مقام' : 'Location',
                subtitle: _profile['location']?.toString().isNotEmpty == true
                    ? _profile['location'] : 'Not set',
                onTap: () => showEditProfileSheet(
                  context: context,
                  nameController: _nameCtrl,
                  phoneController: _phoneCtrl,
                  locationController: _locationCtrl,
                  farmSizeController: _farmCtrl,
                  onSave: () { _saveProfile(); Navigator.pop(context); },
                ),
              ),
              _MenuItem(
                icon: CupertinoIcons.tree,
                label: t.isUrdu ? 'فارم کا سائز' : 'Farm Size',
                subtitle: _profile['farmSize']?.toString().isNotEmpty == true
                    ? '${_profile['farmSize']} acres' : 'Not set',
                onTap: () => showEditProfileSheet(
                  context: context,
                  nameController: _nameCtrl,
                  phoneController: _phoneCtrl,
                  locationController: _locationCtrl,
                  farmSizeController: _farmCtrl,
                  onSave: () { _saveProfile(); Navigator.pop(context); },
                ),
              ),
            ]),
          ),
        ),

        // ── Danger zone ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                subtitle: 'Sign out of your account',
                labelColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => showLogoutConfirmationDialog(
                    context: context, onConfirm: _logout),
              ),
            ]),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildAvatarImage() {
    // Google photoURL is an https:// URL
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      if (_profileImageBase64!.startsWith('http')) {
        return Image.network(
          _profileImageBase64!,
          fit: BoxFit.cover, width: 82, height: 82,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _defaultAvatar(),
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        );
      }
      // Local file path
      if (_profileImageFile != null) {
        return Image.file(
          _profileImageFile!,
          fit: BoxFit.cover, width: 82, height: 82,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        );
      }
      // Base64 encoded
      try {
        return Image.memory(
          base64Decode(_profileImageBase64!),
          fit: BoxFit.cover, width: 82, height: 82,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        );
      } catch (_) {}
    }
    // Local file (picked from gallery)
    if (_profileImageFile != null) {
      return Image.file(
        _profileImageFile!,
        fit: BoxFit.cover, width: 82, height: 82,
        errorBuilder: (_, __, ___) => _defaultAvatar(),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(CupertinoIcons.person_fill, size: 40, color: AppColors.primary),
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
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkCaption : AppColors.lightCaption,
        letterSpacing: 0.8,
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

// ── Stat item ─────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final Color? color;
  const _StatItem({required this.value, required this.label, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? AppColors.darkOnSurface : const Color(0xFF1B2B1E));
    final captionColor = isDark ? AppColors.darkCaption : AppColors.lightCaption;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, color: captionColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 36,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}





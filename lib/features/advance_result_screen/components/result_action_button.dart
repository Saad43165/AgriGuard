// lib/features/ResultScreen/presentation/components/result_action_button.dart
//
// FIXES IN THIS VERSION
//  1. "Done" → haptic feedback + green SnackBar: "PDF saved: filename.pdf"
//  2. Path tile is now tappable → opens a real folder picker (file_picker)
//     and physically moves the PDF to the chosen directory
//  3. _currentFile tracks the live File reference across renames + moves
//  4. onFileChanged callback keeps the parent _generatedPdf in sync
//  5. All deprecated withOpacity() → withValues(alpha:) (Flutter 3.27+)
//  6. AnimatedBuilder + clamp replaces ScaleTransition on speed-dial items
//     (prevents negative-scale crash on rapid open/close)
//  7. Header X button also triggers _done() so feedback fires consistently
//
// ── pubspec.yaml — add once ──────────────────────────────────────────────
//   dependencies:
//     file_picker: ^8.1.2
//     path:        ^1.9.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../utils/advance_pdf_generator.dart';
import '../utils/advance_share_handler.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Root widget
// ═══════════════════════════════════════════════════════════════════════════
class ResultActionButton extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final Map<String, dynamic> originalScanData;
  final Uint8List? plantImageBytes;

  const ResultActionButton({
    super.key,
    required this.analysisResult,
    required this.originalScanData,
    this.plantImageBytes,
  });

  @override
  State<ResultActionButton> createState() => _ResultActionButtonState();
}

class _ResultActionButtonState extends State<ResultActionButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isGeneratingPdf = false;
  File? _generatedPdf;

  late AnimationController _menuCtrl;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _rotationAnim = Tween<double>(begin: 0, end: 0.375).animate(
        CurvedAnimation(parent: _menuCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _menuCtrl.forward() : _menuCtrl.reverse();
    HapticFeedback.mediumImpact();
  }

  void _close() {
    if (!_isExpanded) return;
    setState(() => _isExpanded = false);
    _menuCtrl.reverse();
  }

  Future<void> _handleShare() async {
    HapticFeedback.lightImpact();
    _close();
    await AdvancedShareHandler.shareResults(
      context: context,
      analysisResult: widget.analysisResult,
      originalScanData: widget.originalScanData,
      pdfFile: _generatedPdf,
    );
  }

  Future<void> _handleGeneratePdf() async {
    if (_isGeneratingPdf) return;
    _close();
    setState(() => _isGeneratingPdf = true);
    try {
      if (!mounted) return;
      _showGenerating();

      final pdfFile = await AdvancedPdfGenerator.generatePdf(
        analysisResult: widget.analysisResult,
        originalScanData: widget.originalScanData,
        plantImageBytes: widget.plantImageBytes,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        _generatedPdf = pdfFile;
        _isGeneratingPdf = false;
      });
      _showSuccess(pdfFile);
    } catch (e, st) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _isGeneratingPdf = false);
      _showError('$e');
      debugPrint('PDF Error: $e\n$st');
    }
  }

  // keeps parent reference fresh after dialog renames / moves the file
  void _onFileChanged(File f) => setState(() => _generatedPdf = f);

  void _showGenerating() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _GeneratingDialog(),
  );

  void _showSuccess(File f) => showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _SuccessDialog(
      pdfFile: f,
      onFileChanged: _onFileChanged,
      onShare: () {
        Navigator.of(context).pop();
        _handleShare();
      },
    ),
  );

  void _showError(String msg) => showDialog(
    context: context,
    builder: (_) => _ErrorDialog(message: msg),
  );

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _SpeedItem(
          show: _isExpanded,
          delay: 80,
          icon: Icons.share_rounded,
          label: 'Share',
          color: const Color(0xFF1E88E5),
          onTap: _handleShare,
        ),
        const SizedBox(height: 10),
        _SpeedItem(
          show: _isExpanded,
          delay: 0,
          icon: Icons.picture_as_pdf_rounded,
          label: _isGeneratingPdf ? 'Generating…' : 'Save PDF',
          color: const Color(0xFFE65100),
          isLoading: _isGeneratingPdf,
          onTap: _isGeneratingPdf ? null : _handleGeneratePdf,
        ),
        const SizedBox(height: 14),
        FloatingActionButton(
          heroTag: 'result_main_fab',
          onPressed: _toggle,
          backgroundColor: primary,
          elevation: 6,
          child: RotationTransition(
            turns: _rotationAnim,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                _isExpanded ? Icons.close_rounded : Icons.menu_rounded,
                key: ValueKey(_isExpanded),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Speed-dial pill
// ═══════════════════════════════════════════════════════════════════════════
class _SpeedItem extends StatefulWidget {
  final bool show;
  final int delay;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SpeedItem({
    required this.show,
    required this.delay,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  State<_SpeedItem> createState() => _SpeedItemState();
}

class _SpeedItemState extends State<_SpeedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    if (widget.show) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_SpeedItem old) {
    super.didUpdateWidget(old);
    if (widget.show != old.show) {
      if (widget.show) {
        Future.delayed(Duration(milliseconds: widget.delay),
                () { if (mounted) _ctrl.forward(); });
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final v = _anim.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: v,
          alignment: Alignment.centerRight,
          child: Opacity(opacity: v, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap == null
            ? null
            : () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.onTap == null
                  ? [const Color(0xFFBDBDBD), const Color(0xFF9E9E9E)]
                  : [widget.color, widget.color.withValues(alpha: 0.78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Generating Dialog
// ═══════════════════════════════════════════════════════════════════════════
class _GeneratingDialog extends StatefulWidget {
  const _GeneratingDialog();

  @override
  State<_GeneratingDialog> createState() => _GeneratingDialogState();
}

class _GeneratingDialogState extends State<_GeneratingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 40,
                offset: const Offset(0, 16)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFE65100).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 7)),
                  ],
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Generating Report',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('Building your PDF analysis…',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500, height: 1.4)),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                minHeight: 5,
                backgroundColor: Color(0xFFF0F0F0),
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Success Dialog
// ═══════════════════════════════════════════════════════════════════════════
class _SuccessDialog extends StatefulWidget {
  final File pdfFile;
  final VoidCallback onShare;
  final ValueChanged<File> onFileChanged;

  const _SuccessDialog({
    required this.pdfFile,
    required this.onShare,
    required this.onFileChanged,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  late File _currentFile;
  String _fileSize    = '';
  String _createdDate = '';
  bool _isRenaming    = false;
  bool _renamed       = false;
  bool _isPickingFolder = false;

  static const _green  = Color(0xFF2E7D32);
  static const _blue   = Color(0xFF1565C0);
  static const _orange = Color(0xFFBF360C);
  static const _purple = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    _currentFile = widget.pdfFile;

    final base = p.basename(_currentFile.path);
    _nameCtrl = TextEditingController(
      text: base.endsWith('.pdf') ? base.substring(0, base.length - 4) : base,
    );

    _refreshMeta();
    _createdDate = _fmtDate(DateTime.now());

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _scaleAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _refreshMeta() {
    try {
      _fileSize = _fmtBytes(_currentFile.lengthSync());
    } catch (_) {
      _fileSize = '—';
    }
  }

  String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1048576).toStringAsFixed(2)} MB';
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ── shared snack bar ──────────────────────────────────────────────────────
  void _snack(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: Colors.white, size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
      backgroundColor: ok ? _green : const Color(0xFFD32F2F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── FIX 1: Done → haptic + green SnackBar confirmation ───────────────────
  void _done() {
    HapticFeedback.lightImpact();
    final name = p.basename(_currentFile.path);
    Navigator.of(context).pop();
    // addPostFrameCallback so the snack appears on the screen behind the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return; // dialog already gone, check parent scaffold
      // parent scaffold is mounted; show snack via root messenger
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text('PDF saved: $name',
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Rename ────────────────────────────────────────────────────────────────
  Future<void> _rename() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isRenaming = true);
    try {
      final newPath = p.join(p.dirname(_currentFile.path), '$name.pdf');
      final renamed = await _currentFile.rename(newPath);
      setState(() {
        _currentFile = renamed;
        _renamed     = true;
        _isRenaming  = false;
      });
      widget.onFileChanged(renamed);
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isRenaming = false);
      _snack('Rename failed: $e', ok: false);
    }
  }

  // ── FIX 2: folder picker → move file ─────────────────────────────────────
  Future<void> _pickFolder() async {
    setState(() => _isPickingFolder = true);
    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose where to save the PDF',
      );

      if (dir == null) {
        setState(() => _isPickingFolder = false);
        return; // user cancelled
      }

      final fileName = p.basename(_currentFile.path);
      final destPath = p.join(dir, fileName);

      if (_currentFile.path == destPath) {
        setState(() => _isPickingFolder = false);
        return; // already there
      }

      final moved = await _currentFile.rename(destPath);
      setState(() {
        _currentFile    = moved;
        _isPickingFolder = false;
        _renamed        = false;
      });
      widget.onFileChanged(moved);
      HapticFeedback.mediumImpact();
      _snack('Saved to $dir', ok: true);
    } catch (e) {
      setState(() => _isPickingFolder = false);
      _snack('Could not move file: $e', ok: false);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 48,
                    offset: const Offset(0, 18)),
              ],
            ),
            child: SingleChildScrollView(
              // keyboard avoidance
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaStrip(),
                        const SizedBox(height: 18),
                        _buildLabel('File Name',
                            Icons.drive_file_rename_outline_rounded),
                        const SizedBox(height: 8),
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildLabel('Save Location',
                            Icons.folder_open_rounded),
                        const SizedBox(height: 8),
                        _buildPathTile(),
                        const SizedBox(height: 20),
                        _buildActions(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PDF Saved',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2)),
                Text('Rename or choose where to save',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          // header X also triggers _done for consistent feedback
          IconButton(
            onPressed: _done,
            visualDensity: VisualDensity.compact,
            tooltip: 'Close',
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── Meta strip ────────────────────────────────────────────────────────────
  Widget _buildMetaStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _metaItem(Icons.data_usage_rounded,     _fileSize,    _blue),
          _vDivider(),
          _metaItem(Icons.calendar_today_rounded,  _createdDate, _purple),
          _vDivider(),
          _metaItem(Icons.picture_as_pdf_rounded,  'PDF',        _orange),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text, Color color) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    ),
  );

  Widget _vDivider() =>
      Container(width: 1, height: 30, color: const Color(0xFFDDE0E5));

  Widget _buildLabel(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey.shade500),
      const SizedBox(width: 5),
      Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.2)),
    ],
  );

  // ── File name field ───────────────────────────────────────────────────────
  Widget _buildNameField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _rename(),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 12),
                    border: InputBorder.none,
                    suffixText: '.pdf',
                    suffixStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                  ),
                  onChanged: (_) => setState(() => _renamed = false),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _renamed
                    ? Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: _green),
                      SizedBox(width: 4),
                      Text('Renamed successfully',
                          style: TextStyle(
                              fontSize: 11,
                              color: _green,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _renamed
              ? _iconBtn(
              key: const ValueKey('ok'),
              icon: Icons.check_rounded,
              bg: _green,
              onTap: null)
              : _iconBtn(
              key: const ValueKey('sv'),
              icon: Icons.save_rounded,
              bg: _blue,
              onTap: _isRenaming ? null : _rename,
              loading: _isRenaming),
        ),
      ],
    );
  }

  Widget _iconBtn({
    required Key key,
    required IconData icon,
    required Color bg,
    required VoidCallback? onTap,
    bool loading = false,
  }) =>
      GestureDetector(
        key: key,
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [bg, bg.withValues(alpha: 0.80)]),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                  color: bg.withValues(alpha: 0.25),
                  blurRadius: 7,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: loading
              ? const Padding(
              padding: EdgeInsets.all(11),
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 20),
        ),
      );

  // ── Path tile — tappable, opens folder picker ─────────────────────────────
  Widget _buildPathTile() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: _isPickingFolder ? null : _pickFolder,
        borderRadius: BorderRadius.circular(13),
        splashColor: _blue.withValues(alpha: 0.08),
        highlightColor: _blue.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isPickingFolder
                ? const Color(0xFFE3F2FD)
                : const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _isPickingFolder
                  ? _blue.withValues(alpha: 0.45)
                  : const Color(0xFFE8EAED),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // folder icon or spinner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isPickingFolder
                    ? Container(
                  key: const ValueKey('spin'),
                  width: 32, height: 32,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const CircularProgressIndicator(
                      strokeWidth: 2.2, color: _blue),
                )
                    : Container(
                  key: const ValueKey('folder'),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.folder_rounded,
                      color: _blue, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              // path text + tap hint
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentFile.path,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF546E7A),
                          height: 1.45),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 11,
                            color: _isPickingFolder
                                ? _blue
                                : Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          _isPickingFolder
                              ? 'Opening picker…'
                              : 'Tap to change folder',
                          style: TextStyle(
                              fontSize: 10,
                              color: _isPickingFolder
                                  ? _blue
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // copy button
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: _currentFile.path));
                  HapticFeedback.lightImpact();
                  _snack('Path copied to clipboard', ok: true);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: _blue, size: 14),
                ),
              ),
              const SizedBox(width: 5),
              // change-folder badge
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.drive_folder_upload_rounded,
                    color: _blue, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        // Done — FIX: haptic + SnackBar confirmation
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _done,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Done'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: Color(0xFFDDE0E5), width: 1.5),
              foregroundColor: const Color(0xFF616161),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: widget.onShare,
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error Dialog
// ═══════════════════════════════════════════════════════════════════════════
class _ErrorDialog extends StatelessWidget {
  final String message;
  const _ErrorDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 38,
                offset: const Offset(0, 14)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFD32F2F), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  elevation: 0,
                ),
                child: const Text('Dismiss',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
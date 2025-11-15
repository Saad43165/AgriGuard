// lib/features/scan_history/presentation/components/scan_options_bottomsheet/scan_options_bottomsheet.dart
import 'dart:io';
import 'package:agriguard_fyp/features/home/screens/bottom_sheet_widgets/services/pdf_action_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pdf_success_dialog.dart';
import 'option_tile.dart';


class ScanOptionsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> scan;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const ScanOptionsBottomSheet({
    super.key,
    required this.scan,
    required this.onDelete,
    this.onShare,
  });

  @override
  State<ScanOptionsBottomSheet> createState() => _ScanOptionsBottomSheetState();
}

class _ScanOptionsBottomSheetState extends State<ScanOptionsBottomSheet> {
  final _pdfService = PdfActionsService();
  bool _isGeneratingPdf = false;

  Future<void> _generatePdf() async {
    if (_isGeneratingPdf || !mounted) return;
    setState(() => _isGeneratingPdf = true);

    await _pdfService.generateAndShowPdf(
      context: context,
      scan: widget.scan,
      onError: (msg) => _showError(msg),
      onSuccess: (file) => _showPdfSuccess(file),
    );

    if (mounted) setState(() => _isGeneratingPdf = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  Future<void> _showPdfSuccess(File pdfFile) async {
    await showDialog(
      context: context,
      builder: (_) => PdfSuccessDialog(pdfFile: pdfFile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.15), blurRadius: 20, offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(theme),
            _buildHeader(theme),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  OptionTile(
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Generate PDF Report',
                    subtitle: 'Download detailed analysis',
                    onTap: _isGeneratingPdf ? null : _generatePdf,
                    trailing: _isGeneratingPdf ? const _MiniLoader() : null,
                  ),
                  OptionTile(
                    icon: Icons.content_copy_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Copy Results',
                    subtitle: 'Share as formatted text',
                    onTap: () {
                      Navigator.pop(context);
                      _pdfService.copyResultsToClipboard(context, widget.scan);
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  OptionTile(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    title: 'Delete Scan',
                    subtitle: 'Remove from history',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) => Container(
    margin: const EdgeInsets.only(top: 12, bottom: 8),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withOpacity(0.2),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildHeader(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text('Scan Options', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
      ],
    ),
  );
}

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
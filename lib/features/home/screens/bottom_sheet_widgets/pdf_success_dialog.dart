import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfSuccessDialog extends StatelessWidget {
  final File pdfFile;

  const PdfSuccessDialog({super.key, required this.pdfFile});

  Future<void> _saveWithOptions(BuildContext context) async {
    print('🔘 Opening save options dialog...');

    // DON'T pop the context - keep it alive
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _SaveOptionsDialog(
        currentFileName: pdfFile.path.split('/').last,
      ),
    );

    print('📋 Save options result: $result');

    if (result == null) {
      print('❌ User cancelled');
      return;
    }

    if (!context.mounted) {
      print('❌ Context not mounted');
      return;
    }

    final fileName = result['fileName'] as String;
    final location = result['location'] as String;

    print('📁 Saving to location: $location with filename: $fileName');

    // Context is still valid here
    await _saveToLocation(context, fileName, location);
  }

  Future<void> _saveToLocation(
      BuildContext context,
      String fileName,
      String location,
      ) async {
    print('💾 _saveToLocation called: $fileName at $location');
    print('   Context mounted: ${context.mounted}');

    if (!context.mounted) {
      print('❌ Context lost before save');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Saving to ${_getLocationName(location)}...',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Request permission for Android
      if (Platform.isAndroid) {
        print('📱 Requesting Android storage permission...');

        PermissionStatus status;
        final androidVersion = 33; // Default

        if (androidVersion >= 30) {
          // Android 11+
          status = await Permission.manageExternalStorage.request();

          // Fallback to storage permission if manage external storage is denied
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
        } else {
          status = await Permission.storage.request();
        }

        print('✅ Permission status: $status');

        if (!status.isGranted && !status.isLimited) {
          if (!context.mounted) return;
          Navigator.pop(context); // Close loading
          _showSnackBar(
            context,
            'Storage permission is required to save files.\nPlease grant permission in settings.',
            isError: true,
          );
          return;
        }
      }

      String savedPath;

      if (location == 'downloads') {
        // Save to Downloads
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          print('📁 Creating Downloads directory...');
          await downloadsDir.create(recursive: true);
        }
        savedPath = '${downloadsDir.path}/$fileName';
        print('📥 Copying to Downloads: $savedPath');
        await pdfFile.copy(savedPath);

      } else if (location == 'agriguard') {
        // Save to AgriGuard folder in Downloads
        final customDir = Directory('/storage/emulated/0/Download/AgriGuard');
        if (!await customDir.exists()) {
          print('📁 Creating AgriGuard directory...');
          await customDir.create(recursive: true);
        }
        savedPath = '${customDir.path}/$fileName';
        print('📥 Copying to AgriGuard folder: $savedPath');
        await pdfFile.copy(savedPath);

      } else if (location == 'documents') {
        // Save to Documents
        final documentsDir = Directory('/storage/emulated/0/Documents');
        if (!await documentsDir.exists()) {
          print('📁 Creating Documents directory...');
          await documentsDir.create(recursive: true);
        }
        savedPath = '${documentsDir.path}/$fileName';
        print('📥 Copying to Documents: $savedPath');
        await pdfFile.copy(savedPath);

      } else {
        throw Exception('Unknown location: $location');
      }

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      print('✅ File saved successfully: $savedPath');

      // Show success message
      _showSnackBar(
        context,
        'PDF saved successfully!\n📁 ${_formatPath(savedPath)}',
        isError: false,
      );
    } catch (e, stackTrace) {
      print('❌ Error saving file: $e');
      print('Stack trace: $stackTrace');

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      _showSnackBar(
        context,
        'Failed to save: ${e.toString()}\n\nTry granting storage permission in Settings.',
        isError: true,
      );
    }
  }

  String _formatPath(String path) {
    // Format path for display
    if (path.contains('/Download/AgriGuard/')) {
      return 'Download/AgriGuard/${path.split('/').last}';
    } else if (path.contains('/Download/')) {
      return 'Download/${path.split('/').last}';
    } else if (path.contains('/Documents/')) {
      return 'Documents/${path.split('/').last}';
    } else if (path.contains('/storage/emulated/0/')) {
      return path.replaceAll('/storage/emulated/0/', '');
    } else {
      return path.split('/').last;
    }
  }

  String _getLocationName(String location) {
    switch (location) {
      case 'downloads':
        return 'Downloads';
      case 'agriguard':
        return 'AgriGuard Folder';
      case 'documents':
        return 'Documents';
      default:
        return 'Storage';
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    print('📤 Sharing PDF...');
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'AgriGuard Plant Health Report',
        text: 'Here is my plant health analysis report from AgriGuard',
      );
      print('✅ Share sheet opened');
    } catch (e) {
      print('❌ Share error: $e');
      if (context.mounted) {
        _showSnackBar(context, 'Failed to share: $e', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 6 : 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizeKB = (pdfFile.lengthSync() / 1024).toStringAsFixed(1);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDF Generated!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your report is ready',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Info cards
                  _buildInfoCard(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'File Size',
                    value: '$sizeKB KB',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Format',
                    value: 'PDF Document',
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.access_time_rounded,
                    label: 'Created',
                    value: 'Just now',
                    color: const Color(0xFF8B5CF6),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          onPressed: () {
                            print('🔘 Share button pressed');
                            Navigator.pop(context);
                            _sharePdf(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.download_rounded,
                          label: 'Save',
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ],
                          ),
                          onPressed: () {
                            print('🔘 Save button pressed');
                            // DON'T pop here - keep dialog open during save
                            _saveWithOptions(context);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Close button
                  TextButton(
                    onPressed: () {
                      print('🔘 Close button pressed');
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== SAVE OPTIONS DIALOG ====================
class _SaveOptionsDialog extends StatefulWidget {
  final String currentFileName;

  const _SaveOptionsDialog({required this.currentFileName});

  @override
  State<_SaveOptionsDialog> createState() => _SaveOptionsDialogState();
}

class _SaveOptionsDialogState extends State<_SaveOptionsDialog> {
  late TextEditingController _fileNameController;
  String _selectedLocation = 'downloads';

  @override
  void initState() {
    super.initState();
    // Generate default filename without extension
    final timestamp = DateTime.now();
    final defaultName = 'AgriGuard_Report_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
    _fileNameController = TextEditingController(text: defaultName);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.save_rounded,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Save PDF',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name input
            Text(
              'File Name',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                hintText: 'Enter file name',
                suffixText: '.pdf',
                prefixIcon: const Icon(Icons.description_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 20),

            // Location selection
            Text(
              'Save Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildLocationOption(
              icon: Icons.download_rounded,
              title: 'Downloads',
              subtitle: '/Download/',
              value: 'downloads',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 8),
            _buildLocationOption(
              icon: Icons.folder_special,
              title: 'AgriGuard Folder',
              subtitle: '/Download/AgriGuard/',
              value: 'agriguard',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 8),
            _buildLocationOption(
              icon: Icons.description_outlined,
              title: 'Documents',
              subtitle: '/Documents/',
              value: 'documents',
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            print('❌ Save dialog cancelled');
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final fileName = _fileNameController.text.trim();
            if (fileName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a file name')),
              );
              return;
            }

            print('✅ Save dialog confirmed: $fileName.pdf at $_selectedLocation');

            Navigator.pop(context, {
              'fileName': '$fileName.pdf',
              'location': _selectedLocation,
            });
          },
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedLocation == value;

    return InkWell(
      onTap: () {
        print('📍 Location selected: $value');
        setState(() => _selectedLocation = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }
}
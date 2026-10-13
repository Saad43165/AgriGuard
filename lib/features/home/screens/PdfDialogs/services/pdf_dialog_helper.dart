import 'package:agriguard_fyp/core/widgets/app_themes.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfDialogHelper {
  // Show snackbar
  static void showSnackBar(
      BuildContext context,
      String message, {
        required bool isError,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.emeraldDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  // Save to location
  static Future<void> saveToLocation({
    required BuildContext context,
    required File pdfFile,
    required String fileName,
    required String location,
  }) async {
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          margin: const EdgeInsets.all(48),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );

    try {
      // Android 10+ lets apps create files in Download/Documents without any
      // permission. Only older devices need WRITE_EXTERNAL_STORAGE, so ask
      // for it only when the first write attempt is refused.
      String savedPath;
      try {
        savedPath = await _saveFile(pdfFile, fileName, location);
      } on FileSystemException {
        if (!Platform.isAndroid || !await _requestStoragePermission()) {
          if (context.mounted) {
            Navigator.pop(context);
            showSnackBar(context, 'Storage permission required', isError: true);
          }
          return;
        }
        savedPath = await _saveFile(pdfFile, fileName, location);
      }

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      showSnackBar(
        context,
        'Saved to ${_formatPath(savedPath)}',
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      showSnackBar(context, 'Failed to save: $e', isError: true);
    }
  }

  // Request legacy storage permission (only needed on Android 9 and below)
  static Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited;
  }

  // Save file to specific location
  static Future<String> _saveFile(
      File pdfFile,
      String fileName,
      String location,
      ) async {
    Directory targetDir;

    switch (location) {
      case 'downloads':
        targetDir = Directory('/storage/emulated/0/Download');
        break;
      case 'agriguard':
        targetDir = Directory('/storage/emulated/0/Download/AgriGuard');
        break;
      case 'documents':
        targetDir = Directory('/storage/emulated/0/Documents');
        break;
      default:
        throw Exception('Unknown location: $location');
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final savedPath = '${targetDir.path}/$fileName';
    await pdfFile.copy(savedPath);

    return savedPath;
  }

  // Format path for display
  static String _formatPath(String path) {
    if (path.contains('/Download/AgriGuard/')) {
      return 'AgriGuard/${path.split('/').last}';
    } else if (path.contains('/Download/')) {
      return 'Downloads/${path.split('/').last}';
    } else if (path.contains('/Documents/')) {
      return 'Documents/${path.split('/').last}';
    } else {
      return path.split('/').last;
    }
  }
}
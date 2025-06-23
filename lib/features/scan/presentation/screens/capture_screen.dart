// lib/features/scan/presentation/screens/capture_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../home/presentation/widgets/nav_bar.dart';

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  XFile? _imageFile;
  bool _isLoading = false;
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processAndNavigate() async {
    if (_imageFile == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      Directory appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('Failed to get documents directory: $e');
        appDir = await getTemporaryDirectory();
      }

      final fileName = 'leaf_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile = File('${appDir.path}/$fileName');

      await _verifyAndCopyFile(File(_imageFile!.path), permanentFile);

      // Verify file exists before navigation
      if (!await permanentFile.exists()) {
        throw Exception('Copied file does not exist at ${permanentFile.path}');
      }
      debugPrint('File copied successfully to: ${permanentFile.path}');

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.imageEdit,
          arguments: {'imagePath': permanentFile.path},
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process image. Please try again. Error: ${e.toString()}');
      debugPrint('Image processing error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _verifyAndCopyFile(File source, File destination) async {
    if (!await source.exists()) {
      throw Exception('Source file does not exist at ${source.path}');
    }
    await source.copy(destination.path);
    if (!await destination.exists()) {
      throw Exception('Failed to create file copy at ${destination.path}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: AppDurations.snackBarDuration,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.scanPlant),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppMeasurements.smallPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
          if (_isLoading || _isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1, // Changed to 1 for Scan
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              break;
            case 1:
            // Already on Scan screen, no navigation needed
              break;
            case 2:
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
              break;
          }
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.imageError, size: 60, color: Theme.of(context).disabledColor),
          const SizedBox(height: AppMeasurements.smallPadding),
          Text(
            AppStrings.noImageSelected,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppMeasurements.extraSmallPadding),
          Text(
            AppStrings.captureOrSelectLeaf,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
      child: Image.file(
        File(_imageFile!.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.imageError, size: 60, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: AppMeasurements.smallPadding),
                Text(
                  AppStrings.failedToLoadImage,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppMeasurements.defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageButton(
                icon: AppIcons.scan,
                label: AppStrings.camera,
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              _buildImageButton(
                icon: Icons.photo_library,
                label: AppStrings.gallery,
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
          if (_imageFile != null) SizedBox(height: AppMeasurements.smallPadding),
          if (_imageFile != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processAndNavigate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppMeasurements.smallPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppMeasurements.borderRadius),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(AppStrings.editAndAnalyze),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: AppMeasurements.iconSizeMedium),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            padding: const EdgeInsets.all(AppMeasurements.smallPadding),
          ),
        ),
        const SizedBox(height: AppMeasurements.extraSmallPadding),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
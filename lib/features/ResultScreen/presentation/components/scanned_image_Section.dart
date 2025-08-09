import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../Profile/presentation/Components/glass_card.dart';
import 'section_header.dart';

class ScannedImageSection extends StatefulWidget {
  final String imagePath;  // Only accept imagePath for local files
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;

  const ScannedImageSection({
    super.key,
    required this.imagePath,  // Required parameter
    this.height = 200,
    this.width,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  State<ScannedImageSection> createState() => _ScannedImageSectionState();
}

class _ScannedImageSectionState extends State<ScannedImageSection> {
  late Future<File> _imageFileFuture;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageFileFuture = _loadImageFile();
  }

  Future<File> _loadImageFile() async {
    try {
      final file = File(widget.imagePath);
      if (await file.exists()) {
        await file.readAsBytes().then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false;
            });
          }
        });
        return file;
      }
      throw Exception('File not found');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Scanned Image',
          icon: Icons.photo_camera_rounded,
        ),
        const SizedBox(height: AppMeasurements.smallPadding),
        GlassCard(
          child: _buildImageContent(context),
        ),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        child: _buildImageWidget(context),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    if (_isLoading) return _buildLoadingIndicator(context);
    if (_hasError) return _buildErrorPlaceholder(context, Icons.broken_image_rounded, 'Failed to load image');

    return FutureBuilder<File>(
      future: _imageFileFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorPlaceholder(context, Icons.error_outline, 'Image error');
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingIndicator(context);
        if (!snapshot.hasData) return _buildErrorPlaceholder(context, Icons.image_not_supported_outlined, 'No image data');

        return Image.file(
          snapshot.data!,
          fit: widget.fit,
          width: widget.width ?? double.infinity,
          height: widget.height,
        );
      },
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context, IconData icon, String message) {
    final theme = Theme.of(context);
    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      color: theme.colorScheme.error.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.error, size: AppMeasurements.getResponsiveIconSizeLarge(context)),
          const SizedBox(height: 8),
          Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }
}
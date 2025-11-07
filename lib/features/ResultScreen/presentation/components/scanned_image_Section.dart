import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_measurements.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'section_header.dart';

class ScannedImageSection extends StatefulWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;
  final Widget? placeholder;
  final Widget? errorWidget;

   ScannedImageSection({
    super.key,
    required this.imagePath,
    this.height = 200,
    this.width,
    this.fit = BoxFit.cover,
    this.onTap,
    this.placeholder,
    this.errorWidget,
  }): assert(imagePath.isNotEmpty, 'imagePath cannot be empty');

  @override
  State<ScannedImageSection> createState() => _ScannedImageSectionState();
}

class _ScannedImageSectionState extends State<ScannedImageSection> {
  late Future<File> _imageFileFuture;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _imageFileFuture = _loadImageFile();
  }

  @override
  void didUpdateWidget(covariant ScannedImageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _reloadImage();
    }
  }

  void _reloadImage() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _imageFileFuture = _loadImageFile();
    });
  }

  Future<File> _loadImageFile() async {
    if (!mounted) return Future.error('Widget not mounted');

    try {
      final file = File(widget.imagePath);

      // Check file existence
      if (!await file.exists()) {
        throw FileSystemException('File not found', widget.imagePath);
      }

      // Verify file can be read and is an image
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('File is empty');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }

      return file;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
      debugPrint('Error loading image file: $e');
      return Future.error(e);
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
      onTap: () {
        if (_hasError) {
          _reloadImage();
        }
        widget.onTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppMeasurements.getResponsiveBorderRadius(context),
        ),
        child: _buildImageWidget(context),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? _buildLoadingIndicator(context);
    }

    if (_hasError) {
      return widget.errorWidget ?? _buildErrorPlaceholder(context);
    }

    return FutureBuilder<File>(
      future: _imageFileFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.errorWidget ?? _buildErrorPlaceholder(context);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ?? _buildLoadingIndicator(context);
        }

        if (!snapshot.hasData) {
          return widget.errorWidget ?? _buildErrorPlaceholder(context);
        }

        return Image.file(
          snapshot.data!,
          fit: widget.fit,
          width: widget.width ?? double.infinity,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorPlaceholder(context);
          },
        );
      },
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      color: theme.colorScheme.error.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: theme.colorScheme.error,
            size: AppMeasurements.getResponsiveIconSizeLarge(context),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Failed to load image',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to retry',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
          ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Loading image...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
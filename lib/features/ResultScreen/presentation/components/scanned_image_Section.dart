import 'dart:io';
import 'package:flutter/material.dart';

class ScannedImageSection extends StatefulWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;

  const ScannedImageSection({
    super.key,
    required this.imagePath,
    this.height = 280,
    this.width,
    this.fit = BoxFit.cover,
    this.onTap,
  }) : assert(imagePath != '', 'imagePath cannot be empty');

  @override
  State<ScannedImageSection> createState() => _ScannedImageSectionState();
}

class _ScannedImageSectionState extends State<ScannedImageSection> {
  bool _isLoading = true;
  bool _hasError = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadImageFile();
  }

  @override
  void didUpdateWidget(covariant ScannedImageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _reloadImage();
    }
  }

  void _reloadImage() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageFile = null;
    });
    _loadImageFile();
  }

  Future<void> _loadImageFile() async {
    if (!mounted) return;

    try {
      final file = File(widget.imagePath);

      if (!await file.exists()) {
        throw FileSystemException('Image file not found', widget.imagePath);
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      if (mounted) {
        setState(() {
          _imageFile = file;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_hasError) {
          _reloadImage();
        }
        widget.onTap?.call();
      },
      child: _buildImageContent(context),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildImageWidget(context),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator(context);
    }

    if (_hasError || _imageFile == null) {
      return _buildErrorPlaceholder(context);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          _imageFile!,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image render error: $error');
            return _buildErrorPlaceholder(context);
          },
        ),
        // Gradient overlay for better text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        // Scanned Image Label
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_camera_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Scanned Image',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.error.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.broken_image_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Image',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The image could not be displayed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _reloadImage,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading image...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
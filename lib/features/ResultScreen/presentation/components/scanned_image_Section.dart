import 'dart:io';
import 'package:flutter/material.dart';
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
    this.height = 250,
    this.width,
    this.fit = BoxFit.cover,
    this.onTap,
    this.placeholder,
    this.errorWidget,
  }) : assert(imagePath.isNotEmpty, 'imagePath cannot be empty');

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
    if (!mounted) return;
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

      if (!await file.exists()) {
        throw FileSystemException('Image file not found', widget.imagePath);
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Image file is empty');
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
      debugPrint('Error loading image: $e');
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
        const SizedBox(height: 12),
        _buildImageContent(context),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (_hasError) {
          _reloadImage();
        }
        widget.onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface.withOpacity(0.5)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildImageWidget(context),
        ),
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
            debugPrint('Image render error: $error');
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
      color: theme.colorScheme.error.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _reloadImage,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
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
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
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
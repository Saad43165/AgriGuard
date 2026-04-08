import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lottie/lottie.dart';

class RemoteLottie extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final bool repeat;
  final bool animate;
  final Widget? fallback;

  const RemoteLottie({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.repeat = true,
    this.animate = true,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DefaultCacheManager().getSingleFile(url),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Lottie.file(
            snapshot.data!,
            fit: fit,
            alignment: alignment,
            repeat: repeat,
            animate: animate,
          );
        }
        if (snapshot.hasError) {
          return fallback ?? const SizedBox.shrink();
        }
        return fallback ??
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
    );
  }
}


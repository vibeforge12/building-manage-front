import 'package:flutter/material.dart';

class FullScreenImageBackground extends StatelessWidget {
  const FullScreenImageBackground({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.high,
  });

  final String assetPath;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, fit: fit, filterQuality: filterQuality);
  }
}

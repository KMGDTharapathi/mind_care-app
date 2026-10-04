import 'dart:io';

import 'package:flutter/widgets.dart';

/// IO (Android/iOS/desktop) implementation of [AttachmentImage]: renders the
/// selected file directly from its path via [Image.file].
class AttachmentImageImpl extends StatelessWidget {
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;

  const AttachmentImageImpl({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        height: 100,
        color: const Color(0xFFE0E0E0),
        child: const Icon(null),
      ),
    );
  }
}
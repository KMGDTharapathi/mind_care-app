import 'package:flutter/material.dart';

/// Web implementation of [AttachmentImage]. Browsers cannot open local
/// filesystem paths (the picker only returns an in-memory file), so show a
/// placeholder thumbnail instead of crashing the build on `dart:io`.
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
    return Container(
      height: height ?? 180,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.broken_image_outlined,
        color: Color(0xFF9E9E9E),
        size: 40,
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import 'attachment_image_impl_io.dart'
    if (dart.library.js_interop) 'attachment_image_impl_web.dart' as impl;

/// Renders a local image attachment. On IO platforms this shows the actual
/// file bytes; on web (where `dart:io` does not exist) it shows a placeholder,
/// since browsers cannot open local filesystem paths.
class AttachmentImage extends StatelessWidget {
  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;

  const AttachmentImage({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return impl.AttachmentImageImpl(
      path: path,
      height: height,
      width: width,
      fit: fit,
    );
  }
}
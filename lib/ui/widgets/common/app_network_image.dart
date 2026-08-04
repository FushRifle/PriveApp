import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum AppNetworkImagePreset { avatar, thumbnail, card, fullscreen }

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final AppNetworkImagePreset preset;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorBuilder;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.preset = AppNetworkImagePreset.card,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return errorBuilder?.call(context) ?? const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final ratio = MediaQuery.devicePixelRatioOf(context);
        final logicalWidth = width != null && width!.isFinite
            ? width!
            : constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : size.width;
        final logicalHeight = height != null && height!.isFinite
            ? height!
            : constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : logicalWidth;
        final limits = _limitsFor(preset);
        final cacheWidth =
            (logicalWidth * ratio).round().clamp(limits.$1, limits.$2);
        final cacheHeight =
            (logicalHeight * ratio).round().clamp(limits.$1, limits.$2);

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          filterQuality: filterQuality,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          maxWidthDiskCache: limits.$2,
          maxHeightDiskCache: limits.$2,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: placeholder == null
              ? null
              : (context, _) => placeholder!.call(context),
          errorWidget: errorBuilder == null
              ? null
              : (context, _, __) => errorBuilder!.call(context),
        );
      },
    );
  }

  (int, int) _limitsFor(AppNetworkImagePreset value) {
    return switch (value) {
      AppNetworkImagePreset.avatar => (48, 256),
      AppNetworkImagePreset.thumbnail => (120, 720),
      AppNetworkImagePreset.card => (240, 1440),
      AppNetworkImagePreset.fullscreen => (480, 2160),
    };
  }
}

CachedNetworkImageProvider appNetworkImageProvider(
  BuildContext context,
  String imageUrl, {
  AppNetworkImagePreset preset = AppNetworkImagePreset.avatar,
  double logicalWidth = 64,
  double? logicalHeight,
}) {
  final ratio = MediaQuery.devicePixelRatioOf(context);
  final maxPixels = switch (preset) {
    AppNetworkImagePreset.avatar => 256,
    AppNetworkImagePreset.thumbnail => 720,
    AppNetworkImagePreset.card => 1440,
    AppNetworkImagePreset.fullscreen => 2160,
  };
  return CachedNetworkImageProvider(
    imageUrl,
    maxWidth: (logicalWidth * ratio).round().clamp(48, maxPixels),
    maxHeight:
        ((logicalHeight ?? logicalWidth) * ratio).round().clamp(48, maxPixels),
  );
}

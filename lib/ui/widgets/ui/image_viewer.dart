import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? caption;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    this.caption,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  final Dio _dio = Dio();

  bool _isSaving = false;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _CircleActionButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _CircleActionButton(
                    icon: _isSaving ? Icons.hourglass_top : Icons.download,
                    onTap: _isSaving ? null : _saveImage,
                    tooltip: 'Save',
                    isLoading: _isSaving,
                  ),
                  const SizedBox(width: 10),
                  _CircleActionButton(
                    icon: _isSharing ? Icons.hourglass_top : Icons.share,
                    onTap: _isSharing ? null : _shareImage,
                    tooltip: 'Share',
                    isLoading: _isSharing,
                  ),
                ],
              ),
            ),
            if (widget.caption != null && widget.caption!.isNotEmpty)
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    widget.caption!,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      if (kIsWeb) {
        await Share.share(
          widget.imageUrl,
          subject: widget.caption ?? 'Shared image',
        );
        return;
      }

      final file = await _downloadImage();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.caption,
      );
    } catch (e) {
      _showSnackBar('Unable to share image');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (kIsWeb) {
        _showSnackBar('Saving images is not supported on web');
        return;
      }

      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.addOnly,
        ),
      );
      if (!permission.isAuth) {
        _showSnackBar('Photo access is required to save images');
        return;
      }

      final file = await _downloadImage();
      await PhotoManager.editor.saveImageWithPath(
        file.path,
        title: file.uri.pathSegments.last,
      );
      _showSnackBar('Saved to gallery');
    } catch (e) {
      _showSnackBar('Unable to save image');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<File> _downloadImage() async {
    final response = await _dio.get<List<int>>(
      widget.imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/clique_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Image download failed');
    }

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isLoading;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.55),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withOpacity(0.10),
        ),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Icon(
                icon,
                color: AppColors.white,
                size: 20,
              ),
      ),
    );

    if (tooltip == null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return Tooltip(
      message: tooltip!,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

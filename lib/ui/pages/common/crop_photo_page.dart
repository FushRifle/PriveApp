import 'dart:typed_data';

import 'package:clique/app/configs/colors.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class CropPhotoPage extends StatefulWidget {
  final Uint8List imageBytes;
  final double? aspectRatio;

  const CropPhotoPage({
    super.key,
    required this.imageBytes,
    this.aspectRatio,
  });

  @override
  State<CropPhotoPage> createState() => _CropPhotoPageState();
}

class _CropPhotoPageState extends State<CropPhotoPage> {
  final CropController _controller = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Crop(
              controller: _controller,
              image: widget.imageBytes,
              aspectRatio: widget.aspectRatio,
              baseColor: AppColors.black,
              maskColor: AppColors.black.withOpacity(0.58),
              radius: 8,
              onCropped: _handleCropResult,
              progressIndicator: const Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                children: [
                  _ActionButton(
                    tooltip: 'Close',
                    icon: Icons.close_rounded,
                    onPressed:
                        _isCropping ? null : () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _ActionButton(
                    tooltip: 'Rotate',
                    icon: Icons.crop_rotate_rounded,
                    onPressed:
                        _isCropping ? null : () => _controller.rotateLeft(),
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    tooltip: 'Confirm',
                    icon: Icons.check_rounded,
                    isPrimary: true,
                    onPressed: _isCropping
                        ? null
                        : () {
                            setState(() => _isCropping = true);
                            _controller.crop();
                          },
                  ),
                ],
              ),
            ),
          ),
          if (_isCropping)
            const Positioned.fill(
              child: ColoredBox(
                color: Color.fromRGBO(0, 0, 0, 0.28),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleCropResult(dynamic result) {
    if (!mounted) return;

    final bytes = _readCroppedBytes(result);
    if (bytes != null) {
      Navigator.pop(context, bytes);
      return;
    }

    setState(() => _isCropping = false);
  }

  Uint8List? _readCroppedBytes(dynamic result) {
    if (result is Uint8List) return result;
    try {
      final dynamic croppedImage = result.croppedImage;
      if (croppedImage is Uint8List) return croppedImage;
    } catch (_) {}
    return null;
  }
}

class _ActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color:
            isPrimary ? AppColors.primary : AppColors.black.withOpacity(0.56),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: AppColors.white,
          iconSize: 22,
          constraints: const BoxConstraints.tightFor(width: 46, height: 46),
        ),
      ),
    );
  }
}

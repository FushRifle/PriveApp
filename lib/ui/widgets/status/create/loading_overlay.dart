import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';

class LoadingOverlay extends StatelessWidget {
  final double uploadProgress;
  final bool isSubmitting;

  const LoadingOverlay({
    super.key,
    required this.uploadProgress,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.05),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: isSubmitting ? value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2030),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: uploadProgress > 0 ? uploadProgress : null,
                          strokeWidth: 3,
                          color: AppColors.primary,
                          backgroundColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      if (uploadProgress > 0)
                        Text(
                          '${(uploadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    uploadProgress > 0
                        ? 'Uploading...'
                        : 'Creating Story',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your story is being processed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
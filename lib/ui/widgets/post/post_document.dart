import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/models/feeds_models.dart';
import 'package:clique/ui/widgets/ui/document_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostDocument extends StatelessWidget {
  final FeedPost post;
  final Attachment attachment;

  const PostDocument({
    super.key,
    required this.post,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = _fileNameFromUrl(attachment.url);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        if (attachment.url.trim().isEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document link is unavailable'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return DocumentViewer(
                documentUrl: attachment.url,
                fileName: fileName,
                caption: post.content.trim().isNotEmpty ? post.content : null,
              );
            },
          ),
        );
      },
      child: Container(
        color:
            AppColors.primary.withOpacity(AppColors.isDarkMode ? 0.12 : 0.06),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.isDarkMode
                    ? AppColors.cardBorderColor
                    : AppColors.primary.withOpacity(0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.insert_drive_file_rounded,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to view document',
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fileNameFromUrl(String url) {
    if (url.trim().isEmpty) return 'Document';

    final uri = Uri.tryParse(url);

    if (uri == null || uri.pathSegments.isEmpty) {
      final fallback = url.split('/').last.trim();
      return fallback.isEmpty ? 'Document' : fallback;
    }

    final fileName = Uri.decodeComponent(uri.pathSegments.last).trim();
    return fileName.isEmpty ? 'Document' : fileName;
  }
}

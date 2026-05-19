import 'dart:io';
import 'package:cirqle/bloc/home/feed_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/app/configs/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cirqle/core/cloudinary_service.dart';
import 'package:cirqle/data/models/feeds_models.dart';
import 'package:file_picker/file_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  final List<MediaItem> _mediaItems = [];
  final List<String> _hashtags = [];

  bool _isPrivate = false;
  bool _isSubmitting = false;

  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _captionController.text.trim().isNotEmpty ||
      _hashtags.isNotEmpty ||
      _mediaItems.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDarkMode ? AppColors.darkBackground : AppColors.backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(isDarkMode),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaSection(),
                  if (_mediaItems.isNotEmpty) const SizedBox(height: 24),
                  _buildCaptionInput(isDarkMode),
                  const SizedBox(height: 24),
                  _buildHashtagSection(isDarkMode),
                  const SizedBox(height: 24),
                  _buildOptionsSection(isDarkMode),
                  const SizedBox(height: 32),
                  _buildPostButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon:
            Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Create Post',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildMediaSection() {
    if (_mediaItems.isEmpty) {
      return _buildMediaPickerGrid();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mediaItems.length + 1,
            itemBuilder: (context, index) {
              if (index == _mediaItems.length) {
                return _buildAddMoreButton();
              }
              return _buildMediaItem(_mediaItems[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPickerGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _buildMediaOption(
          icon: Icons.photo_library,
          label: 'Gallery',
          color: Colors.purple,
          onTap: () => _pickMedia(MediaType.image, ImageSource.gallery),
        ),
        _buildMediaOption(
          icon: Icons.camera_alt,
          label: 'Camera',
          color: Colors.blue,
          onTap: () => _pickMedia(MediaType.image, ImageSource.camera),
        ),
        _buildMediaOption(
          icon: Icons.videocam,
          label: 'Video',
          color: Colors.green,
          onTap: () => _pickMedia(MediaType.video, ImageSource.gallery),
        ),
        _buildMediaOption(
          icon: Icons.picture_as_pdf,
          label: 'Document',
          color: Colors.red,
          onTap: _pickDocument,
        ),
        _buildMediaOption(
          icon: Icons.text_fields,
          label: 'Text Only',
          color: Colors.orange,
          onTap: () {},
        ),
        _buildMediaOption(
          icon: Icons.music_note,
          label: 'Audio',
          color: Colors.teal,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(MediaItem media, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 180,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: media.type == MediaType.image
                ? _buildImagePreview(media)
                : _buildDocumentPreview(media),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    media.type == MediaType.image
                        ? Icons.image
                        : Icons.insert_drive_file,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    media.type == MediaType.image ? 'Image' : 'Document',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      width: 180,
      height: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: GestureDetector(
        onTap: _showAddMediaOptions,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              'Add More',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(MediaItem media) {
    if (kIsWeb && media.fileBytes != null) {
      return Image.memory(media.fileBytes!, fit: BoxFit.cover);
    }
    if (media.file != null) {
      return Image.file(media.file!, fit: BoxFit.cover);
    }
    return Container(color: Colors.grey, child: const Icon(Icons.broken_image));
  }

  Widget _buildDocumentPreview(MediaItem media) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 48, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              media.fileName?.split('/').last ?? 'Document',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionInput(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          maxLines: 4,
          style: const TextStyle(fontSize: 15, height: 1.4),
          decoration: InputDecoration(
            hintText: 'Write a caption...',
            hintStyle: AppTheme.greyTextStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: AppColors.greyColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hashtags',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hashtagController,
          onSubmitted: _addHashtag,
          decoration: InputDecoration(
            hintText: 'Add hashtags (press Enter to add)',
            hintStyle: AppTheme.greyTextStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: AppColors.greyColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (_hashtags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hashtags.map((tag) => _buildHashtagChip(tag)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildHashtagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("#$tag",
              style: const TextStyle(color: AppColors.primary, fontSize: 13)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _hashtags.remove(tag)),
            child: Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: AppColors.greyColor),
              const SizedBox(width: 12),
              Text(
                'Private post',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          Switch(
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPostButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasContent && !_isSubmitting ? _submitPost : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Share Post',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showAddMediaOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                )),
            const SizedBox(height: 16),
            _buildBottomSheetOption(Icons.photo_library, 'Image from Gallery',
                () => _pickMedia(MediaType.image, ImageSource.gallery)),
            _buildBottomSheetOption(Icons.camera_alt, 'Take Photo',
                () => _pickMedia(MediaType.image, ImageSource.camera)),
            _buildBottomSheetOption(Icons.videocam, 'Video',
                () => _pickMedia(MediaType.video, ImageSource.gallery)),
            _buildBottomSheetOption(
                Icons.picture_as_pdf, 'Document', _pickDocument),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(
      IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 24, color: AppColors.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _pickMedia(MediaType type, ImageSource source) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      if (type == MediaType.image) {
        pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      } else {
        pickedFile = await picker.pickVideo(source: source);
      }

      if (pickedFile != null) {
        setState(() {
          _mediaItems.add(MediaItem(
            file: File(pickedFile!.path),
            type: type,
          ));
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick media: $e', isError: true);
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx'
        ],
      );

      if (result != null) {
        setState(() {
          _mediaItems.add(MediaItem(
            file: File(result.files.single.path!),
            type: MediaType.document,
            fileName: result.files.single.name,
          ));
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick document: $e', isError: true);
    }
  }

  void _removeMedia(int index) {
    setState(() => _mediaItems.removeAt(index));
  }

  void _addHashtag(String tag) {
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() {
        _hashtags.add(tag.replaceAll('#', '').trim().toLowerCase());
        _hashtagController.clear();
      });
    }
  }

  Future<void> _submitPost() async {
    setState(() => _isSubmitting = true);

    try {
      List<Attachment> attachments = [];

      for (final media in _mediaItems) {
        if (media.file != null) {
          String? url;

          if (media.type == MediaType.image) {
            url = await _cloudinaryService.uploadImage(media.file!);
          } else if (media.type == MediaType.video) {
            url = await _cloudinaryService.uploadVideo(media.file!);
          } else if (media.type == MediaType.document) {
            url = await _cloudinaryService.uploadDocument(
                media.file!, media.fileName ?? 'document');
          }

          if (url != null) {
            attachments.add(Attachment(
              type: media.type == MediaType.image
                  ? 'image'
                  : media.type == MediaType.video
                      ? 'video'
                      : 'document',
              url: url,
            ));
          }
        }
      }

      String content = _captionController.text.trim();
      if (_hashtags.isNotEmpty) {
        if (content.isNotEmpty) content += '\n\n';
        content += _hashtags.map((h) => '#$h').join(' ');
      }

      context.read<FeedBloc>().add(CreateFeedPost(
            content: content,
            attachments: attachments.isNotEmpty
                ? attachments.map((a) => a.toJson()).toList()
                : null,
          ));

      _showSnackBar('Post created successfully!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

enum MediaType { image, video, document }

class MediaItem {
  final File? file;
  final Uint8List? fileBytes;
  final String? fileName;
  final MediaType type;

  MediaItem({
    this.file,
    this.fileBytes,
    this.fileName,
    required this.type,
  });
}

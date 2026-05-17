import 'dart:io';
import 'package:Prive/bloc/home/feed_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:Prive/core/cloudinary_service.dart';
import 'package:Prive/data/models/feeds_models.dart';

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

  VideoPlayerController? _videoController;
  int _currentMediaIndex = 0;

  bool _isPrivate = false;
  bool _isSubmitting = false;

  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDarkMode ? AppColors.darkBackground : AppColors.backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaSection(),
                  const SizedBox(height: 24),
                  _buildCaptionInput(),
                  const SizedBox(height: 24),
                  _buildHashtagSection(),
                  const SizedBox(height: 24),
                  _buildOptionsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
        'New Post',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed:
                (_isSubmitting || _mediaItems.isEmpty) ? null : _submitPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(60, 40),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Share",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    if (_mediaItems.isEmpty) {
      return _buildEmptyMediaGrid();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 400,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: _mediaItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentMediaIndex = index;
                    _initializeVideoForIndex(index);
                  });
                },
                itemBuilder: (context, index) {
                  final media = _mediaItems[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: media.type == MediaType.image
                        ? _buildImagePreview(media)
                        : _buildVideoPreview(media),
                  );
                },
              ),
              if (_mediaItems.length > 1) _buildPageIndicator(),
              _buildMediaActionButton(
                top: true,
                icon: Icons.close,
                onTap: _deleteCurrentMedia,
              ),
              _buildMediaActionButton(
                bottom: true,
                icon: Icons.add,
                onTap: _showAddMediaOptions,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(MediaItem media) {
    if (kIsWeb && media.fileBytes != null) {
      return Image.memory(
        media.fileBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (media.file != null) {
      return Image.file(
        media.file!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    return Container(
      color: Colors.grey,
      child: const Center(child: Text('No image')),
    );
  }

  Widget _buildVideoPreview(MediaItem media) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_videoController!),
        Positioned.fill(
          child: InkWell(
            onTap: _toggleVideoPlayback,
          ),
        ),
        if (!_videoController!.value.isPlaying)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _mediaItems.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentMediaIndex == index
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool top = false,
    bool bottom = false,
  }) {
    return Positioned(
      top: top ? 16 : null,
      bottom: bottom ? 16 : null,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyMediaGrid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _showAddMediaOptions,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.greyColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppColors.greyColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Add photos or videos',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to select',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.greyColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.greyColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
          Text(
            "#$tag",
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _hashtags.remove(tag)),
            child: Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
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

  void _showAddMediaOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildBottomSheetOption(
              icon: Icons.photo_library,
              title: 'Choose from gallery',
              onTap: () => _pickMedia(ImageSource.gallery, MediaType.image),
            ),
            _buildBottomSheetOption(
              icon: Icons.camera_alt,
              title: 'Take photo',
              onTap: () => _pickMedia(ImageSource.camera, MediaType.image),
            ),
            _buildBottomSheetOption(
              icon: Icons.videocam,
              title: 'Record video',
              onTap: () => _pickMedia(ImageSource.camera, MediaType.video),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading:
          Icon(icon, size: 24, color: isDarkMode ? Colors.white : Colors.black),
      title: Text(title,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _pickMedia(ImageSource source, MediaType type) async {
    try {
      final picker = ImagePicker();
      XFile? pickedFile;

      if (type == MediaType.image) {
        pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      } else {
        pickedFile = await picker.pickVideo(source: source);
      }

      if (pickedFile == null) return;

      if (kIsWeb) {
        final fileBytes = await pickedFile.readAsBytes();
        setState(() {
          _mediaItems.add(MediaItem(
            fileBytes: fileBytes,
            fileName: pickedFile!.name,
            type: type,
          ));
        });
      } else {
        setState(() {
          _mediaItems.add(MediaItem(
            file: File(pickedFile!.path),
            type: type,
          ));
        });
      }

      if (type == MediaType.video && _mediaItems.length == 1) {
        _initializeVideoForIndex(0);
      }
    } catch (e) {
      _showSnackBar('Failed to pick media: $e', isError: true);
    }
  }

  void _deleteCurrentMedia() {
    setState(() {
      _videoController?.dispose();
      _mediaItems.removeAt(_currentMediaIndex);
      if (_mediaItems.isEmpty) {
        _videoController = null;
      } else {
        _currentMediaIndex =
            _currentMediaIndex.clamp(0, _mediaItems.length - 1);
        _initializeVideoForIndex(_currentMediaIndex);
      }
    });
  }

  void _addHashtag(String tag) {
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() {
        _hashtags.add(tag.replaceAll('#', '').trim().toLowerCase());
        _hashtagController.clear();
      });
    }
  }

  void _initializeVideoForIndex(int index) {
    final media = _mediaItems[index];
    if (media.type != MediaType.video) {
      _videoController?.pause();
      return;
    }

    _videoController?.dispose();
    final file = media.file;
    if (file != null) {
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        }).catchError((e) => debugPrint('Video init error: $e'));
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  Future<void> _submitPost() async {
    if (_mediaItems.isEmpty) {
      _showSnackBar('Please add at least one photo or video', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<Attachment> attachments = [];

      // Upload media if exists (optional)
      for (int i = 0; i < _mediaItems.length; i++) {
        final media = _mediaItems[i];
        final file = media.file;

        if (file != null) {
          String? url;

          if (media.type == MediaType.image) {
            url = await _cloudinaryService.uploadImage(file);
          } else if (media.type == MediaType.video) {
            url = await _cloudinaryService.uploadVideo(file);
          }

          if (url != null && url.isNotEmpty) {
            attachments.add(Attachment(
              type: media.type == MediaType.image ? 'image' : 'video',
              url: url,
            ));
          }
        }
      }

      // Build content with hashtags
      String content = _captionController.text.trim();
      if (_hashtags.isNotEmpty) {
        if (content.isNotEmpty) content += '\n\n';
        content += _hashtags.map((h) => '#$h').join(' ');
      }

      // Dispatch CreateFeedPost event to FeedBloc
      context.read<FeedBloc>().add(CreateFeedPost(
            content: content,
            attachments: attachments.isNotEmpty
                ? attachments.map((a) => a.toJson()).toList()
                : null,
          ));

      _showSnackBar('Post created successfully!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Error creating post: ${e.toString()}', isError: true);
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

enum MediaType { image, video }

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

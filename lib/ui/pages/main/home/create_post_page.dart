import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media_app/data/hooks/home/feed_hook.dart';

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
  bool _isVideoInitialized = false;
  int _currentMediaIndex = 0;

  bool _isPrivate = false;
  bool _isLoading = false;

  late final FeedHook _feedHook;

  @override
  void initState() {
    super.initState();
    _feedHook = FeedHook();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    for (var media in _mediaItems) {
      media.dispose();
    }
    _videoController?.dispose();
    _feedHook.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent =
        _captionController.text.isNotEmpty || _mediaItems.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
          _buildBottomBar(hasContent),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black, size: 24),
        onPressed: () {
          _videoController?.pause();
          Navigator.pop(context);
        },
      ),
      title: Text(
        'New Post',
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
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
                        ? Image.file(
                            media.file!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : _buildVideoPlayer(media),
                  );
                },
              ),
              if (_mediaItems.length > 1)
                Positioned(
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
                              ? AppColors.purpleColor
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _deleteCurrentMedia,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _showAddMediaOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmptyMediaGrid() {
    return GestureDetector(
      onTap: _showAddMediaOptions,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.greyColor.withOpacity(0.2),
            width: 1,
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

  void _showAddMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
            _buildSheetOption(
              icon: Icons.photo_library,
              title: 'Choose from gallery',
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, MediaType.image);
              },
            ),
            _buildSheetOption(
              icon: Icons.camera_alt,
              title: 'Take photo',
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.camera, MediaType.image);
              },
            ),
            _buildSheetOption(
              icon: Icons.videocam,
              title: 'Record video',
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.camera, MediaType.video);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  Widget _buildVideoPlayer(MediaItem media) {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.purpleColor),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_videoController!),
        Positioned.fill(
          child: InkWell(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
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

  void _initializeVideoForIndex(int index) {
    final media = _mediaItems[index];
    if (media.type == MediaType.video && media.file != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(media.file!)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
        }).catchError((error) {
          debugPrint('Error initializing video: $error');
        });
    } else {
      _videoController?.pause();
      _isVideoInitialized = false;
    }
  }

  Widget _buildCaptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.greyColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.purpleColor),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hashtags',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.greyColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.purpleColor),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (_hashtags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hashtags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purpleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "#$tag",
                            style: TextStyle(
                              color: AppColors.purpleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _hashtags.remove(tag)),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.purpleColor,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Switch(
            value: _isPrivate,
            onChanged: (value) {
              setState(() => _isPrivate = value);
            },
            activeColor: AppColors.purpleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool hasContent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.greyColor.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (hasContent && !_isLoading) ? _submitPost : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purpleColor,
              disabledBackgroundColor: AppColors.greyColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Share Post',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
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

      if (pickedFile != null) {
        setState(() {
          _mediaItems.add(MediaItem(
            file: File(pickedFile!.path),
            type: type,
          ));
          if (type == MediaType.video && _mediaItems.length == 1) {
            _initializeVideoForIndex(0);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  void _deleteCurrentMedia() {
    setState(() {
      _mediaItems.removeAt(_currentMediaIndex);
      if (_mediaItems.isEmpty) {
        _videoController?.dispose();
        _isVideoInitialized = false;
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

  void _submitPost() async {
    setState(() => _isLoading = true);

    try {
      // Get the first media item (if any)
      String? imageUrl;
      if (_mediaItems.isNotEmpty) {
        // For now, just use the file path - you'll need to upload to server first
        imageUrl = _mediaItems.first.file?.path;
      }

      // Combine caption and hashtags
      String content = _captionController.text;
      if (_hashtags.isNotEmpty) {
        content += '\n\n' + _hashtags.map((h) => '#$h').join(' ');
      }

      // Create post using FeedHook
      final success = await _feedHook.createPost(
        content: content,
        imageUrl: imageUrl,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

enum MediaType { image, video }

class MediaItem {
  final File? file;
  final MediaType type;

  MediaItem({
    this.file,
    required this.type,
  });

  void dispose() {}
}

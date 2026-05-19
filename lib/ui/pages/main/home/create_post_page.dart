import 'dart:io';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clique/core/cloudinary_service.dart';
import 'package:clique/data/models/feeds_models.dart';
import 'package:file_picker/file_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  final List<MediaItem> _mediaItems = [];
  final List<String> _hashtags = [];

  bool _isSubmitting = false;
  PostCreationStep _currentStep = PostCreationStep.options;

  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _currentStep == PostCreationStep.options
                ? () => Navigator.pop(context)
                : _goBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _currentStep == PostCreationStep.options
                    ? Icons.close
                    : Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Text(
            _getTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_currentStep != PostCreationStep.options)
            GestureDetector(
              onTap: _currentStep == PostCreationStep.textInput
                  ? _submitTextPost
                  : (_currentStep == PostCreationStep.mediaPreview
                      ? _submitPost
                      : null),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case PostCreationStep.options:
        return 'Create Post';
      case PostCreationStep.textInput:
        return 'Write Caption';
      case PostCreationStep.mediaPreview:
        return 'Preview';
      default:
        return 'Create Post';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case PostCreationStep.options:
        return _buildOptionsGrid();
      case PostCreationStep.textInput:
        return _buildTextInput();
      case PostCreationStep.mediaPreview:
        return _buildMediaPreview();
      default:
        return const SizedBox();
    }
  }

  void _goBack() {
    if (_currentStep == PostCreationStep.textInput) {
      setState(() => _currentStep = PostCreationStep.options);
    } else if (_currentStep == PostCreationStep.mediaPreview) {
      setState(() => _currentStep = PostCreationStep.options);
      _mediaItems.clear();
    }
  }

  // ==================== OPTIONS GRID ====================

  Widget _buildOptionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildOptionCard(
          icon: Icons.text_fields,
          title: 'Text Only',
          subtitle: 'Share your thoughts',
          color: Colors.orange,
          onTap: () =>
              setState(() => _currentStep = PostCreationStep.textInput),
        ),
        _buildOptionCard(
          icon: Icons.photo_library,
          title: 'Image',
          subtitle: 'Share a photo',
          color: Colors.purple,
          onTap: () => _pickMedia(MediaType.image, ImageSource.gallery),
        ),
        _buildOptionCard(
          icon: Icons.camera_alt,
          title: 'Camera',
          subtitle: 'Take a photo',
          color: Colors.blue,
          onTap: () => _pickMedia(MediaType.image, ImageSource.camera),
        ),
        _buildOptionCard(
          icon: Icons.videocam,
          title: 'Video',
          subtitle: 'Share a video',
          color: Colors.green,
          onTap: () => _pickMedia(MediaType.video, ImageSource.gallery),
        ),
        _buildOptionCard(
          icon: Icons.picture_as_pdf,
          title: 'Document',
          subtitle: 'Share a file',
          color: Colors.red,
          onTap: _pickDocument,
        ),
        _buildOptionCard(
          icon: Icons.music_note,
          title: 'Audio',
          subtitle: 'Coming soon',
          color: Colors.teal,
          onTap: () => _showComingSoon(),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TEXT INPUT (Clean, no border/background) ====================

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              autofocus: true,
              maxLines: null,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          _buildHashtagInput(),
        ],
      ),
    );
  }

  Widget _buildHashtagInput() {
    final TextEditingController hashtagController = TextEditingController();

    return Column(
      children: [
        TextField(
          controller: hashtagController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Add hashtags (press Enter)',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon:
                const Icon(Icons.tag, color: AppColors.primary, size: 20),
          ),
          onSubmitted: (tag) {
            if (tag.isNotEmpty) {
              setState(() {
                _hashtags.add(tag.replaceAll('#', '').trim().toLowerCase());
                hashtagController.clear();
              });
            }
          },
        ),
        if (_hashtags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hashtags.map((tag) => _buildHashtagChip(tag)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildHashtagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
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

  // ==================== MEDIA PREVIEW ====================

  Widget _buildMediaPreview() {
    if (_mediaItems.isEmpty) return const SizedBox();

    final media = _mediaItems.first;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: media.type == MediaType.image
                  ? _buildImagePreview(media)
                  : _buildDocumentPreview(media),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextInputForMedia(),
        const SizedBox(height: 16),
        _buildHashtagInputForMedia(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildImagePreview(MediaItem media) {
    if (kIsWeb && media.fileBytes != null) {
      return Image.memory(media.fileBytes!, height: 400, fit: BoxFit.contain);
    }
    if (media.file != null) {
      return Image.file(media.file!, height: 400, fit: BoxFit.contain);
    }
    return Container(color: Colors.grey, height: 400);
  }

  Widget _buildDocumentPreview(MediaItem media) {
    return Container(
      height: 300,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            media.fileName?.split('/').last ?? 'Document',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputForMedia() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _textController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Write a caption...',
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade900,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHashtagInputForMedia() {
    final TextEditingController hashtagController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: hashtagController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add hashtags',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade900,
              prefixIcon:
                  const Icon(Icons.tag, color: AppColors.primary, size: 18),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (tag) {
              if (tag.isNotEmpty) {
                setState(() {
                  _hashtags.add(tag.replaceAll('#', '').trim().toLowerCase());
                  hashtagController.clear();
                });
              }
            },
          ),
          if (_hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _hashtags.map((tag) => _buildHashtagChip(tag)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== MEDIA PICKING ====================

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
          _mediaItems.clear();
          _mediaItems.add(MediaItem(
            file: File(pickedFile!.path),
            type: type,
          ));
          _currentStep = PostCreationStep.mediaPreview;
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
          _mediaItems.clear();
          _mediaItems.add(MediaItem(
            file: File(result.files.single.path!),
            type: MediaType.document,
            fileName: result.files.single.name,
          ));
          _currentStep = PostCreationStep.mediaPreview;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick document: $e', isError: true);
    }
  }

  void _showComingSoon() {
    _showSnackBar('Audio posts coming soon!', isError: false);
  }

  // ==================== SUBMIT ====================

  Future<void> _submitTextPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty && _hashtags.isEmpty) {
      _showSnackBar('Please enter some text', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String finalContent = content;
      if (_hashtags.isNotEmpty) {
        if (finalContent.isNotEmpty) finalContent += '\n\n';
        finalContent += _hashtags.map((h) => '#$h').join(' ');
      }

      context.read<FeedBloc>().add(CreateFeedPost(
            content: finalContent,
            attachments: null,
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

  Future<void> _submitPost() async {
    if (_mediaItems.isEmpty) return;

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

      String content = _textController.text.trim();
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

enum PostCreationStep { options, textInput, mediaPreview }

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

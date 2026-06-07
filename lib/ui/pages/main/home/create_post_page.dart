import 'dart:io';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/media_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({
    super.key,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final MediaService _mediaService = MediaService();

  final List<MediaItem> _mediaItems = [];
  final List<String> _hashtags = [];

  bool _isSubmitting = false;
  bool _isPicking = false;
  double _uploadProgress = 0.0;

  PostCreationStep _currentStep = PostCreationStep.options;

  @override
  void initState() {
    super.initState();

    _textController.addListener(_onComposerChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onComposerChanged);
    _textController.dispose();
    _hashtagController.dispose();
    _cloudinaryService.cancelAllUploads();
    super.dispose();
  }

  void _onComposerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _hasMedia => _mediaItems.isNotEmpty;

  bool get _canSubmit {
    if (_isSubmitting || _isPicking) return false;

    final hasText = _textController.text.trim().isNotEmpty;
    final hasTags = _hashtags.isNotEmpty ||
        _extractHashtags(_hashtagController.text).isNotEmpty;

    if (_currentStep == PostCreationStep.textInput) {
      return hasText || hasTags;
    }

    if (_currentStep == PostCreationStep.mediaPreview) {
      return _hasMedia;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSubmitting) {
          _showSnackBar(
            'Post is uploading. Please wait.',
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(
                    title: _title,
                    isFirstStep: _currentStep == PostCreationStep.options,
                    isSubmitting: _isSubmitting,
                    canSubmit: _canSubmit,
                    onBack: _handleBack,
                    onSubmit: _handleSubmit,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildCurrentStep(),
                    ),
                  ),
                ],
              ),
              if (_isSubmitting) _UploadOverlay(progress: _uploadProgress),
            ],
          ),
        ),
      ),
    );
  }

  String get _title {
    switch (_currentStep) {
      case PostCreationStep.options:
        return 'Create Post';
      case PostCreationStep.textInput:
        return 'Write Post';
      case PostCreationStep.mediaPreview:
        return 'Preview';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case PostCreationStep.options:
        return _OptionsGrid(
          key: const ValueKey('options'),
          isPicking: _isPicking,
          onText: () {
            HapticFeedback.lightImpact();

            setState(() {
              _currentStep = PostCreationStep.textInput;
            });
          },
          onImage: () => _pickMedia(MediaType.image, ImageSource.gallery),
          onCamera: () => _pickMedia(MediaType.image, ImageSource.camera),
          onVideo: () => _pickMedia(MediaType.video, ImageSource.gallery),
          onAudio: _showComingSoon,
        );

      case PostCreationStep.textInput:
        return _TextPostComposer(
          key: const ValueKey('text_input'),
          textController: _textController,
          hashtagController: _hashtagController,
          hashtags: _hashtags,
          enabled: !_isSubmitting,
          onAddHashtag: _addHashtag,
          onRemoveHashtag: _removeHashtag,
        );

      case PostCreationStep.mediaPreview:
        return _MediaPostComposer(
          key: const ValueKey('media_preview'),
          mediaItems: _mediaItems,
          textController: _textController,
          hashtagController: _hashtagController,
          hashtags: _hashtags,
          enabled: !_isSubmitting,
          onAddHashtag: _addHashtag,
          onRemoveHashtag: _removeHashtag,
          onChangeMedia: _clearMediaAndGoBack,
        );
    }
  }

  void _handleBack() {
    if (_isSubmitting) return;

    if (_currentStep == PostCreationStep.options) {
      Navigator.pop(context);
      return;
    }

    if (_currentStep == PostCreationStep.textInput) {
      setState(() {
        _currentStep = PostCreationStep.options;
      });
      return;
    }

    if (_currentStep == PostCreationStep.mediaPreview) {
      _clearMediaAndGoBack();
    }
  }

  void _clearMediaAndGoBack() {
    setState(() {
      _mediaItems.clear();
      _currentStep = PostCreationStep.options;
      _uploadProgress = 0.0;
    });
  }

  void _handleSubmit() {
    if (!_canSubmit) return;

    if (_currentStep == PostCreationStep.textInput) {
      _submitTextPost();
      return;
    }

    if (_currentStep == PostCreationStep.mediaPreview) {
      _submitMediaPost();
    }
  }

  void _addHashtag(String rawTag) {
    final tags = _extractHashtags(rawTag)
        .where((tag) => !_hashtags.contains(tag))
        .toList();

    if (tags.isEmpty) {
      _hashtagController.clear();
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _hashtags.addAll(tags);
      _hashtagController.clear();
    });
  }

  void _removeHashtag(String tag) {
    HapticFeedback.selectionClick();

    setState(() {
      _hashtags.remove(tag);
    });
  }

  String _contentWithHashtags() {
    String content = _textController.text.trim();
    final tags = <String>[
      ..._hashtags,
      ..._extractHashtags(_hashtagController.text),
    ];
    final uniqueTags = _dedupeTags(tags);

    if (uniqueTags.isNotEmpty) {
      if (content.isNotEmpty) {
        content += '\n\n';
      }

      content += uniqueTags.map((tag) => '#$tag').join(' ');
    }

    return content;
  }

  List<String> _extractHashtags(String rawValue) {
    return rawValue
        .split(RegExp(r'[\s,]+'))
        .map((tag) => tag.replaceAll('#', '').trim().toLowerCase())
        .where((tag) => RegExp(r'^[a-z0-9_]+$').hasMatch(tag))
        .toList();
  }

  List<String> _dedupeTags(Iterable<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in tags) {
      if (seen.add(tag)) result.add(tag);
    }
    return result;
  }

  Future<void> _pickMedia(
    MediaType type,
    ImageSource source,
  ) async {
    if (_isPicking || _isSubmitting) return;

    setState(() {
      _isPicking = true;
    });

    try {
      if (type == MediaType.image) {
        if (source == ImageSource.gallery) {
          final pickedFiles = await _imagePicker.pickMultiImage(
            imageQuality: 85,
            maxWidth: 1800,
          );

          if (pickedFiles.isEmpty) return;

          final selectedFiles = pickedFiles.take(4).toList();
          final items = <MediaItem>[];

          for (final pickedFile in selectedFiles) {
            final croppedFile = await _mediaService.cropImage(pickedFile);
            if (croppedFile == null) continue;

            final bytes = kIsWeb ? await croppedFile.readAsBytes() : null;
            items.add(
              MediaItem(
                file: kIsWeb ? null : File(croppedFile.path),
                fileBytes: bytes,
                fileName: croppedFile.name,
                type: type,
              ),
            );
          }

          if (items.isEmpty) return;

          if (!mounted) return;

          setState(() {
            _mediaItems
              ..clear()
              ..addAll(items);

            _currentStep = PostCreationStep.mediaPreview;
          });
          return;
        }

        final pickedFile = await _imagePicker.pickImage(
            source: source, imageQuality: 85, maxWidth: 1800);

        if (pickedFile == null) return;

        final croppedFile = await _mediaService.cropImage(pickedFile);
        if (croppedFile == null) return;

        final bytes = kIsWeb ? await croppedFile.readAsBytes() : null;

        if (!mounted) return;

        setState(() {
          _mediaItems
            ..clear()
            ..add(
              MediaItem(
                file: kIsWeb ? null : File(croppedFile.path),
                fileBytes: bytes,
                fileName: croppedFile.name,
                type: type,
              ),
            );

          _currentStep = PostCreationStep.mediaPreview;
        });
      } else {
        final pickedFile = await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2),
        );

        if (pickedFile == null) return;

        final bytes = kIsWeb ? await pickedFile.readAsBytes() : null;

        if (!mounted) return;

        setState(() {
          _mediaItems
            ..clear()
            ..add(
              MediaItem(
                file: kIsWeb ? null : File(pickedFile.path),
                fileBytes: bytes,
                fileName: pickedFile.name,
                type: type,
              ),
            );

          _currentStep = PostCreationStep.mediaPreview;
        });
      }
    } catch (e) {
      _showSnackBar(
        'Failed to pick media: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  void _showComingSoon() {
    _showSnackBar('Audio posts coming soon');
  }

  Future<void> _submitTextPost() async {
    final content = _contentWithHashtags();

    if (content.trim().isEmpty) {
      _showSnackBar(
        'Please enter some text',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      context.read<FeedBloc>().add(
            CreateFeedPost(
              content: content,
              attachments: null,
            ),
          );

      _showSnackBar('Post created successfully');

      await Future<void>.delayed(
        const Duration(milliseconds: 450),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(
        'Error: $e',
        isError: true,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitMediaPost() async {
    if (_mediaItems.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (kIsWeb || _mediaItems.any((media) => media.file == null)) {
      _showSnackBar(
        'Media upload is only supported for local files right now.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      final attachments = <Attachment>[];

      for (final media in _mediaItems.take(4)) {
        final attachment = await _uploadMedia(media);
        if (attachment != null) {
          attachments.add(attachment);
        }
      }

      if (!mounted) return;

      final content = _contentWithHashtags();

      context.read<FeedBloc>().add(
            CreateFeedPost(
              content: content,
              attachments: attachments.isNotEmpty
                  ? attachments.map((item) => item.toJson()).toList()
                  : null,
            ),
          );

      _showSnackBar('Post created successfully');

      await Future<void>.delayed(
        const Duration(milliseconds: 450),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(
        'Error: $e',
        isError: true,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<Attachment?> _uploadMedia(MediaItem media) async {
    final file = media.file;

    if (file == null) return null;

    String? url;

    if (media.type == MediaType.image) {
      url = await _cloudinaryService.uploadImage(
        file,
        onProgress: _onUploadProgress,
      );
    } else if (media.type == MediaType.video) {
      url = await _cloudinaryService.uploadVideo(
        file,
        onProgress: _onUploadProgress,
      );
    }

    if (url == null || url.isEmpty) return null;

    return Attachment(
      type: media.type.name,
      url: url,
    );
  }

  void _onUploadProgress(double progress) {
    if (!mounted) return;

    setState(() {
      _uploadProgress = progress.clamp(0.0, 1.0);
    });
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final bool isFirstStep;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _Header({
    required this.title,
    required this.isFirstStep,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _CircleButton(
            icon: isFirstStep ? Icons.close : Icons.arrow_back,
            onTap: onBack,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isFirstStep ? 0 : 1,
            child: IgnorePointer(
              ignoring: isFirstStep,
              child: GestureDetector(
                onTap: canSubmit ? onSubmit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: canSubmit
                        ? AppColors.primary
                        : AppColors.dynamicBorder.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            'Post',
                            style: TextStyle(
                              color: canSubmit
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: AppColors.blackTextColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _OptionsGrid extends StatelessWidget {
  final bool isPicking;
  final VoidCallback onText;
  final VoidCallback onImage;
  final VoidCallback onCamera;
  final VoidCallback onVideo;
  final VoidCallback onAudio;

  const _OptionsGrid({
    super.key,
    required this.isPicking,
    required this.onText,
    required this.onImage,
    required this.onCamera,
    required this.onVideo,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _PostOption(
        icon: Icons.text_fields_rounded,
        title: 'Write',
        subtitle: 'Start with text',
        color: AppColors.orange,
        onTap: onText,
      ),
      _PostOption(
        icon: Icons.photo_library_rounded,
        title: 'Image',
        subtitle: 'Choose a photo',
        color: AppColors.purple,
        onTap: onImage,
      ),
      _PostOption(
        icon: Icons.camera_alt_rounded,
        title: 'Camera',
        subtitle: 'Take a photo',
        color: AppColors.blue,
        onTap: onCamera,
      ),
      _PostOption(
        icon: Icons.videocam_rounded,
        title: 'Video',
        subtitle: 'Share a video',
        color: AppColors.green,
        onTap: onVideo,
      ),
      _PostOption(
        icon: Icons.music_note_rounded,
        title: 'Audio',
        subtitle: 'Coming soon',
        color: AppColors.teal,
        onTap: onAudio,
      ),
    ];

    final primaryOptions = options.take(4).toList();
    final secondaryOptions = options.skip(4).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            _ComposerPromptCard(onTap: onText),
            const SizedBox(height: 18),
            Text(
              'Add media',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: primaryOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.32,
              ),
              itemBuilder: (context, index) {
                return _OptionCard(option: primaryOptions[index]);
              },
            ),
            const SizedBox(height: 12),
            ...secondaryOptions.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionListTile(option: option),
              ),
            ),
          ],
        ),
        if (isPicking)
          Positioned.fill(
            child: Container(
              color: AppColors.black.withOpacity(0.45),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final _PostOption option;

  const _OptionCard({
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          option.onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cardBorderColor,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  option.icon,
                  color: option.color,
                  size: 25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                option.title,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                option.subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerPromptCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ComposerPromptCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowElevated,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's happening?",
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share a thought, photo, or video.',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionListTile extends StatelessWidget {
  final _PostOption option;

  const _OptionListTile({
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          option.onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(option.icon, color: option.color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextPostComposer extends StatelessWidget {
  final TextEditingController textController;
  final TextEditingController hashtagController;
  final List<String> hashtags;
  final bool enabled;
  final ValueChanged<String> onAddHashtag;
  final ValueChanged<String> onRemoveHashtag;

  const _TextPostComposer({
    super.key,
    required this.textController,
    required this.hashtagController,
    required this.hashtags,
    required this.enabled,
    required this.onAddHashtag,
    required this.onRemoveHashtag,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorderColor),
              ),
              child: TextField(
                controller: textController,
                enabled: enabled,
                autofocus: true,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 20,
                  height: 1.38,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: AppTheme.greyTextStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _HashtagInput(
            controller: hashtagController,
            hashtags: hashtags,
            enabled: enabled,
            compact: false,
            onAddHashtag: onAddHashtag,
            onRemoveHashtag: onRemoveHashtag,
          ),
        ],
      ),
    );
  }
}

class _MediaPostComposer extends StatelessWidget {
  final List<MediaItem> mediaItems;
  final TextEditingController textController;
  final TextEditingController hashtagController;
  final List<String> hashtags;
  final bool enabled;
  final ValueChanged<String> onAddHashtag;
  final ValueChanged<String> onRemoveHashtag;
  final VoidCallback onChangeMedia;

  const _MediaPostComposer({
    super.key,
    required this.mediaItems,
    required this.textController,
    required this.hashtagController,
    required this.hashtags,
    required this.enabled,
    required this.onAddHashtag,
    required this.onRemoveHashtag,
    required this.onChangeMedia,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MediaPreview(
            mediaItems: mediaItems,
            onChangeMedia: onChangeMedia,
          ),
          const SizedBox(height: 18),
          _CaptionInput(
            controller: textController,
            enabled: enabled,
          ),
          const SizedBox(height: 14),
          _HashtagInput(
            controller: hashtagController,
            hashtags: hashtags,
            enabled: enabled,
            compact: true,
            onAddHashtag: onAddHashtag,
            onRemoveHashtag: onRemoveHashtag,
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final List<MediaItem> mediaItems;
  final VoidCallback onChangeMedia;

  const _MediaPreview({
    required this.mediaItems,
    required this.onChangeMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 460,
        minHeight: 260,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cardBorderColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildPreviewContent(),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: AppColors.black.withOpacity(0.58),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onChangeMedia,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final media = mediaItems.first;

    if (mediaItems.length > 1 &&
        mediaItems.every((item) => item.type == MediaType.image)) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mediaItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final item = mediaItems[index];

          if (kIsWeb && item.fileBytes != null) {
            return Image.memory(item.fileBytes!, fit: BoxFit.cover);
          }

          if (item.file != null) {
            return Image.file(item.file!, fit: BoxFit.cover);
          }

          return const SizedBox.shrink();
        },
      );
    }

    if (media.type == MediaType.image) {
      if (kIsWeb && media.fileBytes != null) {
        return Image.memory(
          media.fileBytes!,
          fit: BoxFit.contain,
        );
      }

      if (media.file != null) {
        return Image.file(
          media.file!,
          fit: BoxFit.contain,
        );
      }
    }

    if (media.type == MediaType.video) {
      return _LargeFilePreview(
        icon: Icons.play_circle_fill_rounded,
        title: media.fileName ?? 'Selected video',
        subtitle: 'Video will be uploaded with your post',
      );
    }

    return const SizedBox.shrink();
  }
}

class _LargeFilePreview extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LargeFilePreview({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 76,
              ),
              const SizedBox(height: 18),
              Text(
                title.split('/').last,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _CaptionInput({
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cardBorderColor,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: 4,
        minLines: 2,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 15,
          height: 1.35,
        ),
        decoration: InputDecoration(
          hintText: 'Write a caption...',
          hintStyle: AppTheme.greyTextStyle.copyWith(
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class _HashtagInput extends StatelessWidget {
  final TextEditingController controller;
  final List<String> hashtags;
  final bool enabled;
  final bool compact;
  final ValueChanged<String> onAddHashtag;
  final ValueChanged<String> onRemoveHashtag;

  const _HashtagInput({
    required this.controller,
    required this.hashtags,
    required this.enabled,
    required this.compact,
    required this.onAddHashtag,
    required this.onRemoveHashtag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: compact
              ? BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.cardBorderColor,
                  ),
                )
              : BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.cardBorderColor,
                  ),
                ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 15,
            ),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Add hashtags',
              hintStyle: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.tag_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: onAddHashtag,
          ),
        ),
        if (hashtags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hashtags.map((tag) {
                return _HashtagChip(
                  tag: tag,
                  onRemove: () => onRemoveHashtag(tag),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;

  const _HashtagChip({
    required this.tag,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadOverlay extends StatelessWidget {
  final double progress;

  const _UploadOverlay({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Positioned.fill(
      child: Container(
        color: AppColors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cardBorderColor,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Publishing post',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: progress <= 0 ? null : progress,
                  color: AppColors.primary,
                  backgroundColor: AppColors.dynamicBorder,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 12),
                Text(
                  progress <= 0 ? 'Preparing...' : '$percentage%',
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
}

class _PostOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PostOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

enum PostCreationStep {
  options,
  textInput,
  mediaPreview,
}

enum MediaType {
  image,
  video,
}

class MediaItem {
  final File? file;
  final Uint8List? fileBytes;
  final String? fileName;
  final MediaType type;

  const MediaItem({
    this.file,
    this.fileBytes,
    this.fileName,
    required this.type,
  });
}

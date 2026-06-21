import 'dart:async';
import 'dart:io';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/media_service.dart';
import 'package:clique/core/services/tagging/tagging_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/core/models/create_post_models.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clique/ui/widgets/home/create-post/create_post_options_view.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';
part '../../../widgets/home/create-post/create_post_page_header.dart';
part '../../../widgets/home/create-post/create_post_composer.dart';
part '../../../widgets/home/create-post/create_post_upload_overlay.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({
    super.key,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController =
      HighlightTokenTextEditingController();
  final TextEditingController _hashtagController =
      HighlightTokenTextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final MediaService _mediaService = MediaService();
  final UserService _userService = UserService();
  final TaggingService _taggingService = TaggingService();

  final List<MediaItem> _mediaItems = [];
  final List<String> _hashtags = [];
  final List<String> _trendingHashtags = const [
    'technology',
    'flutter',
    'design',
    'startups',
    'business',
    'gaming',
    'movies',
    'sports',
    'music',
    'fitness',
  ];

  PostComposerType _postType = PostComposerType.post;
  String _anonymousCategory = 'confession';
  int _pollExpirationHours = 24;

  bool _isSubmitting = false;
  bool _isPicking = false;
  double _uploadProgress = 0.0;

  PostCreationStep _currentStep = PostCreationStep.options;

  @override
  void initState() {
    super.initState();

    _textController.addListener(_onComposerChanged);
    for (final controller in _pollOptionControllers) {
      controller.addListener(_onComposerChanged);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onComposerChanged);
    _textController.dispose();
    _hashtagController.dispose();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
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
      if (_postType == PostComposerType.poll) {
        return _textController.text.trim().isNotEmpty &&
            _pollOptions.length >= 2;
      }
      return hasText || hasTags;
    }

    if (_currentStep == PostCreationStep.mediaPreview) {
      return _hasMedia;
    }

    return false;
  }

  List<String> get _pollOptions => _pollOptionControllers
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList();

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
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -70,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.12),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.10),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
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
    if (_currentStep == PostCreationStep.options) {
      return 'Create Content';
    }

    if (_currentStep == PostCreationStep.mediaPreview) {
      return 'Preview';
    }

    return switch (_postType) {
      PostComposerType.post => 'Write Post',
      PostComposerType.poll => 'Create Poll',
      PostComposerType.question => 'Create Question',
      PostComposerType.anonymous => 'Anonymous Post',
    };
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case PostCreationStep.options:
        return CreatePostOptionsView(
          key: const ValueKey('options'),
          isPicking: _isPicking,
          currentType: _postType,
          onTypeSelected: (type) {
            HapticFeedback.lightImpact();
            setState(() {
              _postType = type;
              if (_postType != PostComposerType.anonymous) {
                _anonymousCategory = 'confession';
              }
              _currentStep = PostCreationStep.textInput;
            });
          },
          onAnonymousSelected: () {
            HapticFeedback.lightImpact();
            setState(() {
              _postType = PostComposerType.anonymous;
              _anonymousCategory = 'confession';
              _currentStep = PostCreationStep.textInput;
            });
          },
          onQuestionSelected: () {
            HapticFeedback.lightImpact();
            setState(() {
              _postType = PostComposerType.question;
              _currentStep = PostCreationStep.textInput;
            });
          },
          onPollSelected: () {
            HapticFeedback.lightImpact();
            setState(() {
              _postType = PostComposerType.poll;
              _currentStep = PostCreationStep.textInput;
            });
          },
          onImage: () => _pickMedia(MediaType.image, ImageSource.gallery),
          onReels: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, NamedRoutes.createReelScreen);
          },
          onCamera: () => _pickMedia(MediaType.image, ImageSource.camera),
          onVideo: () => _pickMedia(MediaType.video, ImageSource.gallery),
          onAudio: _showComingSoon,
        );

      case PostCreationStep.textInput:
        return _TextPostComposer(
          key: const ValueKey('text_input'),
          postType: _postType,
          anonymousCategory: _anonymousCategory,
          textController: _textController,
          hashtagController: _hashtagController,
          hashtags: _hashtags,
          enabled: !_isSubmitting,
          onPostTypeChanged: _setComposerType,
          onAnonymousCategoryChanged: _setAnonymousCategory,
          onAddHashtag: _addHashtag,
          onRemoveHashtag: _removeHashtag,
          suggestionsBuilder: _suggestTokens,
          pollOptionControllers: _pollOptionControllers,
          pollExpirationHours: _pollExpirationHours,
          onPollExpirationHoursChanged: (hours) =>
              setState(() => _pollExpirationHours = hours),
          onAddPollOption: _addPollOption,
          onRemovePollOption: _removePollOption,
        );

      case PostCreationStep.mediaPreview:
        return _MediaPostComposer(
          key: const ValueKey('media_preview'),
          postType: _postType,
          anonymousCategory: _anonymousCategory,
          mediaItems: _mediaItems,
          textController: _textController,
          hashtagController: _hashtagController,
          hashtags: _hashtags,
          enabled: !_isSubmitting,
          onPostTypeChanged: _setComposerType,
          onAnonymousCategoryChanged: _setAnonymousCategory,
          onAddHashtag: _addHashtag,
          onRemoveHashtag: _removeHashtag,
          onChangeMedia: _clearMediaAndGoBack,
          suggestionsBuilder: _suggestTokens,
          pollOptionControllers: _pollOptionControllers,
          pollExpirationHours: _pollExpirationHours,
          onPollExpirationHoursChanged: (hours) =>
              setState(() => _pollExpirationHours = hours),
          onAddPollOption: _addPollOption,
          onRemovePollOption: _removePollOption,
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

  void _setComposerType(PostComposerType nextType) {
    if (_postType == nextType) return;

    setState(() {
      _postType = nextType;
      if (_postType != PostComposerType.anonymous) {
        _anonymousCategory = 'confession';
      }
    });
  }

  void _setAnonymousCategory(String category) {
    setState(() {
      _anonymousCategory = category;
    });
  }

  void _addPollOption() {
    setState(() {
      _pollOptionControllers.add(TextEditingController());
    });
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length <= 2) return;

    setState(() {
      _pollOptionControllers[index].dispose();
      _pollOptionControllers.removeAt(index);
    });
  }

  Future<List<ComposerTokenSuggestion>> _suggestTokens(
    ComposerTokenType type,
    String query,
  ) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (type == ComposerTokenType.mention) {
      if (normalizedQuery.isEmpty) {
        return const [];
      }

      try {
        final users = await _userService.searchUsers(
          normalizedQuery,
          limit: 8,
        );

        return users
            .map(
              (user) => ComposerTokenSuggestion(
                value: _readSuggestionValue(user),
                label: _readSuggestionLabel(user),
                subtitle: _readSuggestionSubtitle(user),
              ),
            )
            .where((suggestion) => suggestion.value.isNotEmpty)
            .toList();
      } catch (_) {
        return const [];
      }
    }

    final sourceTags = <String>{
      ..._trendingHashtags,
      ..._hashtags,
      ..._extractHashtags(_hashtagController.text),
    };

    final results = sourceTags
        .where((tag) => tag.toLowerCase().contains(normalizedQuery))
        .take(8)
        .map(
          (tag) => ComposerTokenSuggestion(
            value: tag,
            label: '#$tag',
            subtitle: 'Hashtag',
          ),
        )
        .toList();

    if (results.isNotEmpty) return results;

    if (normalizedQuery.isEmpty) {
      return _trendingHashtags
          .take(8)
          .map(
            (tag) => ComposerTokenSuggestion(
              value: tag,
              label: '#$tag',
              subtitle: 'Popular topic',
            ),
          )
          .toList();
    }

    return [
      ComposerTokenSuggestion(
        value: normalizedQuery.replaceAll(RegExp(r'[^a-z0-9_]+'), ''),
        label: '#$normalizedQuery',
        subtitle: 'Create new hashtag',
      ),
    ];
  }

  String _readSuggestionValue(Map<String, dynamic> user) {
    final username = user['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;
    final name = user['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name.replaceAll(' ', '_');
    return user['id']?.toString().trim() ?? '';
  }

  String _readSuggestionLabel(Map<String, dynamic> user) {
    final name = user['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final username = user['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return '@$username';
    return 'User';
  }

  String? _readSuggestionSubtitle(Map<String, dynamic> user) {
    final username = user['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return '@$username';
    return null;
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
            final croppedFile = await _mediaService.cropImage(
              pickedFile,
              context: context,
            );
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

        final croppedFile = await _mediaService.cropImage(
          pickedFile,
          context: context,
        );
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
      final feedBloc = context.read<FeedBloc>();
      final initialPostIds =
          feedBloc.state.posts.map((post) => post.id).toSet();

      feedBloc.add(
        CreateFeedPost(
          content: content,
          attachments: null,
          postType: _postType.apiValue,
          isAnonymous: _postType == PostComposerType.anonymous,
          anonymousCategory: _postType == PostComposerType.anonymous
              ? _anonymousCategory
              : null,
          pollOptions: _postType == PostComposerType.poll ? _pollOptions : null,
          pollExpirationHours:
              _postType == PostComposerType.poll ? _pollExpirationHours : null,
        ),
      );

      final createdPost = await _waitForPostCreation(
        feedBloc,
        initialPostIds,
      );

      if (createdPost == null) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      unawaited(_syncUserTags('post', createdPost.id, content));

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
      final feedBloc = context.read<FeedBloc>();
      final initialPostIds =
          feedBloc.state.posts.map((post) => post.id).toSet();

      feedBloc.add(
        CreateFeedPost(
          content: content,
          attachments: attachments.isNotEmpty
              ? attachments.map((item) => item.toJson()).toList()
              : null,
          postType: _postType.apiValue,
          isAnonymous: _postType == PostComposerType.anonymous,
          anonymousCategory: _postType == PostComposerType.anonymous
              ? _anonymousCategory
              : null,
          pollOptions: _postType == PostComposerType.poll ? _pollOptions : null,
          pollExpirationHours:
              _postType == PostComposerType.poll ? _pollExpirationHours : null,
        ),
      );

      final createdPost = await _waitForPostCreation(
        feedBloc,
        initialPostIds,
      );

      if (createdPost == null) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
        return;
      }

      unawaited(_syncUserTags('post', createdPost.id, content));

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

  Future<FeedPost?> _waitForPostCreation(
    FeedBloc feedBloc,
    Set<int> initialPostIds,
  ) async {
    final completedState = await feedBloc.stream.firstWhere(
      (state) => !state.isCreatingPost,
    );

    if (!mounted) return null;

    if (completedState.generalError != null) {
      _showSnackBar(
        completedState.generalError!,
        isError: true,
      );
      return null;
    }

    final newPosts = completedState.posts
        .where((post) => !initialPostIds.contains(post.id))
        .toList();

    if (newPosts.isEmpty) {
      _showSnackBar(
        'Post created, but the feed did not update.',
        isError: true,
      );
      return null;
    }

    return newPosts.first;
  }

  Future<void> _syncUserTags(
    String contentType,
    int contentId,
    String content,
  ) async {
    final usernames = _extractMentions(content);
    if (usernames.isEmpty) return;

    try {
      await _taggingService.syncUserTags(
        contentType: contentType,
        contentId: contentId,
        usernames: usernames,
      );
    } catch (e) {
      debugPrint('User tag sync skipped: $e');
    }
  }

  List<String> _extractMentions(String rawValue) {
    final seen = <String>{};
    return RegExp(r'@([A-Za-z0-9_]+)')
        .allMatches(rawValue)
        .map((match) => match.group(1)?.toLowerCase() ?? '')
        .where((username) => username.isNotEmpty && seen.add(username))
        .toList();
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
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

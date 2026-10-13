import 'dart:async';
import 'dart:io';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/media_service.dart';
import 'package:clique/core/services/home/post_draft_service.dart';
import 'package:clique/core/services/tagging/tagging_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/core/models/create_post_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';
import 'package:clique/ui/pages/main/reels/create_reel_page.dart';

class CreatePostPage extends StatefulWidget {
  final Map<String, dynamic>? initialDraft;
  const CreatePostPage({super.key, this.initialDraft});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _textController =
      HighlightTokenTextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final MediaService _mediaService = MediaService();
  final UserService _userService = UserService();
  final TaggingService _taggingService = TaggingService();
  final PostDraftService _draftService = PostDraftService();

  final List<MediaItem> _mediaItems = [];
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
  Timer? _draftSaveTimer;
  late String _draftId;

  @override
  void initState() {
    super.initState();
    _draftId = widget.initialDraft?['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    _restoreDraft(widget.initialDraft);
    _textController.addListener(_onComposerChanged);
    for (final controller in _pollOptionControllers) {
      controller.addListener(_onComposerChanged);
    }
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    _textController.removeListener(_onComposerChanged);
    _textController.dispose();
    _composerFocusNode.dispose();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
    _cloudinaryService.cancelAllUploads();
    super.dispose();
  }

  void _onComposerChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleDraftSave();
  }

  void _restoreDraft(Map<String, dynamic>? draft) {
    if (draft == null) return;

    final restoredText = draft['text']?.toString() ?? '';
    final legacyTags = <String>{
      ...(draft['hashtags'] as List? ?? const []).map((tag) => '$tag'),
      ..._extractHashtags(draft['hashtagText']?.toString() ?? ''),
    };
    final missingTags = legacyTags
        .where((tag) =>
            !restoredText.toLowerCase().contains('#${tag.toLowerCase()}'))
        .map((tag) => '#$tag')
        .join(' ');
    _textController.text = missingTags.isEmpty
        ? restoredText
        : '${restoredText.trim()}${restoredText.trim().isEmpty ? '' : '\n\n'}$missingTags';
    _postType = PostComposerType.values.firstWhere(
      (type) => type.name == draft['postType']?.toString(),
      orElse: () => PostComposerType.post,
    );
    _anonymousCategory =
        draft['anonymousCategory']?.toString() ?? _anonymousCategory;
    _pollExpirationHours =
        int.tryParse(draft['pollExpirationHours']?.toString() ?? '') ??
            _pollExpirationHours;

    final pollOptions =
        (draft['pollOptions'] as List? ?? const []).map((e) => '$e').toList();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
    _pollOptionControllers
      ..clear()
      ..addAll(
        (pollOptions.length < 2 ? ['', ''] : pollOptions)
            .map((value) => TextEditingController(text: value)),
      );

    _mediaItems
      ..clear()
      ..addAll(PostDraftService.mediaItemsFromDraft(draft));
  }

  void _scheduleDraftSave() {
    if (_isSubmitting) return;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 450), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (_isSubmitting) return;

    final hasContent = _textController.text.trim().isNotEmpty ||
        _pollOptions.isNotEmpty ||
        _mediaItems.isNotEmpty;
    if (!hasContent) {
      await _draftService.deleteDraft(_draftId);
      return;
    }

    await _draftService.upsertDraft({
      'id': _draftId,
      'text': _textController.text,
      'postType': _postType.name,
      'anonymousCategory': _anonymousCategory,
      'pollExpirationHours': _pollExpirationHours,
      'pollOptions':
          _pollOptionControllers.map((controller) => controller.text).toList(),
      'mediaItems': _mediaItems
          .map((item) => {
                'path': item.file?.path,
                'fileName': item.fileName,
                'type': item.type.name,
              })
          .toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  bool get _hasMedia => _mediaItems.isNotEmpty;

  bool get _hasDraftContent =>
      _textController.text.trim().isNotEmpty ||
      _pollOptions.isNotEmpty ||
      _mediaItems.isNotEmpty;

  bool get _canSubmit {
    if (_isSubmitting || _isPicking) return false;

    final hasText = _textController.text.trim().isNotEmpty;

    if (_postType == PostComposerType.poll) {
      return _textController.text.trim().isNotEmpty && _pollOptions.length >= 2;
    }
    if (_postType == PostComposerType.question) {
      return hasText;
    }
    return hasText || _hasMedia;
  }

  List<String> get _pollOptions => _pollOptionControllers
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSubmitting) {
          _showSnackBar('Post is uploading. Please wait.', isError: true);
          return;
        }
        _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _Header(
                    canSubmit: _canSubmit,
                    isSubmitting: _isSubmitting,
                    onBack: _handleBack,
                    onSubmit: _handleSubmit,
                  ),
                  Expanded(
                    child: _ComposerSection(
                      postType: _postType,
                      anonymousCategory: _anonymousCategory,
                      textController: _textController,
                      composerFocusNode: _composerFocusNode,
                      mediaItems: _mediaItems,
                      pollOptionControllers: _pollOptionControllers,
                      pollExpirationHours: _pollExpirationHours,
                      enabled: !_isSubmitting && !_isPicking,
                      onPostTypeChanged: (type) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _postType = type;
                          if (type != PostComposerType.anonymous) {
                            _anonymousCategory = 'confession';
                          }
                        });
                      },
                      onCreateReel: _openReelComposer,
                      onAnonymousCategoryChanged: (cat) {
                        setState(() => _anonymousCategory = cat);
                      },
                      suggestionsBuilder: _suggestTokens,
                      onPollExpirationHoursChanged: (h) {
                        setState(() => _pollExpirationHours = h);
                      },
                      onAddPollOption: _addPollOption,
                      onRemovePollOption: _removePollOption,
                      onRemoveMedia: (index) {
                        setState(() {
                          _mediaItems.removeAt(index);
                        });
                      },
                    ),
                  ),
                  _ComposerToolbar(
                    enabled: !_isSubmitting && !_isPicking,
                    onPickImage: () =>
                        _pickMedia(MediaType.image, ImageSource.gallery),
                    onPickCamera: () =>
                        _pickMedia(MediaType.image, ImageSource.camera),
                    onPickVideo: () =>
                        _pickMedia(MediaType.video, ImageSource.gallery),
                    onAddHashtag: _insertHashtagToken,
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

  // --- Back & Draft Confirmation -------------------------------------------
  Future<void> _handleBack() async {
    if (_hasDraftContent) {
      await _confirmDraftExit();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDraftExit() async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Save draft?'),
          content:
              const Text('Keep this post draft or discard it before leaving.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'keep'),
              child: const Text('Keep draft'),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null || action == 'cancel') return;
    if (action == 'discard') {
      await _draftService.deleteDraft(_draftId);
    } else {
      await _saveDraft();
    }
    if (mounted) Navigator.pop(context);
  }

  // --- Submit Logic ----------------------------------------------------------
  void _handleSubmit() {
    if (!_canSubmit) return;
    if (_mediaItems.isNotEmpty) {
      _submitMediaPost();
    } else {
      _submitTextPost();
    }
  }

  void _insertHashtagToken() {
    if (_isSubmitting || _isPicking) return;

    final value = _textController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(start, value.text.length);
    final needsSpace = start > 0 &&
        !RegExp(r'\s').hasMatch(value.text.substring(start - 1, start));
    final insertion = needsSpace ? ' #' : '#';
    final updated = value.text.replaceRange(start, end, insertion);

    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );
    _composerFocusNode.requestFocus();
    HapticFeedback.selectionClick();
  }

  void _addPollOption() {
    final controller = TextEditingController()..addListener(_onComposerChanged);
    setState(() {
      _pollOptionControllers.add(controller);
    });
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length <= 2) return;
    setState(() {
      _pollOptionControllers[index].dispose();
      _pollOptionControllers.removeAt(index);
    });
  }

  // --- Token Suggestions ----------------------------------------------------
  Future<List<ComposerTokenSuggestion>> _suggestTokens(
    ComposerTokenType type,
    String query,
  ) async {
    final normalizedQuery = query.trim().toLowerCase();

    if (type == ComposerTokenType.mention) {
      if (normalizedQuery.isEmpty) return const [];

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
      ..._extractHashtags(_textController.text),
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

  // --- Content & Hashtags ---------------------------------------------------
  String _contentWithHashtags() {
    return _textController.text.trim();
  }

  List<String> _extractHashtags(String rawValue) {
    return rawValue
        .split(RegExp(r'[\s,]+'))
        .map((tag) => tag.replaceAll('#', '').trim().toLowerCase())
        .where((tag) => RegExp(r'^[a-z0-9_]+$').hasMatch(tag))
        .toList();
  }

  List<String> _extractMentions(String rawValue) {
    final seen = <String>{};
    return RegExp(r'@([A-Za-z0-9_]+)')
        .allMatches(rawValue)
        .map((match) => match.group(1)?.toLowerCase() ?? '')
        .where((username) => username.isNotEmpty && seen.add(username))
        .toList();
  }

  // --- Media Picking (now just adds to list, no step change) -----------------
  Future<void> _pickMedia(MediaType type, ImageSource source) async {
    if (_isPicking || _isSubmitting) return;

    setState(() => _isPicking = true);

    try {
      if (type == MediaType.image) {
        if (source == ImageSource.gallery) {
          final pickedFiles = await _imagePicker.pickMultiImage(
            imageQuality: 85,
            maxWidth: 1800,
          );
          if (pickedFiles.isEmpty) return;
          if (!mounted) return;

          final selectedFiles = pickedFiles.take(4).toList();
          for (final pickedFile in selectedFiles) {
            if (!mounted) return;
            final croppedFile = await _mediaService.cropImage(
              pickedFile,
              context: context,
            );
            if (croppedFile == null) continue;
            final bytes = kIsWeb ? await croppedFile.readAsBytes() : null;
            setState(() {
              _mediaItems.add(MediaItem(
                file: kIsWeb ? null : File(croppedFile.path),
                fileBytes: bytes,
                fileName: croppedFile.name,
                type: type,
              ));
            });
          }
        } else {
          final pickedFile = await _imagePicker.pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 1800,
          );
          if (pickedFile == null) return;
          if (!mounted) return;
          final croppedFile = await _mediaService.cropImage(
            pickedFile,
            context: context,
          );
          if (croppedFile == null) return;
          final bytes = kIsWeb ? await croppedFile.readAsBytes() : null;
          setState(() {
            _mediaItems.add(MediaItem(
              file: kIsWeb ? null : File(croppedFile.path),
              fileBytes: bytes,
              fileName: croppedFile.name,
              type: type,
            ));
          });
        }
      } else {
        final pickedFile = await _imagePicker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2),
        );
        if (pickedFile == null) return;
        if (!mounted) return;

        final bytes = kIsWeb ? await pickedFile.readAsBytes() : null;
        if (!mounted) return;
        setState(() {
          _mediaItems.add(
            MediaItem(
              file: kIsWeb ? null : File(pickedFile.path),
              fileBytes: bytes,
              fileName: pickedFile.name,
              type: type,
            ),
          );
        });
      }
      _scheduleDraftSave();
    } catch (e) {
      _showSnackBar('Failed to pick media: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _openReelComposer() async {
    if (kIsWeb) {
      _showSnackBar(
        'Posting this video as a reel is not available on web yet.',
        isError: true,
      );
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'create_reel_from_post_composer'),
        builder: (_) => BlocProvider(
          create: (_) => ReelBloc(),
          child: CreateReelPage(
            initialCaption: _textController.text.trim(),
          ),
        ),
      ),
    );

    if (created != true || !mounted) return;
    await _draftService.deleteDraft(_draftId);
    if (mounted) Navigator.pop(context, true);
  }

  // --- Post Submission -------------------------------------------------------
  Future<void> _submitTextPost() async {
    final content = _contentWithHashtags();
    if (content.trim().isEmpty) {
      _showSnackBar('Please enter some text', isError: true);
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

      final createdPost = await _waitForPostCreation(feedBloc, initialPostIds);
      if (createdPost == null) {
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }

      unawaited(_syncUserTags('post', createdPost.id, content));
      unawaited(_draftService.deleteDraft(_draftId));

      _showSnackBar('Post created successfully');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
      if (mounted) setState(() => _isSubmitting = false);
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
        if (attachment != null) attachments.add(attachment);
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

      final createdPost = await _waitForPostCreation(feedBloc, initialPostIds);
      if (createdPost == null) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _uploadProgress = 0.0;
          });
        }
        return;
      }

      unawaited(_syncUserTags('post', createdPost.id, content));
      unawaited(_draftService.deleteDraft(_draftId));

      _showSnackBar('Post created successfully');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
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
    return Attachment(type: media.type.name, url: url);
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
      _showSnackBar(completedState.generalError!, isError: true);
      return null;
    }

    final newPosts = completedState.posts
        .where((post) => !initialPostIds.contains(post.id))
        .toList();
    if (newPosts.isEmpty) {
      _showSnackBar('Post created, but the feed did not update.',
          isError: true);
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

  void _showSnackBar(String message, {bool isError = false}) {
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

// -----------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _Header({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.65)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close composer',
              onPressed: isSubmitting ? null : onBack,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.text,
                fixedSize: const Size.square(38),
              ),
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Create post',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.border.withOpacity(0.55),
                disabledForegroundColor: AppColors.textHint,
                minimumSize: const Size(88, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, size: 16),
                        SizedBox(width: 7),
                        Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerSection extends StatelessWidget {
  final PostComposerType postType;
  final String anonymousCategory;
  final TextEditingController textController;
  final FocusNode composerFocusNode;
  final List<MediaItem> mediaItems;
  final List<TextEditingController> pollOptionControllers;
  final int pollExpirationHours;
  final bool enabled;
  final ValueChanged<PostComposerType> onPostTypeChanged;
  final VoidCallback onCreateReel;
  final ValueChanged<String> onAnonymousCategoryChanged;
  final ValueChanged<int> onPollExpirationHoursChanged;
  final VoidCallback onAddPollOption;
  final ValueChanged<int> onRemovePollOption;
  final ComposerTokenSuggestionsBuilder suggestionsBuilder;
  final ValueChanged<int> onRemoveMedia;

  const _ComposerSection({
    required this.postType,
    required this.anonymousCategory,
    required this.textController,
    required this.composerFocusNode,
    required this.mediaItems,
    required this.pollOptionControllers,
    required this.pollExpirationHours,
    required this.enabled,
    required this.onPostTypeChanged,
    required this.onCreateReel,
    required this.onAnonymousCategoryChanged,
    required this.onPollExpirationHoursChanged,
    required this.onAddPollOption,
    required this.onRemovePollOption,
    required this.suggestionsBuilder,
    required this.onRemoveMedia,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        12,
        14,
        12,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.secondary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'What do you want to share?',
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TokenSuggestionField(
                      controller: textController,
                      focusNode: composerFocusNode,
                      enabled: enabled,
                      suggestionsBuilder: suggestionsBuilder,
                      minLines: 6,
                      maxLines: null,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: _composerHint(postType),
                        hintStyle: AppTheme.greyTextStyle.copyWith(
                          fontSize: 15,
                          color: AppColors.textSecondary.withOpacity(0.55),
                        ),
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.alternate_email_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mention people',
                          style: AppTheme.greyTextStyle.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.tag_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add topics',
                          style: AppTheme.greyTextStyle.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (postType == PostComposerType.poll) ...[
                      const SizedBox(height: 18),
                      _PollComposerPanel(
                        enabled: enabled,
                        optionControllers: pollOptionControllers,
                        expirationHours: pollExpirationHours,
                        onExpirationHoursChanged: onPollExpirationHoursChanged,
                        onAddOption: onAddPollOption,
                        onRemoveOption: onRemovePollOption,
                      ),
                    ],
                    if (postType == PostComposerType.question) ...[
                      const SizedBox(height: 14),
                      _QuestionPromptPanel(enabled: enabled),
                    ],
                    if (mediaItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 128,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: mediaItems.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = mediaItems[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 112,
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: item.type == MediaType.image
                                      ? (kIsWeb && item.fileBytes != null
                                          ? Image.memory(
                                              item.fileBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : item.file != null
                                              ? Image.file(
                                                  item.file!,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(Icons.image))
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.play_circle_fill_rounded,
                                              color: AppColors.secondary,
                                              size: 34,
                                            ),
                                            const SizedBox(height: 7),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                              child: Text(
                                                item.fileName ?? 'Video',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.greyTextStyle
                                                    .copyWith(fontSize: 9),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => onRemoveMedia(index),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (postType == PostComposerType.anonymous) ...[
                Text(
                  'Anonymous category',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Confession',
                    'Advice',
                    'Relationship',
                    'Rant',
                    'Question',
                  ].map((category) {
                    final selected =
                        category.toLowerCase() == anonymousCategory;
                    return FilterChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: enabled
                          ? (_) => onAnonymousCategoryChanged(
                                category.toLowerCase(),
                              )
                          : null,
                      backgroundColor: AppColors.transparent,
                      selectedColor: AppColors.primary.withOpacity(0.14),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary.withOpacity(0.55)
                            : AppColors.border.withOpacity(0.7),
                      ),
                      shape: const StadiumBorder(),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'Post format',
                          style: AppTheme.blackTextStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose how people interact with this post',
                          style:
                              AppTheme.greyTextStyle.copyWith(fontSize: 10.5),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...PostComposerType.values.map((type) {
                        final selected = type == postType;
                        return SizedBox(
                          width: cellWidth,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _PostFormatOption(
                              icon: _composerIcon(type),
                              label: type.label,
                              selected: selected,
                              onTap: enabled
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      onPostTypeChanged(type);
                                    }
                                  : null,
                            ),
                          ),
                        );
                      }),
                      SizedBox(
                        width: cellWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _PostFormatOption(
                            icon: Icons.movie_creation_outlined,
                            label: 'Reels',
                            selected: false,
                            onTap: enabled ? onCreateReel : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _composerHint(PostComposerType type) => switch (type) {
        PostComposerType.post => 'What are you thinking about?',
        PostComposerType.poll => 'Write the question people should vote on...',
        PostComposerType.question => 'Ask something worth answering...',
        PostComposerType.anonymous => 'Say what you need to say...',
      };

  static IconData _composerIcon(PostComposerType type) => switch (type) {
        PostComposerType.post => Icons.notes_rounded,
        PostComposerType.poll => Icons.poll_outlined,
        PostComposerType.question => Icons.help_outline_rounded,
        PostComposerType.anonymous => Icons.visibility_off_outlined,
      };
}

class _PostFormatOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PostFormatOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withOpacity(0.14)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.secondary.withOpacity(0.65)
                  : AppColors.border.withOpacity(0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.secondary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.secondary : AppColors.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerToolbar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPickImage;
  final VoidCallback onPickCamera;
  final VoidCallback onPickVideo;
  final VoidCallback onAddHashtag;

  const _ComposerToolbar({
    required this.enabled,
    required this.onPickImage,
    required this.onPickCamera,
    required this.onPickVideo,
    required this.onAddHashtag,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.65)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add to your post',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ToolbarAction(
                  tooltip: 'Add photos',
                  icon: Icons.image_outlined,
                  enabled: enabled,
                  onTap: onPickImage,
                ),
                const SizedBox(width: 6),
                _ToolbarAction(
                  tooltip: 'Open camera',
                  icon: Icons.photo_camera_outlined,
                  enabled: enabled,
                  onTap: onPickCamera,
                ),
                const SizedBox(width: 6),
                _ToolbarAction(
                  tooltip: 'Add video',
                  icon: Icons.video_library_outlined,
                  enabled: enabled,
                  onTap: onPickVideo,
                ),
                const SizedBox(width: 6),
                _ToolbarAction(
                  tooltip: 'Add hashtag',
                  icon: Icons.tag_rounded,
                  enabled: enabled,
                  onTap: onAddHashtag,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _ToolbarAction({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.secondary.withOpacity(0.14),
          foregroundColor: AppColors.secondary,
          disabledForegroundColor: AppColors.textHint,
          disabledBackgroundColor: AppColors.border.withOpacity(0.25),
          fixedSize: const Size.square(38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: Icon(icon, size: 19),
      ),
    );
  }
}

class _PollComposerPanel extends StatelessWidget {
  final bool enabled;
  final List<TextEditingController> optionControllers;
  final int expirationHours;
  final ValueChanged<int> onExpirationHoursChanged;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;

  const _PollComposerPanel({
    required this.enabled,
    required this.optionControllers,
    required this.expirationHours,
    required this.onExpirationHoursChanged,
    required this.onAddOption,
    required this.onRemoveOption,
  });

  @override
  Widget build(BuildContext context) {
    final durations = [12, 24, 48, 72];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.poll_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Poll Options',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: enabled ? onAddOption : null,
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expires in $expirationHours hours',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...optionControllers.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PollOptionField(
                  controller: controller,
                  enabled: enabled,
                  index: index + 1,
                  canRemove: optionControllers.length > 2,
                  onRemove: () => onRemoveOption(index),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Expiration',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durations.map((hours) {
              final selected = hours == expirationHours;
              return ChoiceChip(
                label: Text('${hours}h'),
                selected: selected,
                onSelected:
                    enabled ? (_) => onExpirationHoursChanged(hours) : null,
                selectedColor: AppColors.primary.withOpacity(0.16),
                backgroundColor: AppColors.backgroundColor,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected
                      ? AppColors.primary.withOpacity(0.26)
                      : AppColors.cardBorderColor,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PollOptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _PollOptionField({
    required this.controller,
    required this.enabled,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Option $index',
              hintStyle: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.cardBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.cardBorderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (canRemove) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ],
    );
  }
}

class _QuestionPromptPanel extends StatelessWidget {
  final bool enabled;

  const _QuestionPromptPanel({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              enabled
                  ? 'Questions invite replies. Keep yours clear and specific.'
                  : 'Question publishing is temporarily unavailable.',
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadOverlay extends StatelessWidget {
  final double progress;

  const _UploadOverlay({required this.progress});

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
              border: Border.all(color: AppColors.cardBorderColor),
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
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

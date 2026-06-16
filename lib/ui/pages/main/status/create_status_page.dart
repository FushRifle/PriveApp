import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';

class CreateStatusPage extends StatefulWidget {
  const CreateStatusPage({super.key});

  @override
  State<CreateStatusPage> createState() => _CreateStatusPageState();
}

class _CreateStatusPageState extends State<CreateStatusPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<StoriesState>? _createStorySubscription;

  File? _selectedMediaFile;
  String? _selectedMediaType;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  Color _selectedColor = AppColors.storyTextBackground;
  double _fontSize = 28;
  TextAlign _textAlign = TextAlign.center;
  bool _isEditingText = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  final List<String> _hashtags = [];

  static const List<Color> _backgroundColors = [
    AppColors.storyTextBackground,
    AppColors.storyPurple,
    AppColors.storyRed,
    AppColors.storyDeepPurple,
    AppColors.storyTeal,
    AppColors.storyMuted,
    AppColors.primary,
    AppColors.secondary,
    AppColors.storyYellow,
    AppColors.storyGreen,
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onComposerChanged);
    _hashtagController.addListener(_onComposerChanged);
  }

  @override
  void dispose() {
    _createStorySubscription?.cancel();
    _videoController?.dispose();
    _textController.removeListener(_onComposerChanged);
    _hashtagController.removeListener(_onComposerChanged);
    _textController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  bool get _hasText => _storyContentWithHashtags().isNotEmpty;
  bool get _hasMedia => _selectedMediaFile != null;
  bool get _hasVideo => _selectedMediaType == 'video' && _selectedMediaFile != null;
  bool get _hasContent => _hasText || _hasMedia;

  void _onComposerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting && !_isEditingText,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isSubmitting) {
          _showSnackBar('Story is uploading. Please wait.', isError: true);
          return;
        }

        if (_isEditingText) {
          setState(() => _isEditingText = false);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildTransparentAppBar(),
        body: Stack(
          children: [
            _buildBackground(),
            if (_isSubmitting) _buildLoadingOverlay(),
            if (!_isSubmitting) _buildMainContent(),
            if (!_isEditingText && !_isSubmitting) _buildFloatingTools(),
            if (!_isEditingText && !_isSubmitting && !_hasContent)
              _buildInteractionHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundColor,
            _hasMedia
                ? AppColors.primary.withOpacity(0.08)
                : _selectedColor.withOpacity(0.8),
            AppColors.secondary.withOpacity(0.06),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isEditingText) {
      return _buildTextEditorPanel();
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isEditingText = true),
                    behavior: HitTestBehavior.translucent,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_hasMedia) ...[
                            _StoryImagePreview(
                              mediaFile: _selectedMediaFile!,
                              mediaType: _selectedMediaType ?? 'image',
                              videoController: _videoController,
                              isVideoInitialized: _isVideoInitialized,
                              onReplace: _showMediaPicker,
                              onRemove: _clearMedia,
                            ),
                            const SizedBox(height: 14),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _hasText || !_hasMedia
                                ? _StoryHashtagText(
                                    text: _hasText
                                        ? _storyContentWithHashtags()
                                        : "What's happening?",
                                    textAlign: _textAlign,
                                    style: TextStyle(
                                      color: AppColors.blackTextColor,
                                      fontSize: _hasText ? _fontSize : 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.4,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 10,
                                          color: AppColors.black45,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_hasMedia || _hasText) _buildMiniStatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextEditorPanel() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor.withOpacity(0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (_hasMedia)
                    _StoryTextMediaPreview(
                      mediaFile: _selectedMediaFile!,
                      mediaType: _selectedMediaType ?? 'image',
                      videoController: _videoController,
                      isVideoInitialized: _isVideoInitialized,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit your story',
                                style: AppTheme.blackTextStyle.copyWith(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Keep it short, bold, and easy to read.',
                                style: AppTheme.greyTextStyle.copyWith(
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      showCursor: true,
                      cursorColor: AppColors.primary,
                      selectionHeightStyle: BoxHeightStyle.tight,
                      selectionWidthStyle: BoxWidthStyle.tight,
                      textAlignVertical: TextAlignVertical.top,
                      maxLines: null,
                      minLines: 5,
                      textAlign: _textAlign,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: AppTheme.blackTextStyle.copyWith(
                        color: AppColors.text,
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your story...',
                        hintStyle: AppTheme.greyTextStyle.copyWith(
                          fontSize: _fontSize,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _textAlign = _textAlign == TextAlign.center
                                ? TextAlign.left
                                : TextAlign.center;
                          }),
                          icon: Icon(
                            _textAlign == TextAlign.center
                                ? Icons.format_align_center
                                : Icons.format_align_left,
                          ),
                          label: Text(
                            _textAlign == TextAlign.center ? 'Center' : 'Left',
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _showHashtagSheet,
                          icon: const Icon(Icons.tag_rounded),
                          label: const Text('Hashtags'),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: _handleEditorBack,
                          child: const Text('Back'),
                        ),
                      ],
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

  Widget _buildMiniStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _hasMedia
                  ? (_hasVideo ? 'Video attached' : 'Image attached')
                  : 'Text only status',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: _showMediaPicker,
            child: const Text('Replace'),
          ),
          TextButton(
            onPressed: _clearMedia,
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTransparentAppBar() {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.white, size: 22),
        onPressed: _handleEditorBack,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _shareStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
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
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    _isEditingText ? 'Post' : 'Share',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _uploadProgress > 0
                  ? 'Uploading story... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                  : 'Creating your story...',
              style: const TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingTools() {
    return Positioned(
      right: 20,
      top: 120,
      child: Column(
        children: [
          _buildToolButton(Icons.text_fields, 'Text',
              () => setState(() => _isEditingText = true)),
          const SizedBox(height: 20),
          _buildToolButton(Icons.palette_outlined, 'Color', _showColorPicker),
          const SizedBox(height: 20),
          _buildToolButton(Icons.photo_library, 'Media', _showMediaPicker),
          const SizedBox(height: 20),
          _buildToolButton(Icons.tag_rounded, 'Hashtags', _showHashtagSheet),
          const SizedBox(height: 20),
          _buildToolButton(
            _textAlign == TextAlign.center
                ? Icons.format_align_center
                : Icons.format_align_left,
            'Align',
            () => setState(() {
              _textAlign = _textAlign == TextAlign.center
                  ? TextAlign.left
                  : TextAlign.center;
            }),
          ),
          const SizedBox(height: 20),
          _buildToolButton(Icons.clear_all, 'Clear', _clearAll),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withOpacity(0.15),
            border: Border.all(color: AppColors.white24),
          ),
          child: Icon(icon, color: AppColors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildInteractionHint() {
    return const Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Text(
        "Tap to add your story\nor choose background",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.white54, letterSpacing: 1),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        height: 160,
        decoration: const BoxDecoration(
          color: AppColors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Background Color',
                style: TextStyle(color: AppColors.white, fontSize: 16),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _backgroundColors
                      .map((color) => _buildColorOption(color))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _selectedMediaFile = null;
          _selectedMediaType = null;
          _videoController?.dispose();
          _videoController = null;
          _isVideoInitialized = false;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
        ),
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Media',
                  style: TextStyle(color: AppColors.white, fontSize: 18),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.white),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: AppColors.white)),
                onTap: () => _pickMedia(
                  ImageSource.gallery,
                  mediaType: 'image',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.white),
                title: const Text('Take a Photo',
                    style: TextStyle(color: AppColors.white)),
                onTap: () => _pickMedia(
                  ImageSource.camera,
                  mediaType: 'image',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined,
                    color: AppColors.white),
                title: const Text('Choose Video',
                    style: TextStyle(color: AppColors.white)),
                onTap: () => _pickMedia(
                  ImageSource.gallery,
                  mediaType: 'video',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _clearMedia() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    setState(() {
      _selectedMediaFile = null;
      _selectedMediaType = null;
    });
  }

  Future<void> _pickMedia(
    ImageSource source, {
    required String mediaType,
  }) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = mediaType == 'video'
          ? await _imagePicker.pickVideo(
              source: source,
              maxDuration: const Duration(seconds: 45),
            )
          : await _imagePicker.pickImage(
              source: source,
              imageQuality: 85,
            );
      if (pickedFile != null) {
        await _videoController?.dispose();

        setState(() {
          _selectedMediaFile = File(pickedFile.path);
          _selectedMediaType = mediaType;
          _selectedColor = AppColors.transparent;
          _isVideoInitialized = false;
        });

        if (mediaType == 'video') {
          await _initializeVideoController(File(pickedFile.path));
        }
      }
    } catch (e) {
      _showSnackBar('Failed to pick media: $e', isError: true);
    }
  }

  Future<String?> _uploadToCloudinary() async {
    final mediaFile = _selectedMediaFile;
    if (mediaFile == null) return null;

    try {
      final response = _hasVideo
          ? await _cloudinaryService.uploadVideo(
              mediaFile,
              onProgress: (progress) {
                if (!mounted) return;
                setState(() => _uploadProgress = progress);
              },
            )
          : await _cloudinaryService.uploadImage(
              mediaFile,
              onProgress: (progress) {
                if (!mounted) return;
                setState(() => _uploadProgress = progress);
              },
            );
      return response;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  void _showHashtagSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.black87,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Story hashtags',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _hashtagController,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.white),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Add hashtags',
                          hintStyle: TextStyle(
                              color: AppColors.white.withOpacity(0.5)),
                          prefixIcon: const Icon(
                            Icons.tag_rounded,
                            color: AppColors.primary,
                          ),
                          filled: true,
                          fillColor: AppColors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (value) {
                          _addHashtags(value);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 14),
                      if (_currentDraftHashtags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentDraftHashtags.map((tag) {
                            return _StoryHashtagChip(
                              tag: tag,
                              onRemove: () {
                                _removeHashtag(tag);
                                setSheetState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _addHashtags(_hashtagController.text);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addHashtags(String rawValue) {
    final tags = _extractHashtags(rawValue)
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
    setState(() => _hashtags.remove(tag));
  }

  List<String> get _currentDraftHashtags {
    return _dedupeTags([
      ..._hashtags,
      ..._extractHashtags(_hashtagController.text),
    ]);
  }

  String _storyContentWithHashtags() {
    var content = _textController.text.trim();
    final tags = _currentDraftHashtags;

    if (tags.isNotEmpty) {
      if (content.isNotEmpty) content += '\n\n';
      content += tags.map((tag) => '#$tag').join(' ');
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

  Future<void> _shareStatus() async {
    if (!_hasContent) {
      _showSnackBar('Please add text or media to your story', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    final storiesBloc = context.read<StoriesBloc>();

    try {
      String? mediaUrl;
      if (_hasMedia) {
        mediaUrl = await _uploadToCloudinary();
        if (mediaUrl == null) throw Exception('Failed to upload media');
      }

      List<Attachment> attachments = [];
      if (mediaUrl != null) {
        attachments = [
          Attachment(
            type: _hasVideo ? 'video' : 'image',
            url: mediaUrl,
          ),
        ];
      }

      await _createStorySubscription?.cancel();

      _createStorySubscription = storiesBloc.stream.listen((state) {
        if (state.status == StoriesStatus.loaded && !state.isCreating) {
          if (!mounted) return;

          Navigator.pop(context, true);
        } else if (state.status == StoriesStatus.error && mounted) {
          _showSnackBar(state.error ?? 'Failed to share story', isError: true);
          setState(() {
            _isSubmitting = false;
            _uploadProgress = 0.0;
          });
        }

        if (state.status == StoriesStatus.loaded ||
            state.status == StoriesStatus.error) {
          _createStorySubscription?.cancel();
          _createStorySubscription = null;
        }
      });

      // Create story using StoriesBloc
      storiesBloc.add(CreateStoryEvent(
        content: _storyContentWithHashtags(),
        attachments: attachments.isNotEmpty ? attachments : null,
        backgroundColor: _hasMedia
            ? null
            : '#${_selectedColor.value.toRadixString(16).substring(2)}',
        textAlign: _textAlign == TextAlign.center ? 'center' : 'left',
        fontSize: _fontSize,
      ));
    } catch (e) {
      debugPrint('Error sharing story: $e');
      if (mounted) {
        _showSnackBar('Failed to share story: ${e.toString()}', isError: true);
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _clearAll() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    setState(() {
      _textController.clear();
      _hashtagController.clear();
      _hashtags.clear();
      _selectedMediaFile = null;
      _selectedMediaType = null;
      _selectedColor = AppColors.storyTextBackground;
      _textAlign = TextAlign.center;
      _fontSize = 28;
      _uploadProgress = 0.0;
      _isEditingText = false;
    });
    _showSnackBar('All cleared');
  }

  void _handleEditorBack() {
    if (_isSubmitting) {
      _showSnackBar('Story is uploading. Please wait.', isError: true);
      return;
    }

    if (_isEditingText) {
      setState(() => _isEditingText = false);
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _initializeVideoController(File file) async {
    try {
      final controller = VideoPlayerController.file(file);
      _videoController = controller;

      await controller.initialize();

      if (!mounted || _videoController != controller) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.play();

      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (error) {
      debugPrint('Error initializing story video: $error');
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = false;
      });
      _showSnackBar('Failed to load video preview', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}

class _StoryHashtagText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final TextStyle style;

  const _StoryHashtagText({
    required this.text,
    required this.textAlign,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return EffectText(
      text: text,
      textAlign: textAlign,
      style: style,
      hashtagColor: AppColors.storyYellow,
      mentionColor: AppColors.storyGreen,
      effectShadows: const [
        Shadow(
          blurRadius: 12,
          color: AppColors.black87,
          offset: Offset(1, 1),
        ),
      ],
    );
  }
}

class _StoryHashtagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;

  const _StoryHashtagChip({
    required this.tag,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.white,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryImagePreview extends StatelessWidget {
  final File mediaFile;
  final String mediaType;
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _StoryImagePreview({
    required this.mediaFile,
    required this.mediaType,
    required this.videoController,
    required this.isVideoInitialized,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoryMediaFrame(
            mediaFile: mediaFile,
            mediaType: mediaType,
            videoController: videoController,
            isVideoInitialized: isVideoInitialized,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Media preview',
                    style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onReplace,
                  child: const Text('Replace'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    minimumSize: const Size(0, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryTextMediaPreview extends StatelessWidget {
  final File mediaFile;
  final String mediaType;
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;

  const _StoryTextMediaPreview({
    required this.mediaFile,
    required this.mediaType,
    required this.videoController,
    required this.isVideoInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: _StoryMediaFrame(
        mediaFile: mediaFile,
        mediaType: mediaType,
        videoController: videoController,
        isVideoInitialized: isVideoInitialized,
      ),
    );
  }
}

class _StoryMediaFrame extends StatelessWidget {
  final File mediaFile;
  final String mediaType;
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;

  const _StoryMediaFrame({
    required this.mediaFile,
    required this.mediaType,
    required this.videoController,
    required this.isVideoInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: mediaType == 'video'
          ? AspectRatio(
              aspectRatio:
                  videoController?.value.isInitialized == true &&
                          videoController!.value.aspectRatio > 0
                      ? videoController!.value.aspectRatio
                      : 9 / 16,
              child: isVideoInitialized && videoController != null
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: videoController!.value.size.width,
                        height: videoController!.value.size.height,
                        child: VideoPlayer(videoController!),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
            )
          : AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.file(
                mediaFile,
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}

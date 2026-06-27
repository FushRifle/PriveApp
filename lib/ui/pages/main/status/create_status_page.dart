import 'dart:async';
import 'dart:io';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:clique/core/services/status/status_services.dart';
import 'package:clique/core/services/tagging/tagging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:clique/ui/widgets/status/create/create_status_composer_panel.dart';
import 'package:clique/ui/widgets/status/create/create_status_composer_tools.dart';
import 'package:clique/ui/widgets/status/create/background_orb.dart';
import 'package:clique/ui/widgets/status/create/hashtag_chip.dart';
import 'package:clique/ui/widgets/status/create/icon_button_circle.dart';
import 'package:clique/ui/widgets/status/create/loading_overlay.dart';
import 'package:clique/ui/widgets/status/create/media_preview.dart';
import 'package:clique/ui/widgets/status/create/style_controls.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';

class CreateStatusPage extends StatefulWidget {
  const CreateStatusPage({super.key});

  @override
  State<CreateStatusPage> createState() => _CreateStatusPageState();
}

class _CreateStatusPageState extends State<CreateStatusPage>
    with TickerProviderStateMixin {
  static const _maximumStoryVideoDuration = Duration(minutes: 1);

  final TextEditingController _textController =
      HighlightTokenTextEditingController();
  final TextEditingController _hashtagController =
      HighlightTokenTextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final StatusService _statusService = StatusService();
  final TaggingService _taggingService = TaggingService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedMediaFile;
  String? _selectedMediaType;
  VideoPlayerController? _previewVideoController;
  bool _isPreviewVideoReady = false;
  bool _isSubmitting = false;
  bool _isComposerOptionsOpen = false;
  double _uploadProgress = 0.0;

  Color _selectedColor = const Color(0xFF1A1B2F);
  double _fontSize = 28;
  TextAlign _textAlign = TextAlign.center;
  final List<String> _hashtags = [];

  late final AnimationController _pulseController;

  static const List<Color> _backgroundColors = [
    Color(0xFF1A1B2F),
    Color(0xFF6C3BD4),
    Color(0xFFE74C3C),
    Color(0xFF2D1B69),
    Color(0xFF0D9488),
    Color(0xFF374151),
    AppColors.primary,
    AppColors.secondary,
    Color(0xFFEAB308),
    Color(0xFF22C55E),
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onComposerChanged);
    _hashtagController.addListener(_onComposerChanged);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _disposePreviewVideoController();
    _textController.removeListener(_onComposerChanged);
    _hashtagController.removeListener(_onComposerChanged);
    _textController.dispose();
    _hashtagController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _hasText => _storyContentWithHashtags().trim().isNotEmpty;
  bool get _hasMedia => _selectedMediaFile != null;
  bool get _hasContent => _hasText || _hasMedia;

  void _onComposerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _closeComposerOptions() {
    if (!_isComposerOptionsOpen) return;
    setState(() => _isComposerOptionsOpen = false);
  }

  void _toggleComposerOptions() {
    setState(() => _isComposerOptionsOpen = !_isComposerOptionsOpen);
  }

  void _runComposerOption(VoidCallback action) {
    _closeComposerOptions();
    action();
  }

  Future<void> _disposePreviewVideoController() async {
    final controller = _previewVideoController;
    _previewVideoController = null;
    _isPreviewVideoReady = false;
    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }
  }

  Future<void> _preparePreviewController(File file) async {
    await _disposePreviewVideoController();

    final controller = VideoPlayerController.file(file);
    _previewVideoController = controller;

    try {
      await controller.initialize();
      if (controller.value.duration > _maximumStoryVideoDuration) {
        await controller.dispose();
        if (!mounted || _previewVideoController != controller) return;
        setState(() {
          _previewVideoController = null;
          _selectedMediaFile = null;
          _selectedMediaType = null;
          _isPreviewVideoReady = false;
        });
        _showSnackBar(
          'Story videos can be up to 1 minute long',
          isError: true,
        );
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted || _previewVideoController != controller) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isPreviewVideoReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      await controller.dispose();
      setState(() {
        _selectedMediaFile = null;
        _selectedMediaType = null;
        _isPreviewVideoReady = false;
      });
      _showSnackBar('Failed to prepare media preview: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isSubmitting) return;
        if (_hasContent) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1119),
        body: Stack(
          children: [
            _buildBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_hasMedia) ...[
                              MediaPreviewWidget(
                                selectedMediaFile: _selectedMediaFile,
                                selectedMediaType: _selectedMediaType,
                                isPreviewVideoReady: _isPreviewVideoReady,
                                previewVideoController: _previewVideoController,
                                captionController: _textController,
                                captionTextAlign: _textAlign,
                                onRemoveMedia: () {
                                  setState(() {
                                    _selectedMediaFile = null;
                                    _selectedMediaType = null;
                                    _isPreviewVideoReady = false;
                                  });
                                  _disposePreviewVideoController();
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (!_hasMedia)
                              Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 980,
                                    minHeight: 120,
                                    maxHeight: 420,
                                  ),
                                  child: _buildComposerCard(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildComposerOptionsScrim(),
            _buildComposerOptionsDrawer(),
            if (_isSubmitting)
              LoadingOverlay(
                uploadProgress: _uploadProgress,
                isSubmitting: _isSubmitting,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F1119),
                  _hasMedia
                      ? AppColors.primary.withOpacity(0.06)
                      : _selectedColor.withOpacity(0.85),
                  AppColors.secondary.withOpacity(0.04),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -30,
            child: BackgroundOrb(
              color: AppColors.primary.withOpacity(0.12),
              size: 200,
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: BackgroundOrb(
              color: AppColors.secondary.withOpacity(0.1),
              size: 250,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          IconButtonCircle(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _handleBack,
            backgroundColor: AppColors.primary.withOpacity(0.9),
            iconColor: Colors.white,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Story',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasContent ? 'Ready to share' : 'Add content to start',
                  style: AppTheme.greyTextStyle.copyWith(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSubmitting || !_hasContent ? null : _shareStatus,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _hasContent
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.12),
                    boxShadow: _hasContent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.32),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hasContent
                          ? Colors.white.withOpacity(0.18)
                          : Colors.white.withOpacity(0.12),
                    ),
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
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Share',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
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
    );
  }

  Widget _buildComposerCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CreateStatusComposerPanel(
            textController: _textController,
            textAlign: _textAlign,
          ),
        ),
        Positioned(
          right: -10,
          top: 100,
          child: _buildComposerOptionsTab(),
        ),
      ],
    );
  }

  Widget _buildComposerOptionsTab() {
    return Material(
      color: AppColors.primary,
      elevation: 8,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(16),
        right: Radius.circular(16),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(12),
          right: Radius.circular(12),
        ),
        onTap: _toggleComposerOptions,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 40,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
              right: Radius.circular(16),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Icon(
            _isComposerOptionsOpen
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildComposerOptionsScrim() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isComposerOptionsOpen,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          opacity: _isComposerOptionsOpen ? 1 : 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeComposerOptions,
            child: Container(color: Colors.black.withOpacity(0.26)),
          ),
        ),
      ),
    );
  }

  Widget _buildComposerOptionsDrawer() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isComposerOptionsOpen,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final drawerWidth =
                (constraints.maxWidth * 0.72).clamp(240.0, 300.0);
            final drawerHeight =
                (constraints.maxHeight * 0.58).clamp(320.0, 480.0);

            return Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  offset: _isComposerOptionsOpen
                      ? Offset.zero
                      : const Offset(1.08, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    opacity: _isComposerOptionsOpen ? 1 : 0,
                    child: Container(
                      width: drawerWidth,
                      height: drawerHeight,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.26),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tools',
                                    style: AppTheme.blackTextStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _closeComposerOptions,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CreateStatusComposerTools(
                                      onAddMedia: () =>
                                          _runComposerOption(_showMediaPicker),
                                      onAddHashtags: () =>
                                          _runComposerOption(_showHashtagSheet),
                                      onClearAll: () =>
                                          _runComposerOption(_clearAll),
                                      onTextAlignChanged: (value) =>
                                          _runComposerOption(() {
                                        setState(() => _textAlign = value);
                                      }),
                                      activeAlignment: _textAlign,
                                    ),
                                    const SizedBox(height: 18),
                                    StyleControls(
                                      fontSize: _fontSize,
                                      textLength:
                                          _textController.text.trim().length,
                                      selectedColor: _selectedColor,
                                      backgroundColors: _backgroundColors,
                                      onFontSizeChanged: (value) =>
                                          setState(() => _fontSize = value),
                                      onFontSizeChangeEnd:
                                          _closeComposerOptions,
                                      onColorSelected: (color) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedColor = color;
                                          _selectedMediaFile = null;
                                          _selectedMediaType = null;
                                          _isPreviewVideoReady = false;
                                        });
                                        _disposePreviewVideoController();
                                        _closeComposerOptions();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2030),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Add Media',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _MediaPickerOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Gallery',
                  subtitle: 'Select photos or videos',
                  onTap: _showGalleryMediaTypePicker,
                ),
                _MediaPickerOption(
                  icon: Icons.videocam_rounded,
                  title: 'Choose Video',
                  subtitle: 'Capture a video clip',
                  onTap: () =>
                      _pickMedia(ImageSource.gallery, mediaType: 'video'),
                ),
                _MediaPickerOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take Photo',
                  subtitle: 'Capture with camera',
                  onTap: () =>
                      _pickMedia(ImageSource.camera, mediaType: 'image'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGalleryMediaTypePicker() {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery,
                        mediaType: 'image', closeSheet: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(ImageSource.gallery,
                        mediaType: 'video', closeSheet: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(ImageSource source,
      {required String mediaType, bool closeSheet = true}) async {
    if (closeSheet) Navigator.pop(context);

    try {
      final XFile? pickedFile = mediaType == 'video'
          ? await _imagePicker.pickVideo(
              source: source,
              maxDuration: _maximumStoryVideoDuration,
            )
          : await _imagePicker.pickImage(
              source: source,
              imageQuality: 85,
            );

      if (pickedFile == null) return;

      setState(() {
        _selectedMediaFile = File(pickedFile.path);
        _selectedMediaType = mediaType;
        _selectedColor = Colors.transparent;
      });

      if (mediaType == 'video') {
        await _preparePreviewController(File(pickedFile.path));
      } else {
        await _disposePreviewVideoController();
      }
    } catch (e) {
      _showSnackBar('Failed to pick media: $e', isError: true);
    }
  }

  Future<String?> _uploadToCloudinary() async {
    final mediaFile = _selectedMediaFile;
    if (mediaFile == null) return null;

    try {
      final response = _selectedMediaType == 'video'
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2030),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Hashtags',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Increase discoverability with relevant tags',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _hashtagController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setSheetState(() {}),
                        onSubmitted: (value) {
                          _addHashtags(value);
                          setSheetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Type tags separated by space or comma',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          prefixIcon: Icon(
                            Icons.tag_rounded,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_currentDraftHashtags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentDraftHashtags.map((tag) {
                            return HashtagChip(
                              tag: tag,
                              onRemove: () {
                                _removeHashtag(tag);
                                setSheetState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _addHashtags(_hashtagController.text);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Tags',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
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

    _pulseController.repeat(reverse: true);

    final storiesBloc = context.read<StoriesBloc>();

    try {
      String? mediaUrl;
      if (_hasMedia) {
        mediaUrl = await _uploadToCloudinary();
        if (mediaUrl == null) throw Exception('Failed to upload media');
      }

      final attachments = mediaUrl == null
          ? <Attachment>[]
          : [
              Attachment(
                type: _selectedMediaType == 'video' ? 'video' : 'image',
                url: mediaUrl,
              ),
            ];

      final createdStory = await _statusService.createStory(
        content: _storyContentWithHashtags(),
        attachments: attachments.isNotEmpty ? attachments : null,
        backgroundColor: _hasMedia ? null : _colorToHex(_selectedColor),
        textAlign: _textAlign == TextAlign.center
            ? 'center'
            : _textAlign == TextAlign.right
                ? 'right'
                : 'left',
        fontSize: _fontSize,
      );

      if (createdStory == null) {
        throw Exception('Failed to share story');
      }

      unawaited(
        _syncUserTags(
          'status',
          int.tryParse(createdStory.id) ?? 0,
          _storyContentWithHashtags(),
        ),
      );

      storiesBloc.add(const GetStories(refresh: true, silent: true));

      if (!mounted) return;
      Navigator.pop(context, true);
    } on SilentStatusFailure catch (e) {
      debugPrint('Silent status upload failure: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
      _pulseController.stop();
    } catch (e) {
      debugPrint('Error sharing story: $e');
      if (!mounted) return;
      _showSnackBar('Failed to share story: ${e.toString()}', isError: true);
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
      _pulseController.stop();
    }
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _hashtagController.clear();
      _hashtags.clear();
      _selectedMediaFile = null;
      _selectedMediaType = null;
      _isPreviewVideoReady = false;
      _selectedColor = const Color(0xFF1A1B2F);
      _textAlign = TextAlign.center;
      _fontSize = 28;
      _uploadProgress = 0.0;
    });
    _disposePreviewVideoController();
    _showSnackBar('All cleared');
  }

  void _handleBack() {
    if (_isSubmitting) {
      _showSnackBar('Story is uploading. Please wait.', isError: true);
      return;
    }

    if (_hasContent) {
      _confirmDiscard();
      return;
    }

    Navigator.pop(context);
  }

  void _confirmDiscard() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2030),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discard Story?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your story draft will be permanently deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text(
                          'Keep Editing',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size.fromHeight(48),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Discard',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.withOpacity(0.9) : AppColors.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
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
      debugPrint('Status user tag sync skipped: $e');
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
}

class _MediaPickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MediaPickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

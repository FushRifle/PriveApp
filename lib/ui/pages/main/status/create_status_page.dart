import 'dart:async';
import 'dart:io';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/core/models/status_model.dart';

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

  File? _selectedImageFile;
  Color _selectedColor = AppColors.storyTextBackground;
  double _fontSize = 28;
  TextAlign _textAlign = TextAlign.center;
  bool _isEditingText = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  bool _showFontControls = false;
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
  void dispose() {
    _createStorySubscription?.cancel();
    _textController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  bool get _hasText => _storyContentWithHashtags().isNotEmpty;
  bool get _hasImage => _selectedImageFile != null;
  bool get _hasContent => _hasText || _hasImage;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.black,
        appBar: _isEditingText ? null : _buildTransparentAppBar(),
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
      color: _hasImage ? AppColors.black : _selectedColor,
      child: _hasImage
          ? InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              clipBehavior: Clip.none,
              child: SizedBox.expand(
                child: Image.file(
                  _selectedImageFile!,
                  fit: BoxFit.cover,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: _isEditingText
          ? _buildTextInput()
          : GestureDetector(
              onTap: () => setState(() => _isEditingText = true),
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: SingleChildScrollView(
                    child: _hasText || !_hasImage
                        ? _StoryHashtagText(
                            text: _hasText
                                ? _storyContentWithHashtags()
                                : "What's happening?",
                            textAlign: _textAlign,
                            style: TextStyle(
                              color: AppColors.white,
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
                ),
              ),
            ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      color: AppColors.black.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: TextField(
                controller: _textController,
                autofocus: true,
                textAlign: _textAlign,
                maxLines: null,
                cursorColor: AppColors.secondary,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: AppColors.blackTextColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your story...',
                  hintStyle: TextStyle(color: AppColors.greyTextColor),
                ),
              ),
            ),
          ),
          _buildTextInputControls(),
        ],
      ),
    );
  }

  Widget _buildTextInputControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFontControls ? 80 : 0,
            child: _showFontControls ? _buildFontControls() : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.format_size,
                isActive: _showFontControls,
                onTap: () =>
                    setState(() => _showFontControls = !_showFontControls),
              ),
              _buildControlButton(
                icon: _textAlign == TextAlign.center
                    ? Icons.format_align_center
                    : Icons.format_align_left,
                onTap: () => setState(() {
                  _textAlign = _textAlign == TextAlign.center
                      ? TextAlign.left
                      : TextAlign.center;
                }),
              ),
              const SizedBox(width: 20),
              _buildControlButton(
                icon: Icons.close,
                backgroundColor: AppColors.white.withOpacity(0.1),
                onTap: () => setState(() => _isEditingText = false),
              ),
              _buildControlButton(
                icon: Icons.check,
                backgroundColor: AppColors.primary,
                onTap: () => setState(() => _isEditingText = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.format_size, color: AppColors.white70, size: 20),
              Text(
                'Font Size: ${_fontSize.round()}',
                style: const TextStyle(color: AppColors.white70, fontSize: 14),
              ),
            ],
          ),
          Slider(
            value: _fontSize,
            min: 20,
            max: 48,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.white30,
            onChanged: (value) => setState(() => _fontSize = value),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onTap,
    Color? backgroundColor,
    bool isActive = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ??
            (isActive ? AppColors.primary : AppColors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.white, size: 22),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  PreferredSizeWidget _buildTransparentAppBar() {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.white, size: 28),
        onPressed: () => Navigator.pop(context),
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
                : const Text(
                    "Share",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          _selectedImageFile = null;
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
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.white),
                title: const Text('Take a Photo',
                    style: TextStyle(color: AppColors.white)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedColor = AppColors.transparent;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selectedImageFile == null) return null;

    try {
      final response = await _cloudinaryService.uploadImage(
        _selectedImageFile!,
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
                        decoration: InputDecoration(
                          hintText: 'Add hashtags',
                          hintStyle:
                              TextStyle(color: AppColors.white.withOpacity(0.5)),
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
                      if (_hashtags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _hashtags.map((tag) {
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

  String _storyContentWithHashtags() {
    var content = _textController.text.trim();
    final tags = _dedupeTags([
      ..._hashtags,
      ..._extractHashtags(_hashtagController.text),
    ]);

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
      _showSnackBar('Please add text or an image to your story', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    final storiesBloc = context.read<StoriesBloc>();

    try {
      String? imageUrl;
      if (_hasImage) {
        imageUrl = await _uploadToCloudinary();
        if (imageUrl == null) throw Exception('Failed to upload image');
      }

      // Prepare attachments if image exists
      List<Attachment> attachments = [];
      if (imageUrl != null) {
        attachments = [
          Attachment(
            type: 'image',
            url: imageUrl,
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
        backgroundColor: _hasImage
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
    setState(() {
      _textController.clear();
      _selectedImageFile = null;
      _selectedColor = AppColors.storyTextBackground;
      _textAlign = TextAlign.center;
      _fontSize = 28;
      _uploadProgress = 0.0;
    });
    _showSnackBar('All cleared');
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

  static final RegExp _hashtagPattern = RegExp(r'#[A-Za-z0-9_]+');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _hashtagPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      spans.add(
        TextSpan(
          text: match.group(0),
          style: style.copyWith(
            color: AppColors.storyYellow,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(
                blurRadius: 12,
                color: AppColors.black87,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      );

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: style,
        children: spans,
      ),
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

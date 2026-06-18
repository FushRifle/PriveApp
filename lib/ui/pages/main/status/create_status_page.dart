import 'dart:io';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:clique/core/services/status/status_services.dart';
import 'package:clique/ui/widgets/status/create/create_status_composer_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

enum _StatusComposerStyle {
  editorial,
  neon,
}

class CreateStatusPage extends StatefulWidget {
  const CreateStatusPage({super.key});

  @override
  State<CreateStatusPage> createState() => _CreateStatusPageState();
}

class _CreateStatusPageState extends State<CreateStatusPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final StatusService _statusService = StatusService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedMediaFile;
  String? _selectedMediaType;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  Color _selectedColor = AppColors.storyTextBackground;
  double _fontSize = 28;
  TextAlign _textAlign = TextAlign.center;
  final List<String> _hashtags = [];
  final _StatusComposerStyle _stylePreset = _StatusComposerStyle.editorial;

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
    _textController.removeListener(_onComposerChanged);
    _hashtagController.removeListener(_onComposerChanged);
    _textController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  bool get _hasText => _storyContentWithHashtags().trim().isNotEmpty;
  bool get _hasMedia => _selectedMediaFile != null;
  bool get _hasContent => _hasText || _hasMedia;

  void _onComposerChanged() {
    if (!mounted) return;
    setState(() {});
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
        backgroundColor: AppColors.backgroundColor,
        body: Stack(
          children: [
            _buildBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 980),
                                child: _buildComposerCard(),
                              ),
                            ),
                          ),
                          _buildBottomControls(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isSubmitting) _buildLoadingOverlay(),
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
                  AppColors.backgroundColor,
                  _hasMedia
                      ? AppColors.primary.withOpacity(0.08)
                      : _selectedColor.withOpacity(0.88),
                  AppColors.secondary.withOpacity(0.06),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(color: AppColors.primary.withOpacity(0.18)),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: _GlowOrb(color: AppColors.secondary.withOpacity(0.14)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          _TopIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _handleBack,
            backgroundColor: _stylePreset == _StatusComposerStyle.neon
                ? const Color(0xFF171B2E).withOpacity(0.92)
                : AppColors.cardColor.withOpacity(0.88),
            iconColor: _stylePreset == _StatusComposerStyle.neon
                ? AppColors.white
                : AppColors.text,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isSubmitting ? null : _shareStatus,
            style: FilledButton.styleFrom(
              backgroundColor: _actionColor,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              minimumSize: const Size(84, 42),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    _hasContent ? 'Post' : 'Share',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerCard() {
    return CreateStatusComposerPanel(
      textController: _textController,
      textAlign: _textAlign,
      onAddMedia: _showMediaPicker,
      onAddHashtags: _showHashtagSheet,
      onClearAll: _clearAll,
      onTextAlignChanged: (value) => setState(() => _textAlign = value),
    );
  }

  Widget _buildBottomControls() {
    return _buildFontAndPaletteFooter();
  }

  Widget _buildFontAndPaletteFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_textController.text.trim().length} chars',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'Size ${_fontSize.toInt()}',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: _fontSize,
            min: 18,
            max: 42,
            divisions: 24,
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _fontSize = value),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _backgroundColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final color = _backgroundColors[index];
              final selected = color.value == _selectedColor.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedColor = color;
                    _selectedMediaFile = null;
                    _selectedMediaType = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.text,
                    width: selected ? 2.2 : 1,
                  ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.black.withOpacity(0.78),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _uploadProgress > 0
                      ? 'Uploading ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                      : 'Publishing story',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please wait while the story is processed.',
                  textAlign: TextAlign.center,
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _actionColor => AppColors.primary;

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.cardBorderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose image'),
                  onTap: () => _pickMedia(
                    ImageSource.gallery,
                    mediaType: 'image',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Choose video'),
                  onTap: () => _pickMedia(
                    ImageSource.gallery,
                    mediaType: 'video',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a photo'),
                  onTap: () => _pickMedia(
                    ImageSource.camera,
                    mediaType: 'image',
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
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

      if (pickedFile == null) return;

      setState(() {
        _selectedMediaFile = File(pickedFile.path);
        _selectedMediaType = mediaType;
        _selectedColor = AppColors.transparent;
      });
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
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.cardBorderColor),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hashtags',
                        style: AppTheme.blackTextStyle.copyWith(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add tags to make the story easier to discover.',
                        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _hashtagController,
                        autofocus: true,
                        style: AppTheme.blackTextStyle.copyWith(
                          color: AppColors.text,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setSheetState(() {}),
                        onSubmitted: (value) {
                          _addHashtags(value);
                          setSheetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Type hashtags separated by space or comma',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                          prefixIcon: const Icon(Icons.tag_rounded),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
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
                            minimumSize: const Size.fromHeight(50),
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
        backgroundColor:
            _hasMedia ? null : _colorToHex(_selectedColor),
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

      storiesBloc.add(const GetStories(refresh: true, silent: true));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error sharing story: $e');
      if (!mounted) return;
      _showSnackBar('Failed to share story: ${e.toString()}', isError: true);
      setState(() {
        _isSubmitting = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _clearAll() {
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
    });
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
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text('Discard draft?'),
          content: const Text(
            'Your story draft will be cleared if you leave now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: Text(
                'Discard',
                style: TextStyle(color: AppColors.redColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.text,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;

  const _GlowOrb({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            AppColors.transparent,
          ],
        ),
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
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              color: AppColors.text,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

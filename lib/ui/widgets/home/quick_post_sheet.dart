import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

enum QuickPostMode { text, media }

class QuickPostSheet extends StatefulWidget {
  final FeedBloc feedBloc;
  final QuickPostMode mode;

  const QuickPostSheet({
    super.key,
    required this.feedBloc,
    required this.mode,
  });

  @override
  State<QuickPostSheet> createState() => _QuickPostSheetState();
}

class _QuickMedia {
  final XFile file;
  final bool isVideo;

  const _QuickMedia({required this.file, required this.isVideo});
}

class _QuickPostSheetState extends State<QuickPostSheet> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  final List<_QuickMedia> _media = [];

  bool _isPicking = false;
  bool _isPosting = false;
  double _uploadProgress = 0;

  bool get _isMediaMode => widget.mode == QuickPostMode.media;

  bool get _canPost {
    if (_isPicking || _isPosting) return false;
    return _isMediaMode
        ? _media.isNotEmpty
        : _textController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _cloudinary.cancelAllUploads();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenHeight - keyboardInset) * 0.62;

    return PopScope(
      canPop: !_isPosting,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Material(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: sheetHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 9),
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 9),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          onPressed:
                              _isPosting ? null : () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.card,
                            foregroundColor: AppColors.text,
                            fixedSize: const Size.square(38),
                            side: BorderSide(
                              color: AppColors.border.withOpacity(0.55),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                        const SizedBox(width: 6),
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
                        FilledButton.icon(
                          onPressed: _canPost ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor:
                                AppColors.border.withOpacity(0.55),
                            disabledForegroundColor: AppColors.textHint,
                            minimumSize: const Size(88, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            elevation: 0,
                          ),
                          icon: _isPosting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: Text(
                            _isPosting && _isMediaMode
                                ? '${(_uploadProgress * 100).round()}%'
                                : 'Post',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
                  if (_isPosting)
                    LinearProgressIndicator(
                      minHeight: 2,
                      value: _isMediaMode ? _uploadProgress : null,
                      backgroundColor: AppColors.border.withOpacity(0.35),
                      color: AppColors.secondary,
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _ComposerIdentity(),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _textController,
                            autofocus: !_isMediaMode,
                            enabled: !_isPosting,
                            minLines: _isMediaMode ? 3 : 7,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: _isMediaMode
                                  ? 'Add a caption…'
                                  : 'What are you thinking?',
                              hintStyle: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              filled: false,
                              fillColor: AppColors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          if (_isMediaMode) ...[
                            if (_media.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildMediaPreview(),
                            ],
                            const SizedBox(height: 16),
                            _buildMediaActions(),
                          ],
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
    );
  }

  Widget _buildMediaActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to your post',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_media.length}/4 selected',
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _MediaPickerButton(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Add photos',
            onTap: _isPicking || _isPosting ? null : _pickImages,
          ),
          const SizedBox(width: 4),
          _MediaPickerButton(
            icon: Icons.video_library_outlined,
            label: 'Add video',
            onTap: _isPicking || _isPosting ? null : _pickVideo,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return SizedBox(
      height: _media.length == 1 ? 220 : 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _media[index];
          return Stack(
            children: [
              Container(
                width: _media.length == 1
                    ? MediaQuery.sizeOf(context).width - 32
                    : 118,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                ),
                child: item.isVideo
                    ? _VideoPreview(fileName: item.file.name)
                    : kIsWeb
                        ? Image.network(item.file.path, fit: BoxFit.cover)
                        : Image.file(File(item.file.path), fit: BoxFit.cover),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: IconButton(
                  tooltip: 'Remove attachment',
                  onPressed: _isPosting
                      ? null
                      : () => setState(() => _media.removeAt(index)),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.black54,
                    foregroundColor: AppColors.white,
                    fixedSize: const Size.square(28),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_media.length >= 4) {
      _showMessage('You can add up to 4 media items.');
      return;
    }
    setState(() => _isPicking = true);
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (!mounted || files.isEmpty) return;
      final remaining = 4 - _media.length;
      setState(() {
        _media.addAll(
          files.take(remaining).map(
                (file) => _QuickMedia(file: file, isVideo: false),
              ),
        );
      });
    } catch (error) {
      _showMessage('Could not open your photo gallery: $error');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickVideo() async {
    if (_media.length >= 4) {
      _showMessage('You can add up to 4 media items.');
      return;
    }
    setState(() => _isPicking = true);
    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (!mounted || file == null) return;
      setState(() => _media.add(_QuickMedia(file: file, isVideo: true)));
    } catch (error) {
      _showMessage('Could not open your video gallery: $error');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    if (_isMediaMode && kIsWeb) {
      _showMessage('Quick media posting is currently available on mobile.');
      return;
    }

    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _isPosting = true;
      _uploadProgress = 0;
    });

    try {
      final attachments = <Map<String, dynamic>>[];
      for (var index = 0; index < _media.length; index++) {
        final item = _media[index];
        final file = File(item.file.path);
        final url = item.isVideo
            ? await _cloudinary.uploadVideo(
                file,
                onProgress: (progress) => _setOverallProgress(index, progress),
              )
            : await _cloudinary.uploadImage(
                file,
                onProgress: (progress) => _setOverallProgress(index, progress),
              );
        attachments.add({
          'type': item.isVideo ? 'video' : 'image',
          'url': url,
        });
      }

      widget.feedBloc.add(
        CreateFeedPost(
          content: _textController.text.trim(),
          attachments: attachments.isEmpty ? null : attachments,
          postType: 'standard',
        ),
      );

      final result = await widget.feedBloc.stream.firstWhere(
        (state) => !state.isCreatingPost,
      );
      if (!mounted) return;
      if (result.generalError != null) {
        throw Exception(result.generalError);
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      _showMessage('Could not publish post: $error');
    }
  }

  void _setOverallProgress(int index, double progress) {
    if (!mounted || _media.isEmpty) return;
    setState(() {
      _uploadProgress = ((index + progress) / _media.length).clamp(0, 1);
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _ComposerIdentity extends StatelessWidget {
  const _ComposerIdentity();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, Map<String, dynamic>?>(
      selector: (state) => state.currentUser,
      builder: (context, user) {
        final name =
            (user?['name'] ?? user?['username'] ?? 'You').toString().trim();
        final avatar = (user?['avatar'] ?? '').toString().trim();
        final initial = name.isEmpty ? 'Y' : name[0].toUpperCase();

        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.55),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: avatar.startsWith('http')
                    ? AppNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        preset: AppNetworkImagePreset.avatar,
                        placeholder: (_) => _IdentityFallback(initial: initial),
                        errorBuilder: (_) =>
                            _IdentityFallback(initial: initial),
                      )
                    : _IdentityFallback(initial: initial),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'You' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Visible to everyone',
                        style: AppTheme.greyTextStyle.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IdentityFallback extends StatelessWidget {
  final String initial;

  const _IdentityFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.secondary.withOpacity(0.12),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final String fileName;

  const _VideoPreview({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.secondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MediaPickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.secondary.withOpacity(0.12),
          foregroundColor: AppColors.secondary,
          disabledBackgroundColor: AppColors.border.withOpacity(0.35),
          disabledForegroundColor: AppColors.textHint,
          fixedSize: const Size.square(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

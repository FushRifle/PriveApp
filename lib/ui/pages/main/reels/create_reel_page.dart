import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/core/cloudinary_service.dart';

class CreateReelPage extends StatefulWidget {
  const CreateReelPage({
    super.key,
  });

  @override
  State<CreateReelPage> createState() => _CreateReelPageState();
}

class _CreateReelPageState extends State<CreateReelPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _musicController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  final CloudinaryService _cloudinaryService = CloudinaryService();

  File? _selectedVideoFile;

  VideoPlayerController? _videoController;

  bool _isVideoInitialized = false;
  bool _isUploading = false;
  bool _isPickingVideo = false;

  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _captionController.dispose();
    _musicController.dispose();

    _disposeVideoController();

    _cloudinaryService.cancelAllUploads();

    super.dispose();
  }

  Future<void> _disposeVideoController() async {
    final controller = _videoController;

    _videoController = null;
    _isVideoInitialized = false;

    await controller?.pause();
    await controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isUploading) {
          _showSnackBar(
            'Upload in progress. Please wait.',
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: _buildAppBar(),
        body: BlocListener<ReelBloc, ReelState>(
          listenWhen: (previous, current) {
            return _isUploading &&
                (previous.status != current.status ||
                    previous.error != current.error);
          },
          listener: (context, state) {
            if (state.status == ReelStatus.success) {
              _showSnackBar('Reel uploaded successfully');

              if (!mounted) return;

              Navigator.pop(context, true);
              return;
            }

            if (state.error != null && state.error!.isNotEmpty) {
              _showSnackBar(
                state.error!,
                isError: true,
              );

              if (!mounted) return;

              setState(() {
                _isUploading = false;
              });

              context.read<ReelBloc>().add(ClearReelError());
            }
          },
          child: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.close,
          color: AppColors.white,
        ),
        onPressed: _isUploading ? null : () => Navigator.pop(context),
      ),
      title: const Text(
        'Create Reel',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: ElevatedButton(
            onPressed: _canShare ? _uploadReel : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.grey.shade800,
              disabledForegroundColor: AppColors.grey.shade500,
              shape: const StadiumBorder(),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              minimumSize: const Size(70, 40),
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text(
                    'Share',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  bool get _canShare {
    return _selectedVideoFile != null &&
        _isVideoInitialized &&
        !_isUploading &&
        !_isPickingVideo;
  }

  Widget _buildBody() {
    if (_selectedVideoFile == null) {
      return _buildVideoPicker();
    }

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            bottom: 32,
          ),
          child: Column(
            children: [
              _buildVideoPreview(),
              const SizedBox(height: 16),
              _buildCaptionInput(),
              const SizedBox(height: 16),
              _buildMusicInput(),
              const SizedBox(height: 32),
            ],
          ),
        ),
        if (_isUploading) _buildUploadOverlay(),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isPickingVideo ? null : _showVideoPickerOptions,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.grey.shade900,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.7),
                    width: 1.5,
                  ),
                ),
                child: _isPickingVideo
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.video_call,
                        size: 52,
                        color: AppColors.white,
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a video to create a reel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey.shade300,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from gallery or record a new video',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: const BoxConstraints(
        maxHeight: 560,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Container(
                  color: AppColors.grey,
                ),
              ),
              if (_isVideoInitialized && _videoController != null)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              if (!_isVideoInitialized)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              if (_isVideoInitialized && _videoController != null)
                GestureDetector(
                  onTap: _toggleVideoPlayback,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: AppColors.white,
                      size: 40,
                    ),
                  ),
                ),
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _isUploading ? null : _changeVideo,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.black.withOpacity(0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionInput() {
    return _InputSection(
      label: 'Caption',
      child: TextField(
        controller: _captionController,
        enabled: !_isUploading,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
        ),
        maxLines: 3,
        maxLength: 2200,
        decoration: InputDecoration(
          hintText: 'Write a caption...',
          hintStyle: TextStyle(
            color: AppColors.grey.shade600,
          ),
          border: InputBorder.none,
          counterStyle: TextStyle(
            color: AppColors.grey.shade600,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildMusicInput() {
    return _InputSection(
      label: 'Music (Optional)',
      child: TextField(
        controller: _musicController,
        enabled: !_isUploading,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Add music to your reel...',
          hintStyle: TextStyle(
            color: AppColors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
    final percentage = (_uploadProgress * 100).clamp(0, 100).toInt();

    return Positioned.fill(
      child: Container(
        color: AppColors.black.withOpacity(0.72),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.grey,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Uploading reel',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                LinearProgressIndicator(
                  value: _uploadProgress <= 0 ? null : _uploadProgress,
                  color: AppColors.primary,
                  backgroundColor: AppColors.grey.shade800,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 12),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: AppColors.grey.shade400,
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

  void _showVideoPickerOptions() {
    if (_isUploading) return;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.grey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                _PickerTile(
                  icon: Icons.video_library,
                  title: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.gallery);
                  },
                ),
                _PickerTile(
                  icon: Icons.videocam,
                  title: 'Record Video',
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_isPickingVideo || _isUploading) return;

    setState(() {
      _isPickingVideo = true;
    });

    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );

      if (pickedFile == null) return;

      await _setSelectedVideo(File(pickedFile.path));
    } catch (e) {
      _showSnackBar(
        'Failed to pick video: $e',
        isError: true,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isPickingVideo = false;
      });
    }
  }

  Future<void> _setSelectedVideo(File file) async {
    await _disposeVideoController();

    if (!mounted) return;

    setState(() {
      _selectedVideoFile = file;
      _isVideoInitialized = false;
    });

    await _initializeVideoController(file);
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
      debugPrint('Error initializing video: $error');

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = false;
      });

      _showSnackBar(
        'Failed to load video',
        isError: true,
      );
    }
  }

  void _toggleVideoPlayback() {
    final controller = _videoController;

    if (controller == null || !_isVideoInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    if (!mounted) return;

    setState(() {});
  }

  void _changeVideo() {
    _showVideoPickerOptions();
  }

  Future<void> _uploadReel() async {
    final file = _selectedVideoFile;

    if (file == null || _isUploading) return;

    FocusScope.of(context).unfocus();

    await _videoController?.pause();

    if (!mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final videoUrl = await _cloudinaryService.uploadVideo(
        file,
        onProgress: (progress) {
          if (!mounted) return;

          setState(() {
            _uploadProgress = progress.clamp(0.0, 1.0);
          });
        },
      );

      if (!mounted) return;

      final caption = _captionController.text.trim();
      final music = _musicController.text.trim();

      final data = <String, dynamic>{
        'videoUrl': videoUrl,
        'caption': caption,
        if (music.isNotEmpty) 'music': music,
      };

      context.read<ReelBloc>().add(
            CreateReel(data: data),
          );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Failed to upload reel: $e',
        isError: true,
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
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

class _InputSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _InputSection({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey.shade900,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.grey.shade800,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.white,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

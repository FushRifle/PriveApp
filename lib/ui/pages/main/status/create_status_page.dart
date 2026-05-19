import 'dart:async';
import 'dart:io';
import 'package:cirqle/core/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/bloc/status/stories_bloc.dart';
import 'package:cirqle/data/models/status_model.dart';

class CreateStatusPage extends StatefulWidget {
  const CreateStatusPage({super.key});

  @override
  State<CreateStatusPage> createState() => _CreateStatusPageState();
}

class _CreateStatusPageState extends State<CreateStatusPage> {
  final TextEditingController _textController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImageFile;
  Color _selectedColor = const Color(0xFF1D1B20);
  double _fontSize = 28;
  TextAlign _textAlign = TextAlign.center;
  bool _isEditingText = false;
  bool _isSubmitting = false;
  final double _uploadProgress = 0.0;
  bool _showFontControls = false;

  static const List<Color> _backgroundColors = [
    Color(0xFF1D1B20),
    Color(0xFF6750A4),
    Color(0xFFB3261E),
    Color(0xFF21005D),
    Color(0xFF006A6A),
    Color(0xFF434948),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E77E),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _hasText => _textController.text.trim().isNotEmpty;
  bool get _hasImage => _selectedImageFile != null;
  bool get _hasContent => _hasText || _hasImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
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
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _hasImage ? Colors.black : _selectedColor,
      child: _hasImage
          ? Image.file(
              _selectedImageFile!,
              fit: BoxFit.cover,
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
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      _hasText ? _textController.text : "What's happening?",
                      textAlign: _textAlign,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _hasText ? _fontSize : 20,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        shadows: const [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black45,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      color: Colors.black.withOpacity(0.95),
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
                backgroundColor: Colors.white.withOpacity(0.1),
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
              const Icon(Icons.format_size, color: Colors.white70, size: 20),
              Text(
                'Font Size: ${_fontSize.round()}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Slider(
            value: _fontSize,
            min: 20,
            max: 48,
            activeColor: AppColors.primary,
            inactiveColor: Colors.white30,
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
            (isActive ? AppColors.primary : Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  PreferredSizeWidget _buildTransparentAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _shareStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
                      color: Colors.white,
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
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _uploadProgress > 0
                  ? 'Uploading story... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                  : 'Creating your story...',
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
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
        style: TextStyle(color: Colors.white54, letterSpacing: 1),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 160,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Background Color',
                style: TextStyle(color: Colors.white, fontSize: 16),
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
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
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
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take a Photo',
                    style: TextStyle(color: Colors.white)),
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
          _selectedColor = Colors.transparent;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selectedImageFile == null) return null;

    try {
      final response =
          await _cloudinaryService.uploadImage(_selectedImageFile!);
      return response;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _shareStatus() async {
    if (!_hasContent) {
      _showSnackBar('Please add text or an image to your story', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

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

      // Create story using StoriesBloc
      context.read<StoriesBloc>().add(CreateStoryEvent(
            content: _textController.text.trim(),
            attachments: attachments.isNotEmpty ? attachments : null,
            backgroundColor: _hasImage
                ? null
                : '#${_selectedColor.value.toRadixString(16).substring(2)}',
            textAlign: _textAlign == TextAlign.center ? 'center' : 'left',
            fontSize: _fontSize,
          ));

      // Declare subscription first
      late final StreamSubscription<StoriesState> subscription;

      subscription = context.read<StoriesBloc>().stream.listen((state) {
        if (state.status == StoriesStatus.loaded && !state.isCreating) {
          if (mounted) {
            _showSnackBar('Story shared successfully!');
            Navigator.pop(context, true);
          }
          subscription.cancel();
        } else if (state.status == StoriesStatus.error && mounted) {
          _showSnackBar(state.error ?? 'Failed to share story', isError: true);
          setState(() => _isSubmitting = false);
          subscription.cancel();
        }
      });
    } catch (e) {
      debugPrint('Error sharing story: $e');
      if (mounted) {
        _showSnackBar('Failed to share story: ${e.toString()}', isError: true);
      }
      setState(() => _isSubmitting = false);
    }
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _selectedImageFile = null;
      _selectedColor = const Color(0xFF1D1B20);
      _textAlign = TextAlign.center;
      _fontSize = 28;
    });
    _showSnackBar('All cleared');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}

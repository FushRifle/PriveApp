import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/data/services/cloudinary_service.dart';
import 'package:Prive/data/services/home/feed_service.dart';
import 'package:Prive/data/services/user/user_service.dart';

class CreateStatusPage extends StatefulWidget {
  const CreateStatusPage({super.key});

  @override
  State<CreateStatusPage> createState() => _CreateStatusPageState();
}

class _CreateStatusPageState extends State<CreateStatusPage> {
  final TextEditingController _textController = TextEditingController();
  final UserService _userService = UserService();
  final FeedService _feedService = FeedService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedImageUrl;
  File? _selectedImageFile;
  Color _selectedColor = const Color(0xFF1D1B20);
  double _fontSize = 28;
  TextAlign _textAlign = TextAlign.center;
  bool _isEditingText = false;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _showFontControls = false;

  final List<Color> _backgroundColors = [
    const Color(0xFF1D1B20),
    const Color(0xFF6750A4),
    const Color(0xFFB3261E),
    const Color(0xFF21005D),
    const Color(0xFF006A6A),
    const Color(0xFF434948),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFE66D),
    const Color(0xFF95E77E),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      await _userService.getCurrentUser();
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _isEditingText ? null : _buildTransparentAppBar(),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: _selectedImageFile != null ? Colors.black : _selectedColor,
            child: _selectedImageFile != null && _selectedImageUrl != null
                ? Image.file(
                    File(_selectedImageUrl!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : null,
          ),

          // Loading overlay with progress
          if (_isUploading) _buildLoadingOverlay(),

          // Main Content
          Center(
            child: _isEditingText ? _buildTextInput() : _buildContentDisplay(),
          ),

          // Floating Tools
          if (!_isEditingText && !_isUploading) _buildFloatingTools(),

          // Interaction Hint
          if (!_isEditingText &&
              !_isUploading &&
              _textController.text.isEmpty &&
              _selectedImageFile == null)
            const Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Text(
                "Tap to add your story\nor choose background",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, letterSpacing: 1),
              ),
            ),
        ],
      ),
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
                  : 'Uploading your story...',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
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
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: (_isLoading || _isUploading) ? null : _shareStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                minimumSize: const Size(60, 40),
                maximumSize: const Size(100, 40),
              ),
              child: _isLoading
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
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentDisplay() {
    final hasText = _textController.text.isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => _isEditingText = true),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: SingleChildScrollView(
            child: Text(
              hasText ? _textController.text : "What's happening?",
              textAlign: _textAlign,
              style: TextStyle(
                color: Colors.white,
                fontSize: hasText ? _fontSize : 20,
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
    );
  }

  Widget _buildTextInput() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text Input
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
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your story...',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),

          // Bottom Controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                // Expandable Font Controls
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showFontControls ? 80 : 0,
                  child: _showFontControls
                      ? Column(
                          children: [
                            // Font Size Slider
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(Icons.format_size,
                                          color: Colors.white70, size: 20),
                                      Text(
                                        'Font Size: ${_fontSize.round()}',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _fontSize,
                                    min: 20,
                                    max: 48,
                                    activeColor: AppColors.purpleColor,
                                    inactiveColor: Colors.white30,
                                    onChanged: (value) {
                                      setState(() => _fontSize = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Font Settings Button
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _showFontControls
                            ? AppColors.purpleColor
                            : Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.format_size,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFontControls = !_showFontControls;
                          });
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    // Text Align Button
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _textAlign == TextAlign.center
                              ? Icons.format_align_center
                              : Icons.format_align_left,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _textAlign = _textAlign == TextAlign.center
                                ? TextAlign.left
                                : TextAlign.center;
                          });
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Cancel Button
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 24),
                        onPressed: () => setState(() => _isEditingText = false),
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    // Done Button
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purpleColor,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.check,
                            color: Colors.white, size: 24),
                        onPressed: () => setState(() => _isEditingText = false),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTools() {
    return Positioned(
      right: 20,
      top: 120,
      child: Column(
        children: [
          _toolCircle(
            Icons.text_fields,
            () => setState(() => _isEditingText = true),
            'Text',
          ),
          const SizedBox(height: 20),
          _toolCircle(
            Icons.palette_outlined,
            _showColorPicker,
            'Color',
          ),
          const SizedBox(height: 20),
          _toolCircle(
            Icons.photo_library,
            _showMediaPicker,
            'Media',
          ),
          const SizedBox(height: 20),
          _toolCircle(
            _textAlign == TextAlign.center
                ? Icons.format_align_center
                : Icons.format_align_left,
            () => setState(() {
              _textAlign = _textAlign == TextAlign.center
                  ? TextAlign.left
                  : TextAlign.center;
            }),
            'Align',
          ),
          const SizedBox(height: 20),
          _toolCircle(
            Icons.clear_all,
            _clearAll,
            'Clear',
          ),
        ],
      ),
    );
  }

  Widget _toolCircle(IconData icon, VoidCallback onTap, String tooltip) {
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
                  children: _backgroundColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          _selectedImageUrl = null;
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
                  }).toList(),
                ),
              ),
            ),
          ],
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
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take a Photo',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageUrl = pickedFile.path;
          _selectedColor = Colors.transparent;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadToCloudinary() async {
    if (_selectedImageFile == null) return null;

    try {
      final xFile = XFile(_selectedImageFile!.path);
      final response = await _cloudinaryService.uploadImage(
        file: xFile,
        folder: 'stories',
        tags: ['story', 'status'],
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      return response?.url;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<void> _shareStatus() async {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasImage = _selectedImageFile != null;

    if (!hasText && !hasImage) {
      _showErrorSnackBar('Please add text or an image to your story');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? imageUrl;
      bool isTextOnly = hasText && !hasImage;
      if (hasImage) {
        setState(() => _isUploading = true);
        imageUrl = await _uploadToCloudinary();
        setState(() => _isUploading = false);

        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      await _feedService.createStatus(
        text: hasText ? _textController.text.trim() : '',
        imageUrl: imageUrl,
        backgroundColor: !hasImage && _selectedColor != Colors.transparent
            ? '#${_selectedColor.value.toRadixString(16).substring(2)}'
            : null,
        textAlign: _textAlign == TextAlign.center ? 'center' : 'left',
      );

      if (mounted) {
        _showSuccessSnackBar('Story shared successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error sharing story: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to share story: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _selectedImageUrl = null;
      _selectedImageFile = null;
      _selectedColor = const Color(0xFF1D1B20);
      _textAlign = TextAlign.center;
      _fontSize = 28;
    });
    _showSuccessSnackBar('All cleared');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateStatusPage extends StatefulWidget {
  const CreateStatusPage({super.key});

  @override
  State<CreateStatusPage> createState() => _CreateStatusPageState();
}

class _CreateStatusPageState extends State<CreateStatusPage> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedImage;
  Color _selectedColor = const Color(0xFF1D1B20);
  final double _fontSize = 32;
  TextAlign _textAlign = TextAlign.center;
  bool _isEditingText = false;

  final List<Color> _backgroundColors = [
    const Color(0xFF1D1B20),
    const Color(0xFF6750A4),
    const Color(0xFFB3261E),
    const Color(0xFF21005D),
    const Color(0xFF006A6A),
    const Color(0xFF434948),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
          // 1. Immersive Background
          _buildBackground(),

          // 2. Main Content Layer
          Center(
            child: _isEditingText ? _buildTextInput() : _buildContentDisplay(),
          ),

          // 3. Floating Tools (Only show when not typing)
          if (!_isEditingText) _buildFloatingTools(),

          // 4. Interaction Hint
          if (!_isEditingText && _textController.text.isEmpty)
            const Positioned(
              bottom: 120,
              child: Text("Tap to add your story",
                  style: TextStyle(color: Colors.white54, letterSpacing: 1)),
            ),
        ],
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
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: StadiumBorder(),
              elevation: 0,
            ),
            child: const Text("Share",
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _selectedColor,
        image: _selectedImage != null
            ? DecorationImage(
                image: AssetImage(_selectedImage!), fit: BoxFit.cover)
            : null,
      ),
      child: _selectedImage != null
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.black.withOpacity(0.2)),
            )
          : null,
    );
  }

  Widget _buildContentDisplay() {
    return GestureDetector(
      onTap: () => setState(() => _isEditingText = true),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          _textController.text.isEmpty
              ? "What's happening?"
              : _textController.text,
          textAlign: _textAlign,
          style: TextStyle(
            color: Colors.white,
            fontSize: _fontSize,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                  blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              autofocus: true,
              textAlign: _textAlign,
              maxLines: null,
              cursorColor: Colors.white,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
            const SizedBox(height: 40),
            IconButton(
              icon:
                  const Icon(Icons.check_circle, color: Colors.white, size: 54),
              onPressed: () => setState(() => _isEditingText = false),
            )
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
          _toolCircle(
              Icons.text_fields, () => setState(() => _isEditingText = true)),
          const SizedBox(height: 20),
          _toolCircle(Icons.palette_outlined, _showColorPicker),
          const SizedBox(height: 20),
          _toolCircle(Icons.image_search, _showImagePicker),
          const SizedBox(height: 20),
          _toolCircle(
            _textAlign == TextAlign.center
                ? Icons.format_align_center
                : Icons.format_align_left,
            () => setState(() => _textAlign = _textAlign == TextAlign.center
                ? TextAlign.left
                : TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _toolCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 120,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _backgroundColors
                  .map((c) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = c;
                            _selectedImage = null;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePicker() {
    // Placeholder logic for image gallery selection
    setState(() => _selectedImage = 'assets/profiles/profile_2.jpeg');
  }
}

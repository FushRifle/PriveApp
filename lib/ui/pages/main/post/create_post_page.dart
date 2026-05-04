import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  String? _selectedImage;
  final List<String> _hashtags = [];

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          // Background Decor (Subtle gradient blobs for depth)
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppColors.purpleColor.withOpacity(0.05),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildCreativeCanvas(),
                        const SizedBox(height: 24),
                        _buildModernInput(
                          label: "HASHTAGS",
                          icon: Icons.tag_rounded,
                          child: _buildHashtagInput(),
                        ),
                        const SizedBox(height: 20),
                        _buildOptionGrid(),
                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildPostButton(),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'NEW POST',
              style: AppTheme.blackTextStyle.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
        ),
      ),
    );
  }

  Widget _buildCreativeCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _selectedImage == null ? 200 : 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: AssetImage(_selectedImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_outlined,
                            color: AppColors.purpleColor, size: 40),
                        const SizedBox(height: 12),
                        Text("Add Visual Magic",
                            style: TextStyle(
                                color: AppColors.purpleColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _captionController,
              maxLines: 5,
              style: const TextStyle(
                  fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Tell your story...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput(
      {required String label, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.purpleColor),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildHashtagInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          TextField(
            controller: _hashtagController,
            onSubmitted: (val) => _addHashtag(val),
            decoration: const InputDecoration(
                border: InputBorder.none, hintText: "Type and enter..."),
          ),
          if (_hashtags.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 8,
                children: _hashtags
                    .map((t) => Chip(
                          label: Text("#$t",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                          backgroundColor: Colors.black87,
                          deleteIcon: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                          onDeleted: () => setState(() => _hashtags.remove(t)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ))
                    .toList(),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildOptionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildMinimalTile(Icons.location_on_rounded, "Location"),
        _buildMinimalTile(Icons.alternate_email_rounded, "Mention"),
        _buildMinimalTile(Icons.palette_rounded, "Theme"),
        _buildMinimalTile(Icons.lock_outline_rounded, "Private"),
      ],
    );
  }

  Widget _buildMinimalTile(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPostButton() {
    bool active = _captionController.text.isNotEmpty || _selectedImage != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: MediaQuery.of(context).size.width * 0.9,
      height: 60,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? [
                BoxShadow(
                    color: const Color(0xFF2575FC).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: active ? () {} : null,
          child: const Center(
            child: Text(
              "PUBLISH POST",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  void _pickImage() {
    setState(() => _selectedImage = 'assets/profiles/profile_1.jpeg');
  }

  void _addHashtag(String tag) {
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() {
        _hashtags.add(tag.replaceAll('#', '').trim());
        _hashtagController.clear();
      });
    }
  }
}

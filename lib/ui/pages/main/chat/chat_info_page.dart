import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
import 'package:clique/ui/pages/main/chat/chat_settings_page.dart';

class ChatInfoPage extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final int userId;

  const ChatInfoPage({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.userId,
  });

  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  late int _conversationId;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _conversationId = (widget.userId);
    if (_conversationId != 0) {
      context.read<ChatGalleryCubit>().loadSharedMedia(_conversationId);
      _loadChatSettings();
    }
  }

  void _loadChatSettings() {
    context
        .read<ChatBloc>()
        .add(LoadChatSettings(conversationId: _conversationId));
  }

  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);

    context.read<ChatBloc>().add(UpdateChatSettings(
          conversationId: _conversationId,
          isMuted: _isMuted,
          muteUntil:
              _isMuted ? DateTime.now().add(const Duration(days: 365)) : null,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isMuted ? 'Notifications muted' : 'Notifications unmuted'),
        backgroundColor: AppColors.greenColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _blockUser() async {
    context.read<ChatBloc>().add(BlockUser(userId: _conversationId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('User blocked'), backgroundColor: Colors.red),
    );
    Navigator.pop(context);
  }

  bool get _isBot => widget.userName.toLowerCase() == 'clique';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userName,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSettingsPage(
                    userName: widget.userName,
                    userId: widget.userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, chatState) {
          final conversation = chatState.conversations.firstWhere(
            (c) => c.userId.toString() == widget.userId,
            orElse: () => ConversationModel(
              id: 0,
              userId: 0,
              name: '',
              avatar: '',
              age: 0,
              verified: false,
              lastMessage: '',
              lastMessageType: 'text',
              timestamp: '',
              unreadCount: 0,
              isOnline: false,
              isTyping: false,
              isPinned: false,
              isMuted: false,
              muteUntil: null,
              username: '',
            ),
          );

          _isMuted = conversation.isMuted;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileSection(conversation),
                  const SizedBox(height: 16),
                  _buildMediaSection(),
                  const SizedBox(height: 16),
                  _buildSharedFilesSection(),
                  const SizedBox(height: 16),
                  _buildPrivacySection(context, conversation.isMuted),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(ConversationModel conversation) {
    final firstLetter =
        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U';
    final isOnline = conversation.isOnline;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(firstLetter),
          const SizedBox(height: 16),
          Text(
            '@${widget.userName.toLowerCase().replaceAll(' ', '_')}',
            style: AppTheme.blackTextStyle
                .copyWith(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.greenColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Active now' : 'Offline',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 13,
                  color: isOnline ? AppColors.greenColor : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isBot) ...[
                _buildActionChip(
                    icon: Icons.call,
                    label: 'Audio',
                    color: AppColors.primary,
                    onTap: () {}),
                const SizedBox(width: 16),
                _buildActionChip(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: AppColors.primary,
                    onTap: () {}),
                const SizedBox(width: 16),
              ],
              _buildActionChip(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  color: AppColors.primary,
                  onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String fallbackText) {
    final avatar = widget.userAvatar;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: ClipOval(
        child: avatar.isNotEmpty && avatar.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: avatar,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.primary.withOpacity(0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primary.withOpacity(0.1),
                  child: Center(
                    child: Text(
                      fallbackText,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              )
            : Container(
                color: AppColors.primary.withOpacity(0.1),
                child: Center(
                  child: Text(
                    fallbackText,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: AppTheme.blackTextStyle
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    if (_isBot) return const SizedBox.shrink();

    return BlocBuilder<ChatGalleryCubit, ChatGalleryState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shared Media',
                      style: AppTheme.blackTextStyle
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (state is ChatGalleryLoaded && state.images.isNotEmpty)
                    TextButton(
                      onPressed: () => _showAllMedia(context, state.images),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                      child: const Text('See all'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMediaGrid(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaGrid(ChatGalleryState state) {
    if (state is ChatGalleryLoading) {
      return const Center(
        child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (state is ChatGalleryLoaded && state.images.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No shared media yet', style: AppTheme.greyTextStyle),
        ),
      );
    }

    if (state is ChatGalleryLoaded) {
      final images = state.images.take(4).toList();
      return Row(
        children: List.generate(images.length, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _showImageViewer(images[index].url),
              child: Container(
                height: 80,
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(images[index].url),
                      fit: BoxFit.cover),
                ),
              ),
            ),
          );
        }),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSharedFilesSection() {
    if (_isBot) return const SizedBox.shrink();

    return BlocBuilder<ChatGalleryCubit, ChatGalleryState>(
      builder: (context, state) {
        if (state is ChatGalleryLoaded && state.documents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shared Files',
                  style: AppTheme.blackTextStyle
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              if (state is ChatGalleryLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: AppColors.primary))),
              if (state is ChatGalleryLoaded)
                ...state.documents.take(3).map((doc) => Column(
                      children: [
                        _buildFileItem(
                          icon: _getFileIcon(doc.name),
                          name: doc.name,
                          size: doc.size,
                          color: _getFileColor(doc.name),
                          onTap: () => _openDocument(doc.url),
                        ),
                        if (doc != state.documents.last)
                          const SizedBox(height: 12),
                      ],
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileItem({
    required IconData icon,
    required String name,
    required String size,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTheme.blackTextStyle
                      .copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(size, style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
            ],
          ),
        ),
        IconButton(
            icon: const Icon(Icons.download, color: AppColors.primary),
            onPressed: onTap),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context, bool isMuted) {
    final username = '@${widget.userName.toLowerCase().replaceAll(' ', '_')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon:
                isMuted ? Icons.notifications_off : Icons.notifications_active,
            title: isMuted ? 'Unmute Notifications' : 'Mute Notifications',
            subtitle: isMuted ? 'Currently muted' : 'Currently unmuted',
            onTap: _toggleMute,
          ),
          if (!_isBot) ...[
            const Divider(height: 1, indent: 56),
            _buildInfoTile(
              icon: Icons.block_outlined,
              title: 'Block User',
              subtitle: 'Block $username',
              titleColor: AppColors.redColor,
              onTap: () => _showBlockDialog(context),
            ),
            const Divider(height: 1, indent: 56),
            _buildInfoTile(
              icon: Icons.report_outlined,
              title: 'Report User',
              subtitle: 'Report inappropriate content',
              titleColor: AppColors.redColor,
              onTap: () => _showReportDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.blackColor, size: 24),
      title: Text(title,
          style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.w600, fontSize: 15, color: titleColor)),
      subtitle:
          Text(subtitle, style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: AppColors.greyColor, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showAllMedia(BuildContext context, List<SharedMedia> images) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('All Media',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _showImageViewer(images[index].url),
                  child: CachedNetworkImage(
                      imageUrl: images[index].url, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageViewer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                  child: InteractiveViewer(
                      child: CachedNetworkImage(imageUrl: url))),
              Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _openDocument(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document viewer coming soon')));
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Block ${widget.userName}?',
            style:
                AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold)),
        content: Text('They won\'t be able to message you or see your posts.',
            style: AppTheme.greyTextStyle),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: AppTheme.greyTextStyle)),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _blockUser();
            },
            child: Text('Block',
                style: AppTheme.blackTextStyle
                    .copyWith(color: AppColors.redColor)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Report ${widget.userName}',
            style:
                AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What is the issue?', style: AppTheme.blackTextStyle),
            const SizedBox(height: 16),
            ...['Spam', 'Harassment', 'Inappropriate content', 'Fake account']
                .map((reason) => RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: '',
                      activeColor: AppColors.primary,
                      onChanged: (value) {},
                    )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: AppTheme.greyTextStyle)),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')));
            },
            child: Text('Report',
                style: AppTheme.blackTextStyle
                    .copyWith(color: AppColors.redColor)),
          ),
        ],
      ),
    );
  }
}

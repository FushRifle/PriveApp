import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/core/models/calls.dart';
import 'package:clique/ui/widgets/call/call_button.dart';
import 'package:clique/ui/pages/main/chat/call/call_history_screen.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
import 'package:clique/ui/pages/main/chat/chat_settings_page.dart';

class ChatInfoPage extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final int conversationId;
  final int userId;

  const ChatInfoPage({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.conversationId,
    required this.userId,
  });

  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  late int _conversationId;
  bool _isMuted = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface => AppColors.getCardColor(_isDark);
  Color get _border => AppColors.getCardBorderColor(_isDark);
  Color get _text => AppColors.getTextColor(_isDark);
  Color get _mutedText => AppColors.getTextSecondaryColor(_isDark);
  Color get _divider => AppColors.getDividerColor(_isDark);

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
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
    final nextMuted = !_isMuted;
    setState(() => _isMuted = nextMuted);

    context.read<ChatBloc>().add(UpdateChatSettings(
          conversationId: _conversationId,
          isMuted: nextMuted,
          muteUntil:
              nextMuted ? DateTime.now().add(const Duration(days: 365)) : null,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(nextMuted ? 'Notifications muted' : 'Notifications unmuted'),
        backgroundColor: AppColors.card,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _blockUser() async {
    context.read<ChatBloc>().add(BlockUser(userId: widget.userId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'User blocked',
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.card,
      ),
    );
    Navigator.pop(context);
  }

  bool get _isBot => widget.userName.toLowerCase() == 'Clique';

  void _startCall(String callType) {
    if (widget.userId <= 0) return;
    CallButton.initiateCall(
      context,
      receiver: UserInfo(
        id: widget.userId,
        name: widget.userName,
        username: widget.userName,
        avatar: widget.userAvatar,
      ),
      callType: callType,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _text),
          color: AppColors.primary,
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
            icon: Icon(Icons.settings_outlined, color: _text),
            color: AppColors.primary,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ChatBloc>(),
                    child: ChatSettingsPage(
                      userName: widget.userName,
                      conversationId: widget.conversationId,
                      userId: widget.userId,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (previous, current) =>
            previous.conversations != current.conversations ||
            previous.chatSettings != current.chatSettings,
        builder: (context, chatState) {
          final conversation = chatState.conversations.firstWhere(
            (c) => c.userId == widget.userId,
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

          final effectiveMuted =
              chatState.chatSettings?.isMuted ?? conversation.isMuted;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                  _buildPrivacySection(context, effectiveMuted),
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
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildAvatar(firstLetter),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.greenColor : _mutedText,
                ),
              ),
              const SizedBox(
                width: 6,
                height: 6,
              ),
              Text(
                isOnline ? 'Active now' : 'Offline',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 13,
                  color: isOnline ? AppColors.greenColor : _mutedText,
                  fontWeight: FontWeight.bold,
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
                    onTap: () => _startCall('voice')),
                const SizedBox(width: 16),
                _buildActionChip(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: AppColors.primary,
                    onTap: () => _startCall('video')),
                const SizedBox(width: 16),
              ],
              _buildActionChip(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  color: AppColors.primary,
                  onTap: () {}),
            ],
          ),
          if (!_isBot) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CallHistoryScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(
                      width: 12,
                      height: 3,
                    ),
                    Expanded(
                      child: Text(
                        'Call History',
                        style: AppTheme.blackTextStyle.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _text,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _mutedText,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        color: _surface,
      ),
      child: ClipOval(
        child: avatar.isNotEmpty && avatar.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: avatar,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                memCacheWidth: 220,
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
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shared Media',
                      style: AppTheme.blackTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _text)),
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
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shared Files',
                  style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 16, color: _text)),
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
      decoration: _cardDecoration(),
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
            Divider(height: 1, indent: 56, color: _divider),
            _buildInfoTile(
              icon: Icons.block_outlined,
              title: 'Block User',
              subtitle: 'Block $username',
              titleColor: AppColors.redColor,
              onTap: () => _showBlockDialog(context),
            ),
            Divider(height: 1, indent: 56, color: _divider),
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
      leading: Icon(icon, color: titleColor ?? _mutedText, size: 24),
      title: Text(title,
          style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.w600, fontSize: 15, color: titleColor)),
      subtitle:
          Text(subtitle, style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: _mutedText, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: AppColors.getShadowColor(_isDark),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  void _showAllMedia(BuildContext context, List<SharedMedia> images) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
            color: _surface,
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
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text('All Media',
                    style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _text))),
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
                    imageUrl: images[index].url,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 120),
                    memCacheWidth: 360,
                  ),
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
          backgroundColor: AppColors.black,
          body: Stack(
            children: [
              Center(
                  child: InteractiveViewer(
                      child: CachedNetworkImage(imageUrl: url))),
              Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
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
        return AppColors.red;
      case 'doc':
      case 'docx':
        return AppColors.blue;
      case 'xls':
      case 'xlsx':
        return AppColors.green;
      case 'ppt':
      case 'pptx':
        return AppColors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return AppColors.purple;
      case 'mp4':
      case 'mov':
      case 'avi':
        return AppColors.teal;
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

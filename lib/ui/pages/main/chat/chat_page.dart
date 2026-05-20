import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/core/cloudinary_service.dart';
import 'package:clique/ui/pages/main/chat/chat_info_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final String userId;

  const ChatPage({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.userId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSending = false;
  Timer? _typingTimer;
  int? _conversationId;

  // Chat settings
  String _wallpaper = 'default';
  String _chatColor = 'default';
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _loadInitialData() {
    final userId = int.tryParse(widget.userId);
    if (userId != null) {
      _conversationId = userId;
      context
          .read<ChatBloc>()
          .add(LoadMessages(conversationId: userId, page: 1));
      context
          .read<ChatBloc>()
          .add(LoadConversationInfo(conversationId: userId));
      context.read<ChatBloc>().add(LoadChatSettings(conversationId: userId));
      context.read<ChatBloc>().add(MarkMessagesAsRead(conversationId: userId));
    }
  }

  void _handleSendMessage(String text) async {
    if (text.trim().isEmpty || _isSending || _conversationId == null) return;

    setState(() => _isSending = true);

    context.read<ChatBloc>().add(SendMessage(
          receiverId: _conversationId!,
          message: text,
          messageType: 'text',
        ));

    _textController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isSending = false);
  }

  Future<void> _sendMediaMessage(String filePath, String type) async {
    if (_conversationId == null) return;

    setState(() => _isSending = true);

    try {
      File file = File(filePath);
      String? mediaUrl;

      if (type == 'image') {
        mediaUrl = await _cloudinaryService.uploadImage(file);
      } else if (type == 'video') {
        mediaUrl = await _cloudinaryService.uploadVideo(file);
      } else if (type == 'document') {
        mediaUrl = await _cloudinaryService.uploadDocument(
            file, file.path.split('/').last);
      }

      if (mediaUrl != null) {
        context.read<ChatBloc>().add(SendMessage(
              receiverId: _conversationId!,
              message: type == 'document' ? 'Sent a document' : 'Sent a $type',
              messageType: type,
              mediaUrl: mediaUrl,
            ));
      }
    } catch (e) {
      debugPrint('Error sending media: $e');
      _showSnackBar('Failed to send $type', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _handleTyping() {
    if (_conversationId == null) return;

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      context.read<ChatBloc>().add(SetTyping(
            conversationId: _conversationId!,
            isTyping: false,
          ));
    });

    context.read<ChatBloc>().add(SetTyping(
          conversationId: _conversationId!,
          isTyping: true,
        ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getChatColor() {
    switch (_chatColor) {
      case 'primary':
        return AppColors.primary;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'orange':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Decoration? _getChatBackground() {
    if (_wallpaper == 'default') return null;

    return BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/wallpapers/$_wallpaper.png'),
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.chatSettings != null) {
            setState(() {
              _wallpaper = state.chatSettings!.wallpaper;
              _chatColor = state.chatSettings!.chatColor;
              _isMuted = state.chatSettings!.isMuted;
            });
          }
          if (state.error != null) {
            _showSnackBar(state.error!, isError: true);
            context.read<ChatBloc>().add(ClearChatError());
          }
          if (state.messages.isNotEmpty) {
            _scrollToBottom();
          }
        },
        child: Container(
          decoration: _getChatBackground(),
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state.messagesStatus == ChatStatus.loading &&
                        state.messages.isEmpty) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (state.messages.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages.reversed.toList()[index];
                        return _buildMessageBubble(message);
                      },
                    );
                  },
                ),
              ),
              _buildTypingIndicator(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final chatColor = _getChatColor();

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatInfoPage(
                userName: widget.userName,
                userAvatar: widget.userAvatar,
                userId: widget.userId,
              ),
            ),
          );
        },
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    final conversation = state.conversations.firstWhere(
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

                    String statusText = 'Offline';
                    if (conversation.isTyping) {
                      statusText = 'Typing...';
                    } else if (conversation.isOnline) {
                      statusText = 'Online';
                    }

                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: conversation.isOnline
                                ? AppColors.greenColor
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: AppTheme.greyTextStyle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final fallbackText =
        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U';

    if (widget.userAvatar.isNotEmpty && widget.userAvatar.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: CachedNetworkImageProvider(widget.userAvatar),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Text(
        fallbackText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final conversation = state.conversations.firstWhere(
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

        if (!conversation.isTyping) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 44),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 4,
                        height: 4 + (index == 1 ? 4 : 0),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Typing...',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: _showAttachmentOptions,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(233, 233, 233, 1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.greyColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  style: AppTheme.blackTextStyle.copyWith(fontSize: 15),
                  onChanged: (text) => _handleTyping(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _handleSendMessage(text);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  if (_textController.text.trim().isNotEmpty && !_isSending) {
                    HapticFeedback.lightImpact();
                    _handleSendMessage(_textController.text);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _chatColor == 'default'
                        ? AppColors.primary
                        : _getChatColor(),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isMe = message.isOwn;
    final chatColor = _getChatColor();

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isMe ? 0 : 8,
        right: isMe ? 8 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: CachedNetworkImageProvider(widget.userAvatar),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe ? chatColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == 'image' &&
                      message.mediaUrl != null)
                    GestureDetector(
                      onTap: () => _showImageViewer(message.mediaUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: message.mediaUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (message.messageType == 'video' &&
                      message.mediaUrl != null)
                    GestureDetector(
                      onTap: () => _showVideoViewer(message.mediaUrl!),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: message.mediaUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.messageType == 'document' &&
                      message.mediaUrl != null)
                    GestureDetector(
                      onTap: () => _openDocument(message.mediaUrl!),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file,
                                color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Document',
                                style: AppTheme.blackTextStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.open_in_new, size: 16),
                          ],
                        ),
                      ),
                    ),
                  if (message.message.isNotEmpty &&
                      message.messageType != 'text')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.blackColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (message.messageType == 'text')
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.blackColor,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                      if (isMe && message.isRead)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.done_all,
                              size: 12, color: Colors.white70),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _attachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _attachmentOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                  _attachmentOption(
                    icon: Icons.document_scanner,
                    label: 'Document',
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.blackTextStyle.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(source: source);
    if (image != null) {
      await _sendMediaMessage(image.path, 'image');
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video =
        await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      await _sendMediaMessage(video.path, 'video');
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      await _sendMediaMessage(result.files.single.path!, 'document');
    }
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
                  child: CachedNetworkImage(imageUrl: url),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoViewer(String url) {
    _showSnackBar('Video player coming soon');
  }

  void _openDocument(String url) {
    _showSnackBar('Document viewer coming soon');
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }
}

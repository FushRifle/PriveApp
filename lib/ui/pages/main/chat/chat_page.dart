import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  Timer? _typingTimer;
  int? _conversationId;
  String _wallpaper = 'default';
  String _chatColor = 'default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _conversationId == null) return;

    final messageText = text.trim();
    _textController.clear();

    context.read<ChatBloc>().add(SendMessage(
          receiverId: _conversationId!,
          message: messageText,
          messageType: 'text',
        ));

    _scrollToBottom();
  }

  Future<void> _sendMedia(String filePath, String type) async {
    if (_conversationId == null) return;

    try {
      File file = File(filePath);
      String? mediaUrl;
      String messageText = 'Sent a $type';

      if (type == 'image') {
        mediaUrl = await _cloudinaryService.uploadImage(file);
      } else if (type == 'video') {
        mediaUrl = await _cloudinaryService.uploadVideo(file);
        messageText = 'Sent a video';
      } else if (type == 'document') {
        mediaUrl = await _cloudinaryService.uploadDocument(
            file, file.path.split('/').last);
        messageText = 'Sent a document';
      }

      if (mediaUrl != null) {
        context.read<ChatBloc>().add(SendMessage(
              receiverId: _conversationId!,
              message: messageText,
              messageType: type,
              mediaUrl: mediaUrl,
            ));
      }
    } catch (e) {
      debugPrint('Send media error: $e');
    }
  }

  void _sendTyping(bool isTyping) {
    if (_conversationId == null) return;

    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer =
          Timer(const Duration(seconds: 2), () => _sendTyping(false));
    }

    context.read<ChatBloc>().add(SetTyping(
          conversationId: _conversationId!,
          isTyping: isTyping,
        ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Color _getChatColor() {
    switch (_chatColor) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          // Update settings silently
          if (state.chatSettings != null &&
              (_wallpaper != state.chatSettings!.wallpaper ||
                  _chatColor != state.chatSettings!.chatColor)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _wallpaper = state.chatSettings!.wallpaper;
                _chatColor = state.chatSettings!.chatColor;
              });
            });
          }

          final messages = state.messages.reversed.toList();
          final isLoading =
              state.messagesStatus == ChatStatus.loading && messages.isEmpty;

          return Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary))
                    : messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) =>
                                _buildMessageBubble(messages[index]),
                          ),
              ),
              _buildTypingIndicator(state),
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatInfoPage(
              userName: widget.userName,
              userAvatar: widget.userAvatar,
              userId: widget.userId,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    )),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    final conv = state.conversations.firstWhere(
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
                    String status = 'Offline';
                    if (conv.isTyping) {
                      status = 'Typing...';
                    } else if (conv.isOnline) status = 'Online';

                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: conv.isOnline
                                ? AppColors.greenColor
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(status,
                            style:
                                AppTheme.greyTextStyle.copyWith(fontSize: 11)),
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
            onPressed: () {}),
        IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black),
            onPressed: () {}),
      ],
    );
  }

  Widget _buildAvatar() {
    final fallback =
        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U';
    if (widget.userAvatar.isNotEmpty && widget.userAvatar.startsWith('http')) {
      return CircleAvatar(
          radius: 18,
          backgroundImage: CachedNetworkImageProvider(widget.userAvatar));
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Text(fallback,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: AppColors.greyColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No messages yet',
              style: AppTheme.greyTextStyle
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Start the conversation',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ChatState state) {
    final conv = state.conversations.firstWhere(
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

    if (!conv.isTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(
                    3,
                    (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: 4 + (i == 1 ? 4 : 0),
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppColors.primary),
                        )),
                const SizedBox(width: 8),
                Text('Typing...',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: AppColors.primary, size: 28),
              onPressed: _showAttachmentOptions,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _textController,
                  style: AppTheme.blackTextStyle.copyWith(fontSize: 15),
                  onChanged: (t) => _sendTyping(t.isNotEmpty),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (t) {
                    if (t.trim().isNotEmpty) _sendMessage(t);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_textController.text.trim().isNotEmpty) {
                  _sendMessage(_textController.text);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getChatColor(),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
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
      padding:
          EdgeInsets.only(bottom: 12, left: isMe ? 0 : 8, right: isMe ? 8 : 0),
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
                  backgroundImage:
                      CachedNetworkImageProvider(widget.userAvatar)),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          placeholder: (_, __) => Container(
                              height: 200, color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  if (message.messageType == 'text')
                    Text(message.message,
                        style: TextStyle(
                            color: isMe ? Colors.white : AppColors.blackColor,
                            fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey.shade500),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOption(Icons.photo_library, 'Gallery',
                      () => _pickImage(ImageSource.gallery)),
                  _buildOption(Icons.camera_alt, 'Camera',
                      () => _pickImage(ImageSource.camera)),
                  _buildOption(Icons.videocam, 'Video', () => _pickVideo()),
                  _buildOption(Icons.document_scanner, 'Document',
                      () => _pickDocument()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.blackTextStyle.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image != null) await _sendMedia(image.path, 'image');
  }

  Future<void> _pickVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) await _sendMedia(video.path, 'video');
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _sendMedia(file.path!, 'document');
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _showImageViewer(String url) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  body: Stack(children: [
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
                  ]),
                )));
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

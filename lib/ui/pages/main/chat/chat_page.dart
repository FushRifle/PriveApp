import 'dart:async';
import 'dart:io';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/ui/pages/main/chat/chat_info_page.dart';
import 'package:clique/ui/widgets/chat/message_bubble.dart';
import 'package:clique/ui/widgets/chat/chat_input_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  final int conversationId;
  final String userName;
  final String userAvatar;
  final int userId;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.userName,
    required this.userAvatar,
    required this.userId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  String _wallpaper = 'default';
  Color _chatColor = AppColors.primary;
  MessageModel? _replyingTo;
  bool _isLoadingMore = false;
  bool _hasInitialMessages = false;
  bool _isSending = false;

  Timer? _typingTimer;
  Timer? _messageSyncTimer;
  bool _isTyping = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAuth();
    _loadInitialData();
    _setupScrollListener();
    _startMessageSync();
  }

  void _setupAuth() {
    final authState = context.read<AuthBloc>().state;
    if (authState.isAuthenticated && authState.token != null) {
      context.read<ChatBloc>().setAuthToken(authState.token!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingTimer?.cancel();
    _messageSyncTimer?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 200 &&
          !_isLoadingMore &&
          context.read<ChatBloc>().state.hasMoreMessages) {
        _loadMoreMessages();
      }
    });
  }

  void _sendTyping(bool typing) {
    if (_isTyping == typing) return;

    _isTyping = typing;

    context.read<ChatBloc>().add(
          SetTyping(
            conversationId: widget.conversationId,
            isTyping: typing,
          ),
        );

    _typingTimer?.cancel();

    if (typing) {
      _typingTimer = Timer(
        const Duration(seconds: 2),
        () {
          if (mounted) {
            _isTyping = false;

            context.read<ChatBloc>().add(
                  SetTyping(
                    conversationId: widget.conversationId,
                    isTyping: false,
                  ),
                );
          }
        },
      );
    }
  }

  void _loadInitialData() {
    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(LoadMessages(
      conversationId: widget.conversationId,
      page: 1,
      forceRefresh: true,
    ));
    chatBloc.add(LoadConversationInfo(conversationId: widget.conversationId));
    chatBloc.add(LoadChatSettings(conversationId: widget.conversationId));
    chatBloc.add(MarkMessagesAsRead(conversationId: widget.conversationId));
  }

  void _startMessageSync() {
    _messageSyncTimer?.cancel();
    _messageSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      context.read<ChatBloc>().add(LoadMessages(
            conversationId: widget.conversationId,
            page: 1,
            forceRefresh: true,
            silent: true,
          ));
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final currentPage = context.read<ChatBloc>().state.currentPage;
    context.read<ChatBloc>().add(LoadMessages(
          conversationId: widget.conversationId,
          page: currentPage + 1,
        ));
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isSending) return;

    _sendTyping(false);
    _isSending = true;

    context.read<ChatBloc>().add(
          SendMessage(
            conversationId: widget.conversationId,
            receiverId: widget.userId,
            message: text.trim(),
            messageType: 'text',
            replyToId: _replyingTo?.id,
            replyToMessage: _replyingTo?.message,
            replyToSender: _replyingTo?.isOwn == true ? 'You' : widget.userName,
          ),
        );

    setState(() {
      _replyingTo = null;
    });

    _scrollToBottom();
  }

  void _replyToMessage(MessageModel message) {
    setState(() => _replyingTo = message);
    _scrollToBottom();
  }

  void _sendMedia(File file, UploadType type) {
    context.read<CloudinaryCubit>().uploadFile(type: type, file: file);
  }

  Color _getChatColor() => _chatColor;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CloudinaryCubit, CloudinaryState>(
            listenWhen: (previous, current) =>
                current.status == UploadStatus.success &&
                current.uploadedUrl != null,
            listener: (context, state) {
              String messageText = '';
              switch (state.uploadType) {
                case UploadType.image:
                  messageText = 'Sent an image';
                  break;
                case UploadType.video:
                  messageText = 'Sent a video';
                  break;
                case UploadType.audio:
                  messageText = 'Sent an audio message';
                  break;
                case UploadType.document:
                  messageText = 'Sent a document';
                  break;
                default:
                  messageText = 'Sent a file';
              }
              context.read<ChatBloc>().add(SendMessage(
                    conversationId: widget.conversationId,
                    receiverId: widget.userId,
                    message: messageText,
                    messageType: state.uploadType!.name,
                    mediaUrl: state.uploadedUrl,
                  ));
              _scrollToBottom();
            },
          ),
          BlocListener<ChatBloc, ChatState>(
            listenWhen: (previous, current) =>
                previous.messages.length != current.messages.length ||
                previous.messagesStatus != current.messagesStatus ||
                previous.chatSettings != current.chatSettings,
            listener: (context, state) {
              if (state.chatSettings != null) {
                final settings = state.chatSettings!;
                if (_wallpaper != settings.wallpaper ||
                    _chatColor != _parseColor(settings.chatColor)) {
                  setState(() {
                    _wallpaper = settings.wallpaper;
                    _chatColor = _parseColor(settings.chatColor);
                  });
                }
              }
              if (state.messages.isNotEmpty && !_hasInitialMessages) {
                _hasInitialMessages = true;
                _scrollToBottom();
              }
              if (_isLoadingMore &&
                  state.messagesStatus != ChatStatus.loading) {
                setState(() => _isLoadingMore = false);
              }
              if (_isSending && state.messages.isNotEmpty) {
                _isSending = false;
              }
            },
          ),
        ],
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final messages = state.activeConversationId == widget.conversationId
                ? List<MessageModel>.from(state.messages).reversed.toList()
                : const <MessageModel>[];
            final isLoading =
                state.messagesStatus == ChatStatus.loading && messages.isEmpty;
            final isUploading = context.watch<CloudinaryCubit>().state.status ==
                UploadStatus.uploading;

            return Container(
              decoration: _buildChatBackground(),
              child: Column(
                children: [
                  Expanded(
                    child: isLoading
                        ? _buildLoadingState()
                        : messages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                reverse: false,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                itemCount:
                                    messages.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_isLoadingMore &&
                                      index == messages.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  }
                                  return MessageBubble(
                                    message: messages[index],
                                    userAvatar: widget.userAvatar,
                                    chatColor: _getChatColor(),
                                    index: index,
                                    onReply: () =>
                                        _replyToMessage(messages[index]),
                                  );
                                },
                              ),
                  ),
                  if (isUploading) _buildUploadProgress(),
                  if (_buildTypingIndicator(state))
                    _buildTypingIndicatorWidget(),
                  ChatInputBar(
                    onSendMessage: _sendMessage,
                    onTyping: _sendTyping,
                    replyingTo: _replyingTo,
                    onCancelReply: () => setState(() => _replyingTo = null),
                    sendButtonColor: _getChatColor(),
                    onPickImage: () => _pickImage(ImageSource.gallery),
                    onPickVideo: _pickVideo,
                    onPickDocument: _pickDocument,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }

  Widget _buildUploadProgress() {
    return BlocBuilder<CloudinaryCubit, CloudinaryState>(
      builder: (context, state) {
        if (state.status != UploadStatus.uploading) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Uploading...',
                      style: const TextStyle(fontSize: 12))),
              Text('${(state.progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDark ? AppColors.darkText : AppColors.lightText;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: foregroundColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(
                  value: context.read<ChatBloc>(),
                ),
                BlocProvider(
                  create: (_) => ChatGalleryCubit(),
                ),
              ],
              child: ChatInfoPage(
                userName: widget.userName,
                userAvatar: widget.userAvatar,
                conversationId: widget.conversationId,
                userId: widget.userId,
              ),
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
                    style: AppTheme.blackTextStyle
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    final conv = state.conversations.firstWhere(
                      (c) => c.userId == widget.userId,
                      orElse: () => ConversationModel(
                        id: 0,
                        userId: 0,
                        name: '',
                        username: '',
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
                      ),
                    );
                    String status = 'Offline';
                    if (conv.isTyping) {
                      status = 'Typing...';
                    } else if (conv.isOnline) {
                      status = 'Online';
                    }

                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: conv.isOnline
                                ? AppColors.greenColor
                                : AppColors.grey,
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
            icon: Icon(Icons.call_outlined, color: foregroundColor),
            onPressed: () {}),
        IconButton(
            icon: Icon(Icons.videocam_outlined, color: foregroundColor),
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

  bool _buildTypingIndicator(ChatState state) {
    final conv = state.conversations.firstWhere(
      (c) => c.userId == widget.userId,
      orElse: () => ConversationModel(
        id: 0,
        userId: 0,
        name: '',
        username: '',
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
      ),
    );
    return conv.isTyping;
  }

  Widget _buildTypingIndicatorWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(
                    3,
                    (i) => Container(
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

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image != null) _sendMedia(File(image.path), UploadType.image);
  }

  Future<void> _pickVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) _sendMedia(File(video.path), UploadType.video);
  }

  Future<void> _pickDocument() async {
    final file = await FilePicker.pickFile();
    if (file != null && file.path != null) {
      _sendMedia(File(file.path!), UploadType.document);
    }
  }

  Color _parseColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return AppColors.blue;
      case 'green':
        return AppColors.green;
      case 'purple':
        return AppColors.purple;
      case 'pink':
        return AppColors.pink;
      case 'orange':
        return AppColors.orange;
      case 'teal':
        return AppColors.teal;
      case 'indigo':
        return AppColors.indigo;
      default:
        return AppColors.primary;
    }
  }

  BoxDecoration _buildChatBackground() {
    final wallpaperAsset = _wallpaperAsset(_wallpaper);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (wallpaperAsset == null) {
      return BoxDecoration(color: AppColors.backgroundColor);
    }

    return BoxDecoration(
      color: AppColors.backgroundColor,
      image: DecorationImage(
        image: AssetImage(wallpaperAsset),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          (isDark ? AppColors.black : AppColors.white).withOpacity(0.22),
          BlendMode.srcATop,
        ),
      ),
    );
  }

  String? _wallpaperAsset(String wallpaper) {
    switch (wallpaper) {
      case 'palms':
      case 'modern':
      case 'sunset':
      case 'sky':
      case 'galaxy':
        return 'assets/wallpapers/$wallpaper.png';
      default:
        return null;
    }
  }
}

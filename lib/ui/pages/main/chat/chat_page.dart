import 'dart:async';
import 'dart:io';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/ui/widgets/call/call_button.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/core/models/chat_wallpaper.dart';
import 'package:clique/core/services/media_service.dart';
import 'package:clique/ui/pages/main/chat/chat_info_page.dart';
import 'package:clique/ui/widgets/chat/message_bubble.dart';
import 'package:clique/ui/widgets/chat/chat_input_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatefulWidget {
  final int conversationId;
  final String userName;
  final String userAvatar;
  final int userId;
  final int maxOutgoingMessages;
  final String? messageLimitHint;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.userName,
    required this.userAvatar,
    required this.userId,
    this.maxOutgoingMessages = 0,
    this.messageLimitHint,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final MediaService _mediaService = MediaService();
  final ChatService _chatService = ChatService();

  String _wallpaper = 'default';
  Color _chatColor = AppColors.primary;
  MessageModel? _replyingTo;
  bool _isLoadingMore = false;
  bool _hasInitialMessages = false;
  bool _isSending = false;
  bool _showScrollToBottom = false;

  Timer? _typingTimer;
  Timer? _draftTimer;
  bool _isTyping = false;
  late final VoidCallback _scrollListener;

  @override
  bool get wantKeepAlive => true;

  bool get _isCliqueBot =>
      widget.userId == 0 || widget.userName.toLowerCase() == 'clique';

  bool get _hasMessageLimit => widget.maxOutgoingMessages > 0;

  int _outgoingMessageCount(List<MessageModel> messages) {
    return messages.where((message) => message.isOwn).length;
  }

  bool _hasReachedMessageLimit(List<MessageModel> messages) {
    if (!_hasMessageLimit) return false;
    return _outgoingMessageCount(messages) >= widget.maxOutgoingMessages;
  }

  void _showMessageLimitSnack() {
    _showSnackBar(
      widget.messageLimitHint ??
          'You have reached the message limit for this conversation.',
      isError: true,
    );
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
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuth();
    _scrollListener = _handleScroll;
    _scrollController.addListener(_scrollListener);
    _messageController.addListener(_queueDraftSave);
    _restoreDraft();
    _loadInitialData();
  }

  void _setupAuth() {
    final authState = context.read<AuthBloc>().state;
    if (authState.isAuthenticated && authState.token != null) {
      context.read<ChatBloc>().setAuthToken(authState.token!);
    }
  }

  @override
  void dispose() {
    _saveDraftNow();
    _draftTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _messageController.removeListener(_queueDraftSave);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _restoreDraft() {
    final draft = _chatService.readCachedDraft(
      widget.conversationId,
      cacheOwnerId: _readCurrentUserId(),
    );
    if (draft == null || draft.isEmpty) return;
    _messageController.text = draft;
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
  }

  int? _readCurrentUserId() {
    final user = context.read<AuthBloc>().state.user;
    final raw = user?['id'] ?? user?['userId'] ?? user?['user_id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  void _queueDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 350), _saveDraftNow);
  }

  void _saveDraftNow() {
    unawaited(
      _chatService.saveDraft(
        widget.conversationId,
        _messageController.text,
        cacheOwnerId: _readCurrentUserId(),
      ),
    );
  }

  void _clearDraft() {
    _draftTimer?.cancel();
    unawaited(
      _chatService.clearDraft(
        widget.conversationId,
        cacheOwnerId: _readCurrentUserId(),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted || _isCliqueBot) return;

    context.read<ChatBloc>().add(
          RetryPendingMessages(conversationId: widget.conversationId),
        );
    context.read<ChatBloc>().add(LoadMessages(
          conversationId: widget.conversationId,
          page: 1,
          forceRefresh: true,
          silent: true,
        ));
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAwayFromBottom = position.pixels > 280;
    if (_showScrollToBottom != isAwayFromBottom) {
      setState(() => _showScrollToBottom = isAwayFromBottom);
    }

    final isNearTop = position.maxScrollExtent - position.pixels <= 200;
    if (isNearTop &&
        !_isLoadingMore &&
        !_isCliqueBot &&
        context.read<ChatBloc>().state.hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  void _sendTyping(bool typing) {
    if (_isCliqueBot) return;
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
    if (_isCliqueBot) {
      chatBloc.add(LoadCliqueBotMessages(
        conversationId: widget.conversationId,
      ));
      return;
    }

    chatBloc.add(LoadMessages(
      conversationId: widget.conversationId,
      page: 1,
    ));
    chatBloc.add(LoadConversationInfo(conversationId: widget.conversationId));
    chatBloc.add(LoadChatSettings(conversationId: widget.conversationId));
    chatBloc.add(MarkMessagesAsRead(conversationId: widget.conversationId));
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

    if (_hasReachedMessageLimit(context.read<ChatBloc>().state.messages)) {
      _showMessageLimitSnack();
      return;
    }

    HapticFeedback.lightImpact();
    _sendTyping(false);
    _isSending = true;
    _clearDraft();

    if (_isCliqueBot) {
      context.read<ChatBloc>().add(
            SendCliqueBotMessage(
              conversationId: widget.conversationId,
              message: text.trim(),
              replyToId: _replyingTo?.id,
              replyToMessage: _replyingTo?.message,
              replyToSender:
                  _replyingTo?.isOwn == true ? 'You' : widget.userName,
            ),
          );
      setState(() {
        _replyingTo = null;
      });
      _isSending = false;
      _scrollToBottom();
      return;
    }

    context.read<ChatBloc>().add(
          SendMessage(
            conversationId: widget.conversationId,
            receiverId: widget.userId,
            message: text.trim(),
            messageType: 'text',
            replyToId: _replyingTo?.id,
            replyToMessage: _replyingTo?.message,
            replyToSender: _replyingTo?.isOwn == true ? 'You' : widget.userName,
            replyToStreamMessageId:
                _replyingTo?.streamMessageId ?? _replyingTo?.id.toString(),
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
    if (_hasReachedMessageLimit(context.read<ChatBloc>().state.messages)) {
      _showMessageLimitSnack();
      return;
    }

    context.read<CloudinaryCubit>().uploadFile(type: type, file: file);
  }

  Color _getChatColor() => _chatColor;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent >= 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.pixels < 180;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CloudinaryCubit, CloudinaryState>(
            listenWhen: (previous, current) =>
                current.status == UploadStatus.success &&
                current.uploadedUrl != null,
            listener: (context, state) {
              final currentMessages = context.read<ChatBloc>().state.messages;
              if (_hasReachedMessageLimit(currentMessages)) {
                _showMessageLimitSnack();
                return;
              }

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
                    replyToStreamMessageId: _replyingTo?.streamMessageId ??
                        _replyingTo?.id.toString(),
                  ));
              HapticFeedback.lightImpact();
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
              final shouldAutoScroll = !_hasInitialMessages || _isNearBottom();
              if (state.messages.isNotEmpty && shouldAutoScroll) {
                _hasInitialMessages = true;
                _scrollToBottom();
              } else if (state.messages.isNotEmpty && mounted) {
                setState(() => _showScrollToBottom = true);
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
          buildWhen: (previous, current) {
            return previous.activeConversationId !=
                    current.activeConversationId ||
                previous.messages != current.messages ||
                previous.messagesStatus != current.messagesStatus ||
                previous.chatSettings != current.chatSettings;
          },
          builder: (context, state) {
            final messages = state.activeConversationId == widget.conversationId
                ? state.messages
                : const <MessageModel>[];
            final isLoading =
                state.messagesStatus == ChatStatus.loading && messages.isEmpty;
            final isSyncing = state.messagesStatus == ChatStatus.loading &&
                messages.isNotEmpty;
            final isUploading = context.watch<CloudinaryCubit>().state.status ==
                UploadStatus.uploading;

            return Container(
              decoration: _buildChatBackground(),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        isLoading
                            ? _buildLoadingState()
                            : messages.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    controller: _scrollController,
                                    reverse: true,
                                    cacheExtent: 1400,
                                    addAutomaticKeepAlives: true,
                                    addRepaintBoundaries: true,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    itemCount: messages.length +
                                        (_isLoadingMore ? 1 : 0),
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
                                      final message = messages[index];
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MessageBubble(
                                            message: message,
                                            userAvatar: widget.userAvatar,
                                            chatColor: _getChatColor(),
                                            index: index,
                                            onReply: () =>
                                                _replyToMessage(message),
                                            onRetry: message.isPending
                                                ? () => context
                                                    .read<ChatBloc>()
                                                    .add(RetryPendingMessages(
                                                        conversationId: widget
                                                            .conversationId))
                                                : null,
                                          ),
                                          if (_shouldShowDateSeparator(
                                              messages, index))
                                            _DateSeparator(
                                              label: _formatMessageDate(
                                                message.createdAt,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                        if (_showScrollToBottom && messages.isNotEmpty)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton.small(
                              heroTag:
                                  'chat_scroll_bottom_${widget.conversationId}',
                              backgroundColor: _getChatColor(),
                              foregroundColor: AppColors.white,
                              onPressed: _scrollToBottom,
                              child: const Icon(Icons.keyboard_arrow_down),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSyncing) _buildSyncIndicator(),
                  if (isUploading) _buildUploadProgress(),
                  if (_buildTypingIndicator(state))
                    _buildTypingIndicatorWidget(),
                  if (_hasMessageLimit) _buildMessageLimitBanner(messages),
                  ChatInputBar(
                    controller: _messageController,
                    onSendMessage: _sendMessage,
                    onTyping: _sendTyping,
                    replyingTo: _replyingTo,
                    onCancelReply: () => setState(() => _replyingTo = null),
                    sendButtonColor: _getChatColor(),
                    onPickImage: () => _pickImage(ImageSource.gallery),
                    onPickCamera: () => _pickImage(ImageSource.camera),
                    onPickVideo: _pickVideo,
                    onPickDocument: _pickDocument,
                    onSendVoice: (file) => _sendMedia(file, UploadType.audio),
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mine = index.isEven;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: MediaQuery.sizeOf(context).width * (mine ? 0.58 : 0.66),
            height: index == 1 ? 58 : 42,
            decoration: BoxDecoration(
              color: AppColors.cardColor.withOpacity(0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border.withOpacity(0.45)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSyncIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border.withOpacity(0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: _getChatColor(),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Syncing...',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
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
                  buildWhen: (previous, current) {
                    return previous.conversations != current.conversations;
                  },
                  builder: (context, state) {
                    if (_isCliqueBot) {
                      return Text('Always here',
                          style: AppTheme.greyTextStyle.copyWith(fontSize: 11));
                    }
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
        if (!_isCliqueBot && widget.userId > 0) ...[
          IconButton(
            icon: Icon(Icons.call_outlined, color: foregroundColor),
            onPressed: () => _startCall('voice'),
          ),
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: foregroundColor),
            onPressed: () => _startCall('video'),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    final fallback =
        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U';
    if (_isCliqueBot) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: Text(
          'C',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      );
    }
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
          Text(_isCliqueBot ? 'Say hi to Clique' : 'No messages yet',
              style: AppTheme.greyTextStyle
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
              _isCliqueBot
                  ? 'Your chat is saved on this device'
                  : 'Start the conversation',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  bool _buildTypingIndicator(ChatState state) {
    if (_isCliqueBot) return false;
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

  Widget _buildMessageLimitBanner(List<MessageModel> messages) {
    final remaining =
        (widget.maxOutgoingMessages - _outgoingMessageCount(messages))
            .clamp(0, widget.maxOutgoingMessages);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.messageLimitHint ??
                    'You can send $remaining more message${remaining == 1 ? '' : 's'} here.',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index >= messages.length) return false;
    if (index == messages.length - 1) return true;
    final current = messages[index].createdAt.toLocal();
    final older = messages[index + 1].createdAt.toLocal();
    return current.year != older.year ||
        current.month != older.month ||
        current.day != older.day;
  }

  String _formatMessageDate(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final delta = today.difference(day).inDays;
    if (delta == 0) return 'Today';
    if (delta == 1) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image == null) return;
    if (!mounted) return;

    final cropped = await _mediaService.cropImage(image, context: context);
    if (cropped != null) _sendMedia(File(cropped.path), UploadType.image);
  }

  Future<void> _pickVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video != null) _sendMedia(File(video.path), UploadType.video);
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles();
    final file = result?.files.single;
    if (file?.path != null) {
      _sendMedia(File(file!.path!), UploadType.document);
    }
  }

  void _startCall(String callType) {
    HapticFeedback.lightImpact();
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
    final wallpaperColor = ChatWallpapers.colorFor(_wallpaper);

    if (wallpaperColor != null) {
      return BoxDecoration(color: wallpaperColor);
    }

    if (wallpaperAsset == null) {
      return BoxDecoration(color: AppColors.backgroundColor);
    }

    return BoxDecoration(
      color: AppColors.backgroundColor,
      image: DecorationImage(
        image: AssetImage(wallpaperAsset),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        colorFilter: ColorFilter.mode(
          (isDark ? AppColors.black : AppColors.white).withOpacity(0.10),
          BlendMode.srcOver,
        ),
      ),
    );
  }

  String? _wallpaperAsset(String wallpaper) {
    if (wallpaper == 'default') return _defaultWallpaperAsset();
    return ChatWallpapers.assetFor(wallpaper);
  }

  String _defaultWallpaperAsset() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? 'assets/wallpapers/galaxy.png'
        : 'assets/wallpapers/modern.png';
  }
}

class _DateSeparator extends StatelessWidget {
  final String label;

  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.black.withOpacity(0.24)
                : AppColors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? AppColors.white10 : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

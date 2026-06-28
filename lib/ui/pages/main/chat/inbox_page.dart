import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/ui/pages/main/chat/archived_chat_page.dart';
import 'package:clique/ui/pages/main/chat/chat_page.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:clique/ui/widgets/chat/inbox/inbox_loading_shimmer.dart';
import 'package:clique/ui/widgets/chat/inbox/inbox_message_item.dart';
import 'package:clique/ui/widgets/chat/inbox/inbox_toolbar.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  InboxFilter _filter = InboxFilter.all;
  String _query = '';
  bool _showInitialShimmer = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _scrollController.addListener(_handleScroll);
    _loadConversations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showInitialShimmer = false);
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 500) {
      return;
    }
    final state = context.read<ChatBloc>().state;
    if (state.hasMoreConversations &&
        state.conversationsStatus != ChatStatus.refreshing) {
      context.read<ChatBloc>().add(LoadMoreConversations());
    }
  }

  void _loadConversations() {
    context.read<ChatBloc>().add(LoadConversations());
  }

  Future<void> _refreshConversations() async {
    context.read<ChatBloc>().add(RefreshConversations());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _query) return;
    setState(() => _query = next);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Inbox',
            subtitle: 'Chat With Your Clique.',
            leadingIcon: Icons.message_outlined,
            actionIcon: Icons.archive_rounded,
            onActionTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ChatBloc>(),
                    child: const ArchivedChatPage(),
                  ),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          InboxToolbar(
            controller: _searchController,
            filter: _filter,
            onFilterChanged: (filter) {
              HapticFeedback.selectionClick();
              setState(() => _filter = filter);
            },
            onClearSearch: () => _searchController.clear(),
          ),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              color: AppColors.primary,
              onRefresh: _refreshConversations,
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (previous, current) {
                  return previous.conversations != current.conversations ||
                      previous.conversationsStatus !=
                          current.conversationsStatus ||
                      previous.error != current.error;
                },
                builder: (context, state) {
                  final allConversations = _getDisplayConversations(state);
                  final conversations = _applyFilters(allConversations);
                  final hasCachedOrLiveConversations =
                      allConversations.isNotEmpty;

                  if ((_showInitialShimmer ||
                          state.conversationsStatus == ChatStatus.initial ||
                          state.conversationsStatus == ChatStatus.loading) &&
                      !hasCachedOrLiveConversations) {
                    return const InboxLoadingShimmer();
                  }

                  if (state.conversationsStatus == ChatStatus.error &&
                      !hasCachedOrLiveConversations) {
                    return _buildErrorWidget(state.error);
                  }

                  if (allConversations.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (conversations.isEmpty) {
                    return _buildFilteredEmptyState();
                  }

                  return _buildMessageList(conversations);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No messages yet',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a conversation with someone\nto see your messages here',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.redColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.redColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Failed to load conversations',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadConversations,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(140, 42),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    final label = _query.isNotEmpty
        ? 'No conversations match your search'
        : switch (_filter) {
            InboxFilter.unread => 'No unread conversations',
            InboxFilter.pinned => 'No pinned conversations',
            InboxFilter.all => 'No conversations',
          };
    final subtitle = _query.isNotEmpty
        ? 'Try a name or message preview from another conversation.'
        : switch (_filter) {
            InboxFilter.unread => 'New messages will appear here.',
            InboxFilter.pinned => 'Pin important chats to keep them close.',
            InboxFilter.all => 'Start a conversation to see it here.',
          };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 96),
        Icon(
          _query.isNotEmpty
              ? Icons.manage_search_rounded
              : Icons.filter_list_rounded,
          size: 42,
          color: AppColors.textHint,
        ),
        const SizedBox(height: 16),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTheme.greyTextStyle.copyWith(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  List<ChatMessage> _getDisplayConversations(ChatState state) {
    final conversations = <ChatMessage>[];
    final ownerId = _readCurrentUserId();
    final archivedIds = _chatService.readArchivedConversationIds(
      cacheOwnerId: ownerId,
    );
    final mergedSource = <ConversationModel>[];

    if (state.conversations.isNotEmpty) {
      mergedSource.addAll(state.conversations);
    } else {
      final cachedConversations = _chatService.readCachedConversations(
        cacheOwnerId: ownerId,
      );
      for (final conv in cachedConversations) {
        try {
          mergedSource.add(ConversationModel.fromJson(conv));
        } catch (_) {}
      }
    }

    for (final conv in mergedSource) {
      if (archivedIds.contains(conv.id)) continue;
      final isBot = conv.name.toLowerCase() == 'clique' ||
          conv.username.toLowerCase() == 'clique';
      final latestCachedMessage = _latestCachedMessage(
        conv.id,
        ownerId: ownerId,
      );
      final displayMessage = _pickDisplayMessage(conv, latestCachedMessage);
      final displayTime = _pickDisplayTime(conv, latestCachedMessage);

      conversations.add(ChatMessage(
        id: conv.id.toString(),
        userId: conv.userId,
        name: conv.name,
        message: displayMessage.isNotEmpty
            ? displayMessage
            : (isBot ? 'Welcome to Clique! 👋' : 'No messages yet'),
        time: _formatTimestamp(displayTime),
        avatar: conv.avatar,
        isUnread: conv.unreadCount > 0,
        isOnline: conv.isOnline,
        isTyping: conv.isTyping,
        unreadCount: conv.unreadCount,
        isPinned: conv.isPinned,
        isMuted: conv.isMuted,
        sortTime: _parseTime(displayTime),
      ));
    }

    conversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.sortTime.compareTo(a.sortTime);
    });

    return conversations;
  }

  List<ChatMessage> _applyFilters(List<ChatMessage> conversations) {
    return conversations.where((conversation) {
      switch (_filter) {
        case InboxFilter.unread:
          if (!conversation.isUnread) return false;
          break;
        case InboxFilter.pinned:
          if (!conversation.isPinned) return false;
          break;
        case InboxFilter.all:
          break;
      }

      if (_query.isEmpty) return true;
      return conversation.name.toLowerCase().contains(_query) ||
          conversation.message.toLowerCase().contains(_query);
    }).toList();
  }

  Map<String, dynamic>? _latestCachedMessage(
    int conversationId, {
    int? ownerId,
  }) {
    final messages = _chatService.readCachedMessages(
      conversationId,
      cacheOwnerId: ownerId,
    );
    if (messages.isEmpty) return null;

    Map<String, dynamic>? latest;
    DateTime latestTime = DateTime.fromMillisecondsSinceEpoch(0);

    for (final message in messages) {
      final parsed = _parseTime(message['createdAt']?.toString() ?? '');
      if (parsed.isAfter(latestTime)) {
        latest = message;
        latestTime = parsed;
      }
    }

    return latest;
  }

  String _pickDisplayMessage(
    ConversationModel conversation,
    Map<String, dynamic>? cachedMessage,
  ) {
    final cachedText = cachedMessage?['message']?.toString().trim() ?? '';
    final cachedType =
        (cachedMessage?['messageType'] ?? cachedMessage?['message_type'])
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';
    final isPending = _readInt(cachedMessage?['id']) < 0;
    final prefix = isPending ? 'Sending... ' : '';
    if (cachedType.isNotEmpty && cachedType != 'text') {
      return '$prefix${_previewForMessageType(cachedType)}';
    }
    if (cachedText.isNotEmpty) return '$prefix$cachedText';

    final conversationType = conversation.lastMessageType.trim().toLowerCase();
    if (conversationType.isNotEmpty && conversationType != 'text') {
      return _previewForMessageType(conversationType);
    }
    return conversation.lastMessage.trim();
  }

  String _pickDisplayTime(
    ConversationModel conversation,
    Map<String, dynamic>? cachedMessage,
  ) {
    final cachedTime = cachedMessage?['createdAt']?.toString().trim() ?? '';
    if (cachedTime.isNotEmpty) return cachedTime;
    return conversation.timestamp;
  }

  int? _readCurrentUserId() {
    final user = context.read<AuthBloc>().state.user;
    final rawId = user?['id'] ?? user?['userId'] ?? user?['user_id'];
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _previewForMessageType(String type) {
    switch (type) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice note';
      case 'document':
        return 'Document';
      case 'reel':
        return 'Reel';
      case 'post':
        return 'Post';
      default:
        return 'Attachment';
    }
  }

  DateTime _parseTime(String value) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return 'Now';

    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inDays >= 7) {
        return '${diff.inDays ~/ 7}w';
      } else if (diff.inDays >= 1) {
        return '${diff.inDays}d';
      } else if (diff.inHours >= 1) {
        return '${diff.inHours}h';
      } else if (diff.inMinutes >= 1) {
        return '${diff.inMinutes}m';
      } else {
        return 'Now';
      }
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildMessageList(List<ChatMessage> conversations) {
    return ListView.builder(
      key: const PageStorageKey<String>('chat-inbox-list'),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final message = conversations[index];
        return InboxMessageItem(
          message: message,
          onTap: () => _openChat(message),
          onLongPress: () => _showConversationActions(message),
          onPin: () => _togglePin(message),
          onMute: () => _toggleMute(message),
          onMarkUnread: () => _markUnread(message),
          onArchive: () => _archiveConversation(message),
        );
      },
    );
  }

  void _openChat(ChatMessage message) {
    HapticFeedback.lightImpact();
    final conversationId = int.tryParse(message.id);
    if (conversationId == null) return;

    if (message.unreadCount > 0) {
      context.read<ChatBloc>().add(
            SetConversationUnread(
              conversationId: conversationId,
              unreadCount: 0,
            ),
          );
      context.read<ChatBloc>().add(
            MarkMessagesAsRead(conversationId: conversationId),
          );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: ChatPage(
            conversationId: conversationId,
            userName: message.name,
            userAvatar: message.avatar,
            userId: message.userId,
          ),
        ),
      ),
    );
  }

  Future<void> _archiveConversation(ChatMessage message) async {
    HapticFeedback.mediumImpact();
    final conversationId = int.tryParse(message.id);
    if (conversationId == null) return;

    await _chatService.archiveConversation(
      conversationId,
      cacheOwnerId: _readCurrentUserId(),
    );
    if (!mounted) return;
    setState(() {});
    _showInboxSnack(
      icon: Icons.archive_rounded,
      message: 'Conversation with ${message.name} archived',
    );
  }

  void _togglePin(ChatMessage message) {
    HapticFeedback.selectionClick();
    final conversationId = int.tryParse(message.id);
    if (conversationId == null) return;

    context.read<ChatBloc>().add(
          UpdateChatSettings(
            conversationId: conversationId,
            isPinned: !message.isPinned,
          ),
        );
    _showInboxSnack(
      icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
      message: message.isPinned ? 'Chat unpinned' : 'Chat pinned',
    );
  }

  void _toggleMute(ChatMessage message) {
    HapticFeedback.selectionClick();
    final conversationId = int.tryParse(message.id);
    if (conversationId == null) return;
    final nextMuted = !message.isMuted;

    context.read<ChatBloc>().add(
          UpdateChatSettings(
            conversationId: conversationId,
            isMuted: nextMuted,
            muteUntil: nextMuted
                ? DateTime.now().add(const Duration(days: 3650))
                : null,
          ),
        );
    _showInboxSnack(
      icon: nextMuted
          ? Icons.notifications_off_rounded
          : Icons.notifications_active_outlined,
      message: nextMuted ? 'Chat muted' : 'Chat unmuted',
    );
  }

  void _markUnread(ChatMessage message) {
    HapticFeedback.selectionClick();
    final conversationId = int.tryParse(message.id);
    if (conversationId == null) return;

    context.read<ChatBloc>().add(
          SetConversationUnread(
            conversationId: conversationId,
            unreadCount: message.unreadCount > 0 ? message.unreadCount : 1,
          ),
        );
    _showInboxSnack(
      icon: Icons.mark_chat_unread_outlined,
      message: 'Marked unread',
    );
  }

  void _showConversationActions(ChatMessage message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: _ActionIcon(
                    icon: message.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin_rounded,
                  ),
                  title: Text(message.isPinned ? 'Unpin chat' : 'Pin chat'),
                  onTap: () {
                    Navigator.pop(context);
                    _togglePin(message);
                  },
                ),
                ListTile(
                  leading: _ActionIcon(
                    icon: message.isMuted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_rounded,
                  ),
                  title: Text(message.isMuted ? 'Unmute chat' : 'Mute chat'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleMute(message);
                  },
                ),
                ListTile(
                  leading: const _ActionIcon(
                    icon: Icons.mark_chat_unread_outlined,
                  ),
                  title: const Text('Mark unread'),
                  onTap: () {
                    Navigator.pop(context);
                    _markUnread(message);
                  },
                ),
                ListTile(
                  leading: const _ActionIcon(icon: Icons.archive_rounded),
                  title: const Text('Archive chat'),
                  onTap: () {
                    Navigator.pop(context);
                    _archiveConversation(message);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInboxSnack({
    required IconData icon,
    required String message,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.text.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Small helper icon used in the bottom sheet
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  const _ActionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

// Public data model – used by both this file and the extracted widgets
class ChatMessage {
  final String id;
  final int userId;
  final String name;
  final String message;
  final String time;
  final String avatar;
  final bool isUnread;
  final bool isOnline;
  final bool isTyping;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final DateTime sortTime;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.name,
    required this.message,
    required this.time,
    required this.avatar,
    required this.isUnread,
    required this.isOnline,
    required this.isTyping,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    required this.sortTime,
  });
}

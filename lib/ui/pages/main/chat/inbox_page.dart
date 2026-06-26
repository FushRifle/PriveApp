import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/ui/pages/main/chat/archived_chat_page.dart';
import 'package:clique/ui/pages/main/chat/chat_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/core/services/chat/chat_service.dart';

import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:clique/ui/widgets/chat/inbox_loading_shimmer.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  _InboxFilter _filter = _InboxFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
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
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Messages',
            subtitle: 'Your conversations',
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
          _InboxToolbar(
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

                  if (state.conversationsStatus == ChatStatus.loading &&
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

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildMessageList(context, conversations),
                  );
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
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 40,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No messages yet',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a conversation with someone\nto see your messages here',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 14,
                  height: 1.5,
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.redColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.redColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Failed to load conversations',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadConversations,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 46),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ChatMessage> _getDisplayConversations(ChatState state) {
    final conversations = <_ChatMessage>[];
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

      conversations.add(_ChatMessage(
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

  List<_ChatMessage> _applyFilters(List<_ChatMessage> conversations) {
    return conversations.where((conversation) {
      switch (_filter) {
        case _InboxFilter.unread:
          if (!conversation.isUnread) return false;
          break;
        case _InboxFilter.pinned:
          if (!conversation.isPinned) return false;
          break;
        case _InboxFilter.all:
          break;
      }

      if (_query.isEmpty) return true;
      return conversation.name.toLowerCase().contains(_query) ||
          conversation.message.toLowerCase().contains(_query);
    }).toList();
  }

  Widget _buildFilteredEmptyState() {
    final label = _query.isNotEmpty
        ? 'No conversations match your search'
        : switch (_filter) {
            _InboxFilter.unread => 'No unread conversations',
            _InboxFilter.pinned => 'No pinned conversations',
            _InboxFilter.all => 'No conversations',
          };
    final subtitle = _query.isNotEmpty
        ? 'Try a name or message preview from another conversation.'
        : switch (_filter) {
            _InboxFilter.unread => 'New messages will appear here.',
            _InboxFilter.pinned => 'Pin important chats to keep them close.',
            _InboxFilter.all => 'Start a conversation to see it here.',
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
          size: 54,
          color: AppColors.textHint,
        ),
        const SizedBox(height: 16),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
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

  Widget _buildMessageList(
      BuildContext context, List<_ChatMessage> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with someone\nto see your messages here',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final message = conversations[index];
        return _buildMessageItem(context, message);
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, _ChatMessage message) {
    final firstLetter =
        message.name.isNotEmpty ? message.name[0].toUpperCase() : 'U';
    final isBot = message.name.toLowerCase() == 'clique';

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _togglePin(message);
          return false;
        }

        await _archiveConversation(message);
        return true;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withOpacity(0.9),
              AppColors.secondary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Icon(
          message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          color: AppColors.white,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.archive_rounded,
          color: AppColors.white,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          _openChat(message);
        },
        onLongPress: () => _showConversationActions(message),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: message.isUnread
                ? AppColors.primary.withOpacity(0.04)
                : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: message.isUnread
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: message.isUnread
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: message.isUnread
                            ? AppColors.primary.withOpacity(0.3)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        if (message.isUnread)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildAvatar(message, firstLetter),
                    ),
                  ),
                  if (message.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.greenColor,
                          border: Border.all(
                            color: AppColors.card,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greenColor.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  message.name,
                                  style: AppTheme.blackTextStyle.copyWith(
                                    fontWeight: message.isUnread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBot) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 11,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                              if (message.isPinned) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: message.isUnread
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (message.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.notifications_off_rounded,
                              size: 14,
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            message.isTyping ? 'typing...' : message.message,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              color: message.isTyping
                                  ? AppColors.primary
                                  : message.isUnread
                                      ? AppColors.text
                                      : AppColors.textSecondary,
                              fontWeight: message.isTyping || message.isUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (message.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              message.unreadCount > 99
                                  ? '99+'
                                  : '${message.unreadCount}',
                              style: AppTheme.whiteTextStyle.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(_ChatMessage message) {
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

  Future<void> _archiveConversation(_ChatMessage message) async {
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

  void _togglePin(_ChatMessage message) {
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

  void _toggleMute(_ChatMessage message) {
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

  void _markUnread(_ChatMessage message) {
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

  void _showConversationActions(_ChatMessage message) {
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
                style: TextStyle(color: AppColors.text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildAvatar(_ChatMessage message, String firstLetter) {
    if (message.name.toLowerCase() == 'clique') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            'C',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      );
    }

    if (message.avatar.isNotEmpty && message.avatar.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: message.avatar,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _avatarFallback(firstLetter),
        placeholder: (_, __) => Container(
          color: AppColors.primary.withOpacity(0.05),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
        ),
      );
    }

    return _avatarFallback(firstLetter);
  }

  Widget _avatarFallback(String text) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.primary.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

enum _InboxFilter { all, unread, pinned }

class _InboxToolbar extends StatelessWidget {
  final TextEditingController controller;
  final _InboxFilter filter;
  final ValueChanged<_InboxFilter> onFilterChanged;
  final VoidCallback onClearSearch;

  const _InboxToolbar({
    required this.controller,
    required this.filter,
    required this.onFilterChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search conversations',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_InboxFilter>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: _InboxFilter.all,
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text('All'),
                  ),
                  ButtonSegment(
                    value: _InboxFilter.unread,
                    icon: Icon(Icons.mark_chat_unread_outlined, size: 16),
                    label: Text('Unread'),
                  ),
                  ButtonSegment(
                    value: _InboxFilter.pinned,
                    icon: Icon(Icons.push_pin_outlined, size: 16),
                    label: Text('Pinned'),
                  ),
                ],
                selected: {filter},
                onSelectionChanged: (values) => onFilterChanged(values.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _ChatMessage {
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

  _ChatMessage({
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

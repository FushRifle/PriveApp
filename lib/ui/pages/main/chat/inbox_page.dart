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
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    context.read<ChatBloc>().add(LoadConversations());
  }

  Future<void> _refreshConversations() async {
    context.read<ChatBloc>().add(RefreshConversations());
    await Future.delayed(const Duration(milliseconds: 500));
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
                  final conversations = _getDisplayConversations(state);
                  final hasCachedOrLiveConversations = conversations.isNotEmpty;

                  if (state.conversationsStatus == ChatStatus.loading &&
                      !hasCachedOrLiveConversations) {
                    return const InboxLoadingShimmer();
                  }

                  if (state.conversationsStatus == ChatStatus.error &&
                      !hasCachedOrLiveConversations) {
                    return _buildErrorWidget(state.error);
                  }

                  if (conversations.isEmpty) {
                    return _buildEmptyState();
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

    final sortedConversations = List.of(mergedSource);
    sortedConversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return _parseTime(b.timestamp).compareTo(_parseTime(a.timestamp));
    });

    for (final conv in sortedConversations) {
      if (archivedIds.contains(conv.id)) continue;
      final isBot = conv.name.toLowerCase() == 'clique' ||
          conv.username.toLowerCase() == 'clique';
      final needsCachedPreview =
          conv.lastMessage.trim().isEmpty || conv.timestamp.trim().isEmpty;
      final latestCachedMessage = needsCachedPreview
          ? _latestCachedMessage(
              conv.id,
              ownerId: ownerId,
            )
          : null;
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
        unreadCount: conv.unreadCount,
        isPinned: conv.isPinned,
        isMuted: conv.isMuted,
      ));
    }

    return conversations;
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
    if (cachedText.isNotEmpty) return cachedText;
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
    final rawId = user?['id'];
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
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
      direction: DismissDirection.endToStart,
      background: Container(
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
      onDismissed: (direction) async {
        final conversationId = int.tryParse(message.id);
        if (conversationId != null) {
          await _chatService.archiveConversation(
            conversationId,
            cacheOwnerId: _readCurrentUserId(),
          );
        }
        if (!context.mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.archive_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Conversation with ${message.name} archived',
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
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final conversationId = int.tryParse(message.id);
          if (conversationId != null) {
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
        },
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
                            message.message,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              color: message.isUnread
                                  ? AppColors.text
                                  : AppColors.textSecondary,
                              fontWeight: message.isUnread
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

class _ChatMessage {
  final String id;
  final int userId;
  final String name;
  final String message;
  final String time;
  final String avatar;
  final bool isUnread;
  final bool isOnline;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  _ChatMessage({
    required this.id,
    required this.userId,
    required this.name,
    required this.message,
    required this.time,
    required this.avatar,
    required this.isUnread,
    required this.isOnline,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });
}

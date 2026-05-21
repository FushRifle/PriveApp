import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/ui/pages/main/chat/chat_page.dart';
import '../../../widgets/home/custom_app_bar.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  // ignore: non_constant_identifier_names
  final RefreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                key: RefreshIndicatorKey,
                color: AppColors.primary,
                onRefresh: _refreshConversations,
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state.conversationsStatus == ChatStatus.loading &&
                        state.conversations.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (state.conversationsStatus == ChatStatus.error &&
                        state.conversations.isEmpty) {
                      return _buildErrorWidget(state.error);
                    }

                    final conversations = _getDisplayConversations(state);
                    return _buildMessageList(context, conversations);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'Failed to load conversations',
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConversations,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  List<_ChatMessage> _getDisplayConversations(ChatState state) {
    final conversations = <_ChatMessage>[];
    final sortedConversations = List.of(state.conversations);
    sortedConversations.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    for (final conv in sortedConversations) {
      final isBot = conv.name.toLowerCase() == 'clique' ||
          conv.username.toLowerCase() == 'clique';

      conversations.add(_ChatMessage(
        id: conv.id.toString(),
        userId: conv.userId,
        name: conv.name,
        message: conv.lastMessage.isNotEmpty
            ? conv.lastMessage
            : (isBot ? 'Welcome to Clique! 🤖' : 'No messages yet'),
        time: _formatTimestamp(conv.timestamp),
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

  Widget _buildCustomAppBar(BuildContext context) {
    return CustomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text(
              "Chats",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to search users
                debugPrint('Search tapped');
              },
              icon: const Icon(
                Icons.search,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(
      BuildContext context, List<_ChatMessage> conversations) {
    if (conversations.isEmpty) {
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
              'No conversations yet',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with someone!',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.redColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: Text('Delete conversation with ${message.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation with ${message.name} deleted'),
            backgroundColor: Colors.red,
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
                builder: (context) => ChatPage(
                  conversationId: conversationId,
                  userName: message.name,
                  userAvatar: message.avatar,
                  userId: message.userId,
                ),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isUnread
                ? AppColors.primary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: message.isUnread
                ? Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: message.isUnread
                            ? AppColors.primary
                            : AppColors.greyColor.withOpacity(0.3),
                        width: 2,
                      ),
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
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          message.name,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontWeight: message.isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (isBot) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified,
                            size: 15,
                            opticalSize: 4,
                            color: AppColors.secondary,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          message.time,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontSize: 11,
                            color: message.isUnread
                                ? AppColors.primary
                                : AppColors.greyColor,
                            fontWeight: message.isUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (message.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.notifications_off,
                              size: 14,
                              color: AppColors.greyColor,
                            ),
                          ),
                        if (message.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            message.message,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontWeight: message.isUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              fontSize: 14,
                              color: message.isUnread
                                  ? AppColors.blackColor
                                  : AppColors.greyColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (message.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.primary,
                            ),
                            child: Text(
                              '${message.unreadCount}',
                              style: AppTheme.whiteTextStyle.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: Text(
            'C',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (message.avatar.isNotEmpty) {
      return Image.network(
        message.avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(firstLetter),
      );
    }

    return _avatarFallback(firstLetter);
  }

  Widget _avatarFallback(String text) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
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

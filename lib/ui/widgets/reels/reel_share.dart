import 'package:clique/core/services/friends/friends_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/ui/pages/main/chat/chat_page.dart';
import 'package:clique/ui/widgets/comments/comment_widgets.dart';
import 'package:clique/ui/widgets/reels/helpers/reel_helpers.dart';
import 'package:clique/ui/widgets/reels/reel_actions.dart';

class ReelShareSheet extends StatefulWidget {
  final Map<String, dynamic> reel;
  final String reelId;
  final VoidCallback onShared;

  const ReelShareSheet({
    super.key,
    required this.reel,
    required this.reelId,
    required this.onShared,
  });

  @override
  State<ReelShareSheet> createState() => _ReelShareSheetState();
}

class _ReelShareSheetState extends State<ReelShareSheet> {
  late final ChatService _chatService;
  final TextEditingController _searchController = TextEditingController();

  int? _sendingToUserId;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FriendsBloc()..add(const LoadFriends()),
        ),
        BlocProvider(
          create: (_) => ChatBloc()..add(LoadConversations()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.42,
            maxChildSize: 0.9,
            builder: (context, sheetController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Send to',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSearchField(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildFriendsList(context, sheetController),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search friends',
          hintStyle: TextStyle(
            color: AppColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.icon,
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    ScrollController controller,
  ) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, friendsState) {
        if (friendsState.friendsStatus == FriendsStatus.loading &&
            friendsState.friends.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        if (friendsState.friendsStatus == FriendsStatus.error &&
            friendsState.friends.isEmpty) {
          return SheetMessage(
            icon: Icons.people_outline,
            title: 'Could not load friends',
            subtitle: friendsState.error ?? 'Please try again.',
            actionLabel: 'Retry',
            onAction: () {
              context.read<FriendsBloc>().add(const LoadFriends());
            },
          );
        }

        final friends = _filteredFriends(friendsState.friends);

        if (friends.isEmpty) {
          return const SheetMessage(
            icon: Icons.people_outline,
            title: 'No friends found',
            subtitle: 'Mutual friends will show up here.',
          );
        }

        return BlocBuilder<ChatBloc, ChatState>(
          builder: (context, chatState) {
            return ListView.separated(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              itemCount: friends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final conversation = _conversationFor(
                  chatState.conversations,
                  friend.id,
                );

                return ShareFriendTile(
                  friend: friend,
                  isSending: _sendingToUserId == friend.id,
                  onTap: () => _shareToFriend(
                    context: context,
                    friend: friend,
                    conversationId: conversation?.id,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<FriendUser> _filteredFriends(List<FriendUser> friends) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return friends;

    return friends.where((friend) {
      return friend.name.toLowerCase().contains(query) ||
          friend.username.toLowerCase().contains(query);
    }).toList();
  }

  ConversationModel? _conversationFor(
    List<ConversationModel> conversations,
    int userId,
  ) {
    for (final conversation in conversations) {
      if (conversation.userId == userId) return conversation;
    }

    return null;
  }

  Future<void> _shareToFriend({
    required BuildContext context,
    required FriendUser friend,
    required int? conversationId,
  }) async {
    if (_sendingToUserId != null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _sendingToUserId = friend.id;
    });

    try {
      final response = await _chatService.sendMessage(
        receiverId: friend.id,
        message: _shareText,
        messageType: 'reel',
        mediaUrl: _videoUrl,
      );

      if (!mounted) return;

      widget.onShared();

      final resolvedConversationId = readInt(
        response?['conversationId'] ?? response?['conversation_id'],
      );
      final targetConversationId =
          resolvedConversationId > 0 ? resolvedConversationId : conversationId;

      navigator.pop();

      if (targetConversationId != null && targetConversationId > 0) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => ChatBloc(),
              child: ChatPage(
                conversationId: targetConversationId,
                userName: friend.name,
                userAvatar: friend.avatar ?? '',
                userId: friend.id,
              ),
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Reel sent to ${friend.name}'),
            backgroundColor: AppColors.card,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.card,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingToUserId = null;
        });
      }
    }
  }

  String get _videoUrl {
    final url = widget.reel['videoUrl'] ?? widget.reel['url'];
    return url?.toString() ?? '';
  }

  String get _caption {
    return widget.reel['caption']?.toString().trim() ?? '';
  }

  String get _shareText {
    final buffer = StringBuffer('Shared a reel');

    if (_caption.isNotEmpty) {
      buffer.write(': $_caption');
    }

    if (_videoUrl.isNotEmpty) {
      buffer.write('\n$_videoUrl');
    }

    return buffer.toString();
  }
}

class ShareFriendTile extends StatelessWidget {
  final FriendUser friend;
  final bool isSending;
  final VoidCallback onTap;

  const ShareFriendTile({
    super.key,
    required this.friend,
    required this.isSending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isSending ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          child: Row(
            children: [
              CommentAvatar(
                imageUrl: friend.avatar ?? '',
                fallback: friend.name,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (friend.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppColors.blue,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${friend.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 42,
                height: 34,
                child: isSending
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
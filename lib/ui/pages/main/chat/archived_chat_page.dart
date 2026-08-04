import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/ui/pages/main/chat/chat_page.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArchivedChatPage extends StatefulWidget {
  const ArchivedChatPage({super.key});

  @override
  State<ArchivedChatPage> createState() => _ArchivedChatPageState();
}

class _ArchivedChatPageState extends State<ArchivedChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _archivedConversations();
    final filtered = conversations.where((conversation) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return conversation.name.toLowerCase().contains(query) ||
          conversation.username.toLowerCase().contains(query) ||
          conversation.lastMessage.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Archived Chats',
            subtitle: '${conversations.length} conversations',
            leadingIcon: Icons.arrow_back_ios_new,
            onLeadingTap: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search archived chats',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _ArchivedChatTile(
                        conversation: filtered[index],
                        onOpen: () => _openChat(filtered[index]),
                        onUnarchive: () => _unarchive(filtered[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<ConversationModel> _archivedConversations() {
    final ownerId = _readCurrentUserId();
    final archivedIds =
        _chatService.readArchivedConversationIds(cacheOwnerId: ownerId);
    final byId = <int, ConversationModel>{};

    for (final conv in context.read<ChatBloc>().state.conversations) {
      if (archivedIds.contains(conv.id)) byId[conv.id] = conv;
    }

    for (final raw in _chatService.readCachedConversations(
      cacheOwnerId: ownerId,
    )) {
      try {
        final model = ConversationModel.fromJson(raw);
        if (archivedIds.contains(model.id)) byId[model.id] = model;
      } catch (_) {}
    }

    final conversations = byId.values.toList();
    conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return conversations;
  }

  Future<void> _unarchive(ConversationModel conversation) async {
    await _chatService.unarchiveConversation(
      conversation.id,
      cacheOwnerId: _readCurrentUserId(),
    );
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${conversation.name} moved to inbox'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openChat(ConversationModel conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: ChatPage(
            conversationId: conversation.id,
            userName: conversation.name,
            userAvatar: conversation.avatar,
            userId: conversation.userId,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 56,
              color: AppColors.primary.withOpacity(0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'No archived chats',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Archived conversations will appear here.',
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  int? _readCurrentUserId() {
    final user = context.read<AuthBloc>().state.user;
    final rawId = user?['id'];
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    return int.tryParse(rawId?.toString() ?? '');
  }
}

class _ArchivedChatTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onOpen;
  final VoidCallback onUnarchive;

  const _ArchivedChatTile({
    required this.conversation,
    required this.onOpen,
    required this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onOpen,
      tileColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: _avatar(),
      title: Text(
        conversation.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        conversation.lastMessage.isEmpty
            ? 'No messages yet'
            : conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (conversation.unreadCount > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conversation.unreadCount > 99
                      ? '99+'
                      : conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Unarchive',
            onPressed: onUnarchive,
            icon: const Icon(Icons.unarchive_outlined),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final fallback =
        conversation.name.isNotEmpty ? conversation.name[0].toUpperCase() : 'U';
    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child: conversation.avatar.startsWith('http')
            ? AppNetworkImage(
                imageUrl: conversation.avatar,
                fit: BoxFit.cover,
                preset: AppNetworkImagePreset.avatar,
                errorBuilder: (_) => _fallback(fallback),
              )
            : _fallback(fallback),
      ),
    );
  }

  Widget _fallback(String fallback) {
    return ColoredBox(
      color: AppColors.primary.withOpacity(0.12),
      child: Center(
        child: Text(
          fallback,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

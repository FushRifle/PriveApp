import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/ui/pages/main/chat/chat_info_page.dart';
import 'package:uuid/uuid.dart';

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
  final List<types.Message> _messages = [];
  final _user = types.User(
    id: 'current-user',
    firstName: 'Sajon.co',
    imageUrl: '',
  );

  late types.User _otherUser;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _otherUser = types.User(
      id: widget.userId,
      firstName: widget.userName,
      imageUrl: widget.userAvatar,
    );
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    _messages.addAll([
      types.TextMessage(
        author: _otherUser,
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 30))
            .millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: 'Hey! How are you doing? 👋',
      ),
      types.TextMessage(
        author: _user,
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 28))
            .millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: 'I\'m great! Just working on some new content.',
      ),
      types.TextMessage(
        author: _otherUser,
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 25))
            .millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: 'That sounds awesome! Can\'t wait to see it 🔥',
      ),
      types.TextMessage(
        author: _user,
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 20))
            .millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: 'Thanks! I\'ll share it with you first 😊',
      ),
      types.TextMessage(
        author: _otherUser,
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 15))
            .millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: 'Perfect! Looking forward to it.',
      ),
    ]);
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    setState(() {
      _messages.add(textMessage);
    });

    _textController.clear();
    _scrollToBottom();
    _simulateReply();
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

  void _simulateReply() {
    final randomReplies = [
      'That sounds great! 👍',
      'I totally agree with you',
      'Haha, that\'s funny 😄',
      'Can you tell me more?',
      'Amazing! Keep it up 🎉',
      'I\'ll get back to you on that',
      'Sounds like a plan!',
    ];

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final reply = types.TextMessage(
          author: _otherUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: randomReplies[DateTime.now().second % randomReplies.length],
        );

        setState(() {
          _messages.add(reply);
        });
        _scrollToBottom();
      }
    });
  }

  String _getAvatarFallback() {
    return widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U';
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
      appBar: AppBar(
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
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.greenColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: AppTheme.greyTextStyle.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Implement call
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Implement video call
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
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
                          style: AppTheme.greyTextStyle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.author.id == _user.id;
                      return _buildMessageBubble(message, isMe, index);
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: SafeArea(
              top: false,
              bottom: true,
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showAttachmentOptions();
                      },
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
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTheme.greyTextStyle.copyWith(
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _handleSendPressed(types.PartialText(text: text));
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        if (_textController.text.trim().isNotEmpty) {
                          HapticFeedback.lightImpact();
                          _handleSendPressed(
                            types.PartialText(text: _textController.text),
                          );
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
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
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatar = widget.userAvatar;
    final fallbackText = _getAvatarFallback();

    if (avatar.isNotEmpty && avatar.startsWith('http')) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(avatar),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
      );
    } else if (avatar.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: AssetImage(avatar),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
      );
    } else {
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
  }

  Widget _buildMessageBubble(types.Message message, bool isMe, int index) {
    if (message is types.TextMessage) {
      final showAvatar = !isMe &&
          (index == 0 ||
              (index > 0 &&
                  _messages[index - 1].author.id != message.author.id));

      return Padding(
        padding: EdgeInsets.only(
          bottom: 16,
          left: isMe ? 0 : 8,
          right: isMe ? 8 : 0,
        ),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildAvatar(),
              )
            else if (!isMe)
              const SizedBox(width: 44),
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
                  color: isMe ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.blackColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (isMe) const SizedBox(width: 8),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
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
                      icon: Icons.document_scanner,
                      label: 'File',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Pick file
                      },
                    ),
                    _attachmentOption(
                      icon: Icons.location_on,
                      label: 'Location',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Share location
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      // TODO: Handle image sending
      debugPrint('Image picked: ${image.path}');
    }
  }
}

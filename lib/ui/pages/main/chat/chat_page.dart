import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/ui/pages/main/chat/chat_info_page.dart';
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
  final _user = const types.User(
    id: 'current-user',
    firstName: 'Sajon.co',
    imageUrl: 'profiles/profile_1.jpeg',
  );

  late types.User _otherUser;
  final TextEditingController _textController = TextEditingController();

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
      types.TextMessage(
        author: _otherUser,
        createdAt: DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: 'Love this! Did you take this today?',
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
      _messages.insert(0, textMessage);
    });

    _textController.clear();
    _simulateReply();
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
          _messages.insert(0, reply);
        });
      }
    });
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
        elevation: 1,
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.purpleColor.withOpacity(0.3),
                    width: 2,
                  ),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(widget.userAvatar),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: AppTheme.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Online',
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 12,
                      color: AppColors.greenColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        theme: DefaultChatTheme(
          primaryColor: AppColors.purpleColor,
          secondaryColor: AppColors.purpleColor.withOpacity(0.1),
          backgroundColor: AppColors.backgroundColor,
          inputBackgroundColor: Colors.white,
          inputTextColor: AppColors.blackColor,
          inputTextStyle: AppTheme.blackTextStyle.copyWith(fontSize: 16),
          emptyChatPlaceholderTextStyle: AppTheme.greyTextStyle,
          dateDividerTextStyle: AppTheme.greyTextStyle.copyWith(fontSize: 12),
          sentMessageBodyTextStyle:
              AppTheme.whiteTextStyle.copyWith(fontSize: 14),
          sentMessageCaptionTextStyle:
              AppTheme.greyTextStyle.copyWith(fontSize: 10),
          receivedMessageBodyTextStyle:
              AppTheme.blackTextStyle.copyWith(fontSize: 14),
          receivedMessageCaptionTextStyle:
              AppTheme.greyTextStyle.copyWith(fontSize: 10),
          userNameTextStyle: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 12,
          ),
        ),
        showUserAvatars: true,
        showUserNames: false,
        customBottomWidget: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            bottom: true,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.mood_outlined,
                              color: AppColors.greyColor, size: 24),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style:
                                AppTheme.blackTextStyle.copyWith(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Message...',
                              hintStyle: AppTheme.greyTextStyle,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (text) {
                              if (text.isNotEmpty) {
                                _handleSendPressed(
                                    types.PartialText(text: text));
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file,
                              color: AppColors.greyColor, size: 24),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt_outlined,
                              color: AppColors.greyColor, size: 24),
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            await picker.pickImage(source: ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_textController.text.isNotEmpty) {
                      _handleSendPressed(
                          types.PartialText(text: _textController.text));
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.purpleColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

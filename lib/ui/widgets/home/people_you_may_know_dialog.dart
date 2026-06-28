import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:flutter/material.dart';

class PeopleYouMayKnowDialog extends StatefulWidget {
  const PeopleYouMayKnowDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PeopleYouMayKnowDialog(),
    );
  }

  @override
  State<PeopleYouMayKnowDialog> createState() =>
      _PeopleYouMayKnowDialogState();
}

class _PeopleYouMayKnowDialogState extends State<PeopleYouMayKnowDialog> {
  late final Future<List<Map<String, dynamic>>> _suggestions;

  @override
  void initState() {
    super.initState();
    _suggestions = UserService().getUserSuggestions(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('People You May Know'),
      content: SizedBox(
        width: 420,
        height: 300,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _suggestions,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            final people = snapshot.data ?? const [];
            if (people.isEmpty) {
              return const Center(child: Text('No suggestions right now.'));
            }
            return ListView.separated(
              itemCount: people.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final person = people[index];
                final id = int.tryParse('${person['id'] ?? person['userId']}') ?? 0;
                final name = '${person['name'] ?? person['displayName'] ?? 'Clique user'}';
                final avatar = '${person['avatar'] ?? ''}';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(.1),
                    backgroundImage:
                        avatar.isEmpty ? null : CachedNetworkImageProvider(avatar),
                    child: avatar.isEmpty ? const Icon(Icons.person_outline) : null,
                  ),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: id <= 0
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            NamedRoutes.otherProfileScreen,
                            arguments: id,
                          );
                        },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, NamedRoutes.peopleYouMayKnowScreen);
          },
          child: const Text('See all'),
        ),
      ],
    );
  }
}

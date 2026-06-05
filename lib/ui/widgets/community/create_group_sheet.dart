import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/community/community_bloc.dart';

class CreateGroupSheet extends StatefulWidget {
  final int communityId;

  const CreateGroupSheet({
    super.key,
    required this.communityId,
  });

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createGroup() {
    final name = _nameController.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name must be at least 3 letters')),
      );
      return;
    }

    context.read<CommunityBloc>().add(
          CreateCommunityGroup(
            communityId: widget.communityId,
            name: name,
            description: _descriptionController.text.trim(),
            isPrivate: _isPrivate,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Create group',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                ),
                TextButton(
                    onPressed: _createGroup, child: const Text('Create')),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Private group'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
          ],
        ),
      ),
    );
  }
}

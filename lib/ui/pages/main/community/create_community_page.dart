import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/community/community_bloc.dart';
import 'package:clique/ui/widgets/community/community_list_header.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = CommunityListHeader.categories[1];
  bool _isPrivate = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunityBloc, CommunityState>(
      listenWhen: (previous, current) {
        return previous.actionStatus != current.actionStatus ||
            previous.error != current.error;
      },
      listener: _handleBlocState,
      builder: (context, state) {
        final isSaving = state.actionStatus == CommunityActionStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Create space'),
            actions: [
              TextButton(
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _CreateIntro(isPrivate: _isPrivate),
                const SizedBox(height: 18),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Film Circle, Lagos Founders...',
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.length < 3) {
                            return 'Use at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText:
                              'What should members talk about in this space?',
                        ),
                        validator: (value) {
                          final description = value?.trim() ?? '';
                          if (description.length < 12) {
                            return 'Add a clearer description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Category',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in CommunityListHeader.categories.where(
                      (item) => item.isNotEmpty,
                    ))
                      ChoiceChip(
                        selected: _category == category,
                        label: Text(category),
                        onSelected: (_) => setState(() {
                          _category = category;
                        }),
                        selectedColor: AppColors.primary.withOpacity(0.16),
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _category == category
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _PrivacySelector(
                  isPrivate: _isPrivate,
                  onChanged: (value) => setState(() => _isPrivate = value),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: isSaving ? null : _submit,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(isSaving ? 'Creating...' : 'Create space'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBlocState(BuildContext context, CommunityState state) {
    if (state.error != null && state.error!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
      context.read<CommunityBloc>().add(const ClearCommunityError());
    }

    if (_submitted && state.actionStatus == CommunityActionStatus.success) {
      Navigator.pop(context);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    _submitted = true;

    context.read<CommunityBloc>().add(
          CreateCommunity(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            isPrivate: _isPrivate,
          ),
        );
  }
}

class _CreateIntro extends StatelessWidget {
  final bool isPrivate;

  const _CreateIntro({required this.isPrivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (isPrivate ? AppColors.primary : AppColors.secondary)
                  .withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPrivate ? Icons.lock_outline : Icons.diversity_3_outlined,
              color: isPrivate ? AppColors.primary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrivate ? 'Invite-only space' : 'Open community space',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPrivate
                      ? 'Only approved members can enter and participate.'
                      : 'Anyone can join and start contributing.',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySelector extends StatelessWidget {
  final bool isPrivate;
  final ValueChanged<bool> onChanged;

  const _PrivacySelector({
    required this.isPrivate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Private space',
          style: AppTheme.blackTextStyle.copyWith(fontWeight: AppTheme.bold),
        ),
        subtitle: Text(
          'Restrict this community to invited or approved members.',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
        ),
        value: isPrivate,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}

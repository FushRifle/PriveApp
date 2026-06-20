import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/feedback/feedback_bloc.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  String _category = 'General';

  static const _categories = [
    'General',
    'Bug',
    'Feature request',
    'Safety',
    'Account',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackBloc, FeedbackState>(
      listener: (context, state) {
        if (state.status == FeedbackStatus.success) {
          _messageController.clear();
          _emailController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Feedback sent',
                style: TextStyle(color: AppColors.text),
              ),
              backgroundColor: AppColors.card,
            ),
          );
          context.read<FeedbackBloc>().add(const ClearFeedbackState());
        } else if (state.status == FeedbackStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error ?? 'Failed to send feedback',
                style: TextStyle(color: AppColors.text),
              ),
              backgroundColor: AppColors.card,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == FeedbackStatus.submitting;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Feedback'),
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  'Tell us what happened',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 22,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share bugs, ideas, account issues, or safety concerns.',
                  style: AppTheme.greyTextStyle.copyWith(height: 1.4),
                ),
                const SizedBox(height: 18),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _category,
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _messageController,
                        minLines: 6,
                        maxLines: 10,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'What should we know?',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 10) {
                            return 'Add at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        enabled: !isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Optional',
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: isSubmitting ? null : _submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(isSubmitting ? 'Sending...' : 'Send'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<FeedbackBloc>().add(
          SubmitFeedback(
            category: _category,
            message: _messageController.text.trim(),
            email: _emailController.text.trim(),
          ),
        );
  }
}

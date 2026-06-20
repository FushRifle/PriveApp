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

  static const Map<String, IconData> _categoryIcons = {
    'General': Icons.feedback_outlined,
    'Bug': Icons.bug_report_outlined,
    'Feature request': Icons.lightbulb_outlined,
    'Safety': Icons.shield_outlined,
    'Account': Icons.person_outline,
  };

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
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Feedback sent successfully!',
                    style: TextStyle(color: AppColors.text),
                  ),
                ],
              ),
              backgroundColor: AppColors.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          context.read<FeedbackBloc>().add(const ClearFeedbackState());
        } else if (state.status == FeedbackStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.error ?? 'Failed to send feedback',
                      style: TextStyle(color: AppColors.text),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == FeedbackStatus.submitting;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Feedbacks'),
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.card.withOpacity(0.1),
                          AppColors.secondary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.feedback_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tell us what happened',
                                style: AppTheme.blackTextStyle.copyWith(
                                  fontSize: 20,
                                  fontWeight: AppTheme.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Share bugs, ideas, account issues, or safety concerns.',
                                style: AppTheme.greyTextStyle.copyWith(
                                  height: 1.4,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Category',
                          style: AppTheme.blackTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: AppTheme.semiBold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _categoryIcons[category],
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(category),
                                      ],
                                    ),
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
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              
                            ),
                            style: AppTheme.blackTextStyle.copyWith(fontSize: 15),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: AppColors.card,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Message Section
                        Text(
                          'Message',
                          style: AppTheme.blackTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: AppTheme.semiBold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _messageController,
                          minLines: 6,
                          maxLines: 10,
                          enabled: !isSubmitting,
                          style: AppTheme.blackTextStyle.copyWith(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'What should we know?',
                            hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 15),
                            filled: true,
                            fillColor: AppColors.card,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.border.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.border.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.length < 10) {
                              return 'Add at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Email Section
                        Text(
                          'Email',
                          style: AppTheme.blackTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: AppTheme.semiBold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTheme.blackTextStyle.copyWith(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Optional - so we can follow up',
                            hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 15),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.grey,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.card,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.border.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.border.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: isSubmitting ? null : _submit,
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 20),
                            label: Text(
                              isSubmitting ? 'Sending...' : 'Send Feedback',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
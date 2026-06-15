import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/event/event_bloc.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageController = TextEditingController();

  static const _categories = [
    'Music',
    'Tech',
    'Business',
    'Sports',
    'Social',
    'Nightlife',
  ];

  String _category = _categories.first;
  bool _isPrivate = false;
  bool _submitted = false;
  DateTime? _startsAt;
  DateTime? _endsAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventBloc, EventState>(
      listenWhen: (previous, current) {
        return previous.actionStatus != current.actionStatus ||
            previous.error != current.error;
      },
      listener: _handleStateChange,
      builder: (context, state) {
        final isSaving = state.actionStatus == EventActionStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Create event'),
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
                _IntroCard(isPrivate: _isPrivate),
                const SizedBox(height: 18),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Sunday meetup, Launch party...',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 3) {
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
                          hintText: 'Tell people what this event is about.',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 12) {
                            return 'Add a clearer description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _locationController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'Lagos, Nigeria / Zoom / Rooftop Lounge',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 3) {
                            return 'Add a location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _imageController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Cover image URL',
                          hintText: 'https://...',
                        ),
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
                    for (final category in _categories)
                      ChoiceChip(
                        selected: _category == category,
                        label: Text(category),
                        onSelected: (_) => setState(() {
                          _category = category;
                        }),
                        selectedColor: AppColors.primary.withOpacity(0.12),
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
                _DateTimePickerCard(
                  label: 'Starts at',
                  value: _startsAt,
                  onTap: _pickStartsAt,
                ),
                const SizedBox(height: 12),
                _DateTimePickerCard(
                  label: 'Ends at',
                  value: _endsAt,
                  onTap: _pickEndsAt,
                ),
                const SizedBox(height: 18),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isPrivate,
                  onChanged: (value) => setState(() => _isPrivate = value),
                  title: Text(
                    'Private event',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: AppTheme.medium,
                    ),
                  ),
                  subtitle: Text(
                    'Only invited people can see this event.',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 18),
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
                      : const Icon(Icons.event_available_outlined),
                  label: Text(isSaving ? 'Creating...' : 'Create event'),
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

  void _handleStateChange(BuildContext context, EventState state) {
    if (state.error != null && state.error!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
      context.read<EventBloc>().add(const ClearEventError());
      return;
    }

    if (_submitted && state.actionStatus == EventActionStatus.success) {
      Navigator.pop(context);
    }
  }

  void _submit() {
    if (_startsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a start time')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    _submitted = true;

    context.read<EventBloc>().add(
          CreateEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            location: _locationController.text.trim(),
            imageUrl: _imageController.text.trim(),
            startsAt: _startsAt!,
            endsAt: _endsAt,
            isPrivate: _isPrivate,
          ),
        );
  }

  Future<void> _pickStartsAt() async {
    final selected = await _pickDateTime(
      initial: _startsAt ?? DateTime.now().add(const Duration(hours: 2)),
    );
    if (selected == null) return;
    setState(() {
      _startsAt = selected;
      if (_endsAt != null && _endsAt!.isBefore(selected)) {
        _endsAt = selected.add(const Duration(hours: 2));
      }
    });
  }

  Future<void> _pickEndsAt() async {
    final initial = _endsAt ??
        _startsAt?.add(const Duration(hours: 2)) ??
        DateTime.now().add(const Duration(hours: 4));
    final selected = await _pickDateTime(initial: initial);
    if (selected == null) return;
    setState(() => _endsAt = selected);
  }

  Future<DateTime?> _pickDateTime({required DateTime initial}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null) return null;

    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

class _IntroCard extends StatelessWidget {
  final bool isPrivate;

  const _IntroCard({required this.isPrivate});

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
              isPrivate ? Icons.lock_outline : Icons.event_outlined,
              color: isPrivate ? AppColors.primary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrivate ? 'Private event' : 'Public event',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPrivate
                      ? 'Only invited people can see it and RSVP.'
                      : 'Anyone on the app can discover and join.',
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

class _DateTimePickerCard extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateTimePickerCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null
                        ? 'Pick date and time'
                        : _formatDateTime(value!),
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: AppTheme.medium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${monthNames[local.month - 1]} ${local.day}, $hour:$minute $period';
}

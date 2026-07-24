import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/models/event_model.dart';
import 'package:clique/core/services/tagging/tagging_service.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';

class CreateEventPage extends StatefulWidget {
  final EventModel? event;

  const CreateEventPage({
    super.key,
    this.event,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = HighlightTokenTextEditingController();
  final _descriptionController = HighlightTokenTextEditingController();
  final _locationController = TextEditingController();
  final _imageController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _cloudinaryService = CloudinaryService();
  final _taggingService = TaggingService();

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
  bool _isUploadingCover = false;
  DateTime? _startsAt;
  DateTime? _endsAt;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event == null) return;

    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _imageController.text = event.imageUrl;
    _startsAt = event.startsAt;
    _endsAt = event.endsAt;
    _isPrivate = event.isPrivate;
    if (_categories.contains(event.category)) {
      _category = event.category;
    }
  }

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
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(_isEditing ? 'Edit event' : 'Create event'),
            actions: [
              TextButton(
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  AppColors.primary.withOpacity(0.04),
                  AppColors.secondary.withOpacity(0.04),
                ],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                children: [
                  _CreateEventHero(isPrivate: _isPrivate),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Basics',
                    subtitle: 'Name, description, location, and cover',
                    child: Form(
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
                              hintText:
                                  'Lagos, Nigeria / Zoom / Rooftop Lounge',
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
                          _CoverImageCard(
                            imageUrl: _imageController.text.trim(),
                            isUploading: _isUploadingCover,
                            onTap: _pickCoverImage,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Timing',
                    subtitle: 'When the event starts and ends',
                    child: Column(
                      children: [
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Audience',
                    subtitle: 'Who can see and find this event',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: AppTheme.blackTextStyle.copyWith(
                            fontWeight: AppTheme.bold,
                            fontSize: 14,
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
                                selectedColor:
                                    AppColors.primary.withOpacity(0.12),
                                backgroundColor: AppColors.background,
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: _category == category
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _isPrivate,
                          onChanged: (value) =>
                              setState(() => _isPrivate = value),
                          title: Text(
                            'Private event',
                            style: AppTheme.blackTextStyle.copyWith(
                              fontWeight: AppTheme.medium,
                            ),
                          ),
                          subtitle: Text(
                            'Only invited people can see this event.',
                            style:
                                AppTheme.greyTextStyle.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
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
                    label: Text(
                      isSaving
                          ? (_isEditing ? 'Saving...' : 'Creating...')
                          : (_isEditing ? 'Save changes' : 'Create event'),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

  void _handleStateChange(BuildContext context, EventState state) {
    if (state.error != null && state.error!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.error!,
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.read<EventBloc>().add(const ClearEventError());
      return;
    }

    if (_submitted && state.actionStatus == EventActionStatus.success) {
      _submitted = false;
      if (!_isEditing && state.events.isNotEmpty) {
        final created = state.events.first;
        unawaited(
          _syncUserTags(
            'event',
            created.id,
            '${_titleController.text} ${_descriptionController.text}',
          ),
        );
      }
      Navigator.pop(context);
    }
  }

  void _submit() {
    if (_startsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pick a start time',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    _submitted = true;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final imageUrl = _imageController.text.trim();

    if (_isEditing) {
      context.read<EventBloc>().add(
            UpdateEvent(
              eventId: widget.event!.id,
              title: title,
              description: description,
              category: _category,
              location: location,
              imageUrl: imageUrl,
              startsAt: _startsAt!,
              endsAt: _endsAt,
              isPrivate: _isPrivate,
            ),
          );
      return;
    }

    context.read<EventBloc>().add(
          CreateEvent(
            title: title,
            description: description,
            category: _category,
            location: location,
            imageUrl: imageUrl,
            startsAt: _startsAt!,
            endsAt: _endsAt,
            isPrivate: _isPrivate,
          ),
        );
  }

  Future<void> _syncUserTags(
    String contentType,
    int contentId,
    String content,
  ) async {
    final usernames = _extractMentions(content);
    if (usernames.isEmpty) return;

    try {
      await _taggingService.syncUserTags(
        contentType: contentType,
        contentId: contentId,
        usernames: usernames,
      );
    } catch (e) {
      debugPrint('Event user tag sync skipped: $e');
    }
  }

  List<String> _extractMentions(String rawValue) {
    final seen = <String>{};
    return RegExp(r'@([A-Za-z0-9_]+)')
        .allMatches(rawValue)
        .map((match) => match.group(1)?.toLowerCase() ?? '')
        .where((username) => username.isNotEmpty && seen.add(username))
        .toList();
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

  Future<void> _pickCoverImage() async {
    if (_isUploadingCover) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingCover = true);

    try {
      final url = await _cloudinaryService.uploadImage(
        File(picked.path),
        customFolder: 'feeds',
      );

      if (!mounted) return;
      setState(() {
        _imageController.text = url;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload cover image: $error'),
          backgroundColor: AppColors.card,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingCover = false);
      }
    }
  }
}

class _CreateEventHero extends StatelessWidget {
  final bool isPrivate;

  const _CreateEventHero({
    required this.isPrivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.card.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (isPrivate ? AppColors.primary : AppColors.secondary)
                  .withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isPrivate ? Icons.lock_outline : Icons.event_available_outlined,
              color: isPrivate ? AppColors.primary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Design an event people want to show up for.',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: AppTheme.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep the essentials in one place, then publish when the details feel right.',
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroBadge(
                      icon: Icons.verified_outlined,
                      label: isPrivate ? 'Private' : 'Public',
                    ),
                    _HeroBadge(
                      icon: Icons.schedule_rounded,
                      label: 'Fast setup',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImageCard extends StatelessWidget {
  final String imageUrl;
  final bool isUploading;
  final VoidCallback onTap;

  const _CoverImageCard({
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                AppColors.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _EmptyCoverState(
                      isUploading: isUploading,
                    ),
                  )
                else
                  _EmptyCoverState(
                    isUploading: isUploading,
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.22),
                          ),
                        ),
                        child: Icon(
                          isUploading
                              ? Icons.hourglass_top_rounded
                              : imageUrl.isNotEmpty
                                  ? Icons.image_rounded
                                  : Icons.add_photo_alternate_outlined,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                        height: 20,
                      ),
                      Expanded(
                        child: Text(
                          isUploading
                              ? 'Uploading cover image...'
                              : imageUrl.isNotEmpty
                                  ? 'Tap to replace the cover image'
                                  : 'Tap to add a cover image',
                          style: AppTheme.whiteTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: AppTheme.bold,
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
      ),
    );
  }
}

class _EmptyCoverState extends StatelessWidget {
  final bool isUploading;

  const _EmptyCoverState({
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUploading
                ? Icons.cloud_upload_outlined
                : Icons.add_a_photo_outlined,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 5),
          Text(
            isUploading ? 'Uploading...' : 'Add image',
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          child,
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

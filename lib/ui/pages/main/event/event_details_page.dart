import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/core/models/event_model.dart';
import 'package:clique/ui/pages/main/event/create_event_page.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

class EventDetailsPage extends StatelessWidget {
  final EventModel event;

  const EventDetailsPage({
    super.key,
    required this.event,
  });

  EventModel _currentEvent(EventState state) {
    for (final item in state.events) {
      if (item.id == event.id) return item;
    }
    return event;
  }

  bool _isOwner(BuildContext context, EventModel event) {
    final currentUserId =
        _readCurrentUserId(context.read<AuthBloc>().state.user);
    final hostId = event.hostId != 0 ? event.hostId : event.host?.id;
    return currentUserId != null &&
        hostId != null &&
        hostId > 0 &&
        currentUserId == hostId;
  }

  int? _readCurrentUserId(Map<String, dynamic>? user) {
    if (user == null) return null;
    final candidates = [
      user['id'],
      user['userId'],
      user['user_id'],
      user['profileUserId'],
      user['profile_user_id'],
      if (user['user'] is Map) (user['user'] as Map)['id'],
      if (user['user'] is Map) (user['user'] as Map)['userId'],
      if (user['user'] is Map) (user['user'] as Map)['user_id'],
      if (user['currentUser'] is Map) (user['currentUser'] as Map)['id'],
      if (user['current_user'] is Map) (user['current_user'] as Map)['id'],
      if (user['profile'] is Map) (user['profile'] as Map)['userId'],
      if (user['profile'] is Map) (user['profile'] as Map)['user_id'],
      if (user['profile'] is Map) (user['profile'] as Map)['id'],
      if (user['activeProfile'] is Map)
        (user['activeProfile'] as Map)['userId'],
      if (user['activeProfile'] is Map)
        (user['activeProfile'] as Map)['user_id'],
      if (user['activeProfile'] is Map) (user['activeProfile'] as Map)['id'],
      if (user['active_profile'] is Map)
        (user['active_profile'] as Map)['userId'],
      if (user['active_profile'] is Map)
        (user['active_profile'] as Map)['user_id'],
      if (user['active_profile'] is Map) (user['active_profile'] as Map)['id'],
    ];
    for (final value in candidates) {
      final id = value is int
          ? value
          : value is num
              ? value.toInt()
              : int.tryParse(value?.toString() ?? '');
      if (id != null && id > 0) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventBloc, EventState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus ||
          previous.error != current.error,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        final error = state.error;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
          );
          context.read<EventBloc>().add(const ClearEventError());
          return;
        }
        if (state.actionStatus == EventActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your response has been updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final currentEvent = _currentEvent(state);
        final isOwner = _isOwner(context, currentEvent);
        final isBusy = state.actionStatus == EventActionStatus.loading &&
            state.activeEventId == currentEvent.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Event details'),
            actions: [
              IconButton(
                tooltip: 'Copy event details',
                onPressed: () => _copyEvent(context, currentEvent),
                icon: const Icon(Icons.copy_all_rounded),
              ),
              if (isOwner)
                IconButton(
                  tooltip: 'Edit event',
                  onPressed: () => _openEdit(context, currentEvent),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _DetailsWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _HeaderCard(
                      event: currentEvent,
                      isOwner: isOwner,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _DetailsWidth(
                    child: _EventStatusBanner(event: currentEvent),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _DetailsWidth(
                    child: _SectionCard(
                      title: 'At a glance',
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.schedule_rounded,
                            title: _formatDate(currentEvent.startsAt),
                            subtitle: _formatTimeRange(
                              currentEvent.startsAt,
                              currentEvent.endsAt,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            icon: Icons.place_outlined,
                            title: currentEvent.location.isEmpty
                                ? 'Location not set'
                                : currentEvent.location,
                            subtitle: currentEvent.isPrivate
                                ? 'Shared with invited guests'
                                : 'Visible to the community',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _DetailsWidth(
                    child: _SectionCard(
                      title: isOwner ? 'Hosted by you' : 'Host',
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.12),
                            backgroundImage:
                                currentEvent.host?.avatar.isNotEmpty == true
                                    ? appNetworkImageProvider(
                                        context,
                                        currentEvent.host!.avatar,
                                        logicalWidth: 48,
                                      )
                                    : null,
                            child: currentEvent.host?.avatar.isEmpty != false
                                ? const Icon(
                                    Icons.person_outline,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOwner
                                      ? 'You created this event'
                                      : currentEvent.host?.name.isNotEmpty ==
                                              true
                                          ? currentEvent.host!.name
                                          : 'Event host',
                                  style: AppTheme.blackTextStyle.copyWith(
                                    fontSize: 15,
                                    fontWeight: AppTheme.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isOwner
                                      ? 'Only you can edit this event'
                                      : currentEvent
                                                  .host?.username.isNotEmpty ==
                                              true
                                          ? '@${currentEvent.host!.username}'
                                          : 'Organizer details unavailable',
                                  style: AppTheme.greyTextStyle.copyWith(
                                    fontSize: 12,
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
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverToBoxAdapter(
                  child: _DetailsWidth(
                    child: _SectionCard(
                      title: 'Community response',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetricChip(
                            icon: Icons.check_circle_outline,
                            label: '${currentEvent.goingCount} going',
                          ),
                          _MetricChip(
                            icon: Icons.favorite_border,
                            label: '${currentEvent.interestedCount} interested',
                          ),
                          if (currentEvent.category.isNotEmpty)
                            _MetricChip(
                              icon: Icons.sell_outlined,
                              label: currentEvent.category,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomActionBar(
            event: currentEvent,
            isOwner: isOwner,
            isBusy: isBusy,
            onEdit: () => _openEdit(context, currentEvent),
            onGoing: () => _rsvp(context, currentEvent, 'going'),
            onInterested: () => _rsvp(context, currentEvent, 'interested'),
            onLeave: () => _rsvp(context, currentEvent, 'not_going'),
          ),
        );
      },
    );
  }

  void _openEdit(BuildContext context, EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<EventBloc>(),
          child: CreateEventPage(event: event),
        ),
      ),
    );
  }

  void _rsvp(BuildContext context, EventModel event, String status) {
    HapticFeedback.selectionClick();
    context.read<EventBloc>().add(
          RsvpEvent(eventId: event.id, status: status),
        );
  }

  Future<void> _copyEvent(BuildContext context, EventModel event) async {
    final details = <String>[
      event.title,
      '${_formatDate(event.startsAt)} · ${_formatTimeRange(event.startsAt, event.endsAt)}',
      if (event.location.isNotEmpty) event.location,
      if (event.description.isNotEmpty) event.description,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: details));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event details copied')),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final EventModel event;
  final bool isOwner;

  const _HeaderCard({
    required this.event,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventHeroImage(imageUrl: event.imageUrl),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.category.isNotEmpty || event.isPrivate || isOwner)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isOwner)
                        _Chip(
                            label: 'Your event', icon: Icons.verified_outlined),
                      if (event.category.isNotEmpty)
                        _Chip(label: event.category, icon: Icons.sell_outlined),
                      if (event.isPrivate)
                        _Chip(label: 'Private', icon: Icons.lock_outline),
                    ],
                  ),
                if (event.category.isNotEmpty || event.isPrivate || isOwner)
                  const SizedBox(height: 12),
                Text(
                  event.title,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 24,
                    fontWeight: AppTheme.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.event_outlined,
                  title: _formatDate(event.startsAt),
                  subtitle: _formatTimeRange(event.startsAt, event.endsAt),
                ),
                const SizedBox(height: 14),
                Text(
                  event.description.isEmpty
                      ? 'No description provided.'
                      : event.description,
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventHeroImage extends StatelessWidget {
  final String imageUrl;

  const _EventHeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().startsWith('http')) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: AppNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          preset: AppNetworkImagePreset.card,
          placeholder: (_) => _placeholder(),
          errorBuilder: (_) => _placeholder(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        color: AppColors.background,
        alignment: Alignment.center,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.event_outlined,
            color: AppColors.primary,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.event_outlined,
          color: AppColors.primary,
          size: 40,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 15,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: AppTheme.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({
    required this.label,
    required this.icon,
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
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final EventModel event;
  final bool isOwner;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onGoing;
  final VoidCallback onInterested;
  final VoidCallback onLeave;

  const _BottomActionBar({
    required this.event,
    required this.isOwner,
    required this.isBusy,
    required this.onEdit,
    required this.onGoing,
    required this.onInterested,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final hasEnded = (event.endsAt ??
            event.startsAt.add(const Duration(hours: 4)))
        .isBefore(DateTime.now());
    return Material(
      color: AppColors.card,
      elevation: 12,
      shadowColor: AppColors.black.withOpacity(0.12),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: isOwner
                  ? FilledButton.icon(
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit event'),
                      style: _filledStyle(),
                    )
                  : hasEnded
                      ? Container(
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'This event has ended',
                            style: AppTheme.greyTextStyle.copyWith(
                              fontWeight: AppTheme.bold,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: isBusy
                                    ? null
                                    : event.isGoing
                                        ? onLeave
                                        : onGoing,
                                icon: isBusy
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Icon(
                                        event.isGoing
                                            ? Icons.check_circle_rounded
                                            : Icons.event_available_outlined,
                                      ),
                                label: Text(
                                  event.isGoing ? 'Going' : 'I’m going',
                                ),
                                style: _filledStyle(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isBusy
                                    ? null
                                    : event.isInterested
                                        ? onLeave
                                        : onInterested,
                                icon: Icon(
                                  event.isInterested
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                ),
                                label: Text(
                                  event.isInterested ? 'Saved' : 'Interested',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _filledStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _DetailsWidth extends StatelessWidget {
  final Widget child;

  const _DetailsWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }
}

class _EventStatusBanner extends StatelessWidget {
  final EventModel event;

  const _EventStatusBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final end =
        event.endsAt ?? event.startsAt.add(const Duration(hours: 4));
    final hasEnded = end.isBefore(now);
    final isLive = !event.startsAt.isAfter(now) && end.isAfter(now);
    final start = event.startsAt.difference(now);

    final icon = hasEnded
        ? Icons.history_rounded
        : isLive
            ? Icons.sensors_rounded
            : Icons.notifications_active_outlined;
    final title = hasEnded
        ? 'This event has ended'
        : isLive
            ? 'Happening now'
            : _startsInLabel(start);
    final subtitle = hasEnded
        ? 'You can still view the event details and community response.'
        : isLive
            ? 'The event is currently in progress.'
            : 'Save your response so you don’t miss it.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            (isLive ? AppColors.success : AppColors.primary).withOpacity(0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (isLive ? AppColors.success : AppColors.primary)
              .withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: isLive ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _startsInLabel(Duration duration) {
  if (duration.inDays >= 1) {
    return 'Starts in ${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
  }
  if (duration.inHours >= 1) {
    return 'Starts in ${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
  }
  final minutes = duration.inMinutes.clamp(1, 59);
  return 'Starts in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String _formatTimeRange(DateTime startsAt, DateTime? endsAt) {
  final start = _formatTime(startsAt.toLocal());
  final end = endsAt == null ? null : _formatTime(endsAt.toLocal());
  if (end == null) return start;
  return '$start - $end';
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

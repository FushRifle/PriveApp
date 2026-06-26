import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/core/models/event_model.dart';
import 'package:clique/ui/pages/main/event/create_event_page.dart';

class EventDetailsPage extends StatelessWidget {
  final EventModel event;

  const EventDetailsPage({
    super.key,
    required this.event,
  });

  bool _isOwner(BuildContext context) {
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
      if (user['profile'] is Map) (user['profile'] as Map)['userId'],
      if (user['profile'] is Map) (user['profile'] as Map)['user_id'],
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
    final isOwner = _isOwner(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Event details'),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Edit event',
              onPressed: () => _openEdit(context),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _HeaderCard(
                event: event,
                isOwner: isOwner,
                onEdit: () => _openEdit(context),
                onGoing: () => context.read<EventBloc>().add(
                      RsvpEvent(eventId: event.id, status: 'going'),
                    ),
                onInterested: () => context.read<EventBloc>().add(
                      RsvpEvent(eventId: event.id, status: 'interested'),
                    ),
                onLeave: () => context.read<EventBloc>().add(
                      RsvpEvent(eventId: event.id, status: 'not_going'),
                    ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _SectionCard(
                title: 'Where',
                child: _InfoRow(
                  icon: Icons.place_outlined,
                  title: event.location.isEmpty
                      ? 'Location not set'
                      : event.location,
                  subtitle: event.isPrivate
                      ? 'Private event'
                      : 'Visible to the community',
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _SectionCard(
                title: isOwner ? 'Hosted by you' : 'Host',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      backgroundImage: event.host?.avatar.isNotEmpty == true
                          ? CachedNetworkImageProvider(event.host!.avatar)
                          : null,
                      child: event.host?.avatar.isEmpty != false
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
                                : event.host?.name.isNotEmpty == true
                                    ? event.host!.name
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
                                : event.host?.username.isNotEmpty == true
                                    ? '@${event.host!.username}'
                                    : 'Organizer details unavailable',
                            style:
                                AppTheme.greyTextStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverToBoxAdapter(
              child: _SectionCard(
                title: 'Activity',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricChip(
                      icon: Icons.check_circle_outline,
                      label: '${event.goingCount} going',
                    ),
                    _MetricChip(
                      icon: Icons.favorite_border,
                      label: '${event.interestedCount} interested',
                    ),
                    if (event.category.isNotEmpty)
                      _MetricChip(
                        icon: Icons.sell_outlined,
                        label: event.category,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
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
}

class _HeaderCard extends StatelessWidget {
  final EventModel event;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onGoing;
  final VoidCallback onInterested;
  final VoidCallback onLeave;

  const _HeaderCard({
    required this.event,
    required this.isOwner,
    required this.onEdit,
    required this.onGoing,
    required this.onInterested,
    required this.onLeave,
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
                if (event.category.isNotEmpty || event.isPrivate)
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
                const SizedBox(height: 16),
                _RSVPBar(
                  event: event,
                  isOwner: isOwner,
                  onEdit: onEdit,
                  onGoing: onGoing,
                  onInterested: onInterested,
                  onLeave: onLeave,
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
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
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

class _RSVPBar extends StatelessWidget {
  final EventModel event;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onGoing;
  final VoidCallback onInterested;
  final VoidCallback onLeave;

  const _RSVPBar({
    required this.event,
    required this.isOwner,
    required this.onEdit,
    required this.onGoing,
    required this.onInterested,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return FilledButton.icon(
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton(
          onPressed: event.isGoing ? onLeave : onGoing,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(event.isGoing ? 'Leave' : 'Going'),
        ),
        OutlinedButton(
          onPressed: event.isInterested ? onLeave : onInterested,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(event.isInterested ? 'Leave' : 'Interested'),
        ),
      ],
    );
  }
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

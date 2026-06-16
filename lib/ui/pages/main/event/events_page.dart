import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/core/models/event_model.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:clique/ui/pages/main/event/create_event_page.dart';
import 'package:clique/ui/pages/main/event/event_details_page.dart';

const _eventCategories = [
  '',
  'Music',
  'Tech',
  'Business',
  'Sports',
  'Social',
  'Nightlife',
];

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;
  String _category = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized || !mounted) return;
      _initialized = true;
      context.read<EventBloc>().add(const LoadEvents(refresh: true));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocConsumer<EventBloc, EventState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.actionStatus != current.actionStatus,
      listener: _handleStateChange,
      builder: (context, state) {
        final todayCount = state.events
            .where((event) => _isSameDay(event.startsAt, DateTime.now()))
            .length;
        final goingCount = state.events.where((event) => event.isGoing).length;

        if (state.status == EventStatus.loading && state.events.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (state.events.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: _EventsEmpty(onCreate: _openCreateEvent),
          );
        }

        final featuredEvent = state.events.first;
        final remaining = state.events.length > 1
            ? state.events.sublist(1)
            : const <EventModel>[];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: AppPageHeader(
                  title: 'Events',
                  subtitle:
                      'Discover live conversations, meetups, and moments worth showing up for.',
                  leadingIcon: Icons.event_rounded,
                  actionIcon: Icons.add_rounded,
                  onActionTap: _openCreateEvent,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroStatChip(
                        icon: Icons.event_available_outlined,
                        label: '${state.events.length} total',
                      ),
                      _HeroStatChip(
                        icon: Icons.today_outlined,
                        label: '$todayCount today',
                      ),
                      _HeroStatChip(
                        icon: Icons.how_to_reg_outlined,
                        label: '$goingCount going',
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _SearchAndFilters(
                    searchController: _searchController,
                    category: _category,
                    onCategoryChanged: _changeCategory,
                    onSearch: _search,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: _SectionLabel(
                    title: 'Featured',
                    subtitle: 'The next thing people can act on now',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _EventCard(
                    event: featuredEvent,
                    compact: false,
                    onTap: () => _openEventDetails(featuredEvent),
                    onGoing: () => context.read<EventBloc>().add(
                          RsvpEvent(
                            eventId: featuredEvent.id,
                            status: 'going',
                          ),
                        ),
                    onInterested: () => context.read<EventBloc>().add(
                          RsvpEvent(
                            eventId: featuredEvent.id,
                            status: 'interested',
                          ),
                        ),
                    onLeave: () => context.read<EventBloc>().add(
                          RsvpEvent(
                            eventId: featuredEvent.id,
                            status: 'not_going',
                          ),
                        ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: _SectionLabel(
                    title: 'More events',
                    subtitle: remaining.isEmpty
                        ? 'No additional events loaded'
                        : '${remaining.length} more events',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final event = remaining[index];
                    return _EventCard(
                      event: event,
                      compact: true,
                      onTap: () => _openEventDetails(event),
                      onGoing: () => context.read<EventBloc>().add(
                            RsvpEvent(eventId: event.id, status: 'going'),
                          ),
                      onInterested: () => context.read<EventBloc>().add(
                            RsvpEvent(
                              eventId: event.id,
                              status: 'interested',
                            ),
                          ),
                      onLeave: () => context.read<EventBloc>().add(
                            RsvpEvent(
                              eventId: event.id,
                              status: 'not_going',
                            ),
                          ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: remaining.length,
                ),
              ),
              if (state.hasMore && state.events.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, EventState state) {
    final error = state.error;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.read<EventBloc>().add(const ClearEventError());
      return;
    }

    if (state.actionStatus == EventActionStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _changeCategory(String category) {
    setState(() => _category = category);
    context.read<EventBloc>().add(
          SearchEvents(
            query: _searchController.text.trim(),
            category: category,
          ),
        );
  }

  void _search() {
    context.read<EventBloc>().add(
          SearchEvents(
            query: _searchController.text.trim(),
            category: _category,
          ),
        );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 260) return;
    context.read<EventBloc>().add(const LoadMoreEvents());
  }

  void _openCreateEvent() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<EventBloc>(),
          child: const CreateEventPage(),
        ),
      ),
    );
  }

  void _openEventDetails(EventModel event) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<EventBloc>(),
          child: EventDetailsPage(event: event),
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroStatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearch;

  const _SearchAndFilters({
    required this.searchController,
    required this.category,
    required this.onCategoryChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Search and filter',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: AppTheme.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search events',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: onSearch,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in _eventCategories) ...[
                  ChoiceChip(
                    selected: item == category,
                    label: Text(item.isEmpty ? 'All' : item),
                    onSelected: (_) => onCategoryChanged(item),
                    selectedColor: AppColors.primary.withOpacity(0.12),
                    backgroundColor: AppColors.background,
                    showCheckmark: false,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: item == category
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color:
                          item == category ? AppColors.primary : AppColors.text,
                      fontWeight:
                          item == category ? AppTheme.bold : AppTheme.medium,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
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
              const SizedBox(height: 2),
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

class _EventsEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _EventsEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.card,
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No events yet',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 19,
                  fontWeight: AppTheme.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create the first event and let people RSVP.',
                textAlign: TextAlign.center,
                style:
                    AppTheme.greyTextStyle.copyWith(fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create event'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onGoing;
  final VoidCallback onInterested;
  final VoidCallback onLeave;

  const _EventCard({
    required this.event,
    required this.compact,
    required this.onTap,
    required this.onGoing,
    required this.onInterested,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactWidth = constraints.maxWidth < 400;
        final isCompactImage = compact || isCompactWidth;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _EventImage(
                          imageUrl: event.imageUrl, compact: isCompactImage),
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Row(
                          children: [
                            if (event.category.isNotEmpty)
                              _FloatingTag(
                                icon: Icons.sell_outlined,
                                label: event.category,
                              ),
                            const Spacer(),
                            if (event.isPrivate)
                              _FloatingTag(
                                icon: Icons.lock_outline,
                                label: 'Private',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(isCompactImage ? 14 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DateRail(date: event.startsAt),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    maxLines: isCompactImage ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.blackTextStyle.copyWith(
                                      fontSize: isCompactImage ? 16 : 18,
                                      fontWeight: AppTheme.bold,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    event.description.isEmpty
                                        ? 'No description provided.'
                                        : event.description,
                                    maxLines: isCompactImage ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.greyTextStyle.copyWith(
                                      height: 1.45,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (event.location.isNotEmpty)
                              _MetaChip(
                                icon: Icons.place_outlined,
                                label: event.location,
                              ),
                            _MetaChip(
                              icon: Icons.check_circle_outline,
                              label: '${event.goingCount} going',
                            ),
                            _MetaChip(
                              icon: Icons.favorite_border,
                              label: '${event.interestedCount} interested',
                            ),
                            if (event.host?.name.isNotEmpty == true)
                              _MetaChip(
                                icon: Icons.person_outline,
                                label: event.host!.name,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton(
                              onPressed: event.isGoing ? onLeave : onGoing,
                              style: FilledButton.styleFrom(
                                backgroundColor: event.isGoing
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.primary,
                                foregroundColor: event.isGoing
                                    ? AppColors.success
                                    : AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child:
                                  Text(event.isGoing ? 'Going' : 'RSVP going'),
                            ),
                            OutlinedButton(
                              onPressed:
                                  event.isInterested ? onLeave : onInterested,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                event.isInterested ? 'Saved' : 'Interested',
                              ),
                            ),
                          ],
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
}

class _DateRail extends StatelessWidget {
  final DateTime date;

  const _DateRail({required this.date});

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            _monthLabel(local.month),
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${local.day}',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 20,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _weekdayLabel(local.weekday),
            style: AppTheme.greyTextStyle.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  final String imageUrl;
  final bool compact;

  const _EventImage({
    required this.imageUrl,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 136.0 : 178.0;

    if (imageUrl.trim().startsWith('http')) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(height),
          errorWidget: (_, __, ___) => _placeholder(height),
        ),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.background,
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.event_outlined,
            color: AppColors.primary,
            size: 34,
          ),
        ),
      ),
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      color: AppColors.background,
      alignment: Alignment.center,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.event_outlined,
          color: AppColors.primary,
          size: 34,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
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

class _FloatingTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FloatingTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 11,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthLabel(int month) {
  const labels = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return labels[month - 1];
}

String _weekdayLabel(int weekday) {
  const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return labels[weekday - 1];
}

bool _isSameDay(DateTime a, DateTime b) {
  final left = a.toLocal();
  final right = b.toLocal();
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

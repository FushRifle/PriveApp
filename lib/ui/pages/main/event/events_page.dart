import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/core/models/event_model.dart';
import 'package:clique/ui/pages/main/event/create_event_page.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

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
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppPageHeader(
                title: 'Events',
                subtitle: state.events.isEmpty
                    ? 'Discover what is happening'
                    : '${state.events.length} event${state.events.length == 1 ? '' : 's'} loaded',
                leadingIcon: Icons.event_rounded,
                actionIcon: Icons.add_rounded,
                onActionTap: _openCreateEvent,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<EventBloc>().add(
                          const LoadEvents(refresh: true),
                        );
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _EventsHeader(
                          searchController: _searchController,
                          category: _category,
                          eventCount: state.events.length,
                          goingCount: state.events
                              .where((event) => event.isGoing)
                              .length,
                          onCategoryChanged: _changeCategory,
                          onSearch: _search,
                        ),
                      ),
                      if (state.status == EventStatus.loading &&
                          state.events.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (state.events.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EventsEmpty(
                            onCreate: _openCreateEvent,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                          sliver: SliverList.separated(
                            itemBuilder: (context, index) {
                              final event = state.events[index];
                              return _EventCard(
                                event: event,
                                onGoing: () => context.read<EventBloc>().add(
                                      RsvpEvent(
                                        eventId: event.id,
                                        status: 'going',
                                      ),
                                    ),
                                onInterested: () =>
                                    context.read<EventBloc>().add(
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: state.events.length,
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
    if (position.pixels < position.maxScrollExtent - 240) return;
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
}

class _EventsHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String category;
  final int eventCount;
  final int goingCount;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearch;

  const _EventsHeader({
    required this.searchController,
    required this.category,
    required this.eventCount,
    required this.goingCount,
    required this.onCategoryChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.event_available_outlined,
                  value: '$eventCount',
                  label: 'Events',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline,
                  value: '$goingCount',
                  label: 'Going',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Search events',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, size: 20),
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
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = _eventCategories[index];
                final selected = item == category;
                return ChoiceChip(
                  selected: selected,
                  label: Text(item.isEmpty ? 'All' : item),
                  onSelected: (_) => onCategoryChanged(item),
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  backgroundColor: AppColors.card,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontWeight: selected ? AppTheme.bold : AppTheme.medium,
                    fontSize: 14,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _eventCategories.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
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

class _EventsEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _EventsEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No events yet',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: AppTheme.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create the first event and let people RSVP.',
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create event'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onGoing;
  final VoidCallback onInterested;
  final VoidCallback onLeave;

  const _EventCard({
    required this.event,
    required this.onGoing,
    required this.onInterested,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCard : AppColors.card;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventImage(imageUrl: event.imageUrl),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 16,
                              fontWeight: AppTheme.bold,
                            ),
                          ),
                        ),
                        if (event.isPrivate) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (event.category.isNotEmpty)
                          _Pill(
                            icon: Icons.sell_outlined,
                            text: event.category,
                          ),
                        _Pill(
                          icon: Icons.schedule_outlined,
                          text: _formatEventTime(event.startsAt),
                        ),
                        if (event.location.isNotEmpty)
                          _Pill(
                            icon: Icons.place_outlined,
                            text: event.location,
                          ),
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.greyTextStyle.copyWith(
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CountPill(
                          icon: Icons.check_circle_outline,
                          label: '${event.goingCount} going',
                        ),
                        _CountPill(
                          icon: Icons.favorite_border,
                          label: '${event.interestedCount} interested',
                        ),
                        if (event.host?.name.isNotEmpty == true)
                          _CountPill(
                            icon: Icons.person_outline,
                            label: event.host!.name,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: onInterested,
                          child: const Text('Interested'),
                        ),
                        FilledButton(
                          onPressed: event.isGoing ? onLeave : onGoing,
                          style: FilledButton.styleFrom(
                            backgroundColor: event.isGoing
                                ? AppColors.success.withOpacity(0.16)
                                : AppColors.primary,
                            foregroundColor: event.isGoing
                                ? AppColors.success
                                : AppColors.white,
                          ),
                          child: Text(event.isGoing ? 'Leave' : 'Going'),
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
  }
}

class _EventImage extends StatelessWidget {
  final String imageUrl;

  const _EventImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().startsWith('http')) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
          ),
        ),
      );
    }

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Icon(
          Icons.event_outlined,
          color: AppColors.primary,
          size: 36,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.event_outlined,
        color: AppColors.primary,
        size: 36,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
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

class _CountPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTheme.greyTextStyle.copyWith(
            fontSize: 12,
            fontWeight: AppTheme.medium,
          ),
        ),
      ],
    );
  }
}

String _formatEventTime(DateTime value) {
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

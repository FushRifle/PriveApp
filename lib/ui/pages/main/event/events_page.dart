import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/core/models/event_model.dart';

import 'package:clique/ui/widgets/common/main_tab_header.dart';
import 'package:clique/ui/widgets/events/event_card.dart';
import 'package:clique/ui/widgets/events/events_empty_state.dart';
import 'package:clique/ui/widgets/events/events_loading_shimmer.dart';
import 'package:clique/ui/widgets/events/events_section_label.dart';
import 'package:clique/ui/widgets/events/events_search_and_filters.dart';
import 'package:clique/ui/pages/main/event/create_event_page.dart';
import 'package:clique/ui/pages/main/event/event_details_page.dart';

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
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return BlocConsumer<EventBloc, EventState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.actionStatus != current.actionStatus,
      listener: _handleStateChange,
      builder: (context, state) {
        final hasEvents = state.events.isNotEmpty;
        final isInitialLoading = !hasEvents &&
            (state.status == EventStatus.initial ||
                state.status == EventStatus.loading);
        final isEmpty = !hasEvents && state.status == EventStatus.success;
        final hasInitialError = !hasEvents && state.status == EventStatus.error;
        final isFiltered =
            state.query.trim().isNotEmpty || state.category.trim().isNotEmpty;
        final featured = _featuredEvent(state.events);
        final remaining = featured == null
            ? const <EventModel>[]
            : state.events.where((item) => item.id != featured.id).toList();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Column(
            children: [
              MainTabHeader(
                title: 'Events',
                subtitle: 'Find your next room, meetup, or night out.',
                actions: [
                  MainTabHeaderAction(
                    icon: Icons.add_rounded,
                    tooltip: 'Create event',
                    onTap: _openCreateEvent,
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Search & Filters
                      SliverToBoxAdapter(
                        child: _PageWidth(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                            child: EventsSearchAndFilters(
                              searchController: _searchController,
                              category: _category,
                              onCategoryChanged: _changeCategory,
                              onSearch: _search,
                              onQueryChanged: _queueSearch,
                              onClear: _clearSearch,
                            ),
                          ),
                        ),
                      ),

                      // Featured Section Label
                      if (hasEvents)
                        SliverToBoxAdapter(
                          child: _PageWidth(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                              child: EventsSectionLabel(
                                title:
                                    isFiltered ? 'Search results' : 'Up next',
                                subtitle: isFiltered
                                    ? '${state.events.length} ${state.events.length == 1 ? 'event' : 'events'} found'
                                    : 'The closest upcoming event in your community',
                              ),
                            ),
                          ),
                        ),

                      // Background Update Indicator
                      if (state.status == EventStatus.loading &&
                          state.events.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: const _BackgroundUpdatePill(),
                          ),
                        ),

                      // Loading State
                      if (isInitialLoading)
                        const SliverToBoxAdapter(
                          child: _PageWidth(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                              child: EventsLoadingShimmer(),
                            ),
                          ),
                        )

                      // Failed Initial Load
                      else if (hasInitialError)
                        SliverToBoxAdapter(
                          child: _PageWidth(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                              child: _EventsLoadError(onRetry: _retry),
                            ),
                          ),
                        )

                      // Empty State
                      else if (isEmpty)
                        SliverToBoxAdapter(
                          child: _PageWidth(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: EventsEmptyState(
                                onCreate: _openCreateEvent,
                                isFiltered: isFiltered,
                                onClearFilters: _clearFilters,
                              ),
                            ),
                          ),
                        )

                      // Events Content
                      else ...[
                        // Featured Event Card
                        SliverToBoxAdapter(
                          child: _PageWidth(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Builder(
                                builder: (context) {
                                  final currentFeatured = featured!;
                                  return EventCard(
                                    event: currentFeatured,
                                    compact: false,
                                    onTap: () =>
                                        _openEventDetails(currentFeatured),
                                    isOwner: _isOwner(currentFeatured),
                                    onEdit: () =>
                                        _openEditEvent(currentFeatured),
                                    isBusy: state.actionStatus ==
                                            EventActionStatus.loading &&
                                        state.activeEventId ==
                                            currentFeatured.id,
                                    onGoing: () =>
                                        context.read<EventBloc>().add(
                                              RsvpEvent(
                                                eventId: currentFeatured.id,
                                                status: 'going',
                                              ),
                                            ),
                                    onInterested: () =>
                                        context.read<EventBloc>().add(
                                              RsvpEvent(
                                                eventId: currentFeatured.id,
                                                status: 'interested',
                                              ),
                                            ),
                                    onLeave: () =>
                                        context.read<EventBloc>().add(
                                              RsvpEvent(
                                                eventId: currentFeatured.id,
                                                status: 'not_going',
                                              ),
                                            ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // More Events Section
                        if (remaining.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _PageWidth(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 28, 16, 14),
                                child: EventsSectionLabel(
                                  title: isFiltered
                                      ? 'Keep exploring'
                                      : 'More events',
                                  subtitle:
                                      '${remaining.length} more ${remaining.length == 1 ? 'event' : 'events'} to explore',
                                ),
                              ),
                            ),
                          ),

                        // Remaining Events List
                        if (remaining.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            sliver: SliverToBoxAdapter(
                              child: _EventGrid(
                                events: remaining,
                                state: state,
                                isOwner: _isOwner,
                                onTap: _openEventDetails,
                                onEdit: _openEditEvent,
                                onRsvp: _rsvp,
                              ),
                            ),
                          ),
                      ],

                      // Pagination Loader
                      if (hasEvents && state.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 40),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Bottom Safe Area
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
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
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final error = state.error;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(error)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          backgroundColor: AppColors.card,
        ),
      );
      context.read<EventBloc>().add(const ClearEventError());
      return;
    }

    if (state.actionStatus == EventActionStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 20,
              ),
              SizedBox(width: 12),
              Text('Updated successfully'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          backgroundColor: AppColors.card,
          duration: const Duration(seconds: 2),
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

  void _queueSearch(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _search);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _search();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _category = '');
    context.read<EventBloc>().add(
          const SearchEvents(query: '', category: ''),
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

  Future<void> _refresh() async {
    final bloc = context.read<EventBloc>();
    bloc.add(const LoadEvents(refresh: true));
    try {
      await bloc.stream
          .firstWhere((state) => state.status != EventStatus.loading)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // The bloc surfaces the request error. The timeout only releases the
      // pull-to-refresh indicator if the network stalls.
    }
  }

  void _retry() {
    context.read<EventBloc>().add(const LoadEvents(refresh: true));
  }

  EventModel? _featuredEvent(List<EventModel> events) {
    if (events.isEmpty) return null;
    final now = DateTime.now();
    final upcoming = events
        .where(
          (event) =>
              (event.endsAt ?? event.startsAt.add(const Duration(hours: 4)))
                  .isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return upcoming.isNotEmpty ? upcoming.first : events.first;
  }

  void _rsvp(EventModel event, String status) {
    HapticFeedback.selectionClick();
    context.read<EventBloc>().add(
          RsvpEvent(eventId: event.id, status: status),
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

  void _openEditEvent(EventModel event) {
    HapticFeedback.lightImpact();
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

  bool _isOwner(EventModel event) {
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
}

class _BackgroundUpdatePill extends StatelessWidget {
  const _BackgroundUpdatePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Updating events...',
            style: AppTheme.greyTextStyle.copyWith(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _EventsLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events couldn’t load',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Check your connection and try again.',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PageWidth extends StatelessWidget {
  final Widget child;

  const _PageWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: child,
      ),
    );
  }
}

class _EventGrid extends StatelessWidget {
  final List<EventModel> events;
  final EventState state;
  final bool Function(EventModel) isOwner;
  final ValueChanged<EventModel> onTap;
  final ValueChanged<EventModel> onEdit;
  final void Function(EventModel, String) onRsvp;

  const _EventGrid({
    required this.events,
    required this.state,
    required this.isOwner,
    required this.onTap,
    required this.onEdit,
    required this.onRsvp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 948),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            const gap = 16.0;
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final event in events)
                  SizedBox(
                    width: cardWidth,
                    child: EventCard(
                      event: event,
                      compact: true,
                      onTap: () => onTap(event),
                      isOwner: isOwner(event),
                      onEdit: () => onEdit(event),
                      isBusy: state.actionStatus == EventActionStatus.loading &&
                          state.activeEventId == event.id,
                      onGoing: () => onRsvp(event, 'going'),
                      onInterested: () => onRsvp(event, 'interested'),
                      onLeave: () => onRsvp(event, 'not_going'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

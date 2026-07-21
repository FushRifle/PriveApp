import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/core/models/event_model.dart';

import 'package:clique/ui/widgets/common/app_page_header.dart';
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
    final theme = Theme.of(context);

    return BlocConsumer<EventBloc, EventState>(
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.actionStatus != current.actionStatus,
      listener: _handleStateChange,
      builder: (context, state) {
        final isInitialLoading =
            state.status == EventStatus.loading && state.events.isEmpty;
        final isEmpty = state.events.isEmpty && !isInitialLoading;
        final remaining = state.events.length > 1
            ? state.events.sublist(1)
            : const <EventModel>[];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<EventBloc>().add(const LoadEvents(refresh: true));
            },
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header Section
                SliverToBoxAdapter(
                  child: AppPageHeader(
                    title: 'Events',
                    subtitle: 'Discover live conversations and meetups.',
                    leadingIcon: Icons.event_rounded,
                    actionIcon: Icons.add_rounded,
                    onActionTap: _openCreateEvent,
                  ),
                ),

                // Search & Filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 40, 10, 20),
                    child: EventsSearchAndFilters(
                      searchController: _searchController,
                      category: _category,
                      onCategoryChanged: _changeCategory,
                      onSearch: _search,
                    ),
                  ),
                ),

                // Featured Section Label
                if (!isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                      child: EventsSectionLabel(
                        title: 'Featured',
                        subtitle: isInitialLoading
                            ? 'Loading upcoming events...'
                            : 'Events people are talking about now',
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
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: EventsLoadingShimmer(),
                    ),
                  )

                // Empty State
                else if (isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: EventsEmptyState(onCreate: _openCreateEvent),
                    ),
                  )

                // Events Content
                else ...[
                  // Featured Event Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Builder(
                        builder: (context) {
                          final currentFeatured = state.events.first;
                          return EventCard(
                            event: currentFeatured,
                            compact: false,
                            onTap: () => _openEventDetails(currentFeatured),
                            isOwner: _isOwner(currentFeatured),
                            onEdit: () => _openEditEvent(currentFeatured),
                            onGoing: () => context.read<EventBloc>().add(
                                  RsvpEvent(
                                    eventId: currentFeatured.id,
                                    status: 'going',
                                  ),
                                ),
                            onInterested: () => context.read<EventBloc>().add(
                                  RsvpEvent(
                                    eventId: currentFeatured.id,
                                    status: 'interested',
                                  ),
                                ),
                            onLeave: () => context.read<EventBloc>().add(
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

                  // More Events Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 24, 10, 16),
                      child: EventsSectionLabel(
                        title: 'More events',
                        subtitle: remaining.isEmpty
                            ? 'No additional events right now'
                            : '${remaining.length} more ${remaining.length == 1 ? 'event' : 'events'} to explore',
                      ),
                    ),
                  ),

                  // Remaining Events List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 32),
                    sliver: remaining.isEmpty
                        ? const SliverToBoxAdapter(child: SizedBox.shrink())
                        : SliverList.separated(
                            itemBuilder: (context, index) {
                              final event = remaining[index];
                              return EventCard(
                                event: event,
                                compact: true,
                                onTap: () => _openEventDetails(event),
                                isOwner: _isOwner(event),
                                onEdit: () => _openEditEvent(event),
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
                                const SizedBox(height: 14),
                            itemCount: remaining.length,
                          ),
                  ),
                ],

                // Pagination Loader
                if (!isInitialLoading &&
                    !isEmpty &&
                    state.hasMore &&
                    state.events.isNotEmpty)
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
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, EventState state) {
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

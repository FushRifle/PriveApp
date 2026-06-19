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
                  child: EventsSearchAndFilters(
                    searchController: _searchController,
                    category: _category,
                    onCategoryChanged: _changeCategory,
                    onSearch: _search,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: EventsSectionLabel(
                    title: 'Featured',
                    subtitle: isInitialLoading
                        ? 'Loading the next thing people can act on now'
                        : 'The next thing people can act on now',
                  ),
                ),
              ),
              if (state.status == EventStatus.loading &&
                  state.events.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _BackgroundUpdatePill(),
                  ),
                ),
              if (isInitialLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 110),
                    child: EventsLoadingShimmer(),
                  ),
                )
              else if (isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EventsEmptyState(onCreate: _openCreateEvent),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: EventsSectionLabel(
                      title: 'More events',
                      subtitle: remaining.isEmpty
                          ? 'No additional events loaded'
                          : '${remaining.length} more events',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount: remaining.length,
                        ),
                ),
              ],
              if (!isInitialLoading &&
                  !isEmpty &&
                  state.hasMore &&
                  state.events.isNotEmpty)
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
    final user = context.read<AuthBloc>().state.user;
    final rawId = user?['id'];
    final currentUserId = rawId is int
        ? rawId
        : rawId is String
            ? int.tryParse(rawId)
            : null;
    final hostId = event.hostId != 0 ? event.hostId : event.host?.id;
    return currentUserId != null && hostId != null && currentUserId == hostId;
  }
}

class _BackgroundUpdatePill extends StatelessWidget {
  const _BackgroundUpdatePill();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Updating events',
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

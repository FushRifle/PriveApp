import 'dart:async';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFeedService extends FeedService {
  FakeFeedService({
    required this.createdPost,
    required this.refreshResponse,
    this.deleteError,
  });

  final FeedPost createdPost;
  final PostsResponse refreshResponse;
  final Object? deleteError;
  String? lastReaction;

  @override
  Future<FeedPost> createPost({
    required String content,
    List<Map<String, dynamic>>? attachments,
    String postType = 'standard',
    bool isAnonymous = false,
    String? anonymousCategory,
    List<String>? pollOptions,
    int? pollExpirationHours,
  }) async {
    return createdPost;
  }

  @override
  Future<PostsResponse> getPosts({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    return refreshResponse;
  }

  @override
  Future<Map<String, dynamic>> likePost(
    int postId, {
    String reaction = 'Love',
  }) async {
    lastReaction = reaction;
    return {'reaction': reaction};
  }

  @override
  Future<void> deletePost(int postId) async {
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> removeCachedPost(int postId) async {}
}

void main() {
  group('FeedBloc', () {
    test('keeps a newly created post after refresh merges server data',
        () async {
      final createdPost = FeedPost(
        id: 99,
        user: const UserInfo(
          id: 1,
          name: 'Tester',
          handle: 'tester',
          avatar: '',
        ),
        content: 'Local optimistic post',
        attachments: const [],
        time: 'now',
        likes: 0,
        comments: 0,
        isLiked: false,
        createdAt: DateTime.parse('2026-06-16T12:10:00Z'),
      );

      final serverPost = FeedPost(
        id: 1,
        user: const UserInfo(
          id: 2,
          name: 'Server',
          handle: 'server',
          avatar: '',
        ),
        content: 'Server feed item',
        attachments: const [],
        time: 'now',
        likes: 0,
        comments: 0,
        isLiked: false,
        createdAt: DateTime.parse('2026-06-16T12:00:00Z'),
      );

      final bloc = FeedBloc(
        feedService: FakeFeedService(
          createdPost: createdPost,
          refreshResponse: PostsResponse(
            posts: [serverPost],
            hasMore: false,
            page: 1,
          ),
        ),
      );

      addTearDown(bloc.close);

      bloc.add(
        const CreateFeedPost(
          content: 'Local optimistic post',
        ),
      );

      final createdState = await bloc.stream.firstWhere(
        (state) => state.posts.any((post) => post.id == 99),
      );
      expect(createdState.posts.map((post) => post.id), contains(99));

      bloc.add(RefreshFeed());

      final refreshedState = await bloc.stream.firstWhere(
        (state) =>
            state.posts.any((post) => post.id == 1) &&
            state.posts.any((post) => post.id == 99),
      );

      expect(refreshedState.posts.map((post) => post.id), containsAll([1, 99]));
      expect(refreshedState.posts.first.id, 99);
    });

    test('persists the selected post reaction in state and service payload',
        () async {
      final post = _post(id: 7);
      final service = FakeFeedService(
        createdPost: post,
        refreshResponse: PostsResponse(
          posts: [post],
          hasMore: false,
          page: 1,
        ),
      );
      final bloc = FeedBloc(feedService: service);
      addTearDown(bloc.close);

      bloc.add(const GetFeedPosts(refresh: true));
      await bloc.stream.firstWhere((state) => state.posts.isNotEmpty);

      bloc.add(const LikeFeedPost(postId: 7, reaction: 'Haha'));
      final reacted = await bloc.stream.firstWhere(
        (state) => state.posts.first.reaction == 'Haha',
      );

      expect(reacted.posts.first.isLiked, isTrue);
      expect(reacted.posts.first.likes, 1);
      expect(service.lastReaction, 'Haha');
    });

    test('completes deletion only after the service succeeds', () async {
      final post = _post(id: 8);
      final service = FakeFeedService(
        createdPost: post,
        refreshResponse: PostsResponse(
          posts: [post],
          hasMore: false,
          page: 1,
        ),
      );
      final bloc = FeedBloc(feedService: service);
      addTearDown(bloc.close);

      bloc.add(const GetFeedPosts(refresh: true));
      await bloc.stream.firstWhere((state) => state.posts.isNotEmpty);

      final completion = Completer<void>();
      bloc.add(DeleteFeedPost(postId: 8, completer: completion));
      await completion.future;

      expect(bloc.state.posts, isEmpty);
    });

    test('restores a post when server deletion fails', () async {
      final post = _post(id: 9);
      final service = FakeFeedService(
        createdPost: post,
        refreshResponse: PostsResponse(
          posts: [post],
          hasMore: false,
          page: 1,
        ),
        deleteError: StateError('delete failed'),
      );
      final bloc = FeedBloc(feedService: service);
      addTearDown(bloc.close);

      bloc.add(const GetFeedPosts(refresh: true));
      await bloc.stream.firstWhere((state) => state.posts.isNotEmpty);

      final completion = Completer<void>();
      bloc.add(DeleteFeedPost(postId: 9, completer: completion));

      await expectLater(completion.future, throwsA(isA<StateError>()));
      expect(bloc.state.posts.single.id, 9);
    });
  });
}

FeedPost _post({required int id}) {
  return FeedPost(
    id: id,
    user: const UserInfo(
      id: 1,
      name: 'Tester',
      handle: 'tester',
      avatar: '',
    ),
    content: 'Post $id',
    attachments: const [],
    time: 'now',
    likes: 0,
    comments: 0,
    isLiked: false,
    createdAt: DateTime.parse('2026-06-16T12:10:00Z'),
  );
}

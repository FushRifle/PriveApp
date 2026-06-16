import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFeedService extends FeedService {
  FakeFeedService({
    required this.createdPost,
    required this.refreshResponse,
  });

  final FeedPost createdPost;
  final PostsResponse refreshResponse;

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
  });
}

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/bloc/explore/explore_bloc.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/insights/insights_bloc.dart';
import 'package:clique/bloc/match/match_bloc.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

class AppBlocProviders {
  static List<BlocProvider> providers({
    required AuthBloc authBloc,
  }) {
    return [
      BlocProvider<AuthBloc>.value(
        value: authBloc,
      ),
      BlocProvider(
        create: (_) => CloudinaryCubit(),
      ),
      BlocProvider(
        create: (_) => UserBloc(),
      ),
      BlocProvider(
        create: (_) => ProfileBloc(),
      ),
      BlocProvider(
        create: (_) => FeedBloc(),
      ),
      BlocProvider(
        create: (_) => FriendsBloc(),
      ),
      BlocProvider(
        create: (_) => MatchBloc(),
      ),
      BlocProvider(
        create: (_) => InsightsBloc(),
      ),
      BlocProvider(
        create: (_) => StoriesBloc(),
      ),
      BlocProvider(
        create: (_) => ExploreBloc(),
      ),
      BlocProvider(
        create: (_) => ReelBloc(),
      ),
      BlocProvider(
        create: (_) => ChatBloc(),
      ),
      BlocProvider(
        create: (_) => ChatGalleryCubit(),
      ),
    ];
  }
}
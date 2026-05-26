import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';

import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';

import 'package:clique/bloc/profile/profile_bloc.dart';

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

      // GLOBAL CORE BLOCS
      BlocProvider(
        create: (_) => UserBloc(),
      ),

      BlocProvider(
        create: (_) => ProfileBloc(),
      ),
    ];
  }
}

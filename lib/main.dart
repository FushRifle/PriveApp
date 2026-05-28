import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

import 'package:clique/app/configs/theme.dart';
import 'package:clique/managers/auth_guard.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/app/configs/api_config.dart';
import 'package:clique/data/providers/theme_provider.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/data/services/notification/push_notification_service.dart';

import 'package:clique/core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
    debug: false,
  );

  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'dug6225go',
  );

  await PushNotificationService.instance.initialize();

  FlutterError.onError = FlutterError.presentError;
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  DateTime? _lastAuthCheck;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authBloc = AuthBloc()..add(CheckAuthStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _authBloc.close();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();

      if (_lastAuthCheck == null ||
          now.difference(_lastAuthCheck!) > const Duration(seconds: 20)) {
        _lastAuthCheck = now;

        _authBloc.add(CheckAuthStatus());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      themeModeProvider,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: _authBloc,
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
      ],
      child: Builder(
        builder: (context) {
          return BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) {
              return previous.status != current.status ||
                  previous.token != current.token;
            },
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                PushNotificationService.instance.syncDeviceToken();
              }
              if (state.status == AuthStatus.unauthenticated) {
                PushNotificationService.instance.deleteDeviceToken();
              }
            },
            child: MaterialApp(
              title: 'Clique',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: _scaffoldMessengerKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              scrollBehavior: const CustomScrollBehavior(),
              home: const AuthGuard(),
              onGenerateRoute: AppRouter.onGenerateRoute,
            ),
          );
        },
      ),
    );
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(
    BuildContext context,
  ) {
    return const BouncingScrollPhysics();
  }
}

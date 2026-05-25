import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:clique/app/configs/api_config.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/core/providers/bloc_providers.dart';

import 'package:clique/core/router/app_router.dart';

import 'package:clique/data/providers/theme_provider.dart';

import 'package:clique/managers/auth_guard.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';

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

  FlutterError.onError = FlutterError.presentError;
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with WidgetsBindingObserver {
  late final AuthBloc _authBloc;

  final GlobalKey<ScaffoldMessengerState>
      _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authBloc = AuthBloc()
      ..add(CheckAuthStatus());
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
      _authBloc.add(CheckAuthStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      themeModeProvider,
    );

    return MultiBlocProvider(
      providers: AppBlocProviders.providers(
        authBloc: _authBloc,
      ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) {
              return previous.status !=
                      current.status ||
                  previous.error != current.error;
            },
            listener: (context, state) {
              final error =
                  state.error?.toLowerCase() ?? '';

              if (_isCriticalAuthError(error)) {
                context
                    .read<AuthBloc>()
                    .add(SignOutRequested());
              }
            },
          ),
        ],
        child: MaterialApp(
          title: 'Clique',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey:
              _scaffoldMessengerKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          scrollBehavior:
              const CustomScrollBehavior(),
          home: const AuthGuard(),
          onGenerateRoute:
              AppRouter.onGenerateRoute,
        ),
      ),
    );
  }

  bool _isCriticalAuthError(
    String error,
  ) {
    const criticalErrors = [
      'token',
      'session',
      'unauthorized',
      'forbidden',
      'blocked',
      'suspended',
      'invalid credentials',
    ];

    return criticalErrors.any(
      (e) => error.contains(e),
    );
  }
}

class CustomScrollBehavior
    extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(
    BuildContext context,
  ) {
    return const BouncingScrollPhysics();
  }
}
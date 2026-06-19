import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:clique/core/services/calls/stream_call_service.dart';
import 'package:clique/core/services/chat/stream_chat_service.dart';

import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/auth_guard.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/app/configs/api_config.dart';
import 'package:clique/core/services/security/app_lock_service.dart';

import 'package:clique/core/providers/theme_provider.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/subscription/feature_access_cubit.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/services/notification/push_notification_service.dart';
import 'package:clique/firebase_options.dart';

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

  await _initializeFirebase();

  await LocalCacheService.initialize();

  await PushNotificationService.instance.initialize();

  FlutterError.onError = FlutterError.presentError;
}

Future<void> _initializeFirebase() async {
  if (kIsWeb || Firebase.apps.isNotEmpty) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;
  final AppLockService _appLockService = AppLockService.instance;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  DateTime? _lastAuthCheck;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authBloc = AuthBloc();
    PushNotificationService.instance.setNavigatorKey(_navigatorKey);
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
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {}
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      themeModeProvider,
    );
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);

    AppColors.setDarkMode(isDarkMode);

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
        BlocProvider(
          create: (_) => FeatureAccessCubit(),
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
                final token = state.token ?? '';
                StreamCallService.instance.setAuthToken(token);
                StreamChatService.instance.setAuthToken(token);
                unawaited(StreamCallService.instance.connect());
                unawaited(
                    StreamChatService.instance.connect().catchError((_) {}));
                final userID = state.user?['id']?.toString() ?? '';
                context.read<FeatureAccessCubit>()
                  ..load()
                  ..configureRevenueCat(userID);
              }
              if (state.status == AuthStatus.unauthenticated) {
                PushNotificationService.instance.deleteDeviceToken();
                unawaited(StreamCallService.instance.disconnect());
                unawaited(StreamChatService.instance.disconnect());
                StreamCallService.instance.clearAuthToken();
                StreamChatService.instance.clearAuthToken();
                LocalCacheService.clearAll();
                context.read<UserBloc>()
                  ..clearAuthToken()
                  ..add(ResetUserState());
                context.read<ProfileBloc>()
                  ..clearAuthToken()
                  ..add(ResetProfileState());
              }
            },
            child: MaterialApp(
              title: 'Clique',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: _scaffoldMessengerKey,
              navigatorKey: _navigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              scrollBehavior: const CustomScrollBehavior(),
              home: _SecurityGate(
                appLockService: _appLockService,
                child: const AuthGuard(),
              ),
              onGenerateRoute: AppRouter.onGenerateRoute,
            ),
          );
        },
      ),
    );
  }
}

class _SecurityGate extends StatefulWidget {
  final Widget child;
  final AppLockService appLockService;

  const _SecurityGate({
    required this.child,
    required this.appLockService,
  });

  @override
  State<_SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<_SecurityGate>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isUnlocked = false;
  bool _isPrompting = false;
  bool _hasUnlockedThisSession = false;
  DateTime? _lastUnlockAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bootstrap(forcePrompt: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isUnlocked = false;
    }
  }

  Future<void> _bootstrap({bool forcePrompt = false}) async {
    if (_isPrompting) return;

    try {
      final authState = context.read<AuthBloc>().state;

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return;
      }

      if (!authState.isAuthenticated || authState.token == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isUnlocked = true;
        });
        return;
      }

      final userId = _currentUserId();
      final settings = await _resolveAppLockSettings(userId);
      if (!mounted) return;

      if (_isLoading) {
        setState(() => _isLoading = false);
      }

      if (!settings.enabled) {
        setState(() {
          _isUnlocked = true;
        });

        unawaited(
          widget.appLockService
              .load(userId: userId)
              .then((_) {})
              .catchError((_) {}),
        );
        return;
      }

      if (forcePrompt &&
          _hasUnlockedThisSession &&
          _lastUnlockAt != null &&
          settings.timeoutSeconds > 0 &&
          DateTime.now().difference(_lastUnlockAt!) <
              Duration(seconds: settings.timeoutSeconds)) {
        setState(() {
          _isUnlocked = true;
        });

        unawaited(
          widget.appLockService
              .load(userId: userId)
              .then((_) {})
              .catchError((_) {}),
        );
        return;
      }

      if (_isUnlocked && !forcePrompt) {
        unawaited(
          widget.appLockService
              .load(userId: userId)
              .then((_) {})
              .catchError((_) {}),
        );
        return;
      }

      _isPrompting = true;
      final unlocked = await Navigator.of(context).pushNamed<bool>(
        NamedRoutes.lockScreenScreen,
        arguments: userId,
      );
      if (!mounted) return;

      setState(() {
        _isUnlocked = unlocked == true;
        if (_isUnlocked) {
          _hasUnlockedThisSession = true;
          _lastUnlockAt = DateTime.now();
        }
      });

      unawaited(
        widget.appLockService
            .load(userId: userId)
            .then((_) {})
            .catchError((_) {}),
      );
    } finally {
      _isPrompting = false;
    }
  }

  Future<AppLockSettings> _resolveAppLockSettings(int? userId) async {
    final cached = await widget.appLockService.loadCached(userId: userId);

    if (cached.enabled) {
      unawaited(
        widget.appLockService.load(userId: userId).catchError((_) => cached),
      );
      return cached;
    }

    try {
      return await widget.appLockService.load(userId: userId);
    } catch (_) {
      return cached;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        return previous.status != current.status ||
            previous.token != current.token ||
            previous.user != current.user;
      },
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          _bootstrap(forcePrompt: true);
        } else if (state.status == AuthStatus.unauthenticated) {
          setState(() {
            _isLoading = false;
            _isUnlocked = true;
          });
        }
      },
      child: _isLoading && !_isUnlocked
          ? Scaffold(
              backgroundColor: AppColors.backgroundColor,
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : widget.child,
    );
  }

  int? _currentUserId() {
    final currentUser = context.read<AuthBloc>().state.user;
    final raw = currentUser?['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
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

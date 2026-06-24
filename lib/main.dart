import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:clique/core/services/calls/stream_call_service.dart';
import 'package:clique/core/services/chat/stream_chat_service.dart';

import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/auth_guard.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/app/configs/api_config.dart';
import 'package:clique/core/services/security/app_lock_service.dart';

import 'package:clique/core/providers/theme_provider.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/settings/settings_bloc.dart';
import 'package:clique/bloc/subscription/feature_access_cubit.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/services/notification/push_notification_service.dart';
import 'package:clique/firebase_options.dart';
import 'package:clique/ui/pages/auth/security/unlock_page.dart';

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
        BlocProvider(
          create: (_) => SettingsBloc(),
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
                final userID = state.user?['id']?.toString() ?? '';
                final userId = int.tryParse(userID);
                context.read<SettingsBloc>().add(
                      LoadSettings(userId: userId, silent: true),
                    );
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
                childBuilder: (onBootstrapComplete) => AuthGuard(
                  onBootstrapComplete: onBootstrapComplete,
                ),
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
  final Widget Function(VoidCallback onBootstrapComplete) childBuilder;
  final AppLockService appLockService;

  const _SecurityGate({
    required this.childBuilder,
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
  bool _authGuardReady = false;
  int? _lockUserId;
  AppLockSettings? _lockSettings;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      final timeoutSeconds = _lockSettings?.timeoutSeconds ?? 0;
      final shouldRelock = _lockSettings?.enabled == true &&
          timeoutSeconds > 0 &&
          backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >=
              Duration(seconds: timeoutSeconds);
      if (shouldRelock && mounted) {
        setState(() => _isUnlocked = false);
        if (_authGuardReady) {
          unawaited(_bootstrap(forcePrompt: true));
        }
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    }
  }

  Future<void> _bootstrap({bool forcePrompt = false}) async {
    if (_isPrompting || !_authGuardReady) return;

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
      final settingsBloc = context.read<SettingsBloc>();
      settingsBloc.add(LoadSettings(userId: userId, silent: true));
      final settingsState = settingsBloc.state;

      final settings = await _resolveAppLockSettings(userId, settingsState);
      if (!mounted) return;

      if (_isLoading) {
        setState(() => _isLoading = false);
      }

      if (!settings.enabled) {
        setState(() {
          _isUnlocked = true;
          _lockUserId = userId;
          _lockSettings = settings;
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
      if (!mounted) return;

      setState(() {
        _lockUserId = userId;
        _lockSettings = settings;
        _isUnlocked = false;
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

  Future<AppLockSettings> _resolveAppLockSettings(
    int? userId,
    SettingsState settingsState,
  ) async {
    final cached = await widget.appLockService.loadCached(userId: userId);

    // A locally enabled lock must win during cold start. SettingsBloc may
    // still contain the unscoped/default state while AuthGuard bootstraps.
    if (cached.enabled) {
      unawaited(
        widget.appLockService.load(userId: userId).catchError((_) => cached),
      );
      return cached;
    }

    final mergedCached = _mergeSettingsLock(settingsState, cached);

    try {
      final remoteOrCached = await widget.appLockService.load(userId: userId);
      return _mergeSettingsLock(settingsState, remoteOrCached);
    } catch (_) {
      return mergedCached;
    }
  }

  AppLockSettings _mergeSettingsLock(
    SettingsState settingsState,
    AppLockSettings cached,
  ) {
    return AppLockSettings(
      enabled: settingsState.appLockEnabled ?? cached.enabled,
      biometricEnabled:
          settingsState.appLockBiometricEnabled ?? cached.biometricEnabled,
      pinEnabled: settingsState.appLockPinEnabled ?? cached.pinEnabled,
      timeoutSeconds:
          settingsState.appLockTimeoutSeconds ?? cached.timeoutSeconds,
      pin: cached.pin,
    );
  }

  Future<void> _applySettingsState(SettingsState settingsState) async {
    if (!_authGuardReady) return;
    final authState = context.read<AuthBloc>().state;
    if (!authState.isAuthenticated || authState.token == null) return;
    if (settingsState.appLockEnabled == null) return;

    final userId = _currentUserId();
    final cached = await widget.appLockService.loadCached(userId: userId);
    if (!mounted) return;

    final settings = _mergeSettingsLock(settingsState, cached);
    setState(() {
      _isLoading = false;
      _isUnlocked = !settings.enabled;
      _lockUserId = userId;
      _lockSettings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowUnlockPage = !_isUnlocked && _lockSettings?.enabled == true;
    final authGuard = widget.childBuilder(_handleAuthGuardReady);

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            return previous.status != current.status ||
                previous.token != current.token;
          },
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              setState(() {
                _authGuardReady = false;
                _isLoading = true;
                _isUnlocked = false;
              });
            } else if (state.status == AuthStatus.unauthenticated) {
              setState(() {
                _authGuardReady = false;
                _isLoading = false;
                _isUnlocked = true;
                _lockSettings = null;
              });
            }
          },
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (previous, current) {
            return previous.appLockEnabled != current.appLockEnabled ||
                previous.appLockBiometricEnabled !=
                    current.appLockBiometricEnabled ||
                previous.appLockPinEnabled != current.appLockPinEnabled ||
                previous.appLockTimeoutSeconds != current.appLockTimeoutSeconds;
          },
          listener: (context, state) {
            unawaited(_applySettingsState(state));
          },
        ),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          authGuard,
          if (_authGuardReady && _isLoading)
            const _SecurityLoadingPlaceholder()
          else if (_authGuardReady && shouldShowUnlockPage)
            AppUnlockPage(
              isLoading: _isLoading,
              userId: _lockUserId,
              settings: _lockSettings,
              appLockService: widget.appLockService,
              onUnlocked: () {
                if (!mounted) return;
                setState(() => _isUnlocked = true);
              },
            ),
        ],
      ),
    );
  }

  void _handleAuthGuardReady() {
    if (!mounted || _authGuardReady) return;
    setState(() {
      _authGuardReady = true;
      _isLoading = true;
      _isUnlocked = false;
    });
    unawaited(_bootstrap(forcePrompt: true));
  }

  int? _currentUserId() {
    final backendUser = context.read<UserBloc>().state.currentUser;
    final backendId = _readUserId(backendUser?['id']);
    if (backendId != null) return backendId;

    final authUser = context.read<AuthBloc>().state.user;
    return _readUserId(authUser?['id']);
  }

  int? _readUserId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}

class _SecurityLoadingPlaceholder extends StatelessWidget {
  const _SecurityLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: const Center(
        child: SizedBox(
          width: 116,
          height: 116,
          child: _SecurityLoadingAnimation(),
        ),
      ),
    );
  }
}

class _SecurityLoadingAnimation extends StatelessWidget {
  const _SecurityLoadingAnimation();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/loading.json',
      repeat: true,
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

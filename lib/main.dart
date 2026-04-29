import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/ui/pages/home_page.dart';
import 'package:social_media_app/ui/pages/profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Only apply these fixes on web
  if (kIsWeb) {
    // Disable system overlays to prevent keyboard inset issues
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Critical fix for web view insets error
      builder: (context, child) {
        // Get the current media query data
        final mediaQueryData = MediaQuery.of(context);

        // On web, force viewInsets to zero to prevent negative values
        if (kIsWeb) {
          return MediaQuery(
            data: mediaQueryData.copyWith(
              viewInsets: EdgeInsets.zero,
              // Keep viewPadding for safe areas
              viewPadding: EdgeInsets.only(
                top: mediaQueryData.padding.top,
                bottom: mediaQueryData.padding.bottom,
              ),
            ),
            child: child!,
          );
        }

        return child!;
      },
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case NamedRoutes.homeScreen:
            return MaterialPageRoute(builder: (context) => const HomePage());
          case NamedRoutes.profileScreen:
            return MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            );
          default:
            return MaterialPageRoute(builder: (context) => const HomePage());
        }
      },
    );
  }
}

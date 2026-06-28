import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/ui/pages/auth/unified_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unified onboarding starts with name step', (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProfileBloc(),
          ),
          BlocProvider(
            create: (_) => UserBloc(),
          ),
        ],
        child: const MaterialApp(
          home: UnifiedOnboardingPage(),
        ),
      ),
    );

    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}

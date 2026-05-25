import 'package:flutter/material.dart';

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(
    BuildContext context,
  ) {
    return const BouncingScrollPhysics();
  }
}

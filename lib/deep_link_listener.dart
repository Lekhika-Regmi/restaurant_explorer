import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:restaurant_explorer_nepal/screens/explore/explore_screen.dart';
import 'package:restaurant_explorer_nepal/screens/restaurant_detail_screen.dart';
import 'package:restaurant_explorer_nepal/widgets/bottom_navbar.dart';
//custom deep link

class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({super.key, required this.child});
  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  @override
  void initState() {
    final appLinks = AppLinks(); // AppLinks is singleton

    final sub = appLinks.uriLinkStream.listen((uri) {
      log('URI: ${uri.toString()}');

      if (uri.pathSegments.first == 'details' && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CustomBottomNavBar()),
        );
        final id = uri.queryParameters['id'];

        if (id != null && int.tryParse(id) != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RestaurantDetailScreen(restaurantId: id),
            ),
          );
        }
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

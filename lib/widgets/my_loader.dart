import 'package:flutter/material.dart';

class MyLoader extends StatefulWidget {
  const MyLoader({super.key});

  @override
  State<MyLoader> createState() => _MyLoaderState();
}

class _MyLoaderState extends State<MyLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Continuously repeat the animation
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffeeeeee), width: 3),
              ),
            ),
            // Animated progress indicator
            SizedBox(
              width: 180,
              height: 180,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: null, // Indeterminate progress
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.black,
                    ),
                    backgroundColor: Colors.transparent,
                  );
                },
              ),
            ),
            // Center content (optional)
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 40,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

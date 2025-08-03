import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../providers/favorites_provider.dart';

class FavoriteButton extends ConsumerWidget {
  final Restaurant restaurant;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    super.key,
    required this.restaurant,
    this.onSuccess,
    this.onError,
    this.iconSize = 24.0,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.red,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final isFavorite = favoritesState.isFavorite(restaurant.id);

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? activeColor : inactiveColor,
        size: iconSize,
      ),
      onPressed: () async {
        final success = await ref
            .read(favoritesProvider.notifier)
            .toggleFavorite(restaurant);

        if (success) {
          onSuccess?.call();
        } else {
          onError?.call();
        }
      },
    );
  }
}

// Alternative version with more customization
class CustomFavoriteButton extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  final Widget Function(bool isFavorite, bool isLoading, VoidCallback onTap)
  builder;

  const CustomFavoriteButton({
    super.key,
    required this.restaurant,
    required this.builder,
  });

  @override
  ConsumerState<CustomFavoriteButton> createState() =>
      _CustomFavoriteButtonState();
}

class _CustomFavoriteButtonState extends ConsumerState<CustomFavoriteButton> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesProvider);
    final isFavorite = favoritesState.isFavorite(widget.restaurant.id);

    return widget.builder(isFavorite, _isToggling, () async {
      if (_isToggling) return;

      setState(() {
        _isToggling = true;
      });

      try {
        await ref
            .read(favoritesProvider.notifier)
            .toggleFavorite(widget.restaurant);
      } finally {
        if (mounted) {
          setState(() {
            _isToggling = false;
          });
        }
      }
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../services/favorites_service.dart';

// State class for favorites
class FavoritesState {
  final Set<String> favoriteIds;
  final List<Restaurant> favoriteRestaurants;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favoriteIds = const {},
    this.favoriteRestaurants = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    Set<String>? favoriteIds,
    List<Restaurant>? favoriteRestaurants,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      favoriteRestaurants: favoriteRestaurants ?? this.favoriteRestaurants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFavorite(String restaurantId) {
    return favoriteIds.contains(restaurantId);
  }
}

// StateNotifier for managing favorites
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final FavoritesService _favoritesService;

  FavoritesNotifier(this._favoritesService) : super(const FavoritesState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final favoriteIds = await _favoritesService.getFavoriteIds();
      final favoriteRestaurants = await _favoritesService
          .getFavoriteRestaurants();

      state = state.copyWith(
        favoriteIds: favoriteIds,
        favoriteRestaurants: favoriteRestaurants,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load favorites: $e',
      );
    }
  }

  Future<bool> toggleFavorite(Restaurant restaurant) async {
    final isCurrentlyFavorite = state.isFavorite(restaurant.id);

    // Optimistically update the UI
    final newFavoriteIds = Set<String>.from(state.favoriteIds);
    final newFavoriteRestaurants = List<Restaurant>.from(
      state.favoriteRestaurants,
    );

    if (isCurrentlyFavorite) {
      newFavoriteIds.remove(restaurant.id);
      newFavoriteRestaurants.removeWhere((r) => r.id == restaurant.id);
    } else {
      newFavoriteIds.add(restaurant.id);
      newFavoriteRestaurants.add(restaurant);
    }

    state = state.copyWith(
      favoriteIds: newFavoriteIds,
      favoriteRestaurants: newFavoriteRestaurants,
    );

    try {
      bool success;
      if (isCurrentlyFavorite) {
        success = await _favoritesService.removeFromFavorites(restaurant.id);
      } else {
        success = await _favoritesService.addToFavorites(restaurant);
      }

      if (!success) {
        // Revert the optimistic update if the operation failed
        state = state.copyWith(
          favoriteIds: state.favoriteIds,
          favoriteRestaurants: state.favoriteRestaurants,
        );
      }

      return success;
    } catch (e) {
      // Revert the optimistic update on error
      final revertedFavoriteIds = Set<String>.from(state.favoriteIds);
      final revertedFavoriteRestaurants = List<Restaurant>.from(
        state.favoriteRestaurants,
      );

      if (!isCurrentlyFavorite) {
        revertedFavoriteIds.remove(restaurant.id);
        revertedFavoriteRestaurants.removeWhere((r) => r.id == restaurant.id);
      } else {
        revertedFavoriteIds.add(restaurant.id);
        revertedFavoriteRestaurants.add(restaurant);
      }

      state = state.copyWith(
        favoriteIds: revertedFavoriteIds,
        favoriteRestaurants: revertedFavoriteRestaurants,
        error: 'Failed to update favorite: $e',
      );

      return false;
    }
  }

  Future<bool> addToFavorites(Restaurant restaurant) async {
    if (state.isFavorite(restaurant.id)) {
      return false; // Already in favorites
    }

    // Optimistically update
    final newFavoriteIds = Set<String>.from(state.favoriteIds)
      ..add(restaurant.id);
    final newFavoriteRestaurants = List<Restaurant>.from(
      state.favoriteRestaurants,
    )..add(restaurant);

    state = state.copyWith(
      favoriteIds: newFavoriteIds,
      favoriteRestaurants: newFavoriteRestaurants,
    );

    try {
      final success = await _favoritesService.addToFavorites(restaurant);

      if (!success) {
        // Revert on failure
        state = state.copyWith(
          favoriteIds: Set<String>.from(state.favoriteIds)
            ..remove(restaurant.id),
          favoriteRestaurants: List<Restaurant>.from(state.favoriteRestaurants)
            ..removeWhere((r) => r.id == restaurant.id),
        );
      }

      return success;
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        favoriteIds: Set<String>.from(state.favoriteIds)..remove(restaurant.id),
        favoriteRestaurants: List<Restaurant>.from(state.favoriteRestaurants)
          ..removeWhere((r) => r.id == restaurant.id),
        error: 'Failed to add to favorites: $e',
      );
      return false;
    }
  }

  Future<bool> removeFromFavorites(String restaurantId) async {
    if (!state.isFavorite(restaurantId)) {
      return false; // Not in favorites
    }

    // Find the restaurant to remove
    final restaurantToRemove = state.favoriteRestaurants.firstWhere(
      (r) => r.id == restaurantId,
      orElse: () => throw Exception('Restaurant not found in favorites'),
    );

    // Optimistically update
    final newFavoriteIds = Set<String>.from(state.favoriteIds)
      ..remove(restaurantId);
    final newFavoriteRestaurants = List<Restaurant>.from(
      state.favoriteRestaurants,
    )..removeWhere((r) => r.id == restaurantId);

    state = state.copyWith(
      favoriteIds: newFavoriteIds,
      favoriteRestaurants: newFavoriteRestaurants,
    );

    try {
      final success = await _favoritesService.removeFromFavorites(restaurantId);

      if (!success) {
        // Revert on failure
        state = state.copyWith(
          favoriteIds: Set<String>.from(state.favoriteIds)..add(restaurantId),
          favoriteRestaurants: List<Restaurant>.from(state.favoriteRestaurants)
            ..add(restaurantToRemove),
        );
      }

      return success;
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        favoriteIds: Set<String>.from(state.favoriteIds)..add(restaurantId),
        favoriteRestaurants: List<Restaurant>.from(state.favoriteRestaurants)
          ..add(restaurantToRemove),
        error: 'Failed to remove from favorites: $e',
      );
      return false;
    }
  }

  Future<bool> clearAllFavorites() async {
    // Store current state for potential revert
    final currentFavoriteIds = state.favoriteIds;
    final currentFavoriteRestaurants = state.favoriteRestaurants;

    // Optimistically clear
    state = state.copyWith(
      favoriteIds: const {},
      favoriteRestaurants: const [],
    );

    try {
      final success = await _favoritesService.clearAllFavorites();

      if (!success) {
        // Revert on failure
        state = state.copyWith(
          favoriteIds: currentFavoriteIds,
          favoriteRestaurants: currentFavoriteRestaurants,
        );
      }

      return success;
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        favoriteIds: currentFavoriteIds,
        favoriteRestaurants: currentFavoriteRestaurants,
        error: 'Failed to clear favorites: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for the FavoritesNotifier
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
      final favoritesService = ref.watch(favoritesServiceProvider);
      return FavoritesNotifier(favoritesService);
    });

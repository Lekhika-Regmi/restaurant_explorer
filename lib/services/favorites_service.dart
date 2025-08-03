import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/restaurant.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_restaurants';
  static const String _favoritesDataKey = 'favorite_restaurants_data';

  /// Add restaurant to favorites
  Future<bool> addToFavorites(Restaurant restaurant) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current favorite IDs
      List<String> favoriteIds = prefs.getStringList(_favoritesKey) ?? [];

      // Check if already in favorites
      if (favoriteIds.contains(restaurant.id)) {
        return false; // Already in favorites
      }

      // Add to favorites list
      favoriteIds.add(restaurant.id);
      await prefs.setStringList(_favoritesKey, favoriteIds);

      // Store restaurant data for offline access
      Map<String, dynamic> favoritesData = {};
      final existingDataJson = prefs.getString(_favoritesDataKey);
      if (existingDataJson != null) {
        favoritesData = json.decode(existingDataJson);
      }

      favoritesData[restaurant.id] = restaurant.toJson();
      await prefs.setString(_favoritesDataKey, json.encode(favoritesData));

      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove restaurant from favorites
  Future<bool> removeFromFavorites(String restaurantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove from favorites list
      List<String> favoriteIds = prefs.getStringList(_favoritesKey) ?? [];
      favoriteIds.remove(restaurantId);
      await prefs.setStringList(_favoritesKey, favoriteIds);

      // Remove from stored data
      final existingDataJson = prefs.getString(_favoritesDataKey);
      if (existingDataJson != null) {
        Map<String, dynamic> favoritesData = json.decode(existingDataJson);
        favoritesData.remove(restaurantId);
        await prefs.setString(_favoritesDataKey, json.encode(favoritesData));
      }

      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  /// Check if restaurant is in favorites
  Future<bool> isFavorite(String restaurantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favoriteIds = prefs.getStringList(_favoritesKey) ?? [];
      return favoriteIds.contains(restaurantId);
    } catch (e) {
      print('Error checking favorites status: $e');
      return false;
    }
  }

  /// Get all favorite restaurants data
  Future<List<Restaurant>> getFavoriteRestaurants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favoriteIds = prefs.getStringList(_favoritesKey) ?? [];

      if (favoriteIds.isEmpty) {
        return [];
      }

      // Try to get stored restaurant data
      final existingDataJson = prefs.getString(_favoritesDataKey);
      if (existingDataJson != null) {
        Map<String, dynamic> favoritesData = json.decode(existingDataJson);

        List<Restaurant> favorites = [];
        for (String id in favoriteIds) {
          if (favoritesData.containsKey(id)) {
            try {
              Restaurant restaurant = Restaurant.fromJson(favoritesData[id]);
              favorites.add(restaurant);
            } catch (e) {
              print('Error parsing restaurant data for $id: $e');
            }
          }
        }

        return favorites;
      }

      return [];
    } catch (e) {
      print('Error getting favorite restaurants: $e');
      return [];
    }
  }

  /// Get all favorite IDs
  Future<Set<String>> getFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favoriteIds = prefs.getStringList(_favoritesKey) ?? [];
      return favoriteIds.toSet();
    } catch (e) {
      print('Error getting favorite IDs: $e');
      return {};
    }
  }

  /// Clear all favorites
  Future<bool> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      await prefs.remove(_favoritesDataKey);
      return true;
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }
}

// Provider for the FavoritesService
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

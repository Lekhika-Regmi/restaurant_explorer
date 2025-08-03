import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../models/restaurant.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3002', // Your Mockoon URL
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiService() {
    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        //  logPrint: (object) => print('API: $object'),
      ),
    );
  }

  /// Fetch all restaurants with optional filters
  Future<List<Restaurant>> fetchRestaurants({
    String? cuisine,
    String? priceRange,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? city,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};

      // Add filters if provided
      if (cuisine != null && cuisine != 'All') {
        queryParams['cuisine'] = cuisine.toLowerCase();
      }
      if (priceRange != null && priceRange != 'All') {
        queryParams['priceRange'] = _mapPriceRange(priceRange);
      }
      if (city != null) {
        queryParams['city'] = city;
      }
      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude;
        queryParams['lng'] = longitude;
      }
      if (radiusKm != null) {
        queryParams['radius'] = radiusKm;
      }

      final response = await _dio.get<List<dynamic>>(
        '/restaurants',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.json),
      );

      print('API response data: ${response.data}');

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final data = response.data as List;
      List<Restaurant> restaurants = data
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();

      // If location is provided, sort by distance
      if (latitude != null && longitude != null) {
        restaurants.sort((a, b) {
          double distanceA = Geolocator.distanceBetween(
            latitude,
            longitude,
            a.latitude,
            a.longitude,
          );
          double distanceB = Geolocator.distanceBetween(
            latitude,
            longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }

      return restaurants;
    } on DioException catch (e) {
      print('API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to fetch restaurants: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred while fetching restaurants');
    }
  }

  /// Fetch a single restaurant by ID
  Future<Restaurant> fetchRestaurantById(String id) async {
    try {
      print('Fetching restaurant with ID: $id');
      final response = await _dio.get('/restaurants/$id');

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.data == null) {
        throw Exception('Restaurant not found');
      }

      final json = response.data as Map<String, dynamic>;
      print('Parsed JSON: $json');

      final restaurant = Restaurant.fromJson(json);
      print('Created restaurant object: ${restaurant.name}');

      return restaurant;
    } on DioException catch (e) {
      print('API Error fetching restaurant $id: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      print('Request path: ${e.requestOptions.path}');
      throw Exception('Failed to fetch restaurant $id: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching restaurant $id: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Unexpected error fetching restaurant $id: $e');
    }
  }

  /// Search restaurants by name, address, or cuisine
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/restaurants/search',
        queryParameters: {'q': query},
        options: Options(responseType: ResponseType.json),
      );

      if (response.data == null) {
        return []; // Return empty list if no results
      }

      final data = response.data as List;
      return data
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Search API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to search restaurants: ${e.message}');
    } catch (e) {
      print('Unexpected search error: $e');
      throw Exception('Unexpected error occurred during search');
    }
  }

  /// Get restaurants by city/district
  Future<List<Restaurant>> getRestaurantsByLocation(String location) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/restaurants',
        queryParameters: {'location': location},
        options: Options(responseType: ResponseType.json),
      );

      if (response.data == null) {
        return []; // Return empty list if no results
      }

      final data = response.data as List;
      return data
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Location filter API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to get restaurants by location: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred while filtering by location');
    }
  }

  /// Get restaurants by cuisine type
  Future<List<Restaurant>> getRestaurantsByCuisine(String cuisine) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/restaurants',
        queryParameters: {'cuisine': cuisine.toLowerCase()},
        options: Options(responseType: ResponseType.json),
      );

      if (response.data == null) {
        return []; // Return empty list if no results
      }

      final data = response.data as List;
      return data
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Cuisine filter API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to get restaurants by cuisine: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred while filtering by cuisine');
    }
  }

  /// Get nearby restaurants based on user location
  Future<List<Restaurant>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/restaurants/nearby',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radiusKm,
        },
        options: Options(responseType: ResponseType.json),
      );

      if (response.data == null) {
        return []; // Return empty list if no results
      }

      final data = response.data as List;
      List<Restaurant> restaurants = data
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by distance
      restaurants.sort((a, b) {
        double distanceA = Geolocator.distanceBetween(
          latitude,
          longitude,
          a.latitude,
          a.longitude,
        );
        double distanceB = Geolocator.distanceBetween(
          latitude,
          longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return restaurants;
    } on DioException catch (e) {
      print('Nearby restaurants API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to get nearby restaurants: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception(
        'Unexpected error occurred while getting nearby restaurants',
      );
    }
  }

  /// Get popular restaurants
  Future<List<Restaurant>> getPopularRestaurants() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/restaurants/popular',
        options: Options(responseType: ResponseType.json),
      );

      if (response.data == null) {
        return []; // Return empty list if no results
      }

      final data = response.data as List;
      return data
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Popular restaurants API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to get popular restaurants: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception(
        'Unexpected error occurred while getting popular restaurants',
      );
    }
  }

  /// Add restaurant to favorites
  Future<bool> addToFavorites(String restaurantId, String userId) async {
    try {
      final response = await _dio.post(
        '/favorites',
        data: {'restaurantId': restaurantId, 'userId': userId},
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Add to favorites API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to add to favorites: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred while adding to favorites');
    }
  }

  /// Remove restaurant from favorites
  Future<bool> removeFromFavorites(String restaurantId, String userId) async {
    try {
      final response = await _dio.delete('/favorites/$restaurantId/$userId');

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('Remove from favorites API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to remove from favorites: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception(
        'Unexpected error occurred while removing from favorites',
      );
    }
  }

  /// Get user's favorite restaurants
  Future<List<Restaurant>> getFavoriteRestaurants(String userId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/favorites/$userId',
        options: Options(responseType: ResponseType.json),
      );

      if (response.data == null) {
        return []; // Return empty list if no favorites
      }

      final data = response.data as List;
      return data
          .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Get favorites API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to get favorite restaurants: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred while getting favorites');
    }
  }

  /// Submit restaurant review
  Future<bool> submitReview({
    required String restaurantId,
    required String userId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '/reviews',
        data: {
          'restaurantId': restaurantId,
          'userId': userId,
          'rating': rating,
          'comment': comment,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Submit review API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to submit review: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred while submitting review');
    }
  }

  /// Get reviews for a restaurant
  Future<List<Map<String, dynamic>>> getRestaurantReviews(
    String restaurantId,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/reviews/$restaurantId',
        options: Options(responseType: ResponseType.json),
      );

      if (response.data == null) {
        return []; // Return empty list if no reviews
      }

      return (response.data as List)
          .map((review) => review as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      print('Get reviews API Error: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception('Failed to get restaurant reviews: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred while getting reviews');
    }
  }

  /// Helper method to map price range display text to API values
  String _mapPriceRange(String displayRange) {
    if (displayRange.contains('Budget')) return 'budget';
    if (displayRange.contains('Mid-range')) return 'mid-range';
    if (displayRange.contains('Fine Dining')) return 'fine-dining';
    return 'budget';
  }

  /// Test connection to Mockoon server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}

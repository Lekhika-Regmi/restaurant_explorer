// Enhanced restaurant.dart model
import 'package:flutter/material.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? cuisine;
  final String? priceRange;
  final double? rating;
  final List<String>? images;
  final String? phone;
  final String? email;
  final Map<String, String>? openingHours;
  final List<String>? features; // e.g., ['WiFi', 'Parking', 'Delivery']
  final String? description;
  final bool isOpen;
  final String? city;
  final String? district;
  final String? website;
  final int? reviewCount;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.cuisine,
    this.priceRange,
    this.rating,
    this.images,
    this.phone,
    this.email,
    this.openingHours,
    this.features,
    this.description,
    this.isOpen = true,
    this.city,
    this.district,
    this.website,
    this.reviewCount,
  });

  // Factory for JSON deserialization
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _parseDouble(json['location']?['lat'] ?? json['latitude']),
      longitude: _parseDouble(json['location']?['lng'] ?? json['longitude']),
      cuisine: json['cuisine']?.toString(),
      priceRange: json['priceRange']?.toString(),
      rating: _parseDouble(json['rating']),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      openingHours: (json['openingHours'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key.toLowerCase(), value.toString()),
      ),
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : null,
      description: json['description']?.toString(),
      isOpen: json['isOpen'] ?? true,
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      website: json['website']?.toString(),
      reviewCount: json['reviewCount'] as int?,
    );
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': {'lat': latitude, 'lng': longitude},
      'cuisine': cuisine,
      'priceRange': priceRange,
      'rating': rating,
      'images': images,
      'phone': phone,
      'email': email,
      'openingHours': openingHours,
      'features': features,
      'description': description,
      'isOpen': isOpen,
      'city': city,
      'district': district,
      'website': website,
      'reviewCount': reviewCount,
    };
  }

  // Get price range display text
  String get priceRangeDisplay {
    switch (priceRange) {
      case 'budget':
        return 'Budget (Rs. 0-500)';
      case 'mid-range':
        return 'Mid-range (Rs. 500-1500)';
      case 'fine-dining':
        return 'Fine Dining (Rs. 1500+)';
      default:
        return 'Price not specified';
    }
  }

  // Get cuisine display text
  String get cuisineDisplay {
    return cuisine ?? 'Cuisine not specified';
  }

  // Get rating display
  String get ratingDisplay {
    if (rating == null) return 'No rating';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }

  // Get full rating text with review count
  String get fullRatingDisplay {
    if (rating == null) return 'No rating';
    String ratingText = '${rating!.toStringAsFixed(1)} ⭐';
    if (reviewCount != null && reviewCount! > 0) {
      ratingText += ' ($reviewCount reviews)';
    }
    return ratingText;
  }

  // Check if restaurant is currently open (basic implementation)
  bool get isCurrentlyOpen {
    if (openingHours == null) return isOpen;

    final now = DateTime.now();
    final dayOfWeek = _getDayOfWeek(now.weekday);
    final currentTime = TimeOfDay.fromDateTime(now);

    final todayHours = openingHours![dayOfWeek];
    if (todayHours == null || todayHours.toLowerCase() == 'closed') {
      return false;
    }

    // Parse opening hours (format: "09:00 - 22:00")
    if (todayHours.contains(' - ')) {
      final times = todayHours.split(' - ');
      if (times.length == 2) {
        final openTime = _parseTime(times[0]);
        final closeTime = _parseTime(times[1]);

        if (openTime != null && closeTime != null) {
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          final openMinutes = openTime.hour * 60 + openTime.minute;
          final closeMinutes = closeTime.hour * 60 + closeTime.minute;

          // Handle cases where restaurant closes after midnight
          if (closeMinutes < openMinutes) {
            return currentMinutes >= openMinutes ||
                currentMinutes <= closeMinutes;
          } else {
            return currentMinutes >= openMinutes &&
                currentMinutes <= closeMinutes;
          }
        }
      }
    }

    return isOpen;
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[weekday - 1];
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.trim().split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $timeString');
    }
    return null;
  }

  // Get opening hours for today
  String get todaysHours {
    if (openingHours == null) return 'Hours not specified';

    final now = DateTime.now();
    final dayOfWeek = _getDayOfWeek(now.weekday);
    return openingHours![dayOfWeek] ?? 'Hours not specified';
  }

  // Get opening status text
  String get openStatusText {
    if (isCurrentlyOpen) {
      return 'Open';
    } else {
      return 'Closed';
    }
  }

  // Get distance text (requires external distance calculation)
  String getDistanceText(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m away';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km away';
    }
  }

  // Check if restaurant has a specific feature
  bool hasFeature(String feature) {
    return features?.any(
          (f) => f.toLowerCase().contains(feature.toLowerCase()),
        ) ??
        false;
  }

  // Get primary image URL
  String? get primaryImage {
    return images?.isNotEmpty == true ? images!.first : null;
  }

  @override
  String toString() {
    return 'Restaurant{id: $id, name: $name, cuisine: $cuisine, rating: $rating}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Restaurant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

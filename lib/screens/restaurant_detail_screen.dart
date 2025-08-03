import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../widgets/map_view_widget.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  late Future<Restaurant> _futureRestaurant;

  @override
  void initState() {
    super.initState();
    _futureRestaurant = ApiService().fetchRestaurantById(widget.restaurantId);
  }

  Future<void> _toggleFavorite(Restaurant restaurant) async {
    final success = await ref
        .read(favoritesProvider.notifier)
        .toggleFavorite(restaurant);

    if (success) {
      final favoritesState = ref.read(favoritesProvider);
      final isFavorite = favoritesState.isFavorite(restaurant.id);

      final snackBar = SnackBar(
        content: Text(
          isFavorite ? 'Added to favorites!' : 'Removed from favorites!',
        ),
        backgroundColor: isFavorite ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _openInMaps(Restaurant restaurant) async {
    final geoUri = Uri(
      scheme: 'geo',
      path: '${restaurant.latitude},${restaurant.longitude}',
      queryParameters: {
        'q':
            '${restaurant.latitude},${restaurant.longitude}(${restaurant.name})',
      },
    );

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }

    final httpsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${restaurant.latitude},${restaurant.longitude}',
    );

    if (await canLaunchUrl(httpsUri)) {
      await launchUrl(httpsUri);
      return;
    }

    throw 'Could not launch Maps';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onTap,
    Color iconColor = Colors.grey,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(content, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChips(List<String> features) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: features
          .map(
            (feature) => Chip(
              label: Text(feature, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey.shade100,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      body: FutureBuilder<Restaurant>(
        future: _futureRestaurant,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final restaurant = snapshot.data!;
          final isFavorite = favorites.isFavorite(restaurant.id);
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                // App Bar with Hero Image
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: const Color(0xFFFFF290),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Map as background
                        // MapViewWidget(
                        //   latitude: restaurant.latitude,
                        //   longitude: restaurant.longitude,
                        //   title: restaurant.name,
                        //   // showControls: false,
                        // ),
                        // Gradient overlay
                        PageView(
                          children: (restaurant.images ?? []).map((imageName) {
                            return Image.asset(
                              'assets/images/$imageName',
                              fit: BoxFit.cover,
                            );
                          }).toList(),
                        ),

                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black26],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    // Favorite button
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () => _toggleFavorite(restaurant),
                      ),
                    ),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant Name and Rating
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurant.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          restaurant.cuisineDisplay,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          restaurant.priceRangeDisplay,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (restaurant.rating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF290),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  restaurant.ratingDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description
                        if (restaurant.description != null) ...[
                          Text(
                            restaurant.description!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Features
                        if (restaurant.features != null &&
                            restaurant.features!.isNotEmpty) ...[
                          const Text(
                            'Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureChips(restaurant.features!),
                          const SizedBox(height: 16),
                        ],

                        // Contact Information
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildInfoCard(
                          icon: Icons.location_on,
                          title: 'Address',
                          content: restaurant.address,
                          iconColor: Colors.red,
                          onTap: () => _openInMaps(restaurant),
                        ),

                        if (restaurant.phone != null)
                          _buildInfoCard(
                            icon: Icons.phone,
                            title: 'Phone',
                            content: restaurant.phone!,
                            iconColor: Colors.green,
                            onTap: () => _makePhoneCall(restaurant.phone!),
                          ),

                        if (restaurant.email != null)
                          _buildInfoCard(
                            icon: Icons.email,
                            title: 'Email',
                            content: restaurant.email!,
                            iconColor: Colors.blue,
                          ),

                        // Opening Hours
                        if (restaurant.openingHours != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Opening Hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: restaurant.openingHours!.entries.map((
                                  entry,
                                ) {
                                  final day =
                                      entry.key.substring(0, 1).toUpperCase() +
                                      entry.key.substring(1);
                                  final hours =
                                      entry.value?.toString() ?? 'Closed';
                                  final isClosed =
                                      hours.toLowerCase() == 'closed';
                                  final isToday = _isToday(entry.key);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          day,
                                          style: TextStyle(
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isToday
                                                ? Colors.yellow[800]
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          hours.toLowerCase() == 'closed'
                                              ? 'Closed'
                                              : hours,
                                          style: TextStyle(
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isToday
                                                ? Colors.yellow[800]
                                                : hours.toLowerCase() ==
                                                      'closed'
                                                ? Colors.red
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openInMaps(restaurant),
                                icon: const Icon(Icons.directions),
                                label: const Text('Get Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFF290),
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (restaurant.phone != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _makePhoneCall(restaurant.phone!),
                                  icon: const Icon(Icons.call),
                                  label: const Text('Call Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Map Section
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: MapViewWidget(
                            latitude: restaurant.latitude,
                            longitude: restaurant.longitude,
                            title: restaurant.name,
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isToday(String dayName) {
    final now = DateTime.now();
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final today = days[now.weekday - 1];
    return dayName.toLowerCase() == today;
  }
}

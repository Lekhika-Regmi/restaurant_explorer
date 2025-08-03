import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/restaurant.dart';
import '../../providers/favorites_provider.dart';
import '../../screens/restaurant_detail_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  static const id = 'favorites_screen';

  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {
  Position? _currentPosition;
  String _sortBy = 'name'; // 'name', 'distance', 'rating'
  List<Restaurant> _sortedRestaurants = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Load favorites when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _currentPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {});
        _sortRestaurants();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _sortRestaurants() {
    final favoritesState = ref.read(favoritesProvider);
    List<Restaurant> restaurants = List.from(
      favoritesState.favoriteRestaurants,
    );

    switch (_sortBy) {
      case 'name':
        restaurants.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        restaurants.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'distance':
        if (_currentPosition != null) {
          restaurants.sort((a, b) {
            double distanceA = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              a.latitude,
              a.longitude,
            );
            double distanceB = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              b.latitude,
              b.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }

    if (mounted) {
      setState(() {
        _sortedRestaurants = restaurants;
      });
    }
  }

  double _calculateDistance(Restaurant restaurant) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          restaurant.latitude,
          restaurant.longitude,
        ) /
        1000;
  }

  Future<void> _removeFromFavorites(Restaurant restaurant) async {
    final success = await ref
        .read(favoritesProvider.notifier)
        .removeFromFavorites(restaurant.id);
    if (success) {
      _showSnackBar('Removed from favorites', Colors.orange);
      _sortRestaurants(); // Re-sort after removal
    } else {
      _showSnackBar('Failed to remove from favorites', Colors.red);
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Name'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                _sortRestaurants();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Rating'),
              value: 'rating',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                _sortRestaurants();
                Navigator.pop(context);
              },
            ),
            if (_currentPosition != null)
              RadioListTile<String>(
                title: const Text('Distance'),
                value: 'distance',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  _sortRestaurants();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch the favorites state
    final favoritesState = ref.watch(favoritesProvider);

    // Update sorted restaurants when favorites change
    ref.listen<FavoritesState>(favoritesProvider, (previous, next) {
      if (previous?.favoriteRestaurants != next.favoriteRestaurants) {
        _sortRestaurants();
      }
    });

    // Use sorted restaurants if available, otherwise use the state's restaurants
    final displayRestaurants = _sortedRestaurants.isNotEmpty
        ? _sortedRestaurants
        : favoritesState.favoriteRestaurants;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Restaurants',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (displayRestaurants.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.sort, color: Colors.black87),
              onPressed: _showSortDialog,
              tooltip: 'Sort favorites',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) async {
                if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: favoritesState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFF290)),
              ),
            )
          : displayRestaurants.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header with count and sort info
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${displayRestaurants.length} favorite${displayRestaurants.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Sorted by ${_sortBy == 'name'
                            ? 'Name'
                            : _sortBy == 'rating'
                            ? 'Rating'
                            : 'Distance'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Error display
                if (favoritesState.error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            favoritesState.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            ref.read(favoritesProvider.notifier).clearError();
                          },
                        ),
                      ],
                    ),
                  ),

                // Favorites list
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFFFF290),
                    onRefresh: () async {
                      await ref
                          .read(favoritesProvider.notifier)
                          .loadFavorites();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = displayRestaurants[index];
                        final distance = _calculateDistance(restaurant);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF290),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.black87,
                                size: 30,
                              ),
                            ),
                            title: Text(
                              restaurant.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  restaurant.address,
                                  style: const TextStyle(color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        restaurant.cuisineDisplay,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        restaurant.ratingDisplay,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                    if (_currentPosition != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '${distance.toStringAsFixed(1)} km',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeFromFavorites(restaurant),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RestaurantDetailScreen(
                                    restaurantId: restaurant.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Favorite Restaurants',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring and add restaurants\nto your favorites!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Switch to explore tab
              DefaultTabController.of(context)?.animateTo(0);
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Restaurants'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFF290),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text(
          'Are you sure you want to remove all restaurants from your favorites? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(favoritesProvider.notifier)
                  .clearAllFavorites();
              if (success) {
                _showSnackBar('All favorites cleared', Colors.orange);
                setState(() {
                  _sortedRestaurants.clear();
                });
              } else {
                _showSnackBar('Error clearing favorites', Colors.red);
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

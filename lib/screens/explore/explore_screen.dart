import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../auth/auth_service.dart';
import '../../models/restaurant.dart';
import '../../providers/favorites_provider.dart';
import '../../screens/restaurant_detail_screen.dart';
import '../../services/api_service.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  static const id = "explore_screen";

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  final AuthService _auth = AuthService();
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedCuisine = 'All';
  String _selectedPriceRange = 'All';
  double _selectedRadius = 5.0; // km
  Position? _currentPosition;

  final List<String> _cuisineTypes = [
    'All',
    'Nepali',
    'Indian',
    'Chinese',
    'Continental',
    'Italian',
    'Thai',
    'Japanese',
    'Fast Food',
    'Tibetan',
  ];

  final List<String> _priceRanges = [
    'All',
    'Budget (Rs. 0-500)',
    'Mid-range (Rs. 500-1500)',
    'Fine Dining (Rs. 1500+)',
  ];

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentLocation();
    await _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled.', Colors.orange);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are denied', Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Location permissions are permanently denied',
          Colors.red,
        );
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {});
        _filterRestaurants();
      }
    } catch (e) {
      _showSnackBar('Failed to get location: $e', Colors.red);
    }
  }

  Future<void> _loadRestaurants() async {
    if (!mounted) return;

    try {
      final restaurants = await _apiService.fetchRestaurants();
      if (mounted) {
        setState(() {
          _allRestaurants = restaurants;
          _filteredRestaurants = restaurants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to load restaurants: $e', Colors.red);
      }
    }
  }

  void _filterRestaurants() {
    if (!mounted) return;

    List<Restaurant> filtered = List.from(_allRestaurants);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (restaurant) =>
                restaurant.name.toLowerCase().contains(searchTerm) ||
                restaurant.address.toLowerCase().contains(searchTerm) ||
                (restaurant.cuisine?.toLowerCase().contains(searchTerm) ??
                    false),
          )
          .toList();
    }

    // Cuisine filter
    if (_selectedCuisine != 'All') {
      filtered = filtered
          .where(
            (restaurant) =>
                restaurant.cuisine?.toLowerCase() ==
                _selectedCuisine.toLowerCase(),
          )
          .toList();
    }

    // Price range filter
    if (_selectedPriceRange != 'All') {
      String priceRangeKey = _mapPriceRange(_selectedPriceRange);
      filtered = filtered
          .where((restaurant) => restaurant.priceRange == priceRangeKey)
          .toList();
    }

    // Location-based filter
    if (_currentPosition != null) {
      filtered = filtered.where((restaurant) {
        double distance =
            Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              restaurant.latitude,
              restaurant.longitude,
            ) /
            1000; // Convert to km
        return distance <= _selectedRadius;
      }).toList();

      // Sort by distance
      filtered.sort((a, b) {
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

    if (mounted) {
      setState(() {
        _filteredRestaurants = filtered;
      });
    }
  }

  String _mapPriceRange(String displayRange) {
    if (displayRange.contains('Budget')) return 'budget';
    if (displayRange.contains('Mid-range')) return 'mid-range';
    if (displayRange.contains('Fine Dining')) return 'fine-dining';
    return 'budget';
  }

  double _calculateDistance(Restaurant restaurant) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          restaurant.latitude,
          restaurant.longitude,
        ) /
        1000; // Convert to km
  }

  Future<void> _toggleFavorite(Restaurant restaurant) async {
    final success = await ref
        .read(favoritesProvider.notifier)
        .toggleFavorite(restaurant);

    if (success) {
      final favoritesState = ref.read(favoritesProvider);
      final isFavorite = favoritesState.isFavorite(restaurant.id);

      _showSnackBar(
        isFavorite ? 'Added to favorites!' : 'Removed from favorites!',
        isFavorite ? Colors.green : Colors.orange,
      );
    } else {
      _showSnackBar('Failed to update favorites', Colors.red);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Restaurants'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cuisine Filter
                const Text(
                  'Cuisine Type:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCuisine,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _cuisineTypes
                      .map(
                        (cuisine) => DropdownMenuItem(
                          value: cuisine,
                          child: Text(cuisine),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => _selectedCuisine = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Price Range Filter
                const Text(
                  'Price Range:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPriceRange,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _priceRanges
                      .map(
                        (range) =>
                            DropdownMenuItem(value: range, child: Text(range)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => _selectedPriceRange = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Distance Filter
                Text(
                  'Distance: ${_selectedRadius.toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _selectedRadius,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  inactiveColor: Colors.black54,
                  activeColor: Colors.yellow[600],
                  onChanged: (value) =>
                      setDialogState(() => _selectedRadius = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCuisine = 'All';
                  _selectedPriceRange = 'All';
                  _selectedRadius = 5.0;
                });
                _filterRestaurants();
                Navigator.pop(context);
              },
              child: const Text('Reset', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF290),
                foregroundColor: Colors.black87,
              ),
              onPressed: () {
                _filterRestaurants();
                Navigator.pop(context);
              },
              child: const Text('Apply'),
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Watch the favorites state
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search restaurants...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                style: TextStyle(color: Colors.black87),
                onChanged: (_) => _filterRestaurants(),
              )
            : const Text(
                'Explore Restaurants',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _filterRestaurants();
                });
              },
            )
          else ...[
            IconButton(
              visualDensity: VisualDensity(horizontal: 0.5),
              icon: const Icon(Icons.search, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              visualDensity: VisualDensity(horizontal: 0.5),
              icon: const Icon(Icons.filter_list, color: Colors.black87),
              onPressed: _showFilterDialog,
            ),
          ],
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredRestaurants.length} restaurants found',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    if (_currentPosition != null)
                      Text(
                        'Within ${_selectedRadius.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),

                // Active filters chips
                if (_selectedCuisine != 'All' ||
                    _selectedPriceRange != 'All') ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_selectedCuisine != 'All')
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(_selectedCuisine),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() => _selectedCuisine = 'All');
                                _filterRestaurants();
                              },
                              backgroundColor: const Color(0xFFFFF290),
                            ),
                          ),
                        if (_selectedPriceRange != 'All')
                          Chip(
                            label: Text(_selectedPriceRange.split(' ')[0]),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() => _selectedPriceRange = 'All');
                              _filterRestaurants();
                            },
                            backgroundColor: const Color(0xFFFFF290),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Restaurant List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFF290),
                      ),
                    ),
                  )
                : _filteredRestaurants.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No restaurants found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFFFF290),
                    onRefresh: () async {
                      await _loadRestaurants();
                      ref.read(favoritesProvider.notifier).loadFavorites();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _filteredRestaurants[index];
                        final distance = _calculateDistance(restaurant);
                        final isFavorite = favoritesState.isFavorite(
                          restaurant.id,
                        );

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
                              height: 70,
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
                                    // Cuisine chip
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
                                    // Rating chip
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
                                      // Distance chip
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
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () => _toggleFavorite(restaurant),
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
}

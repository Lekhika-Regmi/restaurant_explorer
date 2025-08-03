import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/restaurant.dart';
import '../../screens/restaurant_detail_screen.dart';
import '../../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  static const id = "map_screen";

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;
  final ApiService _apiService = ApiService();

  List<Restaurant> _allRestaurants = [];
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  String _selectedCuisine = 'All';
  double _selectedRadius = 10.0; // km

  // Default location (Kathmandu, Nepal)
  static const LatLng _defaultLocation = LatLng(27.7172, 85.3240);

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadRestaurants();
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
        _updateCameraPosition();
      }
    } catch (e) {
      _showSnackBar('Failed to get location: $e', Colors.red);
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _apiService.fetchRestaurants();
      if (mounted) {
        setState(() {
          _allRestaurants = restaurants;
          _isLoading = false;
        });
        _updateMarkers();
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

  void _updateMarkers() {
    _markers.clear();

    // Add current location marker if available
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Filter restaurants based on selected criteria
    List<Restaurant> filteredRestaurants = _allRestaurants.where((restaurant) {
      // Cuisine filter
      if (_selectedCuisine != 'All' &&
          restaurant.cuisine?.toLowerCase() != _selectedCuisine.toLowerCase()) {
        return false;
      }

      // Distance filter (if current location is available)
      if (_currentPosition != null) {
        double distance =
            Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              restaurant.latitude,
              restaurant.longitude,
            ) /
            1000; // Convert to km

        if (distance > _selectedRadius) {
          return false;
        }
      }

      return true;
    }).toList();

    // Add restaurant markers
    for (Restaurant restaurant in filteredRestaurants) {
      _markers.add(
        Marker(
          markerId: MarkerId(restaurant.id),
          position: LatLng(restaurant.latitude, restaurant.longitude),
          infoWindow: InfoWindow(
            title: restaurant.name,
            snippet:
                '${restaurant.cuisineDisplay} • ${restaurant.ratingDisplay}',
            onTap: () => _navigateToRestaurantDetail(restaurant),
          ),
          icon: _getMarkerIcon(restaurant.cuisine ?? ''),
          onTap: () => _showRestaurantBottomSheet(restaurant),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  BitmapDescriptor _getMarkerIcon(String cuisine) {
    switch (cuisine.toLowerCase()) {
      case 'nepali':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'italian':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'chinese':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case 'tibetan':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'continental':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _updateCameraPosition() {
    if (_controller != null) {
      LatLng target = _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : _defaultLocation;

      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 13.0),
        ),
      );
    }
  }

  void _navigateToRestaurantDetail(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RestaurantDetailScreen(restaurantId: restaurant.id),
      ),
    );
  }

  void _showRestaurantBottomSheet(Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Restaurant info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurant.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF290),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        restaurant.ratingDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Restaurant details
                Row(
                  children: [
                    _buildInfoChip(restaurant.cuisineDisplay, Icons.restaurant),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      restaurant.priceRangeDisplay,
                      Icons.attach_money,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (restaurant.description != null) ...[
                  Text(
                    restaurant.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToRestaurantDetail(restaurant);
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF290),
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Add to favorites functionality
                        Navigator.pop(context);
                        _showSnackBar('Added to favorites!', Colors.green);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.favorite),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Map'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                activeColor: const Color(0xFFFFF290),
                onChanged: (value) =>
                    setDialogState(() => _selectedRadius = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCuisine = 'All';
                  _selectedRadius = 10.0;
                });
                _updateMarkers();
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF290),
                foregroundColor: Colors.black87,
              ),
              onPressed: () {
                _updateMarkers();
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
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurant Map',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFF290),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.black87),
            onPressed: () {
              _getCurrentLocation();
              _updateCameraPosition();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _updateCameraPosition();
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : _defaultLocation,
              zoom: 13.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapType: MapType.normal,
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFF290)),
                ),
              ),
            ),

          // Legend
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem('Your Location', BitmapDescriptor.hueBlue),
                  _buildLegendItem('Nepali', BitmapDescriptor.hueRed),
                  _buildLegendItem('Italian', BitmapDescriptor.hueGreen),
                  _buildLegendItem('Chinese', BitmapDescriptor.hueYellow),
                  _buildLegendItem('Others', BitmapDescriptor.hueRed),
                ],
              ),
            ),
          ),

          // Restaurant count
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF290),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_markers.length - (_currentPosition != null ? 1 : 0)} restaurants',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double hue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getColorFromHue(hue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getColorFromHue(double hue) {
    if (hue == BitmapDescriptor.hueRed) return Colors.red;
    if (hue == BitmapDescriptor.hueBlue) return Colors.blue;
    if (hue == BitmapDescriptor.hueGreen) return Colors.green;
    if (hue == BitmapDescriptor.hueYellow) return Colors.orange;
    if (hue == BitmapDescriptor.hueOrange) return Colors.deepOrange;
    if (hue == BitmapDescriptor.hueViolet) return Colors.purple;
    return Colors.red;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

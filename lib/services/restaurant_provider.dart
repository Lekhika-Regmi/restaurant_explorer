// // 1. Create a Restaurant Provider/Manager to handle state
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../models/restaurant.dart';
// import '../screens/favorites/favorites_screen.dart';
// import '../services/api_service.dart';
//
// class RestaurantProvider extends ChangeNotifier {
//   final ApiService _apiService = ApiService();
//
//   List<Restaurant> _restaurants = [];
//   bool _isLoading = false;
//   String? _error;
//
//   // Getters
//   List<Restaurant> get restaurants => _restaurants;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//
//   // Fetch all restaurants once
//   Future<void> fetchAllRestaurants({
//     String? cuisine,
//     String? priceRange,
//     double? latitude,
//     double? longitude,
//     double? radiusKm,
//     String? city,
//   }) async {
//     if (_restaurants.isNotEmpty && _error == null) {
//       // Already have data, no need to fetch again unless forced
//       return;
//     }
//
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       _restaurants = await _apiService.fetchRestaurants(
//         cuisine: cuisine,
//         priceRange: priceRange,
//         latitude: latitude,
//         longitude: longitude,
//         radiusKm: radiusKm,
//         city: city,
//       );
//       _error = null;
//     } catch (e) {
//       _error = e.toString();
//       _restaurants = [];
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Get restaurant by ID from cached data
//   Restaurant? getRestaurantById(String id) {
//     try {
//       return _restaurants.firstWhere((restaurant) => restaurant.id == id);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   // Filter restaurants locally
//   List<Restaurant> filterRestaurants({
//     String? cuisine,
//     String? priceRange,
//     String? city,
//     String? searchQuery,
//   }) {
//     List<Restaurant> filtered = List.from(_restaurants);
//
//     if (cuisine != null && cuisine != 'All') {
//       filtered = filtered
//           .where(
//             (r) => r.cuisine!.toLowerCase().contains(cuisine.toLowerCase()),
//           )
//           .toList();
//     }
//
//     if (priceRange != null && priceRange != 'All') {
//       filtered = filtered
//           .where(
//             (r) =>
//                 r.priceRange!.toLowerCase().contains(priceRange.toLowerCase()),
//           )
//           .toList();
//     }
//
//     if (city != null && city.isNotEmpty) {
//       filtered = filtered
//           .where((r) => r.address.toLowerCase().contains(city.toLowerCase()))
//           .toList();
//     }
//
//     if (searchQuery != null && searchQuery.isNotEmpty) {
//       filtered = filtered
//           .where(
//             (r) =>
//                 r.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
//                 r.address.toLowerCase().contains(searchQuery.toLowerCase()) ||
//                 r.cuisine!.toLowerCase().contains(searchQuery.toLowerCase()),
//           )
//           .toList();
//     }
//
//     return filtered;
//   }
//
//   // Force refresh data
//   Future<void> refreshRestaurants({
//     String? cuisine,
//     String? priceRange,
//     double? latitude,
//     double? longitude,
//     double? radiusKm,
//     String? city,
//   }) async {
//     _restaurants.clear();
//     await fetchAllRestaurants(
//       cuisine: cuisine,
//       priceRange: priceRange,
//       latitude: latitude,
//       longitude: longitude,
//       radiusKm: radiusKm,
//       city: city,
//     );
//   }
// }
//
// // 2. Updated RestaurantDetailScreen that uses cached data
// class RestaurantDetailScreen extends StatefulWidget {
//   final String restaurantId;
//   final Restaurant? restaurant; // Optional: pass restaurant directly
//
//   const RestaurantDetailScreen({
//     super.key,
//     required this.restaurantId,
//     this.restaurant,
//   });
//
//   @override
//   State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
// }
//
// class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
//   Restaurant? _restaurant;
//   bool _isFavorite = false;
//   bool _isLoadingFavorite = true;
//   bool _isLoading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadRestaurant();
//     _checkFavoriteStatus();
//   }
//
//   Future<void> _loadRestaurant() async {
//     if (widget.restaurant != null) {
//       // Restaurant passed directly
//       setState(() {
//         _restaurant = widget.restaurant;
//         _isLoading = false;
//       });
//       return;
//     }
//
//     // Try to get from provider first
//     final provider = context.read<RestaurantProvider>();
//     final cachedRestaurant = provider.getRestaurantById(widget.restaurantId);
//
//     if (cachedRestaurant != null) {
//       setState(() {
//         _restaurant = cachedRestaurant;
//         _isLoading = false;
//       });
//     } else {
//       // If not in cache, fetch all restaurants first
//       try {
//         await provider.fetchAllRestaurants();
//         final restaurant = provider.getRestaurantById(widget.restaurantId);
//
//         if (restaurant != null) {
//           setState(() {
//             _restaurant = restaurant;
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _error = 'Restaurant not found';
//             _isLoading = false;
//           });
//         }
//       } catch (e) {
//         setState(() {
//           _error = e.toString();
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   // Rest of your existing methods remain the same...
//   Future<void> _checkFavoriteStatus() async {
//     final isFav = await FavoritesScreen.isFavorite(widget.restaurantId);
//     if (mounted) {
//       setState(() {
//         _isFavorite = isFav;
//         _isLoadingFavorite = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//
//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Error')),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error, size: 64, color: Colors.red),
//               const SizedBox(height: 16),
//               Text('Error: $_error'),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Go Back'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     if (_restaurant == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Restaurant Not Found')),
//         body: const Center(child: Text('Restaurant not found')),
//       );
//     }
//
//     // Use your existing build method with _restaurant instead of snapshot.data
//     final restaurant = _restaurant!;
//
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // Your existing SliverAppBar and content...
//           // Replace all instances of `snapshot.data!` with `restaurant`
//         ],
//       ),
//     );
//   }
// }
//
// // 3. Updated way to navigate to restaurant details
// class RestaurantListWidget extends StatelessWidget {
//   final List<Restaurant> restaurants;
//
//   const RestaurantListWidget({super.key, required this.restaurants});
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: restaurants.length,
//       itemBuilder: (context, index) {
//         final restaurant = restaurants[index];
//
//         return ListTile(
//           title: Text(restaurant.name),
//           subtitle: Text(restaurant.address),
//           onTap: () {
//             // Method 1: Pass restaurant directly (recommended)
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => RestaurantDetailScreen(
//                   restaurantId: restaurant.id,
//                   restaurant: restaurant, // Pass the full object
//                 ),
//               ),
//             );
//
//             // Method 2: Just pass ID (will get from cache)
//             // Navigator.push(
//             //   context,
//             //   MaterialPageRoute(
//             //     builder: (context) => RestaurantDetailScreen(
//             //       restaurantId: restaurant.id,
//             //     ),
//             //   ),
//             // );
//           },
//         );
//       },
//     );
//   }
// }
//
// // 4. How to use in your main app
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => RestaurantProvider(),
//       child: MaterialApp(home: RestaurantListScreen()),
//     );
//   }
// }
//
// class RestaurantListScreen extends StatefulWidget {
//   @override
//   _RestaurantListScreenState createState() => _RestaurantListScreenState();
// }
//
// class _RestaurantListScreenState extends State<RestaurantListScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Fetch all restaurants when the app starts
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<RestaurantProvider>().fetchAllRestaurants();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Restaurants')),
//       body: Consumer<RestaurantProvider>(
//         builder: (context, provider, child) {
//           if (provider.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (provider.error != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Error: ${provider.error}'),
//                   ElevatedButton(
//                     onPressed: () => provider.refreshRestaurants(),
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           return RestaurantListWidget(restaurants: provider.restaurants);
//         },
//       ),
//     );
//   }
// }

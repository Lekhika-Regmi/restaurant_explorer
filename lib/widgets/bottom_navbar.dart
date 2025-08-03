import 'package:flutter/material.dart';
import 'package:restaurant_explorer_nepal/screens/account/account_screen.dart';
import 'package:restaurant_explorer_nepal/screens/explore/explore_screen.dart';
import 'package:restaurant_explorer_nepal/screens/favorites/favorites_screen.dart';
import 'package:restaurant_explorer_nepal/screens/maps/map_screen.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _currentIndex = 0;

  // Create screens only once and reuse them
  late final List<Widget> _screens;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize screens once
    _screens = [
      const ExploreScreen(),
      const FavoritesScreen(),
      const AccountScreen(),
      const MapScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        shadowColor: Colors.black54,
        shape: const CircularNotchedRectangle(),
        color: Colors.black87,
        notchMargin: 8.0,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: "Explore",
                isSelected: _currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _NavItem(
                icon: Icons.favorite_border,
                selectedIcon: Icons.favorite,
                label: "Favorites",
                isSelected: _currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: "Account",
                isSelected: _currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              const SizedBox(width: 50), // spacing for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: _currentIndex == 3
              ? const Color(0xFFFFF290)
              : Colors.black87,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(
            _currentIndex == 3 ? Icons.map : Icons.map_outlined,
            color: _currentIndex == 3
                ? Colors.black87
                : const Color(0xFFFFF290),
            size: 28,
          ),
          onPressed: () => _onItemTapped(3),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFFFFF290) : Colors.white70;
    final iconData = isSelected && selectedIcon != null ? selectedIcon! : icon;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(iconData, color: color, size: isSelected ? 28 : 24),
            ),
            // const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:therapist_app/routes/app_routing.dart';
import 'package:therapist_app/utils/color_constants/color_constants.dart';

class CustomBottomNavigation extends StatefulWidget {
  final Widget child; // 👈 Add this

  const CustomBottomNavigation({super.key, required this.child});

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
  int _currentIndex = 0;

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics_outlined),
      activeIcon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Community',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  final List<AppRouteEnum> _routes = [
    AppRouteEnum.homeScreen,
    AppRouteEnum.analyticsScreen,
    AppRouteEnum.communityScreen,
    AppRouteEnum.profileScreen,
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.go(_routes[index].path); // ✅ navigation via GoRouter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child, // 👈 render current active screen
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: ColorConstants.colorBlack12,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: ColorConstants.primaryBrownColor,
          unselectedItemColor: ColorConstants.color999999,
          backgroundColor: ColorConstants.whiteColor,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          items: _navItems,
        ),
      ),
    );
  }
}

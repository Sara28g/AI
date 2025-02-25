import 'package:flutter/material.dart';
import 'package:projectaig/views/HelpMap.dart';
import 'package:projectaig/views/HomePage.dart';
import 'package:projectaig/views/folderspage.dart';
import 'package:projectaig/views/recordings_page.dart';
import 'main_page.dart';

// Main widget that handles navigation and layout
class NavigationLayout extends StatefulWidget {
  const NavigationLayout({super.key});

  @override
  State<NavigationLayout> createState() => _NavigationLayoutState();
}

class _NavigationLayoutState extends State<NavigationLayout> {
  // Track which tab is currently selected
  String activeTab = 'home';
  String previousTab = 'home'; // Track previous tab for returning from medicine

  // App colors - defined here for easy access and modification
  final Color lightperiwinkle = const Color(0xFFBBA5E3);
  final Color lightLavender = const Color(0xFFD8BDDB);
  final Color mediumPurple = const Color(0xFF7D66B8);
  final Color vibrantPink = const Color(0xFFB40085);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main app background
      backgroundColor: lightperiwinkle.withOpacity(0.3),

      // Side menu (drawer)
      endDrawer: _buildDrawer(),

      // Main app content
      body: Stack(
        children: [
          // Main content that doesn't extend behind the nav bar
          Positioned.fill(
            bottom: 65, // Height of the nav bar to avoid overlap
            child: _buildMainContent(),
          ),

          // Bottom nav bar at the bottom z-index
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  // Build the side menu
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer header
          Container(
            height: 100,
            color: lightperiwinkle,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDrawerItem(
            Icons.add_circle_outline,
            'Add Device',
                () {
              print('Add Device tapped');
            },
          ),
          _buildDrawerItem(
            Icons.people_outline,
            'Add Contacts',
                () {
              print('Add Contacts tapped');
            },
          ),
          _buildDrawerItem(
            Icons.phone_outlined,
            'Edit Abuser Phone Number',
                () {
              print('Edit Abuser Phone Number tapped');
            },
          ),
          _buildDrawerItem(
            Icons.mic_none_outlined,
            'Edit Voice',
                () {
              print('Edit Voice tapped');
            },
          ),
          if (activeTab == 'medicine')
            _buildDrawerItem(
              Icons.arrow_back,
              'Return to Home',
                  () {
                setState(() {
                  activeTab = previousTab;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Only show the menu button on home screen, not on folders or medicine screens
        if (activeTab == 'home')
          Container(
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(top: 40, right: 16),
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_open, color: mediumPurple, size: 30),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
        // Page content in center
        Expanded(
          child: Center(
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  // Build the content for each tab
  Widget _buildContent() {
    // Show different content based on active tab
    switch (activeTab) {
      case 'home':
        return Homepage();
      case 'folders':
        return MainPagem();
      case 'medicine':
      // Pass a callback to HelpMapScreen to allow navigation
        return HelpMapScreen(
          onNavigate: (String tab) {
            setState(() {
              activeTab = tab;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Build the bottom navigation bar with FAB style buttons
  Widget _buildBottomNavBar() {
    return Container(
      height: 85, // Taller container to accommodate raised buttons
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The nav bar background
          Container(
            height: 65.0,
            decoration: BoxDecoration(
              color: mediumPurple,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),

          // The floating buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFloatingNavButton('folders', Icons.folder_outlined, Icons.folder, 'Folders'),
              _buildFloatingNavButton('home', Icons.home_outlined, Icons.home, 'Home'),
              _buildFloatingNavButton('medicine', Icons.medical_services_outlined, Icons.medical_services, 'Medicine'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavButton(String tab, IconData outlinedIcon, IconData filledIcon, String label) {
    bool isActive = activeTab == tab;

    return InkWell(
      onTap: () {
        setState(() {
          if (tab == 'medicine' && activeTab != 'medicine') {
            previousTab = activeTab;
          }
          activeTab = tab;
        });
      },
      splashFactory: NoSplash.splashFactory, // No splash effect
      highlightColor: Colors.transparent, // No highlight color
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 50,
        height: 50,
        transform: Matrix4.translationValues(0, isActive ? -20 : 0, 0),
        decoration: BoxDecoration(
          color: isActive ? lightperiwinkle : mediumPurple,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          isActive ? filledIcon : outlinedIcon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Build a menu item for the drawer
  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTapAction) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      leading: Icon(
        icon,
        color: mediumPurple,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: mediumPurple,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTapAction();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: lightLavender,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:projectaig/views/HelpMap.dart';
import 'package:projectaig/views/HomePage.dart';
import 'package:projectaig/views/folderspage.dart';


void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFFBBA5E3),
        scaffoldBackgroundColor: const Color(0xFFD8BDDB).withOpacity(0.3),
      ),
      home: const NavigationLayout(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

// Main widget that handles navigation and layout
class NavigationLayout extends StatefulWidget {
  const NavigationLayout({super.key});

  @override
  State<NavigationLayout> createState() => _NavigationLayoutState();

}

class _NavigationLayoutState extends State<NavigationLayout> {
  // Track which tab is currently selected
  String activeTab = 'home';

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
          _buildMainContent(),
          _buildBottomNavBar(),
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
        ],

      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80), // Space for bottom nav
      child: Column(
        children: [
          if (activeTab != 'medicine')
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, right: 16),
                child: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_open, color: lightperiwinkle, size: 30),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
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
      ),
    );
  }

  // Build the content for each tab
  Widget _buildContent() {
    final style = TextStyle(
      color: lightperiwinkle,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    // Show different content based on active tab
    switch (activeTab) {
      case 'home':
        return Homepage();
      case 'folders':
        return Folderspage();
      case 'medicine':
        return HelpMapScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // Build the bottom navigation bar
  Widget _buildBottomNavBar() {
    if (activeTab == 'medicine')
      return SizedBox.shrink();

      return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: lightperiwinkle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton('home', Icons.home_outlined, Icons.home, 'Home'),
            _buildNavButton('folders', Icons.folder_outlined, Icons.folder, 'Folders'),
            _buildNavButton('medicine', Icons.medical_services_outlined, Icons.medical_services, 'Medicine'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String tab, IconData outlinedIcon, IconData filledIcon, String label) {
    bool isActive = activeTab == tab;



      return GestureDetector(
      onTap: () {
        setState(() => activeTab = tab);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? mediumPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filledIcon : outlinedIcon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a menu item for the drawer
  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTapAction) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(
        icon,
        color: lightperiwinkle,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: lightperiwinkle,
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
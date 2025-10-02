import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_check/pages/homefolder/notificationScreen.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Slight shadow for better appearance
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).pop(), // Close menu
        ),
        title: Text(
          'MENU',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _menuItem(
              title: 'Notifications',
              icon: Icons.notifications,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            // Add more menu items as needed
          ],
        ),
      ),
    );
  }

  // Menu Item Widget
  Widget _menuItem({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF419C9C).withOpacity(0.6),
        ),
        child: ListTile(
          leading: Icon(icon, size: 28, color: Colors.black),
          title: Text(
            title,
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.black),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
        ),
      ),
    );
  }
}

// Notifications Page

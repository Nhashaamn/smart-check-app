import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_check/pages/homefolder/TeamManagementPage.dart';
import 'package:smart_check/pages/homefolder/setting%20folder/SupportChatPage.dart';
import 'package:smart_check/pages/homefolder/setting%20folder/account_handler.dart';
import 'package:smart_check/pages/handleUser/delete_user.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            _SettingsItem(
              title: "Help",
              icon: Icons.help,
              onTap: () {
                // Placeholder for Help action
                Get.snackbar('Help', 'Help feature coming soon!',
                    backgroundColor: const Color(0xFF2D6F6F), colorText: Colors.white);
              },
            ),
            const SizedBox(height: 10),
            _SettingsItem(
              title: "Account",
              icon: Icons.account_box,
              onTap: () => Get.to(() => const Account()),
            ),
            const SizedBox(height: 10),
            _SettingsItem(
              title: "Team Management",
              icon: Icons.group,
              onTap: () => Get.to(() => const TeamManagementPage()),
            ),
            const SizedBox(height: 20),
            Text(
              'Account Actions',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            _SettingsItem(
              title: "Logout",
              icon: Icons.logout,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            _SettingsItem(
              title: "Delete Account",
              icon: Icons.delete,
              onTap: () => Get.to(() => const DeletePage()),
              isDestructive: true,
            ),
             const SizedBox(height: 10),
            _SettingsItem(
  title: "Chat with Support",
  icon: Icons.support_agent,
  onTap: () => Get.to(() => const SupportChatPage()),
),

          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDestructive
                ? [Colors.redAccent, Colors.red]
                : [const Color(0xFF419C9C), const Color(0xFF2D6F6F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
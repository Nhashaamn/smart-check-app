import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart'; // Added for sharing
import 'package:smart_check/pages/homefolder/homepage.dart';
import 'package:smart_check/teamController.dart'; // Import your controller

class Invitepage extends StatefulWidget {
  const Invitepage({super.key});

  @override
  State<Invitepage> createState() => _InvitepageState();
}

class _InvitepageState extends State<Invitepage> {
  final TeamController teamController = Get.find(); // Access the TeamController

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Lighter background for better contrast
      appBar: AppBar(
        backgroundColor: const Color(0xFF419C9C),
        title: const Text(
          'Invite Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Change icon color to white
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text(
                  "Invite members to the Team Circle",
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Share your code out loud or send it in a message",
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF959595),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 70),
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF419C9C).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Dynamically display the team code
                      Obx(() => Text(
                            teamController.selectedTeamCode.isEmpty
                                ? "No Code"
                                : teamController.selectedTeamCode.value,
                            style: const TextStyle(
                              fontSize: 48,
                              color: Color(0xFF419C9C),
                            ),
                          )),
                      const SizedBox(height: 20),
                      const Text(
                        "The code will be active for 2 days",
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF626262),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          // Share the code with a message and optional link
                          final code = teamController.selectedTeamCode.value;
                          final shareText =
                              "Join my Team Circle! Use this code: $code\nDownload the app: https://yourapp.link"; // Replace with your app link
                          Share.share(shareText);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF419C9C),
                          padding: const EdgeInsets.symmetric(
                            vertical: 30,
                            horizontal: 50,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Send code",
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Get.to(const Homepage());
                  },
                  child: const Text(
                    "done",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
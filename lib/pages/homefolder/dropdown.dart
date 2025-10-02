import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_check/pages/create_team.dart';
import 'package:smart_check/pages/invitepage.dart';
import 'package:smart_check/pages/jointeam.dart';
import 'package:smart_check/teamController.dart';

class Dropdown extends StatefulWidget {
  const Dropdown({super.key});

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final TeamController teamController;
  String? selectedTeamName;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<TeamController>()) {
      teamController = Get.put(TeamController());
    } else {
      teamController = Get.find<TeamController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .where('createdBy', isEqualTo: currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                bool hasTeams = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 260,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
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
                      ),
                      child: Center(
                        child: Obx(() => Text(
                              hasTeams
                                  ? (teamController.selectedTeamName.value != 'Select Team'
                                      ? teamController.selectedTeamName.value
                                      : "Select Team")
                                  : "Create Team",
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      ),
                    ),
                    const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () => Get.to(() => const Invitepage()),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF419C9C),
                        ),
                        child: const Icon(Icons.person_add, size: 24, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .where('createdBy', isEqualTo: currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF419C9C)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No teams created yet.",
                      style: GoogleFonts.roboto(fontSize: 16, color: Colors.white70),
                    ),
                  );
                }

                final teams = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index].data() as Map<String, dynamic>;
                    final teamName = team['teamName'] ?? "Unnamed Team";
                    final teamCode = team['teamCode'] ?? "No Code";
                    final teamId = team['teamId'] ?? "";
                    return Obx(() {
                      bool isSelected = teamName == teamController.selectedTeamName.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedTeamName = teamName);
                          teamController.updateTeam(teamName, teamCode, teamId);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF419C9C).withOpacity(0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              teamName,
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  },
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF419C9C), width: 1)),
            ),
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => const Createteam()),
                  child: Container(
                    width: 150,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Create Team",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const JoinTeam()),
                  child: Container(
                    width: 150,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Join Team",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_check/form%20controller.dart';
import 'package:smart_check/pages/homefolder/MyTaskPage.dart';
import 'package:smart_check/pages/homefolder/chatScreen.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TeamsPageContent();
  }
}

class _TeamsPageContent extends StatefulWidget {
  const _TeamsPageContent();

  @override
  _TeamsPageContentState createState() => _TeamsPageContentState();
}

class _TeamsPageContentState extends State<_TeamsPageContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FormController teamController = Get.put(FormController());

  String? currentUserUid;

  @override
  void initState() {
    super.initState();
    _getCurrentUserUid();
  }

  void _getCurrentUserUid() {
    currentUserUid = _auth.currentUser?.uid;
    if (currentUserUid == null) {
      print('No authenticated user found');
    } else {
      print('Current user UID: $currentUserUid');
    }
  }

  Stream<List<Map<String, String>>> _fetchUserTeamsStream() {
    if (currentUserUid == null) {
      print('User UID is null, returning empty stream');
      return Stream.value([]);
    }

    return _firestore.collection('teams').snapshots().asyncMap((teamsSnapshot) async {
      List<Map<String, String>> teams = [];

      for (var team in teamsSnapshot.docs) {
        print('Checking team: ${team.id}');
        final memberDoc = await team.reference
            .collection('members')
            .doc(currentUserUid)
            .get();

        if (memberDoc.exists) {
          final teamName = team.data()['teamName'] as String? ?? 'Unknown Team';
          final createdBy = team.data()['createdBy'] as String? ?? 'Unknown Admin';
          final teamId = team.id;
          teams.add({
            'teamId': teamId,
            'teamName': teamName,
            'createdBy': createdBy,
          });
          print('Found team: $teamName, Admin: $createdBy');
        } else {
          print('User not found in team: ${team.id}');
        }
      }

      print('Fetched teams: $teams');
      return teams;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121E1E), // Darker background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF419C9C), const Color(0xFF2D6F6F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF419C9C).withOpacity(0.2),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Teams',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF419C9C).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121E1E), Color(0xFF1A2A2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 16),
              child: Text(
                'Your Team Spaces',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, String>>>(
                stream: _fetchUserTeamsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF419C9C),
                            backgroundColor: Color(0xFF263535),
                            strokeWidth: 6,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Loading your teams...',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    print('Error in StreamBuilder: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: const Color(0xFF419C9C).withOpacity(0.7),
                            size: 50,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading teams',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your connection and try again',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final userTeams = snapshot.data ?? [];

                  if (userTeams.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_rounded,
                            color: const Color(0xFF419C9C).withOpacity(0.5),
                            size: 60,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Teams Found',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'You are not part of any team yet. Create a new team or ask to join one.',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: userTeams.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final team = userTeams[index];
                      final teamName = team['teamName'] ?? 'Unknown Team';
                      final teamId = team['teamId'] ?? 'Unknown ID';
                      final adminId = team['createdBy'] ?? 'Unknown Admin';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1E2E2E),
                              const Color(0xFF1A2A2A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              print('Selected team: $teamName, Team ID: $teamId, Admin ID: $adminId');
                              teamController.updateTeam(
                                teamName,
                                teamId,
                                adminId,
                              );
                              print('Updated FormController - TeamName: ${teamController.teamName.value}, TeamId: ${teamController.teamId.value}, AdminId: ${teamController.adminId.value}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyTaskPage(
                                    teamName: teamName,
                                    teamId: teamId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF419C9C).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF419C9C).withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.group_rounded,
                                      color: const Color(0xFF419C9C),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          teamName,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Team ID: ${teamId.substring(0, 6)}...',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF419C9C).withOpacity(0.1),
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: Color(0xFF419C9C),
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: () async {
                                      String adminName = 'Admin';
                                      try {
                                        final adminDoc = await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(adminId)
                                            .get();
                                        if (adminDoc.exists) {
                                          adminName = adminDoc.data()?['name'] ?? 'Admin';
                                        }
                                      } catch (e) {
                                        print('Error fetching admin name: $e');
                                      }

                                      print('TeamsPage: Navigating to ChatScreen with teamId: $teamId, adminUid: $adminId, memberUid: ${_auth.currentUser!.uid}');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            teamId: teamId,
                                            teamName: teamName,
                                            adminUid: adminId,
                                            memberUid: _auth.currentUser!.uid,
                                            memberName: adminName,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}
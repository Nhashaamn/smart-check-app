import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_check/components/oval.dart';
import 'package:smart_check/pages/homefolder/Teams.dart';
import 'package:smart_check/pages/homefolder/assigntask.dart';
import 'package:smart_check/pages/homefolder/chatScreen.dart';
import 'package:smart_check/pages/invitepage.dart';
import 'package:smart_check/teamController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainContainer extends StatefulWidget {
  final double maxHeight;

  const MainContainer({super.key, required this.maxHeight});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  final double _minHeight = 200;
  final ValueNotifier<double> _bottomContainerHeight = ValueNotifier(200);
  final TeamController _teamController = Get.find<TeamController>();
  String? _teamId;
  List<Map<String, dynamic>> _cachedMembers = [];
  final Map<String, String?> _profileImageCache = {};

  @override
  void initState() {
    super.initState();
    _teamController.selectedTeamCode.listen((teamCode) {
      _fetchTeamId(teamCode);
      _fetchTeamMembers(teamCode);
    });
    _fetchTeamId(_teamController.selectedTeamCode.value);
    _fetchTeamMembers(_teamController.selectedTeamCode.value);
  }

  Future<void> _fetchTeamId(String teamCode) async {
    if (teamCode.isEmpty) {
      setState(() => _teamId = null);
      return;
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('teamCode', isEqualTo: teamCode)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() => _teamId = querySnapshot.docs.first.id);
      } else {
        setState(() => _teamId = null);
      }
    } catch (e) {
      setState(() => _teamId = null);
      Get.snackbar('Error', 'Failed to fetch team ID.',
          backgroundColor: const Color(0xFF2D6F6F), colorText: Colors.white);
    }
  }

  Future<void> _fetchTeamMembers(String teamCode) async {
    if (teamCode.isEmpty) {
      setState(() => _cachedMembers = []);
      return;
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('teamCode', isEqualTo: teamCode)
          .get();
      if (querySnapshot.docs.isEmpty) {
        setState(() => _cachedMembers = []);
        return;
      }
      final teamDoc = querySnapshot.docs.first;
      final membersSnapshot = await teamDoc.reference.collection('members').get();
      final members = membersSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      for (var member in members) {
        final email = member['email'] ?? '';
        if (email.isNotEmpty && !_profileImageCache.containsKey(email)) {
          final profileImageUrl = await _fetchProfileImageUrl(email);
          _profileImageCache[email] = profileImageUrl;
        }
      }
      setState(() => _cachedMembers = members);
    } catch (e) {
      setState(() => _cachedMembers = []);
      Get.snackbar('Error', 'Failed to fetch team members: $e',
          backgroundColor: const Color(0xFF2D6F6F), colorText: Colors.white);
    }
  }

  Future<String?> _fetchProfileImageUrl(String email) async {
    if (email.isEmpty) return null;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['profileImageUrl'] as String?;
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch profile image: $e',
          backgroundColor: const Color(0xFF2D6F6F), colorText: Colors.white);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          _bottomContainerHeight.value -= details.delta.dy;
          if (_bottomContainerHeight.value < _minHeight) {
            _bottomContainerHeight.value = _minHeight;
          } else if (_bottomContainerHeight.value > widget.maxHeight) {
            _bottomContainerHeight.value = widget.maxHeight;
          }
        },
        child: ValueListenableBuilder<double>(
          valueListenable: _bottomContainerHeight,
          builder: (context, height, child) {
            return Obx(() => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: height,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF263535),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white54,
                          ),
                          height: 6,
                          width: 40,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Oval(
                                      icon: Icons.person,
                                      width: 100,
                                      iconColor: const Color(0xFF419C9C),
                                      onTap: () => Get.to(() => const Invitepage()),
                                    ),
                                    Oval(
                                      icon: Icons.task,
                                      width: 100,
                                      iconColor: const Color(0xFF419C9C),
                                      onTap: _teamController.selectedTeamName.value == 'Select Team'
                                          ? null
                                          : () => Get.to(() => const AssignTask()),
                                    ),
                                    Oval(
                                      icon: Icons.group,
                                      width: 100,
                                      iconColor: const Color(0xFF419C9C),
                                      onTap: () => Get.to(() =>  TeamsPage()),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "People in ${_teamController.selectedTeamName.value}",
                                  style: GoogleFonts.roboto(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_cachedMembers.isEmpty)
                                  Text(
                                    "No members found.",
                                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.white70),
                                  )
                                else
                                  ListView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: _cachedMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = _cachedMembers[index];
                                      return _person(
                                        member['email'] ?? '',
                                        member['name'] ?? 'Unknown',
                                        member['email'] ?? '',
                                        member['uid'] ?? '',
                                        false,
                                      );
                                    },
                                  ),
                                GestureDetector(
                                  onTap: () => Get.to(() => const Invitepage()),
                                  child: _person('', "Add Person", "", "", true),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: GestureDetector(
                                    onTap: _teamController.selectedTeamName.value == 'Select Team'
                                        ? null
                                        : () => Get.to(() => const AssignTask()),
                                    child: Container(
                                      width: 200,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _teamController.selectedTeamName.value == 'Select Team'
                                              ? [Colors.grey, Colors.grey]
                                              : [const Color(0xFF419C9C), const Color(0xFF2D6F6F)],
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
                                          "Assign Task",
                                          style: GoogleFonts.roboto(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ));
          },
        ),
      ),
    );
  }

  Widget _person(String email, String name, String location, String memberUid, bool isAddPerson) {
    final profileImageUrl = _profileImageCache[email] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2D6F6F).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF419C9C),
              backgroundImage: profileImageUrl.isNotEmpty ? CachedNetworkImageProvider(profileImageUrl) : null,
              child: profileImageUrl.isEmpty
                  ? Icon(
                      isAddPerson ? Icons.person_add : Icons.person,
                      size: 30,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    location,
                    style: GoogleFonts.roboto(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (!isAddPerson)
              IconButton(
                icon: const Icon(Icons.message, color: Color(0xFF419C9C)),
                onPressed: () {
                  if (_teamId == null) {
                    Get.snackbar('Error', 'Team ID not found.',
                        backgroundColor: const Color(0xFF2D6F6F), colorText: Colors.white);
                    return;
                  }
                  final adminUid = FirebaseAuth.instance.currentUser!.uid;
                  Get.to(() => ChatScreen(
                        teamId: _teamId!,
                        teamName: _teamController.selectedTeamName.value,
                        adminUid: adminUid,
                        memberUid: memberUid,
                        memberName: name,
                      ));
                },
              ),
          ],
        ),
      ),
    );
  }
}
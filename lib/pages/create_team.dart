import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_check/components/textfeild.dart';
import 'package:smart_check/database/add%20user.dart';
import 'package:smart_check/pages/invitepage.dart';
import 'package:smart_check/teamController.dart';

class Createteam extends StatelessWidget {
  const Createteam({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CreateteamContent();
  }
}

class _CreateteamContent extends StatefulWidget {
  const _CreateteamContent();

  @override
  State<_CreateteamContent> createState() => _CreateteamContentState();
}

class _CreateteamContentState extends State<_CreateteamContent> {
  TextEditingController teamnameController = TextEditingController();
  final db = FirebaseFirestore.instance;
  final TeamController teamController = Get.find();
  String? userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserId();
  }

  Future<String> generateUniqueTeamCode() async {
    String code;
    bool exists;
    do {
      code = generateTeamCode();
      final query = await FirebaseFirestore.instance
          .collection('teams')
          .where('teamCode', isEqualTo: code)
          .get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  Future<void> fetchCurrentUserId() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          userId = currentUser.uid;
        });
      } else {
        Get.snackbar(
          "Error",
          "User not authenticated",
          backgroundColor: const Color(0xFF2D6F6F),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to fetch user ID: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> createTeam() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (teamnameController.text.isEmpty) {
        throw Exception("Please enter a team name");
      }

      final teamCode = await generateUniqueTeamCode();
      final teamName = teamnameController.text;

      final DocumentReference teamRef = await db.collection('teams').add({
        'teamName': teamName,
        'createdBy': userId ?? 'Unknown',
        'teamCode': teamCode,
      });

      final teamID = teamRef.id;
      await teamRef.update({'teamId': teamID});

      teamController.updateTeam(teamName, teamCode, teamID);

      await gotoInvitepage();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to create team: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> gotoInvitepage() async {
    try {
      await Get.to(() => const Invitepage());
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to navigate to Invitepage: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

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
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        title: Text(
          'Create Team',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A2A2A),
              const Color(0xFF263535).withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/Team.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Choose the name of\nyour team",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1A2A2A),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFieldCustom(
                      Controller: teamnameController,
                      obscureText: false,
                      textStyle: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : createTeam,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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
                            BoxShadow(
                              color: const Color(0xFF419C9C).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Create Team',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
      ),
    );
  }

  @override
  void dispose() {
    teamnameController.dispose();
    super.dispose();
  }
}
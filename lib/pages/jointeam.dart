import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_check/pages/homefolder/homepage.dart';
import 'package:lottie/lottie.dart';

class JoinTeam extends StatelessWidget {
  const JoinTeam({super.key});

  @override
  Widget build(BuildContext context) {
    return const _JoinTeamContent();
  }
}

class _JoinTeamContent extends StatefulWidget {
  const _JoinTeamContent();

  @override
  State<_JoinTeamContent> createState() => _JoinTeamContentState();
}

class _JoinTeamContentState extends State<_JoinTeamContent> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void dispose() {
    _pinController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _joinTeam(String enteredCode) async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");

      final querySnapshot = await firestore
          .collection('teams')
          .where('teamCode', isEqualTo: enteredCode)
          .get();

      if (querySnapshot.docs.isEmpty) throw Exception("Invalid invite code");

      final teamDoc = querySnapshot.docs.first;
      final teamId = teamDoc.id;
      final adminId = teamDoc.data()['createdBy'];

      final memberDoc = await firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(currentUser.uid)
          .get();

      if (memberDoc.exists) throw Exception("You are already a member of this team.");

      final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) throw Exception("User data not found");

      final userName = userDoc.data()?['name'] ?? "Unknown User";
      final userEmail = currentUser.email ?? "Unknown Email";

      if (!await _requestLocationPermission()) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      await firestore.collection('teams').doc(teamId).collection('members').doc(currentUser.uid).set({
        'name': userName,
        'email': userEmail,
        'joinedAt': FieldValue.serverTimestamp(),
        'uid': currentUser.uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await firestore.collection('users').doc(adminId).collection('notifications').add({
        'message': "$userName has joined your team with code $enteredCode.",
        'userId': currentUser.uid,
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': "join",
        'teamId': teamId,
      });

      await firestore.collection('teams').doc(teamId).collection('notifications').add({
        'message': "$userName has joined the team.",
        'userId': currentUser.uid,
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': "join",
      });

      _startLocationUpdates(teamId);

      Get.snackbar(
        "Success",
        "You have joined the team successfully!",
        backgroundColor: const Color(0xFF2D6F6F),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      Get.off(const Homepage());
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          "Permission Denied",
          "Location permission is required.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.defaultDialog(
        title: "Permission Required",
        titleStyle: GoogleFonts.roboto(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        middleText: "Enable location permission in settings.",
        middleTextStyle: GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
        backgroundColor: const Color(0xFF263535),
        radius: 12,
        textConfirm: "Go to Settings",
        confirmTextColor: Colors.white,
        buttonColor: const Color(0xFF419C9C),
        textCancel: "Cancel",
        cancelTextColor: Colors.white70,
        onConfirm: () async {
          await Geolocator.openAppSettings();
          Get.back();
        },
      );
      return false;
    }
    return true;
  }

  void _startLocationUpdates(String teamId) {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) async {
        try {
          await firestore
              .collection('teams')
              .doc(teamId)
              .collection('members')
              .doc(currentUser.uid)
              .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print("Error updating location: $e");
        }
      },
      onError: (error) {
        print("Location stream error: $error");
        Get.snackbar(
          "Location Error",
          "Failed to update location: $error",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      },
    );
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
          'Join Team',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
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
                    'assets/animations/join.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Enter the invite code",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: PinCodeTextField(
                      controller: _pinController,
                      appContext: context,
                      length: 6,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        fieldHeight: 50,
                        fieldWidth: 40,
                        borderRadius: BorderRadius.circular(12),
                        activeFillColor: const Color(0xFF263535),
                        inactiveFillColor: const Color(0xFF263535),
                        selectedFillColor: const Color(0xFF419C9C).withOpacity(0.6),
                        activeColor: Colors.white.withOpacity(0.1),
                        inactiveColor: Colors.white.withOpacity(0.1),
                        selectedColor: Colors.white.withOpacity(0.1),
                        borderWidth: 1,
                      ),
                      enableActiveFill: true,
                      textStyle: GoogleFonts.roboto(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Get the code from the person\nsetting up your team's circle",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            final enteredCode = _pinController.text.trim();
                            if (enteredCode.isNotEmpty) {
                              _joinTeam(enteredCode);
                            } else {
                              Get.snackbar(
                                "Error",
                                "Please enter a team code.",
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                borderRadius: 12,
                                margin: const EdgeInsets.all(16),
                              );
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF419C9C)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
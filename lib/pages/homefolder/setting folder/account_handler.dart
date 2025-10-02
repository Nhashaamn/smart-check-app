import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smart_check/pages/homefolder/setting%20folder/utils.dart';
import 'dart:convert';

class Account extends StatelessWidget {
  const Account({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccountContent();
  }
}

class _AccountContent extends StatefulWidget {
  const _AccountContent();

  @override
  State<_AccountContent> createState() => _AccountContentState();
}

class _AccountContentState extends State<_AccountContent> {
  Uint8List? _selectedImage;
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }
      final String userId = user.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'No name';
          _userEmail = userDoc.data()?['email'] ?? 'No email';
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
        });
      } else {
        throw Exception('User document does not exist in Firestore');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching user data: $e';
      });
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectImage() async {
    try {
      final Uint8List? image = await pickImage(ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      print('Error selecting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error selecting image: $e',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2D6F6F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user is currently logged in');
      final String userId = user.uid;

      final url = Uri.parse('https://api.cloudinary.com/v1_1/dcvgxw0so/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'profile'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedImage!,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString) as Map<String, dynamic>;

        final imageUrl = jsonMap['secure_url'] as String;

        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profileImageUrl': imageUrl,
        });

        setState(() {
          _profileImageUrl = imageUrl;
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile image updated successfully',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2D6F6F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading image: $e';
      });
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error uploading image: $e',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
          'Account',
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
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Color(0xFF419C9C))
              : _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.roboto(
                          color: Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFF263535),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, -6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const RadialGradient(
                                            colors: [
                                              Color(0xFF419C9C),
                                              Colors.transparent,
                                            ],
                                            radius: 0.8,
                                          ),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.2),
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF419C9C).withOpacity(0.3),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 80,
                                            backgroundImage: _profileImageUrl != null
                                                ? NetworkImage(_profileImageUrl!)
                                                : _selectedImage != null
                                                    ? MemoryImage(_selectedImage!)
                                                    : const AssetImage("assets/avatar.png") as ImageProvider,
                                            backgroundColor: const Color(0xFF2D6F6F),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 5,
                                        right: 5,
                                        child: _ActionButton(
                                          icon: Icons.add_a_photo,
                                          onTap: _selectImage,
                                          color: const Color(0xFF419C9C),
                                        ),
                                      ),
                                      if (_selectedImage != null)
                                        Positioned(
                                          bottom: 5,
                                          left: 5,
                                          child: _ActionButton(
                                            icon: Icons.upload,
                                            onTap: _uploadImage,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    _userName ?? 'No Name',
                                    style: GoogleFonts.roboto(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _userEmail ?? 'No Email',
                                    style: GoogleFonts.roboto(
                                      fontSize: 20,
                                      color: Colors.white70,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
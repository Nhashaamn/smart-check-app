import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:smart_check/form%20controller.dart';
import 'package:smart_check/pages/homefolder/data/image_Upload_page.dart';

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FormController teamController = Get.find<FormController>();

  void _navigateToImageUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImageUploadPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Current FormController state - TeamName: ${teamController.teamName.value}, TeamId: ${teamController.teamId.value}, AdminId: ${teamController.adminId.value}');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF419C9C),
        title: Obx(() => Text(
              'Polio Data Collection - ${teamController.teamName.value}',
              style: const TextStyle(color: Colors.white),
            )),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Tap the + button to add new data',
          style: TextStyle(
            color: Color(0xFF419C9C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToImageUpload(context),
        backgroundColor: const Color(0xFF419C9C),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
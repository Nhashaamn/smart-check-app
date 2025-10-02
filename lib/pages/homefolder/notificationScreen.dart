import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:get/get.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF419C9C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final timestamp = notification['timestamp']?.toDate() ?? DateTime.now();
              final formattedTime = DateFormat('MMM d, yyyy hh:mm a').format(timestamp);
              final notificationType = notification['type'] ?? 'unknown';
              final message = notification['message'] ?? "No message";
              final teamId = notification['teamId'] ?? '';

              return ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFF419C9C)),
                title: Text(
                  message,
                  style: notificationType == 'remove'
                      ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                      : null,
                ),
                subtitle: Text(formattedTime),
                onTap: notificationType == 'remove'
                    ? () {
                        // Optional: Navigate to a page or show a dialog for removal details
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Team Removal'),
                            content: Text(
                              'You have been removed from the team. Team ID: $teamId. You can no longer access this team.',
                              style: const TextStyle(color: Colors.red),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
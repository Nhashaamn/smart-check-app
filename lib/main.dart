import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:smart_check/teamController.dart';
import 'package:smart_check/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_check/firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase (if you still use it for Firestore/Auth)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize OneSignal
    OneSignal.initialize("126063e3-bc2c-4f88-832f-fb49a3847589"); // <-- Replace with your real App ID
    OneSignal.Notifications.requestPermission(true); // Ask user for notification permission

    // Optional: Listen for foreground notifications
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print("Notification received in foreground: ${event.notification.title} - ${event.notification.body}");
    });

    // Optional: Handle notification click/open events
    OneSignal.Notifications.addClickListener((event) {
      print("Notification clicked: ${event.notification.title}");
      // You can add navigation logic here
    });

    Get.put(TeamController());

    

    runApp(const MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    runApp(const ErrorApp());
  }


}


class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      home: Wrapper(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize the app. Please try again later.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

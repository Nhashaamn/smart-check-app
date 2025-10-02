import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:smart_check/pages/handleUser/login_Page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> deleteUser(String email, String password) async {
  try {
    User? user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "No user is currently signed in");
      return;
    }

    // Reauthenticate user
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
    UserCredential authResult = await user.reauthenticateWithCredential(credential);

    // Delete user
    await authResult.user?.delete();
    
    // Navigate to login page and show confirmation
    Get.offAll(() =>const LoginPage());
    Get.snackbar("Success", "User account deleted successfully");

  } catch (e) {
    // Handle errors
    Get.snackbar("Error", e.toString());
  }
}




import 'package:get/get.dart';

class FormController extends GetxController {
  var teamName = ''.obs;
  var teamId = ''.obs;
  var adminId = ''.obs; // New variable to store the admin ID
  var memberName = ''.obs; // Optional, if you want to store it here

  void updateTeam(String name, String id, String admin) {
    teamName.value = name;
    teamId.value = id;
    adminId.value = admin; // Update the admin ID
  }

  void updateMemberName(String name) {
    memberName.value = name;
  }
}
import 'package:get/get.dart';

class TeamController extends GetxController {
  var selectedTeamName = 'Select Team'.obs; // Observable for team name
  var selectedTeamCode = ''.obs; // Observable for team code
  var selectedTeamID = ''.obs; // Observable for team ID

  void updateTeam(String teamName, String teamCode, String teamID) {
    selectedTeamName.value = teamName;
    selectedTeamCode.value = teamCode;
    selectedTeamID.value = teamID;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

String generateTeamCode() {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  Random random = Random();
  return String.fromCharCodes(Iterable.generate(
      6, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
}

Future<void> createTeam(String teamName, String createdBy) async {
  CollectionReference teams = FirebaseFirestore.instance.collection('teams');
  
  // Generate a unique team code
  String teamCode = generateTeamCode();

  try {
    await teams.add({
      'teamName': teamName,
      'createdBy': createdBy,
      'teamCode': teamCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Team created successfully with code: $teamCode');
  } catch (e) {
    print('Error creating team: $e');
  }
}


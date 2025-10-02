import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:smart_check/pages/homefolder/teamdetailreport.dart';

class TeamReportScreen extends StatefulWidget {
  @override
  _TeamReportScreenState createState() => _TeamReportScreenState();
}

class _TeamReportScreenState extends State<TeamReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, String>> teamsWithData = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeamsWithData();
  }

  Future<void> _fetchTeamsWithData() async {
    try {
      print('Fetching teams with data...');
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User not authenticated.';
        });
        print('Error: User not authenticated.');
        return;
      }

      final snapshot = await _firestore
          .collection('taskData')
          .where('adminId', isEqualTo: user.uid)
          .get();
      print('TaskData snapshot size: ${snapshot.docs.length}');

      final Map<String, String> uniqueTeams = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final teamName = data['teamName'] as String? ?? 'Unknown Team';
        final teamId = data['teamId'] as String? ?? 'Unknown ID';
        if (!uniqueTeams.containsKey(teamName)) {
          uniqueTeams[teamName] = teamId;
          print('Found team: $teamName, ID: $teamId');
        }
      }

      setState(() {
        teamsWithData = uniqueTeams.entries
            .map((entry) => {'teamName': entry.key, 'teamId': entry.value})
            .toList();
        isLoading = false;
        if (teamsWithData.isEmpty) {
          errorMessage = 'No teams with data found where you are the admin.';
        }
      });
      print('Fetched teams with data: $teamsWithData');
    } catch (e) {
      print('Error fetching teams with data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching teams: $e';
      });
    }
  }

  Future<void> _deleteTeamData(String teamId, String teamName) async {
    try {
      // Fetch all taskData entries for the team
      final snapshot = await _firestore
          .collection('taskData')
          .where('teamId', isEqualTo: teamId)
          .get();

      if (snapshot.docs.isEmpty) {
        Get.snackbar('Info', 'No data found to delete for team $teamName.');
        return;
      }

      // Delete each document
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('Deleted taskData document ID: ${doc.id} for team: $teamName');
      }

      // Update the UI by removing the team from the list
      setState(() {
        teamsWithData.removeWhere((team) => team['teamId'] == teamId);
        if (teamsWithData.isEmpty) {
          errorMessage = 'No teams with data found where you are the admin.';
        }
      });

      Get.snackbar('Success', 'Data for team $teamName has been deleted successfully.');
    } catch (e) {
      print('Error deleting team data: $e');
      Get.snackbar('Error', 'Failed to delete data for team $teamName: $e');
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(String teamName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete all data for the team "$teamName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF419C9C)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF419C9C),
        title: const Text(
          'Teams with Data',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF419C9C),
                ),
              )
            : teamsWithData.isEmpty
                ? Center(
                    child: Text(
                      errorMessage ?? 'No teams with data found.',
                      style: const TextStyle(
                        color: Color(0xFF419C9C),
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: teamsWithData.length,
                    itemBuilder: (context, index) {
                      final team = teamsWithData[index];
                      final teamName = team['teamName'] ?? 'Unknown Team';
                      final teamId = team['teamId'] ?? 'Unknown ID';

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.group,
                                color: Color(0xFF419C9C),
                                size: 30,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    print('Navigating to TeamDetailReportPage for team: $teamName, ID: $teamId');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TeamDetailReportPage(
                                          teamId: teamId,
                                          teamName: teamName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    teamName,
                                    style: const TextStyle(
                                      color: Color(0xFF419C9C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await _showDeleteConfirmationDialog(teamName);
                                  if (confirm == true) {
                                    await _deleteTeamData(teamId, teamName);
                                  }
                                },
                                tooltip: 'Delete team data',
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF419C9C),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
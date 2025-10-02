import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_check/pages/homefolder/TaskDetail.dart';

class MyTaskPage extends StatelessWidget {
  final String teamName;

  const MyTaskPage({Key? key, required this.teamName, required String teamId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF419C9C),
        title: Text(
          "Tasks - $teamName",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .where('teamName', isEqualTo: teamName)
            .snapshots(),
        builder: (context, teamSnapshot) {
          if (teamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF419C9C)),
            );
          }

          if (teamSnapshot.hasError) {
            return _buildErrorMessage("Failed to load team data.");
          }

          if (!teamSnapshot.hasData || teamSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState("No tasks found for this team.");
          }

          String teamDocId = teamSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('teams')
                .doc(teamDocId)
                .collection('tasks')
                .snapshots(),
            builder: (context, taskSnapshot) {
              if (taskSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF419C9C)),
                );
              }

              if (taskSnapshot.hasError) {
                return _buildErrorMessage("Failed to load tasks.");
              }

              if (!taskSnapshot.hasData || taskSnapshot.data!.docs.isEmpty) {
                return _buildEmptyState("No tasks assigned to this team yet.");
              }

              var tasks = taskSnapshot.data!.docs;

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  var task = tasks[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.task_alt, color: Color(0xFF419C9C)),
                      title: Text(
                        task['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF419C9C),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          task['description'],
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF419C9C)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailPage(
                              taskId: task.id,
                              taskData: task.data() as Map<String, dynamic>,
                              teamDocId: teamDocId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// **Helper Widget: Empty State**
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// **Helper Widget: Error Message**
  Widget _buildErrorMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

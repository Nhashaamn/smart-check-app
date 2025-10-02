import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_check/pages/homefolder/task.dart';
import 'package:smart_check/teamController.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AssignTask extends StatefulWidget {
  const AssignTask({super.key});

  @override
  State<AssignTask> createState() => _AssignTaskState();
}

class _AssignTaskState extends State<AssignTask> {
  final db = FirebaseFirestore.instance;
  final TeamController teamController = Get.find<TeamController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF419C9C),
        elevation: 0,
        title: Obx(() => Text(
              "Team Tasks",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Get.snackbar(
                "Team Info",
                "Viewing tasks for ${teamController.selectedTeamName.value}",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF2D6F6F),
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (teamController.selectedTeamCode.value.isEmpty) {
          return _buildEmptyState(
            "Select a team first",
            "Choose a team from the Teams page to view assigned tasks",
            Icons.group_add,
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: db
              .collection('teams')
              .where('teamCode', isEqualTo: teamController.selectedTeamCode.value)
              .snapshots(),
          builder: (context, teamSnapshot) {
            if (teamSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingUI();
            }

            if (!teamSnapshot.hasData || teamSnapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                "No team found",
                "The selected team doesn't exist in the database",
                Icons.error_outline,
              );
            }

            String teamDocId = teamSnapshot.data!.docs.first.id;

            return StreamBuilder<QuerySnapshot>(
              stream: db.collection('teams').doc(teamDocId).collection('tasks').snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingUI();
                }

                if (!taskSnapshot.hasData || taskSnapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(
                    "No tasks yet",
                    "Tap the + button to create your first task",
                    Icons.assignment,
                  );
                }

                var tasks = taskSnapshot.data!.docs;
                tasks.sort((a, b) => (b['timestamp'] ?? Timestamp.now())
                    .compareTo(a['timestamp'] ?? Timestamp.now()));

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  backgroundColor: const Color(0xFF419C9C),
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      var task = tasks[index];
                      return _buildTaskCard(task);
                    },
                  ),
                );
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF419C9C),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditTask()),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(QueryDocumentSnapshot task) {
    final date = (task['startDate'] ?? task['timestamp'] ?? Timestamp.now()).toDate();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final time = task['time'] != null 
        ? TimeOfDay(hour: task['time']['hour'], minute: task['time']['minute'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Add task detail view if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      task['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF263238),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF90A4AE)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTask(
                              taskId: task.id,
                              taskData: task.data() as Map<String, dynamic>,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(task.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Color(0xFF419C9C)),
                            const SizedBox(width: 8),
                            Text("Edit", style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red[400]),
                            const SizedBox(width: 8),
                            Text("Delete", style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task['description'] ?? 'No description',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF546E7A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Color(0xFF419C9C)),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF607D8B),
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Color(0xFF419C9C)),
                    const SizedBox(width: 4),
                    Text(
                      time.format(context),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF607D8B),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (task['purpose'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Color(0xFF419C9C)),
                    const SizedBox(width: 4),
                    Text(
                      task['purpose'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF607D8B),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String taskId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Task",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to delete this task?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: const Color(0xFF607D8B)),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteTask(taskId);
            },
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      QuerySnapshot teamSnapshot = await db
          .collection('teams')
          .where('teamCode', isEqualTo: teamController.selectedTeamCode.value)
          .get();

      if (teamSnapshot.docs.isNotEmpty) {
        String teamDocId = teamSnapshot.docs.first.id;

        await db
            .collection('teams')
            .doc(teamDocId)
            .collection('tasks')
            .doc(taskId)
            .delete();

        Get.snackbar(
          "Success",
          "Task deleted successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF2D6F6F),
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete task: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFFCFD8DC),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF607D8B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF90A4AE),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingUI() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFECEFF1),
          highlightColor: const Color(0xFFF5F7F9),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Container(
                  width: 100,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
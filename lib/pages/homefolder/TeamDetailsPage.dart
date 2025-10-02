import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class TeamDetailsPage extends StatefulWidget {
  final String teamId;
  final String teamName;
  final String teamCode;

  const TeamDetailsPage({
    Key? key,
    required this.teamId,
    required this.teamName,
    required this.teamCode,
  }) : super(key: key);

  @override
  _TeamDetailsPageState createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _teamNameController = TextEditingController();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _teamNameController.text = widget.teamName;
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _updateTeamName() async {
    final newTeamName = _teamNameController.text.trim();
    if (newTeamName.isEmpty || newTeamName == widget.teamName) {
      setState(() {
        isEditing = false;
      });
      return;
    }

    try {
      await _firestore.collection('teams').doc(widget.teamId).update({
        'teamName': newTeamName,
      });

      // Update chats with the new team name
      final chatDocs = await _firestore
          .collection('chats')
          .where('teamId', isEqualTo: widget.teamId)
          .get();

      for (var chatDoc in chatDocs.docs) {
        await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('teamId', isEqualTo: widget.teamId)
            .get()
            .then((messages) {
          for (var message in messages.docs) {
            message.reference.update({'teamName': newTeamName});
          }
        });
      }

      Get.snackbar(
        'Success',
        'Team name updated successfully',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        isEditing = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update team name: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteTeam() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Delete Team',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.teamName}"? This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF4CAF50)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    try {
      // Delete members subcollection
      final membersSnapshot = await _firestore
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .get();
      for (var member in membersSnapshot.docs) {
        final memberUid = member.data()['uid'];
        // Notify each member
        await _firestore.collection('users').doc(memberUid).collection('notifications').add({
          'message': 'You have been removed from the team "${widget.teamName}".',
          'teamId': widget.teamId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'remove',
        });
        await member.reference.delete();
      }

      // Delete associated chats
      final chatDocs = await _firestore
          .collection('chats')
          .where('teamId', isEqualTo: widget.teamId)
          .get();
      for (var chatDoc in chatDocs.docs) {
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .get();
        for (var message in messagesSnapshot.docs) {
          await message.reference.delete();
        }
        await chatDoc.reference.delete();
      }

      // Delete the team
      await _firestore.collection('teams').doc(widget.teamId).delete();

      Get.snackbar(
        'Success',
        'Team deleted successfully',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      Navigator.of(context).pop(); // Go back to TeamManagementPage
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete team: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteMember(String memberUid, String memberName) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Remove Member',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$memberName" from "${widget.teamName}"?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF4CAF50)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    try {
      // Delete the member from the team
      await _firestore
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .doc(memberUid)
          .delete();

      // Send a notification to the member
      await _firestore.collection('users').doc(memberUid).collection('notifications').add({
        'message': 'You have been removed from the team "${widget.teamName}".',
        'teamId': widget.teamId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'remove',
      });

      Get.snackbar(
        'Success',
        '$memberName has been removed from the team.',
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove member: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.teamName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A3C34), Color(0xFF2A5C54)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Details',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isEditing
                        ? TextField(
                            controller: _teamNameController,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Team Name',
                              labelStyle: GoogleFonts.poppins(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                'Name: ${widget.teamName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Code: ${widget.teamCode}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                  ),
                  IconButton(
                    icon: Icon(
                      isEditing ? Icons.check : Icons.edit,
                      color: const Color(0xFF4CAF50),
                    ),
                    onPressed: () {
                      if (isEditing) {
                        _updateTeamName();
                      } else {
                        setState(() {
                          isEditing = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Members',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('teams')
                    .doc(widget.teamId)
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                        strokeWidth: 3,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No members found.',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  final members = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index].data() as Map<String, dynamic>;
                      final memberUid = member['uid'] ?? '';
                      final memberName = member['name'] ?? 'Unknown';
                      final memberEmail = member['email'] ?? '';

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.05),
                              offset: const Offset(-4, -4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            memberName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            memberEmail,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteMember(memberUid, memberName),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _deleteTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Delete Team',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
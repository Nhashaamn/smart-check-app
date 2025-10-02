import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_check/pages/homefolder/child%20detail.dart';
import 'package:smart_check/pages/homefolder/reports.dart';

class TeamDetailReportPage extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamDetailReportPage({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamDetailReportPage> createState() => _TeamDetailReportPageState();
}

class _TeamDetailReportPageState extends State<TeamDetailReportPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> teamData = [];
  bool isLoading = true;
  String? errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeamData() async {
    try {
      print('Fetching data for team: ${widget.teamName}, ID: ${widget.teamId}');
      final snapshot = await _firestore
          .collection('taskData')
          .where('teamId', isEqualTo: widget.teamId)
          .get();

      print('Team data snapshot size: ${snapshot.docs.length}');

      setState(() {
        teamData = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        isLoading = false;
        if (teamData.isEmpty) {
          errorMessage = 'No data found for this team.';
        }
      });
      print('Fetched team data: $teamData');
    } catch (e) {
      print('Error fetching team data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching team data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF419C9C),
        title: Text(
          '${widget.teamName} Report',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Child'),
            Tab(text: 'Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Child List
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF419C9C),
                    ),
                  )
                : teamData.isEmpty
                    ? Center(
                        child: Text(
                          errorMessage ?? 'No data found.',
                          style: const TextStyle(
                            color: Color(0xFF419C9C),
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: teamData.length,
                        itemBuilder: (context, index) {
                          final data = teamData[index];
                          final childInfo = data['data']['childInfo'] as Map<String, dynamic>;
                          final childName = childInfo['fullName']?.toString() ?? 'Unknown Child';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChildDetailPage(
                                    childData: data,
                                    childName: childName,
                                  ),
                                ),
                              );
                            },
                            child: Card(
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
                                      Icons.child_care,
                                      color: Color(0xFF419C9C),
                                      size: 30,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Hero(
                                        tag: 'childName-$index',
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            childName,
                                            style: const TextStyle(
                                              color: Color(0xFF419C9C),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFF419C9C),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Tab 2: Navigate to ReportPage
          Container(
            color: Colors.grey[100],
            child: ReportPage(teamData: teamData),
          ),
        ],
      ),
    );
  }
}
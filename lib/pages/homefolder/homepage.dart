import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smart_check/components/barwidget.dart';
import 'package:smart_check/components/icon_circle.dart';
import 'package:smart_check/pages/homefolder/TaskDetail.dart';
import 'package:smart_check/pages/homefolder/Teams.dart';
import 'package:smart_check/pages/homefolder/dropdown.dart';
import 'package:smart_check/pages/homefolder/maincontainer.dart';
import 'package:smart_check/pages/homefolder/notificationScreen.dart';
import 'package:smart_check/pages/homefolder/menupage.dart';
import 'package:smart_check/pages/homefolder/reporttab.dart';
import 'package:smart_check/pages/homefolder/setting%20folder/settingpage.dart';
import 'package:smart_check/teamController.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser!;
  int currentPageIndex = 0;
  bool _isDropdownVisible = false;
  late final TeamController teamController;
  LatLng? _currentPosition;
  bool _isLoading = true;
  final Map<String, Uint8List?> _markerImageCache = {};
  StreamSubscription<Position>? _positionStreamSubscription;
  final Set<String> _notifiedAreas = {}; // Track areas for which notifications have been sent

  @override
  void initState() {
    super.initState();
    teamController = Get.put(TeamController());
    _getCurrentLocation();
    _registerFCMToken();
    _setupFCMListeners();
    _startLocationTracking();
  }

  Future<void> _registerFCMToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': fcmToken}, SetOptions(merge: true));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));
    });
  }

  void _setupFCMListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification!.title}: ${message.notification!.body}',
              style: GoogleFonts.roboto(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2D6F6F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('taskId') && message.data.containsKey('teamDocId')) {
        Get.to(() => TaskDetailPage(
              taskId: message.data['taskId'],
              teamDocId: message.data['teamDocId'],
              taskData: {},
            ));
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data.containsKey('taskId') && message.data.containsKey('teamDocId')) {
        Get.to(() => TaskDetailPage(
              taskId: message.data['taskId'],
              teamDocId: message.data['teamDocId'],
              taskData: {},
            ));
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) async {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Check if user enters any task area
      await _checkTaskAreaEntry(position);
    }, onError: (e) {
      print('Error in location stream: $e');
    });
  }

  Future<void> _checkTaskAreaEntry(Position position) async {
    if (teamController.selectedTeamName.value == 'Select Team') return;

    final teamSnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .where('teamName', isEqualTo: teamController.selectedTeamName.value)
        .limit(1)
        .get();

    if (teamSnapshot.docs.isEmpty) return;

    String teamId = teamSnapshot.docs.first.id;
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('tasks')
        .get();

    for (var taskDoc in tasksSnapshot.docs) {
      final task = taskDoc.data();
      final taskId = task['taskId'] as String;

      // Skip if already notified for this area
      if (_notifiedAreas.contains(taskId)) continue;

      // Check for circle area
      if (task.containsKey('circle')) {
        final circle = task['circle'] as Map<String, dynamic>;
        final center = circle['center'] as Map<String, dynamic>;
        final radius = (circle['radius'] as num).toDouble();
        final centerLatLng = LatLng(center['lat'], center['lng']);
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          centerLatLng.latitude,
          centerLatLng.longitude,
        );

        if (distance <= radius) {
          await _sendNotification(taskId, task['title']);
          _notifiedAreas.add(taskId);
        }
      }

      // Check for polygon area
      if (task.containsKey('polygon')) {
        final polygon = task['polygon'] as Map<String, dynamic>;
        final points = (polygon['points'] as List)
            .map((point) => LatLng(point['lat'], point['lng']))
            .toList();

        if (_isPointInPolygon(position, points)) {
          await _sendNotification(taskId, task['title']);
          _notifiedAreas.add(taskId);
        }
      }
    }
  }

  bool _isPointInPolygon(Position position, List<LatLng> polygonPoints) {
    int intersectCount = 0;
    for (int i = 0; i < polygonPoints.length; i++) {
      final j = (i + 1) % polygonPoints.length;
      if (_rayCastIntersect(position.latitude, position.longitude, polygonPoints[i], polygonPoints[j])) {
        intersectCount++;
      }
    }
    return intersectCount % 2 == 1; // Odd number of intersections means the point is inside
  }

  bool _rayCastIntersect(double lat, double lng, LatLng vertA, LatLng vertB) {
    final aY = vertA.latitude;
    final bY = vertB.latitude;
    final aX = vertA.longitude;
    final bX = vertB.longitude;

    if ((aY > lat) != (bY > lat) &&
        lng < (bX - aX) * (lat - aY) / (bY - aY) + aX) {
      return true;
    }
    return false;
  }

  Future<void> _sendNotification(String taskId, String taskTitle) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add({
      'type': 'area_entry',
      'message': 'You have entered the area for task: $taskTitle',
      'taskId': taskId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<Uint8List?> _getMarkerImageFromUrl(String? profileImageUrl, String name) async {
    const double markerSize = 60.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double radius = markerSize / 2;

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      try {
        final response = await CachedNetworkImageProvider(profileImageUrl).resolve(const ImageConfiguration());
        final completer = Completer<ui.Image>();
        response.addListener(ImageStreamListener((info, _) => completer.complete(info.image)));
        final image = await completer.future;

        final paint = Paint()..isAntiAlias = true;
        canvas.clipPath(Path()
          ..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius)));
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCircle(center: Offset(radius, radius), radius: radius),
          paint,
        );
      } catch (e) {
        print('Error loading profile image: $e');
      }
    }

    final paint = Paint()..color = Colors.cyan;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final textPainter = TextPainter(
      text: TextSpan(
        text: firstLetter,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(markerSize.toInt(), markerSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Stream<Set<Marker>> _streamTeamMembersLocations() async* {
    if (teamController.selectedTeamName.value == 'Select Team') {
      yield <Marker>{};
      return;
    }

    await for (final teamSnapshot in FirebaseFirestore.instance
        .collection('teams')
        .where('teamName', isEqualTo: teamController.selectedTeamName.value)
        .snapshots()) {
      if (teamSnapshot.docs.isEmpty) {
        yield <Marker>{};
        continue;
      }

      String teamId = teamSnapshot.docs.first.id;
      await for (final membersSnapshot in FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .snapshots()) {
        final markers = <Marker>{};
        for (final doc in membersSnapshot.docs) {
          final data = doc.data();
          if (data.containsKey('latitude') &&
              data.containsKey('longitude') &&
              data.containsKey('name') &&
              data.containsKey('email')) {
            final email = data['email'] as String;
            final name = data['name'] as String;
            Uint8List? markerImage = _markerImageCache[email];
            if (markerImage == null) {
              final profileImageUrl = await _fetchProfileImageUrl(email);
              markerImage = await _getMarkerImageFromUrl(profileImageUrl, name);
              _markerImageCache[email] = markerImage ?? await _getMarkerImageFromUrl(null, name);
            }

            markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['latitude'], data['longitude']),
                infoWindow: InfoWindow(
                  title: data['name'],
                  snippet: 'Last updated: ${data['lastUpdated']?.toDate().toLocal().toString() ?? 'N/A'}',
                ),
                icon: markerImage != null
                    ? BitmapDescriptor.fromBytes(markerImage)
                    : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                onTap: () => print('Tapped on ${data['name']}'),
              ),
            );
          }
        }
        yield markers;
      }
    }
  }

  Future<String?> _fetchProfileImageUrl(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['profileImageUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching profile image URL: $e');
      return null;
    }
  }

  Stream<Set<Map<String, dynamic>>> _streamTeamTasks() async* {
    if (teamController.selectedTeamName.value == 'Select Team') {
      yield <Map<String, dynamic>>{};
      return;
    }

    await for (final teamSnapshot in FirebaseFirestore.instance
        .collection('teams')
        .where('teamName', isEqualTo: teamController.selectedTeamName.value)
        .snapshots()) {
      if (teamSnapshot.docs.isEmpty) {
        yield <Map<String, dynamic>>{};
        continue;
      }

      String teamId = teamSnapshot.docs.first.id;
      yield* FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('tasks')
          .snapshots()
          .map((tasksSnapshot) {
        return tasksSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A2A),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2D6F6F),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        currentIndex: currentPageIndex,
        onTap: (index) => setState(() => currentPageIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Report'),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: currentPageIndex,
            children: [
              _buildHomeScreen(),
              TeamsPage(),
              TeamReportScreen(),
            ],
          ),
          if (_isDropdownVisible)
            GestureDetector(
              onTap: () => setState(() => _isDropdownVisible = false),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isDropdownVisible ? 0 : -400,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: const BoxDecoration(
                color: Color(0xFF263535),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Dropdown(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF419C9C)))
          else if (_currentPosition != null)
            StreamBuilder<Set<Marker>>(
              stream: _streamTeamMembersLocations(),
              builder: (context, membersSnapshot) {
                if (membersSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF419C9C)));
                }
                Set<Marker> teamMarkers = membersSnapshot.data ?? <Marker>{};

                return StreamBuilder<Set<Map<String, dynamic>>>(
                  stream: _streamTeamTasks(),
                  builder: (context, tasksSnapshot) {
                    if (tasksSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF419C9C)));
                    }
                    Set<Map<String, dynamic>> tasks = tasksSnapshot.data ?? <Map<String, dynamic>>{};
                    Set<Marker> taskMarkers = {};
                    Set<Circle> taskCircles = {};
                    Set<Polygon> taskPolygons = {};

                    for (var task in tasks) {
                      if (task.containsKey('location')) {
                        final location = task['location'] as Map<String, dynamic>;
                        taskMarkers.add(
                          Marker(
                            markerId: MarkerId(task['taskId']),
                            position: LatLng(location['lat'], location['lng']),
                            infoWindow: InfoWindow(title: task['title'], snippet: 'Task Location'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                        );
                      }
                      if (task.containsKey('circle')) {
                        final circle = task['circle'] as Map<String, dynamic>;
                        final center = circle['center'] as Map<String, dynamic>;
                        taskCircles.add(
                          Circle(
                            circleId: CircleId(task['taskId']),
                            center: LatLng(center['lat'], center['lng']),
                            radius: circle['radius'],
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF419C9C),
                            fillColor: const Color(0xFF419C9C).withOpacity(0.2),
                          ),
                        );
                      }
                      if (task.containsKey('polygon')) {
                        final polygon = task['polygon'] as Map<String, dynamic>;
                        final points = (polygon['points'] as List)
                            .map((point) => LatLng(point['lat'], point['lng']))
                            .toList();
                        taskPolygons.add(
                          Polygon(
                            polygonId: PolygonId(task['taskId']),
                            points: points,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF419C9C),
                            fillColor: const Color(0xFF419C9C).withOpacity(0.2),
                          ),
                        );
                      }
                    }

                    return GoogleMap(
                      initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 10),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('current_location'),
                          position: _currentPosition!,
                          infoWindow: const InfoWindow(title: 'My Location', snippet: 'You are here'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                        ...teamMarkers,
                        ...taskMarkers,
                      },
                      circles: taskCircles,
                      polygons: taskPolygons,
                      mapType: MapType.normal,
                    );
                  },
                );
              },
            )
          else
            Center(
              child: Text(
                'Unable to get location',
                style: GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
              ),
            ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(() => const SettingsPage()),
                      child: const IconCircle(icon: Icons.settings, color: Color(0xFF419C9C)),
                    ),
                    BarWidget(
                      isDropdownVisible: _isDropdownVisible,
                      toggleDropdown: () => setState(() => _isDropdownVisible = !_isDropdownVisible),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(() => const Menu()),
                      child: const IconCircle(icon: Icons.menu, color: Color(0xFF419C9C)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(() => const NotificationScreen()),
                      child: const IconCircle(icon: Icons.notifications, color: Color(0xFF419C9C)),
                    ),
                    const SizedBox(width: 100),
                    const SizedBox(width: 100),
                  ],
                ),
              ),
              Expanded(child: MainContainer(maxHeight: MediaQuery.of(context).size.height * 0.7)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
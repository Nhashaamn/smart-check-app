import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smart_check/pages/homefolder/data/data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  final String teamDocId;
  final Map<String, dynamic> taskData;

  const TaskDetailPage({
    super.key,
    required this.taskId,
    required this.taskData,
    required this.teamDocId,
  });

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late GoogleMapController mapController;
  late LatLng taskLocation;
  late final LocalAuthentication auth;
  bool _faceAuthAvailable = false;
  Set<Circle> circles = {};
  Set<Polygon> polygons = {};
  MapType _currentMapType = MapType.normal;
  LatLng? _currentMemberLocation;
  bool _isInsideArea = false;
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    auth = LocalAuthentication();
    _checkBiometrics();
    _getCurrentLocation();

    taskLocation = LatLng(
      widget.taskData['location']['lat'],
      widget.taskData['location']['lng'],
    );

    if (widget.taskData.containsKey('circle')) {
      circles.add(Circle(
        circleId: const CircleId("task_circle"),
        center: LatLng(
          widget.taskData['circle']['center']['lat'],
          widget.taskData['circle']['center']['lng'],
        ),
        radius: widget.taskData['circle']['radius'],
        strokeWidth: 2,
        strokeColor: const Color(0xFF419C9C),
        fillColor: const Color(0xFF419C9C).withOpacity(0.15),
      ));
    }

    if (widget.taskData.containsKey('polygon')) {
      polygons.add(Polygon(
        polygonId: const PolygonId("task_polygon"),
        points: (widget.taskData['polygon']['points'] as List)
            .map((point) => LatLng(point['lat'], point['lng']))
            .toList(),
        strokeWidth: 2,
        strokeColor: const Color(0xFFE57373),
        fillColor: const Color(0xFFE57373).withOpacity(0.15),
      ));
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      setState(() {
        _faceAuthAvailable = availableBiometrics.contains(BiometricType.face);
      });
    } catch (e) {
      print("Error checking biometrics: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocationLoading = false;
            _isInsideArea = false;
          });
          _showSnackbar("Location permission denied");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentMemberLocation = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
        _isInsideArea = _isLocationInArea(_currentMemberLocation!);
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLocationLoading = false;
        _isInsideArea = false;
      });
      _showSnackbar("Error getting location: $e");
    }
  }

  bool _isLocationInArea(LatLng location) {
    if (circles.isNotEmpty) {
      final circle = circles.first;
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        circle.center.latitude,
        circle.center.longitude,
      );
      if (distance <= circle.radius) return true;
    }

    if (polygons.isNotEmpty) {
      final polygon = polygons.first;
      return _isPointInPolygon(location, polygon.points);
    }
    return false;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygonPoints) {
    int intersectCount = 0;
    for (int i = 0; i < polygonPoints.length; i++) {
      final j = (i + 1) % polygonPoints.length;
      if (_rayCastIntersect(point.latitude, point.longitude, polygonPoints[i], polygonPoints[j])) {
        intersectCount++;
      }
    }
    return intersectCount % 2 == 1;
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

  Future<void> _authenticateUser() async {
    if (!_isInsideArea) {
      _showSnackbar("You must be inside the assigned area to start the task");
      return;
    }

    try {
      bool isAuthenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to start the task',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        final currentUser = FirebaseAuth.instance.currentUser;
        final memberDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        final memberName = memberDoc.data()?['name'] ?? 'Unknown Member';

        final teamDoc = await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.teamDocId)
            .get();
        final adminUid = teamDoc.data()?['adminUid'];

        if (adminUid != null) {
          await FirebaseFirestore.instance.collection('notifications_trigger').add({
            'type': 'fingerprint_auth',
            'taskId': widget.taskId,
            'teamDocId': widget.teamDocId,
            'memberName': memberName,
            'adminUid': adminUid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DataPage()),
        );
      } else {
        _showSnackbar("Authentication failed");
      }
    } catch (e) {
      _showSnackbar("Authentication error: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _openFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapPage(
          taskLocation: taskLocation,
          circles: circles,
          polygons: polygons,
          mapType: _currentMapType,
        ),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime startDate;
    DateTime endDate;
    if (widget.taskData.containsKey('startDate') && widget.taskData.containsKey('endDate')) {
      startDate = (widget.taskData['startDate'] as Timestamp).toDate();
      endDate = (widget.taskData['endDate'] as Timestamp).toDate();
    } else if (widget.taskData.containsKey('date')) {
      startDate = (widget.taskData['date'] as Timestamp).toDate();
      endDate = startDate;
    } else {
      startDate = DateTime.now();
      endDate = DateTime.now();
    }
    
    String formattedStartDate = DateFormat('EEE, MMM d, y').format(startDate);
    String formattedEndDate = DateFormat('EEE, MMM d, y').format(endDate);

    TimeOfDay startTime = TimeOfDay(
      hour: widget.taskData['time']['hour'] ?? 0,
      minute: widget.taskData['time']['minute'] ?? 0,
    );

    TimeOfDay endTime;
    if (widget.taskData.containsKey('endTime')) {
      endTime = TimeOfDay(
        hour: widget.taskData['endTime']['hour'] ?? startTime.hour,
        minute: widget.taskData['endTime']['minute'] ?? startTime.minute,
      );
    } else {
      endTime = TimeOfDay(
        hour: (startTime.hour + 1) % 24,
        minute: startTime.minute,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF419C9C),
        title: const Text("Task Details", style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        )),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title and Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.taskData['title'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.taskData['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Task Details Section
            const Text(
              "Task Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            
            // Date and Time Cards
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    Icons.calendar_today_outlined,
                    "Start Date",
                    formattedStartDate,
                    const Color(0xFF419C9C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    Icons.calendar_today_outlined,
                    "End Date",
                    formattedEndDate,
                    const Color(0xFFE57373),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    Icons.access_time_outlined,
                    "Start Time",
                    startTime.format(context),
                    const Color(0xFF48A9A6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    Icons.access_time_outlined,
                    "End Time",
                    endTime.format(context),
                    const Color(0xFF6A4C93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Location Section
            const Text(
              "Task Location",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            
            // Map Container
            Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: taskLocation,
                        zoom: 10,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("task_location"),
                          position: taskLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                      },
                      circles: circles,
                      polygons: polygons,
                      onMapCreated: (controller) => setState(() => mapController = controller),
                      mapType: _currentMapType,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            onPressed: _openFullScreenMap,
                            mini: true,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.fullscreen, color: Colors.black87),
                            elevation: 2,
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            onPressed: _toggleMapType,
                            mini: true,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.layers, color: Colors.black87),
                            elevation: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Location Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isInsideArea ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isInsideArea ? Icons.check_circle : Icons.error,
                    color: _isInsideArea ? const Color(0xFF388E3C) : const Color(0xFFE57373),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isInsideArea 
                          ? "You are within the task area"
                          : "You are outside the task area",
                      style: TextStyle(
                        color: _isInsideArea ? const Color(0xFF388E3C) : const Color(0xFFE57373),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Start Task Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isInsideArea && !_isLocationLoading ? _authenticateUser : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF419C9C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: const Color(0xFF419C9C).withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_open, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "START TASK",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(_isInsideArea && !_isLocationLoading ? 1 : 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_isLocationLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF419C9C)),
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenMapPage extends StatelessWidget {
  final LatLng taskLocation;
  final Set<Circle> circles;
  final Set<Polygon> polygons;
  final MapType mapType;

  const FullScreenMapPage({
    super.key,
    required this.taskLocation,
    required this.circles,
    required this.polygons,
    required this.mapType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: taskLocation, zoom: 10),
            markers: {
              Marker(
                markerId: const MarkerId("task_location"),
                position: taskLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            },
            circles: circles,
            polygons: polygons,
            mapType: mapType,
            myLocationEnabled: true,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: () {
                    // Add location button functionality if needed
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
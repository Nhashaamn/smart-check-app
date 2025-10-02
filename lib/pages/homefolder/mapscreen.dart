import 'dart:math'; // Add this import

import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationSelected;
  final Function(Circle)? onCircleDrawn;
  final Function(Polygon)? onPolygonDrawn;

  const MapScreen({
    Key? key,
    required this.initialLocation,
    required this.onLocationSelected,
    this.onCircleDrawn,
    this.onPolygonDrawn,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedLocation;
  late GoogleMapController mapController;
  final places = GoogleMapsPlaces(apiKey: "AIzaSyCFt-Elb80sg_qfTf0HlpgnHbTdE485LIY");
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  Set<Polygon> polygons = {};
  bool isDrawingCircle = false;
  bool isDrawingPolygon = false;
  bool _isLoading = true;
  Circle? _selectedCircle;
  Marker? _radiusMarker;
  bool _isSatelliteView = false; // New variable to track map type

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled. Please enable them.")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied. Please enable them in settings.")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
      markers.add(Marker(
        markerId: const MarkerId("current-location"),
        position: selectedLocation!,
      ));
      _isLoading = false;
    });

    mapController.animateCamera(CameraUpdate.newLatLng(selectedLocation!));
  }

  Future<void> _searchLocation() async {
    try {
      Prediction? prediction = await PlacesAutocomplete.show(
        context: context,
        apiKey: "AIzaSyCFt-Elb80sg_qfTf0HlpgnHbTdE485LIY",
        mode: Mode.overlay,
        language: "en",
      );

      if (prediction != null) {
        PlacesDetailsResponse detail = await places.getDetailsByPlaceId(prediction.placeId!);
        if (detail.status == "OK") {
          double lat = detail.result.geometry!.location.lat;
          double lng = detail.result.geometry!.location.lng;

          setState(() {
            selectedLocation = LatLng(lat, lng);
            markers.add(Marker(
              markerId: const MarkerId("selected-location"),
              position: selectedLocation!,
            ));
          });

          mapController.animateCamera(CameraUpdate.newLatLng(selectedLocation!));
          widget.onLocationSelected(selectedLocation!);
        } else {
          print("Places Details API Error: ${detail.status}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to fetch place details: ${detail.status}")),
          );
        }
      }
    } catch (e) {
      print("Search Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  void _onMapTapped(LatLng latLng) {
    if (isDrawingCircle) {
      _createCircle(latLng);
    } else if (isDrawingPolygon) {
      _createPolygon(latLng);
    } else {
      setState(() {
        selectedLocation = latLng;
        markers.add(Marker(
          markerId: const MarkerId("selected-location"),
          position: latLng,
        ));
      });
      widget.onLocationSelected(latLng);
    }
  }

  void _createCircle(LatLng center) {
    final String circleId = "circle-${circles.length}";
    final Circle circle = Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: 500,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.2),
    );

    final Marker radiusMarker = Marker(
      markerId: MarkerId("radius-marker-$circleId"),
      position: _calculateRadiusMarkerPosition(center, circle.radius),
      draggable: true,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      onDragEnd: (LatLng newPosition) {
        _updateCircleRadius(circleId, newPosition);
      },
    );

    setState(() {
      circles.add(circle);
      markers.add(radiusMarker);
      _selectedCircle = circle;
      _radiusMarker = radiusMarker;
    });

    if (widget.onCircleDrawn != null) {
      widget.onCircleDrawn!(circle);
    }
  }

  void _updateCircleRadius(String circleId, LatLng newPosition) {
    final Circle? circle = circles.firstWhere((c) => c.circleId.value == circleId);
    if (circle != null) {
      final double newRadius = _calculateDistance(circle.center, newPosition);

      setState(() {
        circles.remove(circle);
        circles.add(circle.copyWith(radiusParam: newRadius));
        _radiusMarker = _radiusMarker?.copyWith(
          positionParam: _calculateRadiusMarkerPosition(circle.center, newRadius),
        );
      });
    }
  }

  LatLng _calculateRadiusMarkerPosition(LatLng center, double radius) {
    const double bearing = 0;
    return _calculateDestinationPoint(center, radius, bearing);
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  LatLng _calculateDestinationPoint(LatLng start, double distance, double bearing) {
    const double earthRadius = 6378137;
    final double lat1 = start.latitude * (pi / 180);
    final double lon1 = start.longitude * (pi / 180);
    final double angularDistance = distance / earthRadius;
    final double bearingRad = bearing * (pi / 180);

    final double lat2 = asin(
      sin(lat1) * cos(angularDistance) +
          cos(lat1) * sin(angularDistance) * cos(bearingRad),
    );

    final double lon2 = lon1 +
        atan2(
          sin(bearingRad) * sin(angularDistance) * cos(lat1),
          cos(angularDistance) - sin(lat1) * sin(lat2),
        );

    return LatLng(lat2 * (180 / pi), lon2 * (180 / pi));
  }

  void _createPolygon(LatLng point) {
    setState(() {
      if (polygons.isEmpty) {
        polygons.add(Polygon(
          polygonId: PolygonId("polygon-${polygons.length}"),
          points: [point],
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.2),
        ));
      } else {
        polygons.first.points.add(point);
      }
    });
    if (widget.onPolygonDrawn != null) {
      widget.onPolygonDrawn!(polygons.first);
    }
  }

  void _toggleCircleDrawing() {
    setState(() {
      isDrawingCircle = !isDrawingCircle;
      isDrawingPolygon = false;
    });
  }

  void _togglePolygonDrawing() {
    setState(() {
      isDrawingPolygon = !isDrawingPolygon;
      isDrawingCircle = false;
    });
  }

  void _removeLastCircle() {
    if (circles.isNotEmpty) {
      setState(() {
        circles.remove(circles.last);
        markers.removeWhere((marker) => marker.markerId.value.startsWith("radius-marker"));
      });
    }
  }

  void _removeLastPolygon() {
    if (polygons.isNotEmpty) {
      setState(() {
        polygons.remove(polygons.last);
      });
    }
  }

  void _clearAllShapes() {
    setState(() {
      circles.clear();
      polygons.clear();
      markers.removeWhere((marker) => marker.markerId.value.startsWith("radius-marker"));
    });
  }

  void _toggleMapType() { // New method to toggle map type
    setState(() {
      _isSatelliteView = !_isSatelliteView;
      mapController.setMapStyle(null); // Reset any custom styles if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: const Color(0xFF419C9C),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchLocation,
          ),
          IconButton( // New layers button
            icon: Icon(
              _isSatelliteView ? Icons.map : Icons.satellite,
            ),
            onPressed: _toggleMapType,
            tooltip: 'Toggle Map Layers',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _toggleCircleDrawing,
            child: Icon(Icons.circle_outlined),
            backgroundColor: isDrawingCircle ? Colors.blue : Colors.grey,
            tooltip: "Draw Circle",
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _togglePolygonDrawing,
            child: Icon(Icons.polyline),
            backgroundColor: isDrawingPolygon ? Colors.red : Colors.grey,
            tooltip: "Draw Polygon",
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _removeLastCircle,
            child: Icon(Icons.remove_circle_outline),
            backgroundColor: Colors.grey,
            tooltip: "Remove Last Circle",
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _removeLastPolygon,
            child: Icon(Icons.remove),
            backgroundColor: Colors.grey,
            tooltip: "Remove Last Polygon",
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _clearAllShapes,
            child: Icon(Icons.clear),
            backgroundColor: Colors.grey,
            tooltip: "Clear All Shapes",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: selectedLocation ?? widget.initialLocation,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: markers,
              circles: circles,
              polygons: polygons,
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: _isSatelliteView ? MapType.satellite : MapType.normal, // Toggle map type
            ),
    );
  }
}
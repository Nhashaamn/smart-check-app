import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Widget buildChildInfoSection(Map<String, dynamic> childInfo) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ExpansionTile(
      leading: const Icon(
        Icons.child_care,
        color: Color(0xFF419C9C),
      ),
      title: const Text(
        'Child Information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF419C9C),
        ),
      ),
      children: [
        _buildDataRow('Child ID', childInfo['childId']?.toString() ?? 'N/A'),
        _buildDataRow('Full Name', childInfo['fullName']?.toString() ?? 'N/A'),
        _buildDataRow('Gender', childInfo['gender']?.toString() ?? 'N/A'),
        _buildDataRow('Date of Birth/Age', childInfo['dateOfBirthOrAge']?.toString() ?? 'N/A'),
        _buildDataRow('Weight (kg)', childInfo['weightKg']?.toString() ?? 'N/A'),
      ],
    ),
  );
}

Widget buildAddressSection(Map<String, dynamic> address) {
  final latitude = (address['latitude'] as num?)?.toDouble();
  final longitude = (address['longitude'] as num?)?.toDouble();

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ExpansionTile(
      leading: const Icon(
        Icons.location_on,
        color: Color(0xFF419C9C),
      ),
      title: const Text(
        'Address',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF419C9C),
        ),
      ),
      children: [
        _buildDataRow('City', address['city']?.toString() ?? 'N/A'),
        _buildDataRow('Province', address['province']?.toString() ?? 'N/A'),
        if (latitude != null && longitude != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              height: 200, // Fixed height for the map
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(latitude, longitude),
                    zoom: 15, // Zoom level to show the location clearly
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('child_location'),
                      position: LatLng(latitude, longitude),
                      infoWindow: const InfoWindow(
                        title: 'Child Location',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                    ),
                  },
                  zoomControlsEnabled: false, // Disable zoom controls
                  zoomGesturesEnabled: false, // Disable zoom gestures
                  scrollGesturesEnabled: false, // Disable panning
                  rotateGesturesEnabled: false, // Disable rotation
                  tiltGesturesEnabled: false, // Disable tilt
                  myLocationEnabled: false, // No need for user location
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Location not available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget buildParentInfoSection(Map<String, dynamic> parentInfo) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ExpansionTile(
      leading: const Icon(
        Icons.person,
        color: Color(0xFF419C9C),
      ),
      title: const Text(
        'Parent/Guardian Information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF419C9C),
        ),
      ),
      children: [
        _buildDataRow('Name', parentInfo['name']?.toString() ?? 'N/A'),
        _buildDataRow('Contact Number', parentInfo['contactNumber']?.toString() ?? 'N/A'),
      ],
    ),
  );
}

Widget buildVaccinationDetailsSection(Map<String, dynamic> vaccinationDetails) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ExpansionTile(
      leading: const Icon(
        Icons.vaccines,
        color: Color(0xFF419C9C),
      ),
      title: const Text(
        'Vaccination Details',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF419C9C),
        ),
      ),
      children: [
        _buildDataRow('Vaccine Type', vaccinationDetails['vaccineType']?.toString() ?? 'N/A'),
        _buildDataRow('Dose Number', vaccinationDetails['doseNumber']?.toString() ?? 'N/A'),
        _buildDataRow('Vaccine Batch Number', vaccinationDetails['vaccineBatchNumber']?.toString() ?? 'N/A'),
        _buildDataRow('Vaccine Expiry Date', vaccinationDetails['vaccineExpiryDate']?.toString() ?? 'N/A'),
        _buildDataRow('Vaccination Date & Time', vaccinationDetails['vaccinationDateTime']?.toString() ?? 'N/A'),
      ],
    ),
  );
}

Widget buildMemberInfoSection(Map<String, dynamic> childData) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ExpansionTile(
      leading: const Icon(
        Icons.group,
        color: Color(0xFF419C9C),
      ),
      title: const Text(
        'Member Information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF419C9C),
        ),
      ),
      children: [
        _buildDataRow('Member Name', childData['memberName']?.toString() ?? 'N/A'),
        _buildDataRow('Member ID', childData['memberId']?.toString() ?? 'N/A'),
      ],
    ),
  );
}

Widget _buildDataRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
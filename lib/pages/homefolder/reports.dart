import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

class ReportPage extends StatefulWidget {
  final List<Map<String, dynamic>> teamData;

  const ReportPage({super.key, required this.teamData});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String selectedGraph = 'Gender Distribution'; // Default selected graph
  final List<String> graphOptions = [
    'Gender Distribution',
    'Age Distribution',
    'Weight Distribution',
    'Vaccine Type Distribution',
    'Dose Number Distribution',
    'Vaccinations Over Time',
    'Child Location Density',
  ];

  // Filter variables
  String? selectedGender;
  String? selectedAgeRange;
  String? selectedVaccineType;
  String? selectedDoseNumber;
  String? selectedWeightRange;
  DateTime? selectedDate;

  final List<String> genderOptions = ['All', 'Male', 'Female', 'Other'];
  final List<String> ageRangeOptions = ['All', '0-2', '3-5', '6-8', '9-12', '>12'];
  final List<String> vaccineTypeOptions = ['All', 'OPV', 'IPV', 'Others'];
  final List<String> doseNumberOptions = ['All', '0', '1', '2', '3', 'Booster'];
  final List<String> weightRangeOptions = ['All', '0-5', '5-10', '10-15', '15-20', '>20'];

  // Variables for Google Map
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _initialPosition = const LatLng(30.3753, 69.3451); // Center of Pakistan as default

  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.teamData);
    _loadChildLocations();
  }

  void _applyFilters() {
    print('Before filtering: ${widget.teamData.length} items');
    setState(() {
      _filteredData = widget.teamData.where((data) {
        final childInfo = data['data']['childInfo'] as Map<String, dynamic>? ?? {};
        final vaccinationDetails = data['data']['vaccinationDetails'] as Map<String, dynamic>? ?? {};
        final gender = childInfo['gender']?.toString() ?? '';
        final ageString = childInfo['dateOfBirthOrAge']?.toString() ?? '0';
        int age = 0;
        if (int.tryParse(ageString) != null) {
          age = int.parse(ageString);
        } else {
          try {
            final dob = DateTime.tryParse(ageString);
            if (dob != null) {
              final now = DateTime.now();
              age = now.year - dob.year;
              if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
                age--;
              }
            }
          } catch (e) {
            print('Failed to parse date of birth: $ageString');
          }
        }
        final weight = (childInfo['weightKg'] as num?)?.toDouble() ?? 0.0;
        final vaccineType = vaccinationDetails['vaccineType']?.toString() ?? '';
        final doseNumber = vaccinationDetails['doseNumber']?.toString() ?? '';
        final dateString = data['collectionDateTime']?.toString(); // Use collectionDateTime
        DateTime? collectionDate;
        if (dateString != null) {
          collectionDate = DateTime.tryParse(dateString);
        }

        // Gender filter
        bool genderMatch = selectedGender == null || selectedGender == 'All' || gender.toLowerCase() == selectedGender!.toLowerCase();

        // Age filter
        bool ageMatch = selectedAgeRange == null || selectedAgeRange == 'All' ||
            (selectedAgeRange == '0-2' && age <= 2) ||
            (selectedAgeRange == '3-5' && age > 2 && age <= 5) ||
            (selectedAgeRange == '6-8' && age > 5 && age <= 8) ||
            (selectedAgeRange == '9-12' && age > 8 && age <= 12) ||
            (selectedAgeRange == '>12' && age > 12);

        // Weight filter
        bool weightMatch = selectedWeightRange == null || selectedWeightRange == 'All' ||
            (selectedWeightRange == '0-5' && weight <= 5) ||
            (selectedWeightRange == '5-10' && weight > 5 && weight <= 10) ||
            (selectedWeightRange == '10-15' && weight > 10 && weight <= 15) ||
            (selectedWeightRange == '15-20' && weight > 15 && weight <= 20) ||
            (selectedWeightRange == '>20' && weight > 20);

        // Vaccine type filter
        bool vaccineTypeMatch = selectedVaccineType == null || selectedVaccineType == 'All' || vaccineType.toLowerCase() == selectedVaccineType!.toLowerCase();

        // Dose number filter
        bool doseNumberMatch = selectedDoseNumber == null || selectedDoseNumber == 'All' || doseNumber == selectedDoseNumber;

        // Date filter (based on collectionDateTime)
        bool dateMatch = true;
        if (selectedDate != null) {
          if (collectionDate == null) {
            dateMatch = false;
          } else {
            dateMatch = collectionDate.year == selectedDate!.year &&
                collectionDate.month == selectedDate!.month &&
                collectionDate.day == selectedDate!.day;
          }
        }

        return genderMatch && ageMatch && weightMatch && vaccineTypeMatch && doseNumberMatch && dateMatch;
      }).toList();
      print('After filtering: ${_filteredData.length} items');
      _loadChildLocations();
    });
  }

  void _resetFilters() {
    setState(() {
      selectedGender = null;
      selectedAgeRange = null;
      selectedVaccineType = null;
      selectedDoseNumber = null;
      selectedWeightRange = null;
      selectedDate = null;
      _filteredData = List.from(widget.teamData);
      _loadChildLocations();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _applyFilters();
      });
    }
  }

  void _loadChildLocations() {
    final List<LatLng> locations = [];
    for (var data in _filteredData) {
      final childInfo = data['data']['childInfo'] as Map<String, dynamic>? ?? {};
      final address = childInfo['address'] as Map<String, dynamic>? ?? {};
      final double latitude = (address['latitude'] as num?)?.toDouble() ?? 0.0;
      final double longitude = (address['longitude'] as num?)?.toDouble() ?? 0.0;

      if (latitude != 0.0 && longitude != 0.0) {
        locations.add(LatLng(latitude, longitude));
      }
    }

    _markers = _createDensityMarkers(locations);
  }

  Set<Marker> _createDensityMarkers(List<LatLng> locations) {
    final Set<Marker> markers = {};
    final Map<LatLng, int> densityMap = {};

    const double radius = 0.01;
    for (var loc in locations) {
      bool foundCluster = false;
      for (var key in densityMap.keys) {
        final distance = latlong.Distance().as(
          latlong.LengthUnit.Kilometer,
          latlong.LatLng(loc.latitude, loc.longitude),
          latlong.LatLng(key.latitude, key.longitude),
        );
        if (distance < radius) {
          densityMap[key] = densityMap[key]! + 1;
          foundCluster = true;
          break;
        }
      }
      if (!foundCluster) {
        densityMap[loc] = 1;
      }
    }

    densityMap.forEach((location, count) {
      final color = _getMarkerColor(count);
      markers.add(
        Marker(
          markerId: MarkerId(location.toString()),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          infoWindow: InfoWindow(
            title: 'Children: $count',
          ),
        ),
      );
    });

    return markers;
  }

  double _getMarkerColor(int count) {
    if (count >= 5) return BitmapDescriptor.hueRed;
    if (count >= 3) return BitmapDescriptor.hueOrange;
    if (count >= 2) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueGreen;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teamData.isEmpty) {
      return const Center(
        child: Text(
          'No data available for charts.',
          style: TextStyle(
            color: Color(0xFF419C9C),
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[100]!, Colors.grey[300]!],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Filters'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedGender,
                    hint: const Text('Gender'),
                    items: genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGender = newValue;
                        _applyFilters();
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedAgeRange,
                    hint: const Text('Age Range'),
                    items: ageRangeOptions.map((String range) {
                      return DropdownMenuItem<String>(
                        value: range,
                        child: Text(range),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedAgeRange = newValue;
                        _applyFilters();
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedWeightRange,
                    hint: const Text('Weight Range'),
                    items: weightRangeOptions.map((String range) {
                      return DropdownMenuItem<String>(
                        value: range,
                        child: Text(range),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedWeightRange = newValue;
                        _applyFilters();
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedVaccineType,
                    hint: const Text('Vaccine Type'),
                    items: vaccineTypeOptions.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedVaccineType = newValue;
                        _applyFilters();
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDoseNumber,
                    hint: const Text('Dose Number'),
                    items: doseNumberOptions.map((String dose) {
                      return DropdownMenuItem<String>(
                        value: dose,
                        child: Text(dose),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDoseNumber = newValue;
                        _applyFilters();
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context), // Always allow date selection
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: selectedDate == null
                              ? 'Select Date'
                              : DateFormat('yyyy-MM-dd').format(selectedDate!),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _resetFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF419C9C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reset Filters'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Select Graph'),
            _buildGraphSelector(),
            const SizedBox(height: 20),

            _buildSelectedGraph(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF419C9C),
        ),
      ),
    );
  }

  Widget _buildGraphSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButton<String>(
          value: selectedGraph,
          isExpanded: true,
          underline: const SizedBox(),
          items: graphOptions.map((String graph) {
            return DropdownMenuItem<String>(
              value: graph,
              child: Text(
                graph,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF419C9C),
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedGraph = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSelectedGraph() {
    switch (selectedGraph) {
      case 'Gender Distribution':
        return _buildGraphCard('Gender Distribution', _buildGenderPieChart());
      case 'Age Distribution':
        return _buildGraphCard('Age Distribution', _buildAgeBarChart());
      case 'Weight Distribution':
        return _buildGraphCard('Weight Distribution (kg)', _buildWeightBarChart());
      case 'Vaccine Type Distribution':
        return _buildGraphCard('Vaccine Type Distribution', _buildVaccineTypeBarChart());
      case 'Dose Number Distribution':
        return _buildGraphCard('Dose Number Distribution', _buildDoseNumberBarChart());
      case 'Vaccinations Over Time':
        return _buildGraphCard('Vaccinations Over Time', _buildVaccinationOverTimeLineChart());
      case 'Child Location Density':
        return _buildGraphCard('Child Location Density', _buildChildLocationMap());
      default:
        return const SizedBox();
    }
  }

  Widget _buildGraphCard(String title, Widget chart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title),
            SizedBox(
              height: 250,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildLocationMap() {
    if (_markers.isEmpty) {
      return const Center(child: Text('No location data available.'));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 5,
      ),
      markers: _markers,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_markers.isNotEmpty) {
          final bounds = _calculateBounds();
          _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        }
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  LatLngBounds _calculateBounds() {
    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildGenderPieChart() {
    print('Building Gender Pie Chart with ${_filteredData.length} items');
    final genderCount = {'Male': 0, 'Female': 0, 'Other': 0};
    for (var data in _filteredData) {
      final childInfo = data['data']['childInfo'] as Map<String, dynamic>? ?? {};
      final gender = childInfo['gender']?.toString() ?? 'Unknown';
      if (gender.toLowerCase() == 'male') {
        genderCount['Male'] = genderCount['Male']! + 1;
      } else if (gender.toLowerCase() == 'female') {
        genderCount['Female'] = genderCount['Female']! + 1;
      } else {
        genderCount['Other'] = genderCount['Other']! + 1;
      }
    }

    final total = genderCount['Male']! + genderCount['Female']! + genderCount['Other']!;
    if (total == 0) {
      return const Center(child: Text('No gender data available.'));
    }

    return PieChart(
      PieChartData(
        sections: [
          if (genderCount['Male']! > 0)
            PieChartSectionData(
              value: genderCount['Male']!.toDouble(),
              title: 'Male\n${((genderCount['Male']! / total) * 100).toStringAsFixed(1)}%',
              color: Colors.blue,
              radius: 50,
            ),
          if (genderCount['Female']! > 0)
            PieChartSectionData(
              value: genderCount['Female']!.toDouble(),
              title: 'Female\n${((genderCount['Female']! / total) * 100).toStringAsFixed(1)}%',
              color: Colors.pink,
              radius: 50,
            ),
          if (genderCount['Other']! > 0)
            PieChartSectionData(
              value: genderCount['Other']!.toDouble(),
              title: 'Other\n${((genderCount['Other']! / total) * 100).toStringAsFixed(1)}%',
              color: Colors.grey,
              radius: 50,
            ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildAgeBarChart() {
    print('Building Age Bar Chart with ${_filteredData.length} items');
    final ageBins = {
      '0-2': 0,
      '3-5': 0,
      '6-8': 0,
      '9-12': 0,
      '>12': 0,
    };

    for (var data in _filteredData) {
      final childInfo = data['data']['childInfo'] as Map<String, dynamic>? ?? {};
      final ageString = childInfo['dateOfBirthOrAge']?.toString() ?? '0';
      int age = 0;
      if (int.tryParse(ageString) != null) {
        age = int.parse(ageString);
      } else {
        try {
          final dob = DateTime.tryParse(ageString);
          if (dob != null) {
            final now = DateTime.now();
            age = now.year - dob.year;
            if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
              age--;
            }
          }
        } catch (e) {
          print('Failed to parse date of birth: $ageString');
        }
      }
      if (age <= 2) {
        ageBins['0-2'] = ageBins['0-2']! + 1;
      } else if (age <= 5) {
        ageBins['3-5'] = ageBins['3-5']! + 1;
      } else if (age <= 8) {
        ageBins['6-8'] = ageBins['6-8']! + 1;
      } else if (age <= 12) {
        ageBins['9-12'] = ageBins['9-12']! + 1;
      } else {
        ageBins['>12'] = ageBins['>12']! + 1;
      }
    }

    final barGroups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: ageBins['0-2']!.toDouble(), color: Colors.orange)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: ageBins['3-5']!.toDouble(), color: Colors.orange)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: ageBins['6-8']!.toDouble(), color: Colors.orange)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: ageBins['9-12']!.toDouble(), color: Colors.orange)]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: ageBins['>12']!.toDouble(), color: Colors.orange)]),
    ];

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['0-2', '3-5', '6-8', '9-12', '>12'];
                return Text(labels[value.toInt()], style: const TextStyle(color: Colors.black, fontSize: 12));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  Widget _buildWeightBarChart() {
    print('Building Weight Bar Chart with ${_filteredData.length} items');
    final weightBins = {
      '0-5': 0,
      '5-10': 0,
      '10-15': 0,
      '15-20': 0,
      '>20': 0,
    };

    for (var data in _filteredData) {
      final childInfo = data['data']['childInfo'] as Map<String, dynamic>? ?? {};
      final weight = (childInfo['weightKg'] as num?)?.toDouble() ?? 0;
      if (weight <= 5) {
        weightBins['0-5'] = weightBins['0-5']! + 1;
      } else if (weight <= 10) {
        weightBins['5-10'] = weightBins['5-10']! + 1;
      } else if (weight <= 15) {
        weightBins['10-15'] = weightBins['10-15']! + 1;
      } else if (weight <= 20) {
        weightBins['15-20'] = weightBins['15-20']! + 1;
      } else {
        weightBins['>20'] = weightBins['>20']! + 1;
      }
    }

    final barGroups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: weightBins['0-5']!.toDouble(), color: Colors.blue)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: weightBins['5-10']!.toDouble(), color: Colors.blue)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: weightBins['10-15']!.toDouble(), color: Colors.blue)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: weightBins['15-20']!.toDouble(), color: Colors.blue)]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: weightBins['>20']!.toDouble(), color: Colors.blue)]),
    ];

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['0-5', '5-10', '10-15', '15-20', '>20'];
                return Text(labels[value.toInt()], style: const TextStyle(color: Colors.black, fontSize: 12));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  Widget _buildVaccineTypeBarChart() {
    print('Building Vaccine Type Bar Chart with ${_filteredData.length} items');
    final vaccineTypes = <String, int>{};
    for (var data in _filteredData) {
      final vaccinationDetails = data['data']['vaccinationDetails'] as Map<String, dynamic>? ?? {};
      final vaccineType = vaccinationDetails['vaccineType']?.toString() ?? 'Unknown';
      vaccineTypes[vaccineType] = (vaccineTypes[vaccineType] ?? 0) + 1;
    }

    if (vaccineTypes.isEmpty) {
      return const Center(child: Text('No vaccine type data available.'));
    }

    final barGroups = vaccineTypes.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final vaccineType = entry.value.key;
      final count = entry.value.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: count.toDouble(), color: Colors.green),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final vaccineType = vaccineTypes.keys.toList()[value.toInt()];
                return Text(vaccineType, style: const TextStyle(color: Colors.black, fontSize: 12));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  Widget _buildDoseNumberBarChart() {
    print('Building Dose Number Bar Chart with ${_filteredData.length} items');
    final doseNumbers = <String, int>{};
    for (var data in _filteredData) {
      final vaccinationDetails = data['data']['vaccinationDetails'] as Map<String, dynamic>? ?? {};
      final doseNumber = vaccinationDetails['doseNumber']?.toString() ?? 'Unknown';
      doseNumbers[doseNumber] = (doseNumbers[doseNumber] ?? 0) + 1;
    }

    if (doseNumbers.isEmpty) {
      return const Center(child: Text('No dose number data available.'));
    }

    final barGroups = doseNumbers.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final doseNumber = entry.value.key;
      final count = entry.value.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: count.toDouble(), color: Colors.purple),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final doseNumber = doseNumbers.keys.toList()[value.toInt()];
                return Text(doseNumber, style: const TextStyle(color: Colors.black, fontSize: 12));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  Widget _buildVaccinationOverTimeLineChart() {
    print('Building Vaccinations Over Time Line Chart with ${_filteredData.length} items');
    final vaccinationDates = <DateTime, int>{};
    for (var data in _filteredData) {
      final vaccinationDetails = data['data']['vaccinationDetails'] as Map<String, dynamic>? ?? {};
      final dateString = vaccinationDetails['vaccinationDateTime']?.toString();
      if (dateString != null) {
        final date = DateTime.tryParse(dateString);
        if (date != null) {
          final dayKey = DateTime(date.year, date.month, date.day);
          vaccinationDates[dayKey] = (vaccinationDates[dayKey] ?? 0) + 1;
        }
      }
    }

    if (vaccinationDates.isEmpty) {
      return const Center(child: Text('No vaccination date data available.'));
    }

    final sortedDates = vaccinationDates.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), vaccinationDates[sortedDates[i]]!.toDouble()));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= sortedDates.length) return const Text('');
                final date = sortedDates[value.toInt()];
                return Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
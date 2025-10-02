import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smart_check/pages/homefolder/mapscreen.dart';
import 'package:smart_check/teamController.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class EditTask extends StatelessWidget {
  final String? taskId;
  final Map<String, dynamic>? taskData;

  const EditTask({super.key, this.taskId, this.taskData});

  @override
  Widget build(BuildContext context) {
    return _EditTaskContent(taskId: taskId, taskData: taskData);
  }
}

class _EditTaskContent extends StatefulWidget {
  final String? taskId;
  final Map<String, dynamic>? taskData;

  const _EditTaskContent({this.taskId, this.taskData});

  @override
  State<_EditTaskContent> createState() => _EditTaskContentState();
}

class _EditTaskContentState extends State<_EditTaskContent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final db = FirebaseFirestore.instance;
  final TeamController teamController = Get.find<TeamController>();
  final uuid = const Uuid();

  String selectedPurpose = 'Vaccination';
  LatLng? selectedLocation;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? selectedTime;
  Circle? selectedCircle;
  Polygon? selectedPolygon;

  @override
  void initState() {
    super.initState();
    if (widget.taskData != null) {
      titleController.text = widget.taskData!['title'] ?? '';
      descriptionController.text = widget.taskData!['description'] ?? '';
      selectedPurpose = widget.taskData!['purpose'] ?? 'Vaccination';

      if (widget.taskData!.containsKey('location')) {
        selectedLocation = LatLng(
          widget.taskData!['location']['lat'],
          widget.taskData!['location']['lng'],
        );
      }

      if (widget.taskData!.containsKey('circle')) {
        selectedCircle = Circle(
          circleId: const CircleId("selected-circle"),
          center: LatLng(
            widget.taskData!['circle']['center']['lat'],
            widget.taskData!['circle']['center']['lng'],
          ),
          radius: widget.taskData!['circle']['radius'],
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.2),
        );
      }

      if (widget.taskData!.containsKey('polygon')) {
        selectedPolygon = Polygon(
          polygonId: const PolygonId("selected-polygon"),
          points: (widget.taskData!['polygon']['points'] as List)
              .map((point) => LatLng(point['lat'], point['lng']))
              .toList(),
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.2),
        );
      }

      if (widget.taskData!.containsKey('startDate')) {
        startDate = (widget.taskData!['startDate'] as Timestamp).toDate();
      }
      if (widget.taskData!.containsKey('endDate')) {
        endDate = (widget.taskData!['endDate'] as Timestamp).toDate();
      }
      if (widget.taskData!.containsKey('date')) {
        if (startDate == null) startDate = (widget.taskData!['date'] as Timestamp).toDate();
        if (endDate == null) endDate = (widget.taskData!['date'] as Timestamp).toDate();
      }

      if (widget.taskData!.containsKey('time')) {
        selectedTime = TimeOfDay(
          hour: widget.taskData!['time']['hour'],
          minute: widget.taskData!['time']['minute'],
        );
      }
    }
  }

  void saveTask() async {
    if (titleController.text.isEmpty ||
        teamController.selectedTeamCode.value.isEmpty ||
        selectedLocation == null ||
        startDate == null ||
        endDate == null ||
        selectedTime == null) {
      Get.snackbar(
        "Error",
        "Please enter all task details, including start date, end date, time, and location",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (startDate!.isAfter(endDate!)) {
      Get.snackbar(
        "Error",
        "Start date must be before end date",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    String taskId = widget.taskId ?? uuid.v4();
    String selectedTeamCode = teamController.selectedTeamCode.value;

    try {
      final querySnapshot = await db
          .collection('teams')
          .where('teamCode', isEqualTo: selectedTeamCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String teamDocId = querySnapshot.docs.first.id;

        Map<String, dynamic> taskData = {
          'taskId': taskId,
          'title': titleController.text,
          'description': descriptionController.text,
          'purpose': selectedPurpose,
          'location': {
            'lat': selectedLocation!.latitude,
            'lng': selectedLocation!.longitude,
          },
          'startDate': Timestamp.fromDate(startDate!),
          'endDate': Timestamp.fromDate(endDate!),
          'time': {
            'hour': selectedTime!.hour,
            'minute': selectedTime!.minute,
          },
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (selectedCircle != null) {
          taskData['circle'] = {
            'center': {
              'lat': selectedCircle!.center.latitude,
              'lng': selectedCircle!.center.longitude,
            },
            'radius': selectedCircle!.radius,
          };
        }

        if (selectedPolygon != null) {
          taskData['polygon'] = {
            'points': selectedPolygon!.points
                .map((point) => {'lat': point.latitude, 'lng': point.longitude})
                .toList(),
          };
        }

        await db
            .collection('teams')
            .doc(teamDocId)
            .collection('tasks')
            .doc(taskId)
            .set(taskData);

        Get.snackbar(
          "Success",
          widget.taskId == null ? "Task added successfully" : "Task updated successfully",
          backgroundColor: const Color(0xFF2D6F6F),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
        Navigator.pop(context);
      } else {
        Get.snackbar(
          "Error",
          "Team not found",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save task: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _pickLocation() async {
    Get.to(() => MapScreen(
          initialLocation: selectedLocation ?? const LatLng(0, 0),
          onLocationSelected: (LatLng loc) {
            setState(() {
              selectedLocation = loc;
            });
            Get.back();
          },
          onCircleDrawn: (Circle circle) {
            setState(() {
              selectedCircle = circle;
              selectedPolygon = null;
            });
          },
          onPolygonDrawn: (Polygon polygon) {
            setState(() {
              selectedPolygon = polygon;
              selectedCircle = null;
            });
          },
        ));
  }

  Future<void> _pickStartDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF419C9C),
              onPrimary: Colors.white,
              surface: Color(0xFF263535),
            ),
            dialogBackgroundColor: const Color(0xFF263535),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        startDate = pickedDate;
        if (endDate == null || endDate!.isBefore(pickedDate)) {
          endDate = pickedDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? (startDate ?? DateTime.now()).add(const Duration(days: 1)),
      firstDate: startDate ?? DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF419C9C),
              onPrimary: Colors.white,
              surface: Color(0xFF263535),
            ),
            dialogBackgroundColor: const Color(0xFF263535),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (startDate != null && pickedDate.isBefore(startDate!)) {
        Get.snackbar(
          "Error",
          "End date must be after start date",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      } else {
        setState(() {
          endDate = pickedDate;
        });
      }
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF419C9C),
              onPrimary: Colors.white,
              surface: Color(0xFF263535),
            ),
            dialogBackgroundColor: const Color(0xFF263535),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF419C9C).withOpacity(0.2),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.taskId == null ? "Create New Task" : "Edit Task",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121E1E), Color(0xFF1A2A2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Animated Header
              Lottie.asset(
                'assets/animations/edit_task.json',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
              
              // Form Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2E2E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Details',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF419C9C),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title Field
                    _buildTextField(
                      titleController, 
                      "Task Title*",
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description Field
                    _buildTextField(
                      descriptionController, 
                      "Description",
                      maxLines: 3,
                      icon: Icons.description_rounded,
                    ),
                    const SizedBox(height: 16),
                    
                    // Purpose Dropdown
                    _buildDropdown(),
                    const SizedBox(height: 16),
                    
                    // Location Picker
                    _buildLocationPicker(),
                    const SizedBox(height: 16),
                    
                    // Date and Time Row
                    Row(
                      children: [
                        Expanded(child: _buildStartDatePicker()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildEndDatePicker()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Time Picker
                    _buildTimePicker(),
                    const SizedBox(height: 24),
                    
                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF263535),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF419C9C).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70),
          prefixIcon: icon != null ? Icon(
            icon,
            color: const Color(0xFF419C9C),
            size: 22,
          ) : null,
          border: InputBorder.none,
          contentPadding:  EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 0,
          ),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purpose*',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF263535),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF419C9C).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedPurpose,
            dropdownColor: const Color(0xFF1E2E2E),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: Icon(
                Icons.category_rounded,
                color: const Color(0xFF419C9C),
                size: 22,
              ),
            ),
            isExpanded: true,
            onChanged: (String? newValue) {
              setState(() {
                selectedPurpose = newValue!;
              });
            },
            items: ['Vaccination', 'Humanitarian', 'Distribution']
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location*',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF263535),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF419C9C).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: const Color(0xFF419C9C),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedLocation == null
                        ? "Select Location on Map"
                        : "${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)}",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
        if (selectedLocation != null) ...[
          const SizedBox(height: 8),
          Text(
            'Tap to change location or draw area',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStartDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Date*',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickStartDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF263535),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF419C9C).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: const Color(0xFF419C9C),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  startDate == null
                      ? "Select Date"
                      : DateFormat('MMM dd, yyyy').format(startDate!),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End Date*',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickEndDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF263535),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF419C9C).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: const Color(0xFF419C9C),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  endDate == null
                      ? "Select Date"
                      : DateFormat('MMM dd, yyyy').format(endDate!),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time*',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF263535),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF419C9C).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: const Color(0xFF419C9C),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  selectedTime == null
                      ? "Select Time"
                      : selectedTime!.format(context),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF419C9C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF419C9C).withOpacity(0.5),
        ),
        child: Text(
          widget.taskId == null ? "CREATE TASK" : "UPDATE TASK",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
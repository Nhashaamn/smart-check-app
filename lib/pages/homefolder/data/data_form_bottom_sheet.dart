import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:smart_check/form%20controller.dart';
import 'package:geolocator/geolocator.dart';
import 'data_form_utils.dart';

const Map<String, List<String>> pakistanProvincesAndCities = {
  'Punjab': [
    'Lahore',
    'Faisalabad',
    'Rawalpindi',
    'Multan',
    'Gujranwala',
    'Sialkot',
    'Bahawalpur',
    'Sargodha',
    'Jhang',
    'Sheikhupura',
    'Rahim Yar Khan',
    'Gujrat',
    'Kasur',
    'Sahiwal',
    'Okara',
    'Mianwali',
    'Hafizabad',
    'Attock',
    'Jhelum',
    'Mandi Bahauddin',
  ],
  'Sindh': [
    'Karachi',
    'Hyderabad',
    'Sukkur',
    'Larkana',
    'Nawabshah',
    'Mirpur Khas',
    'Jacobabad',
    'Shikarpur',
    'Khairpur',
    'Dadu',
    'Thatta',
    'Badin',
    'Sanghar',
    'Umerkot',
    'Tando Allahyar',
    'Tando Adam',
    'Kotri',
    'Matiari',
    'Jamshoro',
  ],
  'Khyber Pakhtunkhwa': [
    'Peshawar',
    'Mardan',
    'Abbottabad',
    'Swat',
    'Nowshera',
    'Charsadda',
    'Bannu',
    'Kohat',
    'Mansehra',
    'Dera Ismail Khan',
    'Haripur',
    'Swabi',
    'Karak',
    'Lakki Marwat',
    'Battagram',
    'Shangla',
    'Upper Dir',
    'Lower Dir',
    'Malakand',
  ],
  'Balochistan': [
    'Quetta',
    'Turbat',
    'Khuzdar',
    'Chaman',
    'Gwadar',
    'Dera Bugti',
    'Sibi',
    'Zhob',
    'Loralai',
    'Ziarat',
    'Pishin',
    'Qila Saifullah',
    'Qila Abdullah',
    'Panjgur',
    'Kech',
    'Mastung',
    'Kalat',
    'Nushki',
    'Awaran',
  ],
  'Islamabad Capital Territory': [
    'Islamabad'
  ],
  'Gilgit-Baltistan': [
    'Gilgit',
    'Skardu',
    'Chilas',
    'Ghizer',
    'Astore',
    'Ghanche',
    'Kharmang',
    'Shigar',
    'Nagar',
    'Diamer',
  ],
  'Azad Jammu and Kashmir': [
    'Muzaffarabad',
    'Mirpur',
    'Bhimber',
    'Kotli',
    'Rawalakot',
    'Bagh',
    'Hattian Bala',
    'Neelum',
    'Pallandri',
    'Haveli',
  ],
};

class DataFormBottomSheet extends StatefulWidget {
  final String? imageUrl;
  final DateTime collectionDateTime;

  const DataFormBottomSheet({
    super.key,
    this.imageUrl,
    required this.collectionDateTime,
  });

  @override
  _DataFormBottomSheetState createState() => _DataFormBottomSheetState();
}

class _DataFormBottomSheetState extends State<DataFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController parentNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController batchNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();

  String? gender;
  String? vaccineType;
  String? doseNumber;
  String? selectedProvince;
  String? selectedCity;
  List<String> cities = [];

  Future<String> _generateChildId() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FormController teamController = Get.find<FormController>();

    QuerySnapshot snapshot = await _firestore
        .collection('taskData')
        .where('dataType', isEqualTo: 'vaccination')
        .get();

    int childCount = snapshot.docs.length + 1;
    return 'C${childCount.toString().padLeft(3, '0')}';
  }

  Future<void> _saveData(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final FormController teamController = Get.find<FormController>();
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      String memberName = user.displayName ?? '';
      if (memberName.isEmpty) {
        try {
          final memberDoc = await _firestore
              .collection('teams')
              .doc(teamController.teamId.value)
              .collection('members')
              .doc(user.uid)
              .get();
          if (memberDoc.exists) {
            memberName = memberDoc.data()!['name'] as String? ?? user.uid;
          } else {
            memberName = user.uid;
          }
        } catch (e) {
          memberName = user.uid;
          print('Error fetching member name: $e');
        }
      }

      if (teamController.teamId.value.isEmpty || teamController.teamName.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team not selected')),
        );
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching location: $e')),
        );
        return;
      }

      print('Saving data - TeamName: ${teamController.teamName.value}, TeamId: ${teamController.teamId.value}, AdminId: ${teamController.adminId.value}');
      try {
        String childId = await _generateChildId();

        await _firestore.collection('taskData').add({
          'teamId': teamController.teamId.value,
          'teamName': teamController.teamName.value,
          'adminId': teamController.adminId.value,
          'memberId': user.uid,
          'memberName': memberName,
          'dataType': 'vaccination',
          'data': {
            'childInfo': {
              'childId': childId,
              'fullName': fullNameController.text,
              'gender': gender,
              'dateOfBirthOrAge': dobController.text,
              'weightKg': double.tryParse(weightController.text) ?? 0.0,
              'imageUrl': widget.imageUrl,
              'address': {
                'city': selectedCity ?? '',
                'province': selectedProvince ?? '',
                'latitude': position?.latitude ?? 0.0,
                'longitude': position?.longitude ?? 0.0,
              },
            },
            'parentGuardianInfo': {
              'name': parentNameController.text,
              'contactNumber': contactNumberController.text,
            },
            'vaccinationDetails': {
              'vaccineType': vaccineType,
              'doseNumber': doseNumber,
              'vaccineBatchNumber': batchNumberController.text,
              'vaccineExpiryDate': expiryDateController.text,
              'vaccinationDateTime': DateTime.now().toIso8601String(),
            },
          },
          'timestamp': DateTime.now().toIso8601String(),
          'collectionDateTime': widget.collectionDateTime.toIso8601String(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data saved successfully! Child ID: $childId'),
            backgroundColor: const Color(0xFF419C9C),
          ),
        );
        _resetForm();
      } catch (e) {
        print('Error saving data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    }
  }

  void _resetForm() {
    fullNameController.clear();
    dobController.clear();
    weightController.clear();
    parentNameController.clear();
    contactNumberController.clear();
    batchNumberController.clear();
    expiryDateController.clear();
    setState(() {
      gender = null;
      vaccineType = null;
      doseNumber = null;
      selectedProvince = null;
      selectedCity = null;
      cities = [];
    });
    _pageController.jumpToPage(0);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (expiryDateController.text.isNotEmpty) {
      initialDate = DateTime.parse(expiryDateController.text);
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        expiryDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Widget buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        validator: validator,
      ),
    );
  }

  Widget buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF419C9C)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. Child Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF419C9C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildTextField(fullNameController, 'Full Name'),
                        buildDropdownField(
                          'Gender',
                          gender,
                          ['Male', 'Female', 'Other'],
                          (value) => setState(() => gender = value),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select gender';
                            }
                            return null;
                          },
                        ),
                        buildTextField(
                          dobController,
                          'Age (0-4)',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter age';
                            final age = int.tryParse(value);
                            if (age == null) return 'Age must be a number';
                            if (age >= 5) return 'Age must be less than 5';
                            return null;
                          },
                        ),
                        buildTextField(
                          weightController,
                          'Weight (kg)',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter weight';
                            final weight = double.tryParse(value);
                            if (weight == null) return 'Weight must be a number';
                            return null;
                          },
                        ),
                        buildDropdownField(
                          'Province',
                          selectedProvince,
                          pakistanProvincesAndCities.keys.toList(),
                          (value) {
                            setState(() {
                              selectedProvince = value;
                              selectedCity = null;
                              cities = value != null 
                                  ? pakistanProvincesAndCities[value]! 
                                  : [];
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a province';
                            }
                            return null;
                          },
                        ),
                        buildDropdownField(
                          'City',
                          selectedCity,
                          cities,
                          (value) {
                            setState(() {
                              selectedCity = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a city';
                            }
                            return null;
                          },
                          enabled: selectedProvince != null,
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. Parent/Guardian Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF419C9C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildTextField(parentNameController, 'Name'),
                        buildTextField(
                          contactNumberController, 
                          'Contact Number', 
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter contact number';
                            }
                            if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3. Vaccination Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF419C9C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildDropdownField(
                          'Vaccine Type',
                          vaccineType,
                          ['OPV', 'IPV', 'Others'],
                          (value) => setState(() => vaccineType = value),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select vaccine type';
                            }
                            return null;
                          },
                        ),
                        buildDropdownField(
                          'Dose Number',
                          doseNumber,
                          ['0', '1', '2', '3', 'Booster'],
                          (value) => setState(() => doseNumber = value),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select dose number';
                            }
                            return null;
                          },
                        ),
                        buildTextField(
                          batchNumberController, 
                          'Vaccine Batch Number',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter batch number';
                            }
                            return null;
                          },
                        ),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: buildTextField(
                              expiryDateController,
                              'Vaccine Expiry Date',
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select expiry date';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Vaccination Date & Time: Auto-captured on save',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Previous'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _saveData(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF419C9C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(_currentPage < 2 ? 'Next' : 'Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    fullNameController.dispose();
    dobController.dispose();
    weightController.dispose();
    parentNameController.dispose();
    contactNumberController.dispose();
    batchNumberController.dispose();
    expiryDateController.dispose();
    super.dispose();
  }
}
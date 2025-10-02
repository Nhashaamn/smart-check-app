import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart'; // For formatting date and time
import 'data_form_bottom_sheet.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  Uint8List? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  late DateTime _collectionDateTime; // To store date and time of data collection

  @override
  void initState() {
    super.initState();
    _collectionDateTime = DateTime.now(); // Capture date and time on init
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dcvgxw0so/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'profile'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _selectedImage!,
          filename: 'child_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString) as Map<String, dynamic>;
        final imageUrl = jsonMap['secure_url'] as String;
        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error uploading image: $e',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _proceedToForm() async {
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) return;
    }

    // Update collection date and time when proceeding to form
    setState(() {
      _collectionDateTime = DateTime.now();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFF263535),
      builder: (context) => DataFormBottomSheet(
        imageUrl: imageUrl,
        collectionDateTime: _collectionDateTime, // Pass the date and time
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format the date and time for display
    String formattedDateTime = DateFormat('MMM d, yyyy h:mm a').format(_collectionDateTime);

    return Scaffold(
      backgroundColor: const Color(0xFF1A2A2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF419C9C), Color(0xFF2D6F6F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        title: Text(
          'Upload Child Image',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A2A2A),
              const Color(0xFF263535).withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Date and Time Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF263535),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Collected on: $formattedDateTime',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Lottie Animation
                Lottie.asset(
                  'assets/animations/upload_image.json',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
                const SizedBox(height: 20),
                // Image Display
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3E3E),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _selectedImage == null
                      ? Column(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: Colors.white70,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No image selected',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _selectedImage!,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
                // Camera and Gallery Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      gradientColors: const [Color(0xFF419C9C), Color(0xFF2D6F6F)],
                    ),
                    const SizedBox(width: 20),
                    _buildButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      gradientColors: const [Color(0xFF419C9C), Color(0xFF2D6F6F)],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Proceed Button
                _buildButton(
                  onPressed: _isUploading ? null : _proceedToForm,
                  icon: null,
                  label: _isUploading ? 'Uploading...' : 'Proceed to Form',
                  showLoading: _isUploading,
                  width: 220,
                  gradientColors: const [Color(0xFF4DB6AC), Color(0xFF26A69A)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    bool showLoading = false,
    double? width,
    required List<Color> gradientColors,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: onPressed != null ? gradientColors : [Colors.grey, Colors.grey],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
              ],
              showLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
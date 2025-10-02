import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final Future<void> Function() onPressed; // Updated to handle async callback
  final String label; // Button label

  const CustomButton({
    super.key,
    required this.onPressed,
    this.label = "Login", // Default label
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await onPressed(); // Handle the async call correctly
        } catch (e) {
          // You can handle any exceptions here
          print("Error occurred: $e");
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF419C9C),
        padding: const EdgeInsets.symmetric(
          horizontal: 80,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        
        label, // Use the passed label
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

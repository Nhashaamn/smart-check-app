import 'package:flutter/material.dart';

Widget buildTextField(
  TextEditingController controller,
  String label, {
  TextInputType keyboardType = TextInputType.text,
  bool readOnly = false,
  String? Function(String?)? validator, // Add validator parameter
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(color: Colors.white), // Set label text color to white
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF419C9C)),
        ),
      ),
      style: const TextStyle(color: Colors.white), // Set input text color to white
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator, // Pass the validator to TextFormField
    ),
  );
}

Widget buildDropdownField(
  String label,
  String? value,
  List<String> items,
  void Function(String?) onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(color: Colors.white), // Set label text color to white
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF419C9C)),
        ),
      ),
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white), // Set dropdown item text color to white
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select an option' : null,
    ),
  );
}
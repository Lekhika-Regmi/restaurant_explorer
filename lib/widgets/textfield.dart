import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hint,
    required this.label,
    this.controller,
    this.isPassword = false,
  });
  final String hint;
  final String label;
  final bool isPassword;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: Colors.black87,
      obscureText: isPassword,
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black87),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 18,
        ),
        label: Text(
          label,
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w400),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.black54, width: 2),
        ),
      ),
    );
  }
}

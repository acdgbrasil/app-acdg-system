import 'package:flutter/material.dart';
import 'package:social_care/src/ui/home/constants/home_ln10.dart';

class NewRegistrationFab extends StatelessWidget {
  final VoidCallback onPressed;

  const NewRegistrationFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      right: 32,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF4F8448),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          HomeLn10.newRegistration,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

class SuccessScreen extends StatefulWidget {
  final int pointsEarned;
  
  const SuccessScreen({super.key, required this.pointsEarned});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate back to the home screen automatically after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Use popUntil to clear all screens above the home screen
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation/Icon
            Icon(
              Icons.check_circle_rounded,
              size: 150,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 30),
            
            // Success Message
            Text(
              'SUCCESS!',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 10),
            
            // Points Earned
            Text(
              'You earned ${widget.pointsEarned} Eco-Points! 🌿',
              style: const TextStyle(fontSize: 22, color: Colors.black87),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
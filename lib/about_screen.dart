
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Mission', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Medicine Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Welcome to Pharma Finder, the first system to link medicine disposal and pharmacy availability.',
              style: TextStyle(fontSize: 16),
            ),
            const Divider(height: 32),

            // --- Environmental Impact ---
            _buildSection(
              context,
              Icons.water_damage,
              'Stop Water Pollution',
              'We prevent hazardous chemicals from entering rivers and the drinking supply by ensuring unused or expired medicine is disposed of safely at certified return boxes.',
            ),
            const SizedBox(height: 20),

            // --- Consumer Utility ---
            _buildSection(
              context,
              Icons.location_on,
              'Find Stock in Real-Time',
              'Stop wasting trips! We provide live stock status and distance for nearby pharmacies, ensuring you always get what you need.',
            ),
            const SizedBox(height: 20),

            // --- Gamification ---
            _buildSection(
              context,
              Icons.emoji_events,
              'Earn Eco-Points',
              'Your rewards system for being responsible. Scan a return box QR code to instantly earn points redeemable for discounts, coupons, or local donations.',
            ),
            const SizedBox(height: 40),

            Center(
              child: Text(
                'Built with Flutter & Firebase. Version 1.0 Prototype.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for consistent section styling
  Widget _buildSection(BuildContext context, IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
        ),
      ],
    );
  }
}
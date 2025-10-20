import 'package:flutter/material.dart';
import 'stock_update_screen.dart';
import '../rewards_screen.dart';
import 'admin_returns_log_screen.dart'; 

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Stock Management'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // TODO: Implement Admin Logout
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                'Welcome, Pharmacist!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Manage Inventory & Returns for your Pharmacy.',
                  textAlign: TextAlign.center,
                ),
              ),
              // --- CORE ADMIN FEATURE BUTTON (NOW ENABLED) ---
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the Stock Update Form
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const StockUpdateScreen())
                  );
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Update Medicine Stock', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // --- VIEW RETURNS LOG BUTTON (NOW FUNCTIONAL) ---
              TextButton.icon(
                onPressed: () {
                  // Navigate to the comprehensive Admin Log screen
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const AdminReturnsLogScreen(),
                    )
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View Returns Log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// In lib/stock_update_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockUpdateScreen extends StatefulWidget {
  const StockUpdateScreen({super.key});

  @override
  State<StockUpdateScreen> createState() => _StockUpdateScreenState();
}

class _StockUpdateScreenState extends State<StockUpdateScreen> {
  final _medicineNameController = TextEditingController();
  String? _selectedStatus; // New stock status selected by the pharmacist
  bool _isUpdating = false;

  final List<String> _stockOptions = ['In Stock', 'Low Stock', 'Out of Stock'];

  Future<void> _updateStock() async {
    final medicineName = _medicineNameController.text.trim();
    if (medicineName.isEmpty || _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name and select a status.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isUpdating = true; });

    try {
      // NOTE: For a real app, this would use the pharmacist's specific ID and their pharmacy ID.
      // We will update the first inventory document we find matching the name.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pharmacyInventory')
          .where('medicineName', isEqualTo: medicineName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine not found in inventory.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      // Update the stock status of the found document
      final docRef = querySnapshot.docs.first.reference;
      await docRef.update({'stockStatus': _selectedStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock status updated to: $_selectedStatus'), backgroundColor: Colors.green),
        );
        _medicineNameController.clear();
        setState(() {
          _selectedStatus = null;
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isUpdating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Stock Status'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Medicine Name (Case Sensitive)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Medicine Name Input
            TextField(
              controller: _medicineNameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Dolo 650',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            
            // Stock Status Dropdown
            const Text(
              'New Stock Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select New Status',
              ),
              items: _stockOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedStatus = newValue;
                });
              },
            ),
            const SizedBox(height: 50),
            
            // Update Button
            ElevatedButton(
              onPressed: _isUpdating ? null : _updateStock,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: _isUpdating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Apply Stock Update', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
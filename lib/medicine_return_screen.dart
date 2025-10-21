import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'success_screen.dart'; 

class MedicineReturnScreen extends StatefulWidget {
  final String qrCodeValue;
  final String userId; 

  const MedicineReturnScreen({super.key, required this.qrCodeValue, required this.userId});

  @override
  State<MedicineReturnScreen> createState() => _MedicineReturnScreenState();
}

class _MedicineReturnScreenState extends State<MedicineReturnScreen> {
  final _medicineNameController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isExpired = true;
  bool _isSaving = false;
  final int _pointsAwarded = 25; // Define the points here

  Future<void> _saveReturn() async {
    if (_medicineNameController.text.isEmpty || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isSaving = true; });

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(widget.userId);
    final returnRef = firestore.collection('medicineReturns').doc();

    try {
      // Use a transaction to ensure both operations succeed or fail together
      await firestore.runTransaction((transaction) async {
        // 1. Save the new medicine return document
        transaction.set(returnRef, {
          'medicineName': _medicineNameController.text,
          'quantity': int.tryParse(_quantityController.text) ?? 0,
          'isExpired': _isExpired,
          'qrCodeValue': widget.qrCodeValue,
          'returnedAt': Timestamp.now(),
          'userId': widget.userId,
        });

        // 2. Add points to the user's ecoPoints
        transaction.update(userRef, {
          'ecoPoints': FieldValue.increment(_pointsAwarded),
        });
      });

      if (context.mounted) {
        // --- FIX IS HERE: Correctly navigating to the imported widget ---
        Navigator.pushReplacement( 
          context,
          MaterialPageRoute(
            // The widget name must match the class name exactly
            builder: (context) => SuccessScreen(pointsEarned: _pointsAwarded), 
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (context.mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Medicine Return'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Return Box ID: ${widget.qrCodeValue}', style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(controller: _medicineNameController, decoration: const InputDecoration(labelText: 'Medicine Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is this medicine expired?'),
              value: _isExpired,
              onChanged: (bool value) { setState(() { _isExpired = value; }); },
              secondary: Icon(_isExpired ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: _isExpired ? Colors.orange : Colors.green),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: _isSaving ? null : _saveReturn,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirm Return', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
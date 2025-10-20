// In lib/admin_returns_log_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class AdminReturnsLogScreen extends StatelessWidget {
  const AdminReturnsLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: All Returns Log'),
        backgroundColor: Colors.indigo,
        elevation: 4,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'View of all returns system-wide for monitoring and redistribution planning.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          
          // List of ALL Returns (Not filtered by a single user)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // CRUCIAL: Fetching ALL documents from the collection
              stream: FirebaseFirestore.instance
                  .collection('medicineReturns')
                  .orderBy('returnedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error connecting to log database.', style: TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No returns have been logged in the system.'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp timestamp = data['returnedAt'] ?? Timestamp.fromDate(DateTime(0));
                    final date = DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());

                    // Display key data for administration
                    return ListTile(
                      leading: Icon(
                        data['isExpired'] ? Icons.delete_forever : Icons.check_circle_outline,
                        color: data['isExpired'] ? Colors.red : Colors.green,
                      ),
                      title: Text(
                        '${data['medicineName']} (${data['quantity']} units)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Logged by User ID: ${data['userId'].substring(0, 8)}... on $date',
                      ),
                      trailing: Text(
                        data['isExpired'] ? 'EXPIRED' : 'REUSABLE',
                        style: TextStyle(color: data['isExpired'] ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
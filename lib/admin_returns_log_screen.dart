
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class AdminReturnsLogScreen extends StatelessWidget {
  const AdminReturnsLogScreen({super.key});

  // Function to update the status of a returned item
  Future<void> _updateDisposalStatus(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medicineReturns')
          .doc(docId)
          .update({'disposalStatus': 'Ready for Redistribution'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status Updated to Redistribution!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: All Returns Log'),
        backgroundColor: Colors.indigo,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Master log for monitoring and redistribution planning.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                    final isExpired = data['isExpired'] ?? false;
                    final currentStatus = data['disposalStatus'] ?? 'Awaiting Review';

                    return ListTile(
                      leading: Icon(
                        isExpired ? Icons.delete_forever : Icons.check_circle_outline,
                        color: isExpired ? Colors.red : Colors.green,
                      ),
                      title: Text(
                        '${data['medicineName']} (${data['quantity']} units)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'User ID: ${data['userId'].substring(0, 8)}... | Returned on $date',
                      ),
                      trailing: currentStatus == 'Ready for Redistribution'
                          ? const Text('READY', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                          : TextButton(
                              onPressed: isExpired
                                  ? null // Cannot redistribute expired items
                                  : () => _updateDisposalStatus(context, doc.id),
                              child: const Text('Mark Ready', style: TextStyle(fontWeight: FontWeight.bold)),
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
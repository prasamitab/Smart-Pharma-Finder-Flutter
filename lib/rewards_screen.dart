import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class RewardsScreen extends StatelessWidget {
  final String userId; 

  const RewardsScreen({super.key, required this.userId});

  // Function to handle the point redemption transaction
  Future<void> _redeemPoints(BuildContext context, int currentPoints, String currentUserId) async {
    const int redemptionCost = 100;

    if (currentPoints < redemptionCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points. Need 100 to redeem!'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    // Start the safe transaction process
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Fetch the user's current data within the transaction
        final userSnapshot = await transaction.get(
          FirebaseFirestore.instance.collection('users').doc(currentUserId)
        );
        
        // 2. Read the current points (re-check for security/race conditions)
        final currentPointsInDb = userSnapshot.data()?['ecoPoints'] ?? 0;

        if (currentPointsInDb >= redemptionCost) {
          // 3. Update the document: deduct points and increment the counter
          transaction.update(userSnapshot.reference, {
            'ecoPoints': FieldValue.increment(-redemptionCost), // Deduct 100 points
            'redeemedCount': FieldValue.increment(1),          // Track redemption count
          });
        } else {
          // If the points suddenly dropped below 100 during the transaction
          throw Exception("Points check failed during transaction.");
        }
      });

      // Success Message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon Redeemed! 100 Eco-Points spent.'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redemption Failed: Check points and try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards & History'),
      ),
      body: Column(
        children: [
          // 1. Total Points Card (Live Data)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('User not found.');
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final int ecoPoints = userData['ecoPoints'] ?? 0;

                return Card(
                  elevation: 4,
                  color: Colors.teal,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Total Eco Points', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('$ecoPoints 🌿', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        // --- REDEEM BUTTON WITH LOGIC ---
                        ElevatedButton(
                          onPressed: () => _redeemPoints(context, ecoPoints, userId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal,
                          ),
                          child: const Text('Redeem Points / Coupons'),
                        ),
                        // --- END REDEEM BUTTON ---
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. History Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Return History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),

          // 3. Return History List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicineReturns')
                  .where('userId', isEqualTo: userId)
                  .orderBy('returnedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading history.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No return history found.'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp timestamp = data['returnedAt'] ?? Timestamp.fromDate(DateTime(0));
                    final date = DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());
                    final points = 25; // Points earned per transaction

                    return ListTile(
                      leading: Icon(
                        data['isExpired'] ? Icons.delete_forever : Icons.recycling,
                        color: data['isExpired'] ? Colors.red : Colors.green,
                      ),
                      title: Text('${data['medicineName']} (${data['quantity']} units)'),
                      subtitle: Text('Returned on $date'),
                      trailing: Text('+$points Pts', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
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
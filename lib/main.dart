import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pharmacy_finder_screen.dart';
import 'qr_scanner_screen.dart';
import 'medicine_return_screen.dart';
import 'rewards_screen.dart';
import 'map_screen.dart';
import 'auth_screen.dart';
import 'chatbot_screen.dart'; 
import 'admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharma Finder',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // --- AUTH GATE: Checks if user is logged in ---
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasData) {
            // User is logged in, pass the real UID to HomeScreen
            final currentUserId = userSnapshot.data!.uid;
            return HomeScreen(userId: currentUserId); 
          }
          // User is NOT logged in, show the Auth screen
          return const AuthScreen(); 
        },
      ),
      // --- END OF AUTH GATE ---
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- UPDATED HOMESCREEN: Accepts the real userId ---
class HomeScreen extends StatelessWidget {
  final String userId; 
  
  const HomeScreen({super.key, required this.userId}); 

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 4,
        actions: [
          // 1. TEMPORARY ADMIN ACCESS BUTTON (NEW)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
            onPressed: () {
              // Navigate to the Admin Dashboard Screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
            },
            tooltip: 'Admin Access',
          ),
          
          // 2. Launch Chatbot Button
          IconButton(
            icon: const Icon(Icons.forum, color: Colors.blueGrey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
            },
            tooltip: 'Chat with Eco-Bot',
          ),
          
          // 3. User Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PharmacyFinderScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Text('Find Medicine Near Me...', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Return Medicines Card
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () async {
                  final qrCodeResult = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                  );
                  if (qrCodeResult != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicineReturnScreen(
                          qrCodeValue: qrCodeResult,
                          userId: userId, // PASSING THE REAL UID
                        ),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.teal, size: 28),
                      SizedBox(width: 12),
                      Text('Return Medicines', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // My Points & Rewards Card (with StreamBuilder)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RewardsScreen(userId: userId)), // PASSING THE REAL UID
                );
              },
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(), // Using the real UID
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(child: Padding(padding: EdgeInsets.all(30.0), child: Center(child: CircularProgressIndicator())));
                  }
                  if (snapshot.hasError) {
                    return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text('Error loading points.'))));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text('User not found. Please register a new account.'))));
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final int ecoPoints = userData['ecoPoints'] ?? 0;

                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'My Points & Rewards',
                            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$ecoPoints Eco-Points',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // "Did You Know?" Tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💡 Did you know? Flushing unused medicines pollutes our rivers and drinking water.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
      // --- MAP BUTTON INSERTION ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.map, color: Colors.white),
      ),
      // --- END OF MAP BUTTON INSERTION ---
    );
  }
}
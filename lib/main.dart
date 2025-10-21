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
import 'about_screen.dart';
import 'profile_screen.dart'; // NEW: Profile Screen Import
import 'package:google_fonts/google_fonts.dart';

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
    // Define the professional primary color
    const Color primaryTeal = Color(0xFF00796B); 

    return MaterialApp(
      title: 'Pharma Finder',
      theme: ThemeData(
        primaryColor: primaryTeal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.montserrat().fontFamily,
      ),
      // --- AUTH GATE ---
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasData) {
            final currentUserId = userSnapshot.data!.uid;
            return HomeScreen(userId: currentUserId); 
          }
          return const AuthScreen(); 
        },
      ),
      // --- END OF AUTH GATE ---
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- POLISHED HOMESCREEN ---
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
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor, 
        actions: [
          // 1. NEW: Profile/Settings Icon (Replaces the old Logout Button's position)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile & Settings',
          ),

          // 2. TEMPORARY ADMIN ACCESS BUTTON 
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
            },
            tooltip: 'Admin Access',
          ),
          
          // 3. Launch Chatbot Button
          IconButton(
            icon: const Icon(Icons.forum, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
            },
            tooltip: 'Chat with Eco-Bot',
          ),
          
          // 4. About/Mission Button
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
            tooltip: 'Our Mission & About Us',
          ),
        ],
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar (Polished Look)
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
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 10),
                    Text('Find Medicine Near Me...', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Return Medicines Card (Enhanced Styling)
            Card(
              elevation: 4, 
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
                          userId: userId,
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Theme.of(context).primaryColor, size: 32),
                      const SizedBox(width: 16),
                      const Text('RETURN MEDICINES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // My Points & Rewards Card (Enhanced Styling)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RewardsScreen(userId: userId)),
                );
              },
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(child: Padding(padding: EdgeInsets.all(30.0), child: Center(child: CircularProgressIndicator())));
                  }
                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return const Card(child: Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text('User data error.'))));
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final int ecoPoints = userData['ecoPoints'] ?? 0;

                  return Card(
                    elevation: 4,
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'MY POINTS & REWARDS',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$ecoPoints 🌿',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).primaryColor,
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

            // "Did You Know?" Tip (Polished)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flushing unused meds pollutes our rivers!',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                ],
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
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.map, color: Colors.white),
      ),
      // --- END OF MAP BUTTON INSERTION ---
    );
  }
}
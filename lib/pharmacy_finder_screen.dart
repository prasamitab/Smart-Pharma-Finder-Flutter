
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

// Helper class for LatLng (from your existing map implementation)
class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class PharmacyFinderScreen extends StatefulWidget {
  const PharmacyFinderScreen({super.key});

  @override
  State<PharmacyFinderScreen> createState() => _PharmacyFinderScreenState();
}

class _PharmacyFinderScreenState extends State<PharmacyFinderScreen> {
  LatLng? _currentLocation; // Will store the live location
  bool _isLoading = false;
  List<Map<String, dynamic>> _pharmacyResults = [];
  final TextEditingController _searchController = TextEditingController();

  // Helper function to calculate distance (in km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
  
  // 1. Function to get user's live location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied.'), backgroundColor: Colors.red),
      );
    }
  }
  
  // 2. Function to launch phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. function to launch map for navigation 
  Future<void> _launchMap(double lat, double lon) async {
    // Universal Google Maps format: opens the Google Maps app or website for directions (daddr).
    // This is the most reliable cross-platform link.
    final urlString = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    final url = Uri.parse(urlString); 
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch map application.'), backgroundColor: Colors.red),
      );
    }
  }

  // 4. UPDATED Search Function (Fuzzy Search/Case Insensitivity)
  Future<void> _searchPharmacies(String medicineName) async {
    if (medicineName.isEmpty) {
      setState(() { _pharmacyResults = []; });
      return;
    }

    setState(() { _isLoading = true; });
    
    // Normalize query to lowercase (Requires database names to be lowercase!)
    final String normalizedQuery = medicineName.toLowerCase().trim();
    
    await _getCurrentLocation();
    
    if (_currentLocation == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      // Query the all-lowercase database field
      final inventoryQuery = await FirebaseFirestore.instance
          .collection('pharmacyInventory')
          .where('medicineName', isEqualTo: normalizedQuery) 
          .where('stockStatus', whereIn: ['In Stock', 'Low Stock'])
          .get();

      if (inventoryQuery.docs.isEmpty) {
        setState(() { _isLoading = false; _pharmacyResults = []; });
        return;
      }

      final pharmacyIds = inventoryQuery.docs.map((doc) => doc['pharmacyId']).toList();

      final pharmacyQuery = await FirebaseFirestore.instance
          .collection('pharmacies')
          .where(FieldPath.documentId, whereIn: pharmacyIds)
          .get();

      List<Map<String, dynamic>> finalResults = [];

      for (var doc in pharmacyQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final GeoPoint? location = data['location'] as GeoPoint?;
        
        // Skip this pharmacy if location data is missing/null
        if (location == null) continue;

        final distance = _calculateDistance(
          _currentLocation!.latitude, 
          _currentLocation!.longitude,
          location.latitude,
          location.longitude,
        );

        finalResults.add({
          'id': doc.id,
          'name': data['name'],
          'address': data['address'],
          'rating': data['rating'],
          'distance': distance,
          'lat': location.latitude,
          'lon': location.longitude,
          'stockStatus': inventoryQuery.docs
            .firstWhere((invDoc) => invDoc['pharmacyId'] == doc.id)['stockStatus'],
          'phoneNumber': '9988776655', // Placeholder phone number
        });
      }

      // Sort by distance (Highlight Nearest)
      finalResults.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        _pharmacyResults = finalResults;
        _isLoading = false;
      });

    } catch (e) {
      setState(() { _isLoading = false; });
      print("An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Medicine', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField( 
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter medicine name (e.g., dolo 650)',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _searchPharmacies(''); }),
              ),
              onChanged: (value) { _searchPharmacies(value); },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pharmacyResults.isEmpty
                      ? Center(child: Text(_currentLocation == null ? 'Acquiring location...' : 'No stock found for this medicine near you.'))
                      : ListView.builder(
                          itemCount: _pharmacyResults.length,
                          itemBuilder: (context, index) {
                            final pharmacy = _pharmacyResults[index];
                            final isNearest = index == 0; 

                            Color stockColor = Colors.grey;
                            if (pharmacy['stockStatus'] == 'In Stock') {
                              stockColor = Colors.green;
                            } else if (pharmacy['stockStatus'] == 'Low Stock') {
                              stockColor = Colors.orange;
                            }
                            
                            // Polished UI Elements
                            final cardColor = isNearest ? Colors.teal.shade50 : Colors.white;

                            return Card(
                              elevation: isNearest ? 6 : 2, 
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 12), 
                              child: Column(
                                children: [
                                  if (isNearest) 
                                    Container(
                                      color: Theme.of(context).primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      width: double.infinity,
                                      child: const Text('🌟 CLOSEST PHARMACY', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.local_pharmacy, 
                                      color: Theme.of(context).primaryColor,
                                      size: 30,
                                    ),
                                    title: Text(
                                      pharmacy['name'],
                                      style: TextStyle(fontWeight: isNearest ? FontWeight.w900 : FontWeight.bold, fontSize: 17),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(pharmacy['address']),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            // Distance and Rating
                                            Icon(Icons.near_me, color: Colors.blue, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${pharmacy['distance'].toStringAsFixed(1)} km',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(Icons.star, color: Colors.amber, size: 16),
                                            Text('${pharmacy['rating'].toString()}'),
                                          ],
                                        )
                                      ],
                                    ),
                                    trailing: Container(
                                      // Stock Status Pill Badge
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: stockColor,
                                        borderRadius: BorderRadius.circular(20), // Pill Shape
                                      ),
                                      child: Text(
                                        pharmacy['stockStatus'],
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  // Call / Navigate Buttons
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Polished Call Button
                                        OutlinedButton.icon(
                                          onPressed: () => _makePhoneCall(pharmacy['phoneNumber']), 
                                          icon: const Icon(Icons.call, size: 18),
                                          label: const Text('CALL'),
                                        ),
                                        const SizedBox(width: 8),
                                        // Polished Navigate Button
                                        ElevatedButton.icon(
                                          onPressed: () => _launchMap(pharmacy['lat'], pharmacy['lon']),
                                          icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
                                          label: const Text('NAVIGATE', style: TextStyle(color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).primaryColor, 
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
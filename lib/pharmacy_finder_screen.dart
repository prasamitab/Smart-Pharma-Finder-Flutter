// In lib/pharmacy_finder_screen.dart

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
  
  // 1. New function to get user's live location
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
    
    // If permission is granted (or already granted), get position
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied.'), backgroundColor: Colors.red),
      );
    }
  }
  
  // 2. Updated function to launch phone dialer
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

  // 3. Updated function to launch map for navigation
  // Action to launch map for navigation (CORRECTED)
Future<void> _launchMap(double lat, double lon) async {
  final urlString = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
  final url = Uri.parse(urlString); 
  
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not launch map to $lat,$lon'), backgroundColor: Colors.red),
    );
  }
}

  Future<void> _searchPharmacies(String medicineName) async {
    if (medicineName.isEmpty) {
      setState(() { _pharmacyResults = []; });
      return;
    }

    setState(() { _isLoading = true; });

    // Step 0: Get the user's current location
    await _getCurrentLocation();
    
    // If we can't get location, we can't calculate distance. Return an empty list for now.
    if (_currentLocation == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final inventoryQuery = await FirebaseFirestore.instance
          .collection('pharmacyInventory')
          .where('medicineName', isEqualTo: medicineName)
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
        final GeoPoint location = data['location'];
        
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
        title: const Text('Find Medicine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField( /* ... search bar ... */
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter medicine name (e.g., Dolo 650)',
                prefixIcon: const Icon(Icons.search),
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
                      ? Center(child: Text(_currentLocation == null ? 'Acquiring location...' : 'Type a medicine name to begin search.'))
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
                            
                            final cardColor = isNearest ? Colors.teal.shade50 : Colors.white;

                            return Card(
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      Icons.local_pharmacy, 
                                      color: isNearest ? Colors.teal : Colors.grey.shade700,
                                    ),
                                    title: Text(
                                      pharmacy['name'],
                                      style: TextStyle(fontWeight: isNearest ? FontWeight.bold : FontWeight.normal),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(pharmacy['address']),
                                        Row(
                                          children: [
                                            // Distance and Rating
                                            Text(
                                              '${pharmacy['distance'].toStringAsFixed(1)} km away',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.star, color: Colors.amber, size: 16),
                                            Text('${pharmacy['rating'].toString()}'),
                                          ],
                                        )
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: stockColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        pharmacy['stockStatus'],
                                        style: TextStyle(color: stockColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  // Call / Navigate Buttons
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _makePhoneCall(pharmacy['phoneNumber']), // Use the number from the data
                                          icon: const Icon(Icons.call, color: Colors.blue),
                                          label: const Text('Call'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _launchMap(pharmacy['lat'], pharmacy['lon']),
                                          icon: const Icon(Icons.navigation, color: Colors.green),
                                          label: const Text('Navigate'),
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
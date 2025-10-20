
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Start location set near Secunderabad for testing
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(17.4399, 78.4983),
    zoom: 14,
  );

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadPharmacyMarkers();
  }

  // Function to load all pharmacies from Firestore and create markers
  Future<void> _loadPharmacyMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('pharmacies').get();
    
    final newMarkers = snapshot.docs.map((doc) {
      final data = doc.data();
      final GeoPoint location = data['location'];
      
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: data['name'],
          snippet: data['address'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Use green for eco-friendly
      );
    }).toSet();

    setState(() {
      _markers.addAll(newMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy & Return Map'),
        backgroundColor: Colors.teal,
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        mapType: MapType.normal,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }
}
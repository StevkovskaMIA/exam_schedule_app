import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final Map<DateTime, List<String>> events;

  const MapScreen({super.key, required this.events});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadEventMarkers();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
    });
  }

  void _loadEventMarkers() {
    Set<Marker> markers = {};
    widget.events.forEach((date, events) {
      for (var event in events) {
        if (event.toLowerCase().contains('exam')) {
          if (event.contains('Location:')) {
            final location = event.split('Location:')[1].trim();
            final latLng = _parseLocation(location);

            if (latLng != null) {
              markers.add(
                Marker(
                  markerId: MarkerId(event),
                  position: latLng,
                  infoWindow: InfoWindow(title: event),
                ),
              );
            }
          }
        }
      }
    });

    setState(() {
      _markers = markers;
    });
  }

  LatLng? _parseLocation(String location) {
    try {
      final parts = location.split(',');
      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);
      return LatLng(lat, lng);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map of Events'),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}

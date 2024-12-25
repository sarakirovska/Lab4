import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/exam_event.dart';

class MapScreen extends StatefulWidget {
  final ExamEvent event;

  MapScreen({required this.event});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are denied.'),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      if (_currentPosition != null) {
        await _getRoute();
        _fitBounds();
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location: $e'),
        ),
      );
    }
  }

  void _fitBounds() {
    if (_currentPosition != null && _mapController != null) {
      final bounds = LatLngBounds(
        LatLng(
          min(_currentPosition!.latitude, widget.event.location.latitude),
          min(_currentPosition!.longitude, widget.event.location.longitude),
        ),
        LatLng(
          max(_currentPosition!.latitude, widget.event.location.latitude),
          max(_currentPosition!.longitude, widget.event.location.longitude),
        ),
      );

      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(
          padding: EdgeInsets.all(50.0),
        ),
      );
    }
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/'
          '${_currentPosition!.longitude},${_currentPosition!.latitude};'
          '${widget.event.location.longitude},${widget.event.location.latitude}'
          '?overview=full&geometries=geojson'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            _routePoints = coordinates
                .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
                .toList();
          });
        }
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      print('Error getting route: $e');
      setState(() {
        _routePoints = [
          _currentPosition!,
          widget.event.location,
        ];
      });
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Локација на испит'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.event.location,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: widget.event.location,
                          child: Column(
                            children: [
                              Text('Exam Location'),
                              Icon(
                                Icons.location_on,
                                color: const Color.fromARGB(255, 123, 10, 83),
                                size: 40.0,
                              ),
                            ],
                          ),
                        ),
                        if (_currentPosition != null)
                          Marker(
                            width: 40.0,
                            height: 40.0,
                            point: _currentPosition!,
                            child: Column(
                              children: [
                                Text('You'),
                                Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 40.0,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: Colors.blue,
                            strokeWidth: 3.0,
                          ),
                        ],
                      ),
                  ],
                ),
                if (_isLoadingRoute)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Your Location: ${_currentPosition?.latitude ?? "-"}, ${_currentPosition?.longitude ?? "-"}',
                ),
                Text(
                  'Exam Location: ${widget.event.location.latitude}, ${widget.event.location.longitude}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

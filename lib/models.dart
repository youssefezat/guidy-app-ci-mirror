import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

// 1. Represents a physical station (Metro/Bus)
class Station {
  final String name;
  final LatLng coords;
  final int line;

  Station({required this.name, required this.coords, required this.line});
}

// 2. Represents one of the routing results (Fastest, Cheapest, etc.)
class RouteOption {
  final String type; // e.g., "Fastest"
  final String description; // e.g., "Optimized by ACO"
  final int durationMinutes;
  final String price;
  final List<LatLng> polylinePoints;
  final Color routeColor;

  RouteOption({
    required this.type,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.polylinePoints,
    required this.routeColor,
  });
}

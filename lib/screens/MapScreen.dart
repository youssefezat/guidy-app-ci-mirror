import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/instruction_formatter.dart';
import '../services/metro_ticket_advisor.dart';
import '../services/transit_modes.dart';
import '../services/trip_sharing_service.dart';
import '../services/saved_trips_service.dart';
import '../services/trip_history_service.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../services/live_tracking_service.dart';
import '../services/map_marker_service.dart';
import '../widgets/quick_commute_report_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_placeholder.dart';

/// Representation of an active turn-by-turn guidance maneuver.
class WalkManeuverInfo {
  final IconData icon;
  final String? iconKey;
  final String headline;
  final String subline;
  final bool isProximityAlert;

  const WalkManeuverInfo({
    required this.icon,
    this.iconKey,
    required this.headline,
    required this.subline,
    this.isProximityAlert = false,
  });
}

/// Turn-by-turn navigation with high-DPI custom markers,
/// styled walking vs. transit polylines, auto-framing,
/// stop proximity alarms, and Egyptian transit localizations.
class MapScreen extends StatefulWidget {
  final Map<String, dynamic> pathData;

  const MapScreen({super.key, required this.pathData});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Set<Polyline> _routePolylines = {};
  final List<LatLng> _allPoints = [];
  final List<List<LatLng>> _walkSegments = [];
  Color _mainRouteColor = AppColors.primaryTeal;
  List<dynamic> _instructions = [];
  final List<LatLng?> _stepPoints = [];

  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _endIcon;
  BitmapDescriptor? _transferIcon;
  BitmapDescriptor? _stationIcon;
  Set<Marker> _markers = {};
  num? _asNum(dynamic val) => InstructionFormatter.asNum(val);

  bool _stopAlarmEnabled = true;
  bool _stopAlarmTriggeredForCurrent = false;
  String? _upcomingAlarmStation;
  String _destinationTitle = '';

  final ValueNotifier<LatLng?> _currentLocation = ValueNotifier(null);
  final ValueNotifier<String> _distanceToNextStop = ValueNotifier("");
  final ValueNotifier<String?> _locationProblem = ValueNotifier(null);
  bool _localizedDefaultsSet = false;
  bool _hasLoggedArrival = false;
  bool _isSaved = false;
  AppLocalizations? _l10n;

  String? _floatingToastMessage;
  IconData? _floatingToastIcon;
  Color? _floatingToastColor;
  Timer? _floatingToastTimer;

  BitmapDescriptor? _userPuckIcon;
  late AnimationController _puckAnimController;
  LatLng? _prevPuckLocation;
  LatLng? _targetPuckLocation;
  LatLng? _currentPuckLocation;
  double _prevPuckHeading = 0;
  double _targetPuckHeading = 0;
  double _currentPuckHeading = 0;
  Marker? _userMarker;

  bool _isUserMoving = false;
  Position? _lastGpsPosition;
  Timer? _stationaryTimer;

  StreamSubscription<Position>? _positionStream;
  final LiveTrackingService _liveTracking = LiveTrackingService();
  GoogleMapController? _mapController;

  final DraggableScrollableController _sheet = DraggableScrollableController();

  /// Sheet snap points, as a fraction of screen height.
  ///
  /// Landscape needs bigger fractions of a much shorter screen: 24% of a
  /// portrait phone is a readable instruction, 24% of a landscape one is a
  /// sliver. These are read per build from the current orientation, and the
  /// sheet is keyed on orientation so rotating rebuilds it against the new
  /// bounds instead of leaving it at a size that is now out of range.
  double _peekOf(BuildContext c) => _isLandscape(c) ? 0.34 : 0.24;
  double _halfOf(BuildContext c) => _isLandscape(c) ? 0.62 : 0.52;
  double _fullOf(BuildContext c) => _isLandscape(c) ? 0.94 : 0.88;
  bool _isLandscape(BuildContext c) =>
      MediaQuery.of(c).orientation == Orientation.landscape;

  // ------------------------------------------------------------ nav camera
  //
  // A flat north-up map is a picture of the route. A tilted heading-up one is
  // a picture of what the rider is looking at, which is the whole point at a
  // junction: "the map is turning left, so I turn left." Google, Waze and
  // dashboard nav unit converge on the same four settings, and each carries
  // its own weight:
  //
  //   tilt      leans the map away so the road ahead occupies more pixels
  //             than the road behind, which is the ratio a rider needs
  //   bearing   rotates so "up" is "the way I am facing", removing the
  //             mental step of matching a north-up map to the street
  //   zoom      close enough that the next turn is legible
  //   padding   pushes the rider's dot low on screen, because the useful
  //             half of the view is what's ahead of them
  static const double _navTilt = 50;
  static const double _navZoom = 17.5;

  /// Where the rider's dot sits within the visible band of map, measured from
  /// the top. 0.5 would centre them; 0.72 leaves roughly two-thirds of the
  /// view for what's coming.
  static const double _puckFraction = 0.72;

  /// Below this speed the reported course is noise. GPS derives heading from
  /// successive fixes, so a rider standing at a bus stop produces a heading
  /// that spins, and a map that spins with it. Hold the last good one instead.
  static const double _minSpeedForHeading = 0.7; // m/s, a slow walk

  /// Don't re-animate more often than this. The position stream fires every
  /// 2 metres; issuing a new animation on each fix cancels the one in flight
  /// and the map judders instead of gliding.
  static const Duration _cameraThrottle = Duration(milliseconds: 900);

  /// Follow mode: camera tracks the rider, tilted and heading-up. Panning the
  /// map turns it off (the rider wants to look somewhere else, and a camera
  /// that yanks itself back is the single most irritating thing a nav screen
  /// can do); the re-centre button turns it back on.
  bool _followMode = true;

  /// Distinguishes our own animations from the rider's gestures.
  /// onCameraMoveStarted can't tell us which it was, so we mark our own.
  bool _programmaticMove = false;

  double _lastHeading = 0;
  double _lastAppliedHeading = 0;
  DateTime _lastCameraMove = DateTime.fromMillisecondsSinceEpoch(0);

  /// Where the rider physically is. GPS writes this; taps never do.
  int _currentStepIndex = 0;

  /// Which steps the rider has unfolded. Taps write this; GPS never does.
  final Set<int> _expandedSteps = {};

  @override
  void initState() {
    super.initState();
    _puckAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onPuckAnimTick);
    _parsePathData();
    _syncLiveTrackingForCurrentStep();
    _loadCustomIcons();
    _checkSavedTrip();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startLiveTracking();
    });
  }

  Future<void> _checkSavedTrip() async {
    final dest = _destinationTitle.isNotEmpty ? _destinationTitle : 'Destination';
    final saved = await SavedTripsService.isTripSaved('Trip', dest);
    if (mounted) setState(() => _isSaved = saved);
    final startName = _instructions.isNotEmpty ? (_instructions.first['instruction'] ?? 'Origin') : 'Origin';
    final opt = widget.pathData['option'] is Map<String, dynamic>
        ? widget.pathData['option'] as Map<String, dynamic>
        : (widget.pathData['option'] is Map ? Map<String, dynamic>.from(widget.pathData['option']) : null);
    final profile = widget.pathData['type']?.toString() ?? opt?['type']?.toString();
    TripHistoryService.recordTrip(
      startName: startName.toString(),
      endName: dest,
      pathData: widget.pathData,
      option: opt,
      chosenProfile: profile,
      isCompleted: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    if (!_localizedDefaultsSet) {
      _updateDistanceDisplay();
      _localizedDefaultsSet = true;
    }
  }

  void _showFloatingToast(String message, {IconData icon = Icons.info_outline, Color? color}) {
    _floatingToastTimer?.cancel();
    setState(() {
      _floatingToastMessage = message;
      _floatingToastIcon = icon;
      _floatingToastColor = color;
    });
    _floatingToastTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() => _floatingToastMessage = null);
      }
    });
  }

  // ---------------------------------------------------------------- parsing
  void _parsePathData() {
    try {
      final raw = widget.pathData['instructions'];
      if (raw is List) {
        _instructions = raw;
        _stepPoints.addAll(raw.map(_latLngOf));
        for (final step in raw) {
          if (step is Map && step['action'] == 'arrive' && step['station'] != null) {
            _destinationTitle = step['station'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint("Could not parse instructions: $e");
    }

    try {
      _walkSegments.clear();
      _mainRouteColor = _parseColor(widget.pathData['color']) ?? _mainRouteColor;
    } catch (e) {
      debugPrint("Could not parse route colour: $e");
    }

    try {
      final segments = widget.pathData['segments'];
      if (segments is List) {
        int i = 0;
        for (final segment in segments) {
          if (segment is! Map) continue;
          final pts = _pointsOf(segment['points']);
          if (pts.isEmpty) continue;
          final bool isWalk = segment['is_walk'] == true || segment['vehicle_type'] == 'walk';
          final segColor = isWalk
              ? const Color(0xFF2A9D8F)
              : (_parseColor(segment['color']) ?? _mainRouteColor);

          _allPoints.addAll(pts);

          if (isWalk) {
            _walkSegments.add(pts);
            _routePolylines.add(Polyline(
              polylineId: PolylineId('walk_$i'),
              points: pts,
              width: 5,
              color: segColor,
              patterns: [PatternItem.dot, PatternItem.gap(8)],
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
          } else {
            // Subtle casing for contrast
            _routePolylines.add(Polyline(
              polylineId: PolylineId('casing_$i'),
              points: pts,
              width: 8,
              color: Colors.black38,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
            // Vibrant primary route line
            _routePolylines.add(Polyline(
              polylineId: PolylineId('route_$i'),
              points: pts,
              width: 5,
              color: segColor,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ));
          }
          i++;
        }
      }
    } catch (e) {
      debugPrint("Could not parse route segments: $e");
    }
  }

  static List<LatLng> _pointsOf(dynamic raw) {
    if (raw is! List) return <LatLng>[];
    final out = <LatLng>[];
    for (final p in raw) {
      final ll = _latLngOf(p);
      if (ll != null) out.add(ll);
    }
    return out;
  }

  static LatLng? _latLngOf(dynamic p) {
    if (p is! Map) return null;
    final lat = p['lat'], lon = p['lon'];
    if (lat is! num || lon is! num) return null;
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    return LatLng(lat.toDouble(), lon.toDouble());
  }

  static Color? _parseColor(dynamic raw) {
    if (raw is! String) return null;
    final hex = raw.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) return null;
    final v = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
    return v == null ? null : Color(v);
  }

  Future<void> _loadCustomIcons() async {
    try {
      _startIcon = await MapMarkerService.getOriginMarker();
      _endIcon = await MapMarkerService.getDestinationMarker();
      _transferIcon = await MapMarkerService.getTransferMarker();
      _stationIcon = await MapMarkerService.getStationStopMarker(color: _mainRouteColor);
      _userPuckIcon = await _createUserPuckBitmap();
      _buildMarkers();
    } catch (e) {
      debugPrint("Error loading custom icons: $e");
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    if (_allPoints.isEmpty) return;

    // Start Marker (Origin Beacon)
    if (_startIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('origin_pin'),
        position: _allPoints.first,
        icon: _startIcon!,
        anchor: MapMarkerService.centerAnchor,
        zIndexInt: 10,
        infoWindow: const InfoWindow(title: 'نقطة الانطلاق / Start'),
      ));
    }

    // Destination Marker (Precision Teardrop Pin)
    if (_endIcon != null && _allPoints.length > 1) {
      markers.add(Marker(
        markerId: const MarkerId('destination_pin'),
        position: _allPoints.last,
        icon: _endIcon!,
        anchor: MapMarkerService.pinAnchor,
        zIndexInt: 10,
        infoWindow: InfoWindow(title: _destinationTitle.isNotEmpty ? _destinationTitle : 'الوصول / Destination'),
      ));
    }

    // Transfer and key station stop markers from instructions
    for (int i = 0; i < _instructions.length; i++) {
      final step = _instructions[i];
      if (step is! Map) continue;
      final lat = step['lat'], lon = step['lon'];
      if (lat is! num || lon is! num) continue;
      final pos = LatLng(lat.toDouble(), lon.toDouble());
      final action = step['action'];
      final station = (step['station'] ?? '').toString();

      if (action == 'transfer' && _transferIcon != null) {
        markers.add(Marker(
          markerId: MarkerId('transfer_$i'),
          position: pos,
          icon: _transferIcon!,
          anchor: MapMarkerService.centerAnchor,
          zIndexInt: 8,
          infoWindow: InfoWindow(title: 'محطة تحويل / Transfer', snippet: station),
        ));
      } else if (station.isNotEmpty && _stationIcon != null && i > 0 && i < _instructions.length - 1) {
        markers.add(Marker(
          markerId: MarkerId('station_$i'),
          position: pos,
          icon: _stationIcon!,
          anchor: MapMarkerService.centerAnchor,
          zIndexInt: 5,
          infoWindow: InfoWindow(title: station),
        ));
      }
    }

    if (_userMarker != null) {
      markers.add(_userMarker!);
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  void _onPuckAnimTick() {
    if (_prevPuckLocation == null || _targetPuckLocation == null) return;
    final t = Curves.easeInOutCubic.transform(_puckAnimController.value);
    final lat = _prevPuckLocation!.latitude + (_targetPuckLocation!.latitude - _prevPuckLocation!.latitude) * t;
    final lon = _prevPuckLocation!.longitude + (_targetPuckLocation!.longitude - _prevPuckLocation!.longitude) * t;
    final heading = _lerpHeading(_prevPuckHeading, _targetPuckHeading, t);

    _currentPuckLocation = LatLng(lat, lon);
    _currentPuckHeading = heading;
    _updateUserMarker();
  }

  static double _lerpHeading(double from, double to, double t) {
    double diff = (to - from + 180) % 360 - 180;
    if (diff < -180) diff += 360;
    return (from + diff * t + 360) % 360;
  }

  void _updateUserMarker() {
    if (_currentPuckLocation == null || !mounted) return;
    final marker = Marker(
      markerId: const MarkerId('guidy_user_puck'),
      position: _currentPuckLocation!,
      rotation: _currentPuckHeading,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndexInt: 99,
      icon: _userPuckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    setState(() {
      _userMarker = marker;
      _markers = {
        ..._markers.where((m) => m.markerId.value != 'guidy_user_puck'),
        marker,
      };
    });
  }

  void _onGpsPositionReceived(Position position) {
    // 1. Detect movement
    final double speed = position.speed; // meters per second
    bool moved = speed >= 0.5;
    if (!moved && _lastGpsPosition != null) {
      final d = Geolocator.distanceBetween(
        _lastGpsPosition!.latitude, _lastGpsPosition!.longitude,
        position.latitude, position.longitude,
      );
      moved = d >= 2.0;
    }

    _stationaryTimer?.cancel();
    if (moved) {
      if (!_isUserMoving && mounted) {
        setState(() => _isUserMoving = true);
      }
      _stationaryTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted && _isUserMoving) {
          setState(() => _isUserMoving = false);
        }
      });
    } else {
      if (_isUserMoving && mounted) {
        setState(() => _isUserMoving = false);
      }
    }
    _lastGpsPosition = position;

    // 2. Smoothly glide user puck marker to the new GPS position
    final newTarget = LatLng(position.latitude, position.longitude);
    final newHeading = _headingFor(position);

    _prevPuckLocation = _currentPuckLocation ?? newTarget;
    _targetPuckLocation = newTarget;
    _prevPuckHeading = _currentPuckHeading;
    _targetPuckHeading = newHeading;

    _puckAnimController.forward(from: 0.0);

    // 3. Keep current location value notifier and navigation updated
    _currentLocation.value = newTarget;
    _locationProblem.value = null;
    _followRider(position);
    _updateDistanceDisplay();
    _checkIfApproachingNextStep();
    _liveTracking.onPositionUpdate(position.latitude, position.longitude);
  }

  Future<BitmapDescriptor> _createUserPuckBitmap() async {
    const double size = 64;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final center = const Offset(size / 2, size / 2);

    // Soft outer radar glow
    final auraPaint = Paint()
      ..color = const Color(0xFF2DA3E3).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.46, auraPaint);

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(center.dx, center.dy + 1.5), size * 0.32, shadowPaint);

    // Crisp white border
    final rimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.32, rimPaint);

    // Vibrant brand blue core
    final corePaint = Paint()
      ..color = AppColors.primaryTeal
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.26, corePaint);

    // Directional forward navigation arrow / chevron pointing UP
    final arrowPath = Path();
    final topY = center.dy - (size * 0.17);
    final bottomY = center.dy + (size * 0.13);
    final width = size * 0.14;

    arrowPath.moveTo(center.dx, topY);
    arrowPath.lineTo(center.dx + width, bottomY);
    arrowPath.lineTo(center.dx, bottomY - (size * 0.05));
    arrowPath.lineTo(center.dx - width, bottomY);
    arrowPath.close();

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  // ------------------------------------------------------------ nav camera
  /// Marks an animation as ours so [_followMode] survives it. The flag is
  /// cleared by onCameraIdle when the animation settles.
  void _moveCamera(CameraUpdate update) {
    if (_mapController == null) return;
    _programmaticMove = true;
    _mapController!.animateCamera(update);
  }

  /// The heading to point the map at, given a fresh fix.
  /// Calculates forward bearing in degrees (0..360) from [start] to [end].
  static double _calculateBearing(LatLng start, LatLng end) {
    final b = Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    return (b + 360) % 360;
  }

  /// Calculates distance in meters between two coordinates.
  static double _calculateDistance(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude,
      p1.longitude,
      p2.latitude,
      p2.longitude,
    );
  }

  /// Finds the forward bearing along the route path from the rider's current position,
  /// orienting the navigation map directly towards the way the user is supposed to go.
  double _forwardRouteBearing(LatLng position) {
    if (_allPoints.length < 2) return _lastHeading;

    // Find nearest point along the route
    int nearestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < _allPoints.length; i++) {
      final d = _calculateDistance(position, _allPoints[i]);
      if (d < minDistance) {
        minDistance = d;
        nearestIndex = i;
      }
    }

    // Look ahead along the route for a point at least 15 meters away to avoid jitter
    for (int i = nearestIndex; i < _allPoints.length; i++) {
      final d = _calculateDistance(position, _allPoints[i]);
      if (d >= 15) {
        return _calculateBearing(position, _allPoints[i]);
      }
    }

    // Near the end of the route or next segment
    if (nearestIndex < _allPoints.length - 1) {
      return _calculateBearing(position, _allPoints[nearestIndex + 1]);
    } else if (_allPoints.length >= 2) {
      return _calculateBearing(_allPoints[_allPoints.length - 2], _allPoints.last);
    }

    return _lastHeading;
  }

  /// The heading to point the map at, given a fresh fix.
  double _headingFor(Position position) {
    final double h = position.heading;
    if (position.speed >= _minSpeedForHeading && h >= 0 && h < 360) {
      _lastHeading = h;
    } else {
      // When stationary or moving slowly, orient towards the direction the user is supposed to go along the route
      final routeBearing = _forwardRouteBearing(LatLng(position.latitude, position.longitude));
      _lastHeading = routeBearing;
    }
    return _lastHeading;
  }

  /// Puts the camera behind and below the rider, looking the way they're
  /// going. Throttled, and skipped entirely when the rider has taken manual
  /// control of the map.
  void _followRider(Position position) {
    if (!_followMode || _mapController == null) return;

    final now = DateTime.now();
    final double heading = _headingFor(position);
    // A sharp turn beats the throttle: waiting most of a second to rotate
    // through 90 degrees is exactly when the rider is looking at the screen.
    final bool turnedSharply = _angularDistance(heading, _lastAppliedHeading) > 25;
    if (!turnedSharply && now.difference(_lastCameraMove) < _cameraThrottle) return;

    _lastCameraMove = now;
    _lastAppliedHeading = heading;
    _moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: _navZoom,
      tilt: _navTilt,
      bearing: heading,
    )));
  }


  /// Shortest angular distance between two bearings, in degrees. Without the
  /// wrap, 359 and 1 read as 358 degrees apart instead of 2.
  static double _angularDistance(double a, double b) {
    final double d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  /// Back to following the rider, from wherever they panned to.
  Future<void> _recenter() async {
    HapticFeedback.selectionClick();
    final l10n = _l10n ?? AppLocalizations.of(context);
    setState(() => _followMode = true);

    final here = _currentLocation.value;
    if (here != null) {
      _lastCameraMove = DateTime.now();
      final routeBearing = _forwardRouteBearing(here);
      _lastHeading = routeBearing;
      _lastAppliedHeading = routeBearing;
      _moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: here,
        zoom: _navZoom,
        tilt: _navTilt,
        bearing: routeBearing,
      )));
      _showFloatingToast(
        l10n.navRecenterSuccess,
        icon: Icons.my_location_rounded,
        color: AppColors.primaryTeal,
      );
      return;
    }

    _showFloatingToast(
      l10n.navRecenterFinding,
      icon: Icons.location_searching_rounded,
    );

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      if (!mounted) return;
      _currentLocation.value = LatLng(pos.latitude, pos.longitude);
      _locationProblem.value = null;
      _updateDistanceDisplay();
      _moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: _currentLocation.value!,
        zoom: _navZoom,
        tilt: _navTilt,
        bearing: _headingFor(pos),
      )));
      _showFloatingToast(
        l10n.navRecenterSuccess,
        icon: Icons.my_location_rounded,
        color: AppColors.primaryTeal,
      );
    } catch (_) {
      if (!mounted) return;
      if (_allPoints.isNotEmpty) {
        _moveCamera(CameraUpdate.newLatLngZoom(_allPoints.first, 16.0));
        _showFloatingToast(
          l10n.navRecenterFallback,
          icon: Icons.navigation_rounded,
        );
      }
    }
  }

  /// Zooms and fits the full route in the camera viewport
  void _fitRouteBounds({bool animated = true}) {
    if (_mapController == null || _allPoints.isEmpty) return;
    setState(() => _followMode = false);

    if (_allPoints.length == 1) {
      final update = CameraUpdate.newLatLngZoom(_allPoints.first, 15.0);
      if (animated) {
        _moveCamera(update);
      } else {
        _mapController!.moveCamera(update);
      }
      return;
    }

    final update = CameraUpdate.newLatLngBounds(_boundsFromPoints(_allPoints), 60);
    if (animated) {
      _moveCamera(update);
    } else {
      _mapController!.moveCamera(update);
    }
  }

  /// The whole trip, flat and north-up.
  void _showOverview() {
    HapticFeedback.selectionClick();
    final l10n = _l10n ?? AppLocalizations.of(context);
    _fitRouteBounds(animated: true);
    _showFloatingToast(
      l10n.navOverviewToast,
      icon: Icons.fit_screen_rounded,
    );
  }

  /// Map padding. In follow mode the extra top inset is what pushes the
  /// rider's dot down to [_puckFraction] of the visible band -- the map
  /// centres the camera target inside the padded box, so padding the TOP
  /// moves the target down the screen.
  EdgeInsets _mapPadding(BuildContext context) {
    final double bottom = MediaQuery.of(context).size.height * _peekOf(context);
    if (!_followMode) return EdgeInsets.only(bottom: bottom);
    final double band = MediaQuery.of(context).size.height - bottom;
    // centre of padded box = top + (band - top)/2, solved for the target
    // position we want: top = 2 * (band * _puckFraction) - band.
    final double top = (band * (2 * _puckFraction - 1)).clamp(0.0, band * 0.6);
    return EdgeInsets.only(top: top, bottom: bottom);
  }

  // ---------------------------------------------------------------- location
  /// Handles every permission outcome. The previous version only tested for
  /// `denied`; `deniedForever` — what you get after "Don't ask again" — fell
  /// through to `getCurrentPosition()`, which throws, uncaught and unawaited.
  /// Losing GPS mid-trip is normal here too: parts of Line 3 run underground,
  /// so the stream needs an onError.
  Future<void> _startLiveTracking() async {
    final l10n = _l10n ?? AppLocalizations.of(context);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationProblem.value = l10n.navLocationOff;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _locationProblem.value = l10n.navLocationBlocked;
        return;
      }
      if (permission == LocationPermission.denied) {
        _locationProblem.value = l10n.navLocationOff;
        return;
      }

      // 1. Fast path: load cached position instantly with zero latency
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted && _currentLocation.value == null) {
          final p = LatLng(last.latitude, last.longitude);
          _currentPuckLocation = p;
          _currentLocation.value = p;
          _updateUserMarker();
          _updateDistanceDisplay();
        }
      } catch (_) {}

      // 2. Actively poll for an immediate high-accuracy fix so we don't wait for movement
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      ).then((pos) {
        if (!mounted) return;
        _onGpsPositionReceived(pos);
      }).catchError((e) {
        debugPrint("Initial GPS fix error: $e");
      });

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ),
      ).listen(
        (Position position) {
          if (!mounted) return;
          _onGpsPositionReceived(position);
        },
        onError: (Object e) {
          debugPrint("Position stream error: $e");
          if (mounted) _locationProblem.value = l10n.navLocationLost;
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint("Could not start location tracking: $e");
      if (mounted) _locationProblem.value = l10n.navLocationLost;
    }
  }

  void _syncLiveTrackingForCurrentStep() {
    if (_instructions.isEmpty || _currentStepIndex >= _instructions.length) return;
    final step = _instructions[_currentStepIndex] as Map<String, dynamic>;
    final routeId = step['route_id'];
    final action = step['action'];
    final isTransitLeg = (action == 'board' || action == 'transfer') && routeId != null;
    if (isTransitLeg) {
      _liveTracking.startLeg(
        routeId: routeId as String,
        directionId: (step['direction_id'] ?? '') as String,
      );
    } else {
      _liveTracking.endLeg();
    }
  }

  void _updateDistanceDisplay() {
    if (!mounted || _instructions.isEmpty) return;
    final l10n = _l10n ?? AppLocalizations.of(context);

    if (_currentStepIndex >= _instructions.length - 1) {
      _distanceToNextStop.value = l10n.youHaveArrived;
      return;
    }

    final int next = _currentStepIndex + 1;
    final LatLng? target = next < _stepPoints.length ? _stepPoints[next] : null;
    final currentStep = _instructions[_currentStepIndex];
    final nextStep = next < _instructions.length ? _instructions[next] : null;

    String station = '';
    if (nextStep is Map && nextStep['station'] != null && nextStep['station'].toString().trim().isNotEmpty) {
      station = nextStep['station'].toString().trim();
    } else if (currentStep is Map && currentStep['station'] != null && currentStep['station'].toString().trim().isNotEmpty) {
      station = currentStep['station'].toString().trim();
    }

    final here = _currentLocation.value;
    double? dist;

    // 1. Live GPS distance to next waypoint
    if (here != null && target != null) {
      dist = Geolocator.distanceBetween(
        here.latitude, here.longitude, target.latitude, target.longitude,
      );
    }
    // 2. Step planned distance if available
    else if (currentStep is Map && currentStep['distance_m'] != null && (_asNum(currentStep['distance_m']) ?? 0) > 0) {
      dist = (_asNum(currentStep['distance_m']) ?? 0).toDouble();
    }
    // 3. Fallback: distance from origin/current step coordinate to target
    else if (target != null) {
      final origin = (_stepPoints.isNotEmpty && _currentStepIndex < _stepPoints.length && _stepPoints[_currentStepIndex] != null)
          ? _stepPoints[_currentStepIndex]!
          : (_allPoints.isNotEmpty ? _allPoints.first : null);
      if (origin != null) {
        dist = Geolocator.distanceBetween(
          origin.latitude, origin.longitude, target.latitude, target.longitude,
        );
      }
    }

    if (dist != null) {
      if (dist < 100) {
        _distanceToNextStop.value = station.isNotEmpty ? l10n.arrivingAt(station) : l10n.youHaveArrived;
      } else if (dist > 1000) {
        final kmStr = (dist / 1000).toStringAsFixed(1);
        _distanceToNextStop.value = station.isNotEmpty
            ? l10n.distanceKmTo(kmStr, station)
            : l10n.distanceKm(kmStr);
      } else {
        final mStr = dist.toInt().toString();
        _distanceToNextStop.value = station.isNotEmpty
            ? l10n.distanceMTo(mStr, station)
            : '$mStr ${l10n.localeName.startsWith('ar') ? 'متر' : 'm'}';
      }
    } else if (station.isNotEmpty) {
      _distanceToNextStop.value = station;
    }
  }

  void _checkIfApproachingNextStep() {
    final l10n = _l10n ?? AppLocalizations.of(context);
    final here = _currentLocation.value;
    if (here == null || _instructions.isEmpty) return;

    if (_currentStepIndex >= _instructions.length - 1) {
      _distanceToNextStop.value = l10n.youHaveArrived;
      if (!_hasLoggedArrival) {
        _hasLoggedArrival = true;
        AnalyticsService.logTripCompleted();
        ReviewService.onTripCompleted();
      }
      return;
    }

    final int next = _currentStepIndex + 1;
    final LatLng? target = next < _stepPoints.length ? _stepPoints[next] : null;
    // A step without usable coordinates can't drive the readout, but it
    // must not stop navigation either.
    if (target == null) return;

    final String station = (_instructions[next]['station'] ?? '').toString();
    final double distance = Geolocator.distanceBetween(
      here.latitude, here.longitude, target.latitude, target.longitude,
    );

    // Stop Proximity Alarm (~150m before the next transfer or arrival station)
    if (_stopAlarmEnabled && !_stopAlarmTriggeredForCurrent && distance <= 150 && distance > 15) {
      if (station.isNotEmpty) {
        _stopAlarmTriggeredForCurrent = true;
        HapticFeedback.heavyImpact();
        if (mounted) setState(() => _upcomingAlarmStation = station);
      }
    }

    if (distance < 100) {
      _distanceToNextStop.value = station.isNotEmpty ? l10n.arrivingAt(station) : l10n.youHaveArrived;
      _stopAlarmTriggeredForCurrent = false;
      if (mounted) {
        setState(() {
          _currentStepIndex = next;
          _upcomingAlarmStation = null;
        });
      }
      _syncLiveTrackingForCurrentStep();
      final p = _stepPoints[next];
      if (p != null && !_followMode) _moveCamera(CameraUpdate.newLatLngZoom(p, 16.0));
    } else {
      _updateDistanceDisplay();
    }
  }

  @override
  void deactivate() {
    _positionStream?.cancel();
    _positionStream = null;
    _floatingToastTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    _floatingToastTimer?.cancel();
    _stationaryTimer?.cancel();
    _puckAnimController.dispose();
    _positionStream?.cancel();
    _positionStream = null;
    _liveTracking.endLeg();
    _currentLocation.dispose();
    _distanceToNextStop.dispose();
    _locationProblem.dispose();
    _sheet.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  static double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lon1 = from.longitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final lon2 = to.longitude * math.pi / 180;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final rad = math.atan2(y, x);
    return (rad * 180 / math.pi + 360) % 360;
  }

  static double _turnAngle(double b1, double b2) {
    double diff = (b2 - b1 + 180) % 360 - 180;
    if (diff < -180) diff += 360;
    return diff;
  }

  WalkManeuverInfo? _getCurrentManeuver(AppLocalizations l10n) {
    if (_instructions.isEmpty) return null;

    if (_currentStepIndex >= _instructions.length - 1) {
      return WalkManeuverInfo(
        icon: Icons.place_rounded,
        iconKey: 'arrive',
        headline: l10n.walkAtDestination,
        subline: _destinationTitle.isNotEmpty ? _destinationTitle : l10n.tripRecapTitle,
      );
    }

    final currentStep = _instructions[_currentStepIndex];
    if (currentStep is! Map) return null;
    final String action = (currentStep['action'] ?? '').toString();
    final int next = _currentStepIndex + 1;
    final nextStep = next < _instructions.length && _instructions[next] is Map ? _instructions[next] as Map : null;
    final targetStation = (nextStep?['station'] ?? currentStep['station'] ?? '').toString();
    final LatLng? targetCoord = next < _stepPoints.length ? _stepPoints[next] : null;
    final here = _currentLocation.value;

    // Proximity alert (within 150m of next boarding or transfer station)
    if (here != null && targetCoord != null) {
      final distToStop = Geolocator.distanceBetween(
        here.latitude, here.longitude, targetCoord.latitude, targetCoord.longitude,
      );
      if (distToStop <= 150 && targetStation.isNotEmpty) {
        final distStr = distToStop < 20
            ? (l10n.localeName.startsWith('ar') ? 'دلوقتي' : 'Now')
            : '${distToStop.toInt()} ${l10n.localeName.startsWith('ar') ? 'متر متبقية' : 'm left'}';
        return WalkManeuverInfo(
          icon: Icons.notifications_active_rounded,
          iconKey: 'arrive',
          headline: l10n.walkApproachingBoarding(targetStation),
          subline: distStr,
          isProximityAlert: true,
        );
      }
    }

    // Transit leg guidance (board, ride, transfer)
    if (action != 'walk') {
      final routeId = (currentStep['route_id'] ?? '').toString();
      final iconKey = (currentStep['icon'] ?? 'bus').toString();
      final iconData = TransitModes.icon(iconKey);

      if (action == 'board') {
        final headline = routeId.isNotEmpty
            ? (l10n.localeName.startsWith('ar') ? 'استعد تركب $routeId' : 'Board $routeId')
            : (l10n.localeName.startsWith('ar') ? 'استعد للصعود' : 'Prepare to board');
        final subline = targetStation.isNotEmpty
            ? (l10n.localeName.startsWith('ar') ? 'من محطة $targetStation' : 'from $targetStation')
            : '';
        return WalkManeuverInfo(icon: iconData, iconKey: iconKey, headline: headline, subline: subline);
      } else if (action == 'transfer') {
        final headline = l10n.localeName.startsWith('ar') ? 'محطة تحويل' : 'Transfer';
        final subline = targetStation.isNotEmpty
            ? (l10n.localeName.startsWith('ar') ? 'في $targetStation' : 'at $targetStation')
            : '';
        return WalkManeuverInfo(icon: Icons.swap_horiz_rounded, iconKey: 'transfer', headline: headline, subline: subline);
      }
    }

    // Walking leg turn-by-turn guidance along road waypoints
    List<LatLng>? walkPts;
    if (_walkSegments.isNotEmpty) {
      final ref = here ?? (_currentStepIndex < _stepPoints.length ? _stepPoints[_currentStepIndex] : null);
      if (ref != null) {
        double minD = double.infinity;
        for (final seg in _walkSegments) {
          if (seg.isEmpty) continue;
          final d = Geolocator.distanceBetween(ref.latitude, ref.longitude, seg.first.latitude, seg.first.longitude);
          if (d < minD) {
            minD = d;
            walkPts = seg;
          }
        }
      }
      walkPts ??= _walkSegments.first;
    } else if (_allPoints.isNotEmpty) {
      walkPts = _allPoints;
    }

    if (walkPts != null && walkPts.length > 2) {
      final ref = here ?? walkPts.first;
      int closestIdx = 0;
      double minD = double.infinity;
      for (int i = 0; i < walkPts.length; i++) {
        final d = Geolocator.distanceBetween(ref.latitude, ref.longitude, walkPts[i].latitude, walkPts[i].longitude);
        if (d < minD) {
          minD = d;
          closestIdx = i;
        }
      }

      // Look ahead for the next sharp turn maneuver
      for (int k = closestIdx + 1; k < walkPts.length - 1; k++) {
        final segDist = Geolocator.distanceBetween(
          walkPts[k].latitude, walkPts[k].longitude, walkPts[k + 1].latitude, walkPts[k + 1].longitude,
        );
        if (segDist < 5) continue;

        final b1 = _bearingBetween(walkPts[k - 1], walkPts[k]);
        final b2 = _bearingBetween(walkPts[k], walkPts[k + 1]);
        final diff = _turnAngle(b1, b2);

        if (diff.abs() >= 35) {
          double turnDist = Geolocator.distanceBetween(
            ref.latitude, ref.longitude, walkPts[closestIdx].latitude, walkPts[closestIdx].longitude,
          );
          for (int j = closestIdx; j < k; j++) {
            turnDist += Geolocator.distanceBetween(
              walkPts[j].latitude, walkPts[j].longitude, walkPts[j + 1].latitude, walkPts[j + 1].longitude,
            );
          }

          IconData turnIcon;
          String turnAction;
          if (diff > 125 || diff < -125) {
            turnIcon = Icons.u_turn_left_rounded;
            turnAction = l10n.walkManeuverUTurn;
          } else if (diff > 0) {
            turnIcon = Icons.turn_right_rounded;
            turnAction = l10n.walkManeuverRight;
          } else {
            turnIcon = Icons.turn_left_rounded;
            turnAction = l10n.walkManeuverLeft;
          }

          final distStr = turnDist < 1000
              ? '${turnDist.toInt()} ${l10n.localeName.startsWith('ar') ? 'متر' : 'm'}'
              : '${(turnDist / 1000).toStringAsFixed(1)} ${l10n.localeName.startsWith('ar') ? 'كم' : 'km'}';

          final headline = turnDist < 20 ? turnAction : l10n.walkInDistance(distStr, turnAction);
          final subline = targetStation.isNotEmpty
              ? (l10n.localeName.startsWith('ar') ? 'باتجاه $targetStation' : 'towards $targetStation')
              : l10n.walkManeuverStraight;

          return WalkManeuverInfo(
            icon: turnIcon,
            iconKey: 'walk',
            headline: headline,
            subline: subline,
          );
        }
      }
    }

    // Default straight walk maneuver
    final ref = here ?? (walkPts != null && walkPts.isNotEmpty ? walkPts.first : null);
    double straightDist = 0;
    if (ref != null && targetCoord != null) {
      straightDist = Geolocator.distanceBetween(
        ref.latitude, ref.longitude, targetCoord.latitude, targetCoord.longitude,
      );
    } else if (currentStep['distance_m'] != null) {
      straightDist = (_asNum(currentStep['distance_m']) ?? 0).toDouble();
    }

    final distStr = straightDist < 1000
        ? '${straightDist.toInt()} ${l10n.localeName.startsWith('ar') ? 'متر' : 'm'}'
        : '${(straightDist / 1000).toStringAsFixed(1)} ${l10n.localeName.startsWith('ar') ? 'كم' : 'km'}';

    return WalkManeuverInfo(
      icon: Icons.straight_rounded,
      iconKey: 'walk',
      headline: l10n.walkManeuverStraight,
      subline: targetStation.isNotEmpty
          ? (l10n.localeName.startsWith('ar') ? '$distStr إلى $targetStation' : '$distStr to $targetStation')
          : distStr,
    );
  }

  Widget _buildManeuverCard(BuildContext context) {
    final l10n = _l10n ?? AppLocalizations.of(context);
    final maneuver = _getCurrentManeuver(l10n);
    if (maneuver == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAlert = maneuver.isProximityAlert;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFE76F51) : (isDark ? const Color(0xFF1E2630) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isAlert
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppColors.primaryTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              TransitModes.icon(maneuver.iconKey ?? 'walk'),
              color: isAlert ? Colors.white : AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  maneuver.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isAlert ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                if (maneuver.subline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    maneuver.subline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isAlert ? Colors.white.withValues(alpha: 0.9) : (isDark ? Colors.white70 : Colors.black54),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _stepColor(String iconKey) {
    switch (iconKey) {
      case 'walk':
        return const Color(0xFF2A9D8F);
      case 'transfer':
        return const Color(0xFFE76F51);
      case 'arrive':
        return const Color(0xFF264653);
      case 'metro':
        return AppColors.primaryTeal;
      case 'minibus':
        return const Color(0xFFD4A373);
      case 'microbus':
        return const Color(0xFFC77DFF);
      default:
        return const Color(0xFF457B9D);
    }
  }

  IconData _stepIcon(String iconKey) => TransitModes.icon(iconKey);

  bool _hasAlternatives(int index) {
    if (index < 0 || index >= _instructions.length) return false;
    final opts = _instructions[index]['boarding_options'];
    return opts is List && opts.length > 1;
  }

  void _openAlternativesForCurrent() {
    setState(() => _expandedSteps.add(_currentStepIndex));
    if (_sheet.isAttached && mounted) {
      final full = _isLandscape(context) ? 0.94 : 0.88;
      _sheet.animateTo(full,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDark;
    final double peek = _peekOf(context);
    final double half = _halfOf(context);
    final double full = _fullOf(context);

    return Scaffold(
      bottomNavigationBar: const BannerAdPlaceholder(),
      body: Stack(
        children: [
          GoogleMap(
            // Map style is declarative now: GoogleMap(style: ...) replaced the
            // deprecated controller.setMapStyle(). The old imperative version needed
            // a _mapStyleIsDark latch and a post-frame callback to push the style
            // after every theme change; the property just rebuilds with the widget.
            style: isDark ? darkMapStyleJson : null,
            initialCameraPosition: CameraPosition(
              target: _allPoints.isNotEmpty ? _allPoints.first : const LatLng(30.0444, 31.2357),
              zoom: 14.5,
            ),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            // Rotation and tilt are driven by the rider's heading, but the
            // gestures stay enabled: someone who wants to look at the map
            // their own way should be able to, and doing so drops follow mode.
            compassEnabled: true,
            padding: _mapPadding(context),
            onCameraMoveStarted: () {
              if (!_programmaticMove && _followMode) {
                setState(() => _followMode = false);
              }
            },
            onCameraIdle: () => _programmaticMove = false,
            polylines: _routePolylines,
            markers: _markers,
            onMapCreated: (controller) async {
              _mapController = controller;
              if (_allPoints.isNotEmpty) {
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  final here = _currentLocation.value;
                  if (here != null) {
                    final bearing = _forwardRouteBearing(here);
                    _lastHeading = bearing;
                    _lastAppliedHeading = bearing;
                    setState(() => _followMode = true);
                    _moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
                      target: here,
                      zoom: _navZoom,
                      tilt: _navTilt,
                      bearing: bearing,
                    )));
                  } else if (_allPoints.length >= 2) {
                    final bearing = _calculateBearing(_allPoints[0], _allPoints[1]);
                    _lastHeading = bearing;
                    _lastAppliedHeading = bearing;
                    setState(() => _followMode = true);
                    _moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
                      target: _allPoints.first,
                      zoom: _navZoom,
                      tilt: _navTilt,
                      bearing: bearing,
                    )));
                  } else {
                    _fitRouteBounds(animated: true);
                  }
                }
              }
            },
          ),

          // --- Top navigation header bar & stop alarm banner ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _roundButton(
                      context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      color: context.textPrimary,
                      tooltip: l10n.closeMapTooltip,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _roundButton(
                      context,
                      icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                      color: _isSaved ? AppColors.primaryTeal : context.textPrimary,
                      tooltip: l10n.saveTripTooltip,
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final dest = _destinationTitle.isNotEmpty ? _destinationTitle : l10n.tripRecapTitle;
                        if (_isSaved) {
                          await SavedTripsService.removeTripByEndpoints('Trip', dest);
                          if (mounted) {
                            setState(() => _isSaved = false);
                            _showFloatingToast(l10n.tripRemovedToast, icon: Icons.bookmark_border_rounded);
                          }
                        } else {
                          await SavedTripsService.saveTrip(
                            startName: 'Trip',
                            endName: dest,
                            pathData: widget.pathData,
                          );
                          if (mounted) {
                            setState(() => _isSaved = true);
                            _showFloatingToast(l10n.tripSavedToast, icon: Icons.bookmark_rounded, color: AppColors.primaryTeal);
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _roundButton(
                      context,
                      icon: Icons.campaign_outlined,
                      color: context.textPrimary,
                      tooltip: l10n.quickReportTitle,
                      onPressed: () {
                        QuickCommuteReportSheet.show(
                          context,
                          routeData: widget.pathData,
                          steps: _instructions,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _roundButton(
                      context,
                      icon: Icons.share_rounded,
                      color: AppColors.primaryTeal,
                      tooltip: l10n.shareTripTooltip,
                      onPressed: () {
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        final dur = widget.pathData['duration_minutes']?.toString();
                        TripSharingService.shareTrip(
                          context: context,
                          destinationName: _destinationTitle.isNotEmpty
                              ? _destinationTitle
                              : (isAr ? 'الوجهة' : 'Destination'),
                          durationMinutes: dur,
                          lang: isAr ? 'ar' : 'en',
                        );
                      },
                    ),
                  ],
                ),
                _buildManeuverCard(context),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _floatingToastMessage != null
                      ? Container(
                          key: ValueKey(_floatingToastMessage),
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _floatingToastColor ?? context.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _floatingToastIcon ?? Icons.info_outline,
                                color: _floatingToastColor != null ? Colors.white : AppColors.primaryTeal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _floatingToastMessage!,
                                  style: TextStyle(
                                    color: _floatingToastColor != null ? Colors.white : context.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (_stopAlarmEnabled && _upcomingAlarmStation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE76F51),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.navStopAlarmAlert(_upcomingAlarmStation!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => setState(() => _upcomingAlarmStation = null),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // --- Floating map controls (Overview, Recenter, Stop Proximity Alarm) ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 130,
            right: 16,
            child: Column(
              children: [
                _roundButton(
                  context,
                  icon: Icons.fit_screen_rounded,
                  color: AppColors.primaryTeal,
                  tooltip: l10n.navFitRouteTooltip,
                  onPressed: _showOverview,
                ),
                const SizedBox(height: 10),
                _roundButton(
                  context,
                  icon: _followMode ? Icons.my_location_rounded : Icons.location_searching_rounded,
                  color: _followMode ? AppColors.primaryTeal : context.textSecondary,
                  tooltip: _followMode
                      ? l10n.centerOnMyLocationTooltip
                      : l10n.navRecenterTooltip,
                  onPressed: _recenter,
                ),
                const SizedBox(height: 10),
                _roundButton(
                  context,
                  icon: _stopAlarmEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  color: _stopAlarmEnabled ? const Color(0xFFE76F51) : context.textSecondary,
                  backgroundColor: _stopAlarmEnabled ? const Color(0xFFE76F51).withValues(alpha: 0.14) : null,
                  showBadge: _stopAlarmEnabled,
                  tooltip: _stopAlarmEnabled ? l10n.navStopAlarmOn : l10n.navStopAlarmOff,
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _stopAlarmEnabled = !_stopAlarmEnabled;
                      if (!_stopAlarmEnabled) {
                        _upcomingAlarmStation = null;
                      }
                    });
                    _showFloatingToast(
                      _stopAlarmEnabled ? l10n.navStopAlarmActiveToast : l10n.navStopAlarmDisabledToast,
                      icon: _stopAlarmEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      color: _stopAlarmEnabled ? const Color(0xFFE76F51) : null,
                    );
                  },
                ),
              ],
            ),
          ),

          // --- the sheet ---
          if (_instructions.isNotEmpty)
            DraggableScrollableSheet(
              // Keyed on orientation: rotating disposes and rebuilds the
              // sheet against the new snap points, rather than leaving it
              // sized outside the new min/max.
              key: ValueKey(_isLandscape(context)),
              controller: _sheet,
              initialChildSize: half,
              minChildSize: peek,
              maxChildSize: full,
              snap: true,
              snapSizes: [half],
              builder: (context, scrollController) => DecoratedBox(
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.16),
                      blurRadius: 26,
                      offset: const Offset(0, -6),
                    )
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: _sheetHeader(context, l10n)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _stepTile(context, l10n, i),
                        childCount: _instructions.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    Color? backgroundColor,
    bool showBadge = false,
  }) {
    return Material(
      color: backgroundColor ?? context.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(icon, size: 22),
            color: color,
            tooltip: tooltip,
            onPressed: onPressed,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          if (showBadge)
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE76F51),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The pinned part: grab handle, the CURRENT instruction, distance to the
  /// next step, and the direct route into alternatives. Visible at every
  /// snap point, including the smallest.
  Widget _sheetHeader(BuildContext context, AppLocalizations l10n) {
    final step = _instructions[_currentStepIndex] as Map<String, dynamic>;
    final iconKey = InstructionFormatter.iconKey(step);
    final color = _stepColor(iconKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: context.textSecondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                    child: Icon(_stepIcon(iconKey), color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.navNowLabel.toUpperCase(),
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          InstructionFormatter.title(l10n, step),
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          InstructionFormatter.subtitle(l10n, step),
                          style: TextStyle(color: context.textSecondary, fontSize: 13.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: context.fieldFill,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation, size: 14, color: context.textSecondary),
                        const SizedBox(width: 6),
                        ValueListenableBuilder<String>(
                          valueListenable: _distanceToNextStop,
                          builder: (context, text, _) => Text(
                            text,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.pathData['metro_stops'] is int &&
                      (widget.pathData['metro_stops'] as int) > 0)
                    Builder(builder: (ctx) {
                      final int stops = widget.pathData['metro_stops'] as int;
                      final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
                      final rec = MetroTicketAdvisor.calculate(stationCount: stops);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: rec.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: rec.color, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.confirmation_number_outlined, size: 14, color: rec.color),
                            const SizedBox(width: 5),
                            Text(
                              '${isAr ? rec.ticketNameAr : rec.ticketNameEn} (${rec.fareEgp} ج.م)',
                              style: TextStyle(
                                color: rec.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (_hasAlternatives(_currentStepIndex))
                    OutlinedButton.icon(
                      onPressed: _openAlternativesForCurrent,
                      icon: const Icon(Icons.alt_route, size: 16),
                      label: Text(l10n.navOtherVehicles),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 36),
                        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              ValueListenableBuilder<String?>(
                valueListenable: _locationProblem,
                builder: (context, problem, _) {
                  if (problem == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: context.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(problem,
                              style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.35)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: context.fieldFill),
      ],
    );
  }

  /// One row of the journey. Tapping a row that has alternatives unfolds
  /// them in place — this is the only thing that writes _expandedSteps.
  Widget _stepTile(BuildContext context, AppLocalizations l10n, int index) {
    final step = _instructions[index] as Map<String, dynamic>;
    final iconKey = InstructionFormatter.iconKey(step);
    final color = _stepColor(iconKey);
    final bool isNow = index == _currentStepIndex;
    final bool isOpen = _expandedSteps.contains(index);
    final bool tappable = _hasAlternatives(index);
    final bool isLast = index == _instructions.length - 1;

    final int? wait = _asNum(step['wait_min'])?.round();
    final fare = step['fare_egp'];

    return Container(
      color: isNow ? AppColors.primaryTeal.withValues(alpha: context.isDark ? 0.13 : 0.08) : null,
      child: InkWell(
        onTap: tappable
            ? () => setState(() => isOpen ? _expandedSteps.remove(index) : _expandedSteps.add(index))
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // rail: dot + connector, so the list reads as one journey
                  SizedBox(
                    width: 34,
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: context.isDark ? 0.22 : 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: isNow ? 2 : 0),
                          ),
                          child: Icon(_stepIcon(iconKey), color: color, size: 16),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: isOpen ? 18 : 26,
                            color: context.fieldFill,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  InstructionFormatter.title(l10n, step),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              if (isNow) ...[
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    l10n.navNowLabel.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            InstructionFormatter.subtitle(l10n, step),
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (step['station'] != null)
                            Text('${step['station']}',
                                style: TextStyle(color: context.textSecondary, fontSize: 12.5)),
                          if (wait != null && wait > 0 || fare != null) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                if (wait != null && wait > 0) ...[
                                  Icon(Icons.hourglass_empty, size: 12, color: context.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(l10n.stepWaitHint(wait.toString()),
                                      style: TextStyle(color: context.textSecondary, fontSize: 11.5)),
                                ],
                                if (wait != null && wait > 0 && fare != null)
                                  const SizedBox(width: 12),
                                if (fare != null) ...[
                                  Icon(Icons.payments_outlined, size: 12, color: context.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(l10n.fareEgp('$fare'),
                                      style: TextStyle(color: context.textSecondary, fontSize: 11.5)),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (tappable)
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Icon(
                        isOpen ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: context.textSecondary,
                      ),
                    ),
                ],
              ),
              if (isOpen) _alternatives(context, l10n, step),
            ],
          ),
        ),
      ),
    );
  }

  /// Every route covering this corridor — see raptor_engine.py's
  /// _find_equivalent_routes. A live ETA (a rider currently sharing position
  /// on that route) always outranks the schedule-derived headway, and the
  /// two are styled differently rather than presented as equally certain:
  /// live is coloured and marked, schedule-only is muted. At launch there
  /// will be no live data at all, so the muted state is the normal one.
  Widget _alternatives(BuildContext context, AppLocalizations l10n, Map<String, dynamic> step) {
    final List options = step['boarding_options'] ?? const [];

    return Padding(
      padding: const EdgeInsets.only(left: 46, bottom: 14, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.navAlsoServing.toUpperCase(),
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 7),
          ...options.map<Widget>((opt) {
            final bool isPrimary = opt['is_primary'] == true;
            final etaSec = opt['eta_sec'];
            final bool hasLive = etaSec != null;
            final headway = opt['typical_headway_min'];

            final String label = InstructionFormatter.optionSummary(l10n, {
              'vehicle_type': opt['vehicle_type'],
              'route_number': opt['route_number'],
              'route_description': opt['route_description'],
            });

            String detail;
            final etaNum = _asNum(etaSec);
            final headwayNum = _asNum(headway);
            if (hasLive && etaNum != null) {
              final int mins = (etaNum / 60).ceil();
              detail = mins <= 0 ? l10n.navArrivingNow : l10n.navMinutesAway(mins.toString());
            } else if (headwayNum != null && headwayNum.round() > 0) {
              detail = l10n.navEveryMinutes(headwayNum.round().toString());
            } else {
              detail = l10n.navNoLiveData;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: context.fieldFill,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: hasLive
                      ? const Color(0xFF2ECC71)
                      : isPrimary
                          ? AppColors.primaryTeal
                          : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (hasLive) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.navYourRoute,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    detail,
                    style: TextStyle(
                      // Live data gets colour and weight; schedule-derived
                      // stays muted, so a guess never reads as a measurement.
                      color: hasLive ? const Color(0xFF1E9E5A) : context.textSecondary,
                      fontSize: 12,
                      fontWeight: hasLive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

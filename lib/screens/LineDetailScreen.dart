import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../services/instruction_formatter.dart';
import '../services/map_marker_service.dart';
import '../services/transit_modes.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_placeholder.dart';
import '../widgets/error_state.dart';
import '../widgets/line_report_sheet.dart';

enum _LineViewMode { list, map }

/// One line, every stop, in order.
///
/// Most routes run two directions and the stop lists are not mirror
/// images of each other -- one-way streets and turning restrictions mean
/// the outbound and inbound sequences genuinely differ, so showing a
/// single reversed list would be wrong. Directions therefore get their
/// own tabs, each labelled by its terminus, which is what is written on
/// the vehicle's windscreen.
class LineDetailScreen extends StatefulWidget {
  final String routeId;
  final String fallbackTitle;

  const LineDetailScreen({super.key, required this.routeId, required this.fallbackTitle});

  static List<LatLng> extractCoords(Map<String, dynamic> direction) {
    final stopsRaw = List<Map<String, dynamic>>.from(direction['stops'] ?? const []);
    final stopCoords = stopsRaw
        .where((s) => s['lat'] != null && s['lon'] != null)
        .map((s) {
          final lat = InstructionFormatter.asNum(s['lat'])?.toDouble();
          final lon = InstructionFormatter.asNum(s['lon'])?.toDouble();
          return (lat != null && lon != null) ? LatLng(lat, lon) : null;
        })
        .whereType<LatLng>()
        .toList();

    final pointsRaw = (direction['points'] as List?) ?? [];
    List<LatLng> coords = [];
    if (pointsRaw.isNotEmpty) {
      coords = pointsRaw
          .where((p) => p is Map && p['lat'] != null && p['lon'] != null)
          .map((p) {
            final lat = InstructionFormatter.asNum(p['lat'])?.toDouble();
            final lon = InstructionFormatter.asNum(p['lon'])?.toDouble();
            return (lat != null && lon != null) ? LatLng(lat, lon) : null;
          })
          .whereType<LatLng>()
          .toList();
    }

    // Fall back to sequential stops if polyline points are missing or too few
    if (coords.length < 2) {
      return stopCoords;
    }

    // Strict connectivity guarantee:
    // Ensure the polyline connects directly to the origin marker and destination marker
    if (stopCoords.isNotEmpty) {
      final firstStop = stopCoords.first;
      final lastStop = stopCoords.last;

      if (coords.first.latitude != firstStop.latitude ||
          coords.first.longitude != firstStop.longitude) {
        coords.insert(0, firstStop);
      }
      if (coords.last.latitude != lastStop.latitude ||
          coords.last.longitude != lastStop.longitude) {
        coords.add(lastStop);
      }
    }

    return coords;
  }

  @override
  State<LineDetailScreen> createState() => _LineDetailScreenState();
}

class _LineDetailScreenState extends State<LineDetailScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  // A flag rather than a translated sentence -- see the same fix in
  // LinesScreen. Holding the localized string froze the error in the
  // language that happened to be active when the request failed.
  bool _failed = false;
  Map<String, dynamic>? _detail;
  int _directionIndex = 0;
  _LineViewMode _viewMode = _LineViewMode.list;
  GoogleMapController? _mapController;
  int? _selectedStopIndex;

  BitmapDescriptor? _originIcon;
  BitmapDescriptor? _destinationIcon;
  BitmapDescriptor? _stopDotIcon;
  BitmapDescriptor? _selectedStopDotIcon;
  Color? _cachedModeColor;
  bool _creatingIcons = false;

  Future<void> _initStopDotIcons(Color modeColor) async {
    if ((_cachedModeColor == modeColor && _stopDotIcon != null && _originIcon != null) || _creatingIcons) return;
    _creatingIcons = true;
    _cachedModeColor = modeColor;

    try {
      final origin = await MapMarkerService.getOriginMarker();
      final dest = await MapMarkerService.getDestinationMarker();
      final dot = await MapMarkerService.getStationStopMarker(color: modeColor, isSelected: false);
      final selectedDot = await MapMarkerService.getStationStopMarker(color: modeColor, isSelected: true);

      if (mounted) {
        setState(() {
          _originIcon = origin;
          _destinationIcon = dest;
          _stopDotIcon = dot;
          _selectedStopDotIcon = selectedDot;
          _creatingIcons = false;
        });
      }
    } catch (_) {
      _creatingIcons = false;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final lang = Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
    try {
      final detail = await _api.fetchRouteDetail(widget.routeId, lang: lang);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _directionIndex = 0;
        _selectedStopIndex = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _openReport(Map<String, dynamic> detail, Map<String, dynamic> direction) {
    final stops = List<Map<String, dynamic>>.from(direction['stops'] ?? const []);
    Map<String, dynamic>? selectedStop;
    if (_selectedStopIndex != null &&
        _selectedStopIndex! >= 0 &&
        _selectedStopIndex! < stops.length) {
      selectedStop = stops[_selectedStopIndex!];
    }
    LineReportSheet.show(
      context,
      routeId: widget.routeId,
      routeNumber: detail['number']?.toString(),
      routeDescription: detail['description']?.toString(),
      vehicleType: detail['vehicle_type']?.toString(),
      directionIndex: _directionIndex,
      directionTerminus: direction['towards']?.toString(),
      stops: stops,
      selectedStop: selectedStop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = _detail;

    final number = (detail?['number'] ?? '').toString().trim();
    final title = number.isNotEmpty ? number : widget.fallbackTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (detail != null) ...[
            IconButton(
              icon: const Icon(Icons.flag_outlined, size: 20),
              tooltip: l10n.reportAnIssueWithThisLine,
              onPressed: () {
                final directions = List<Map<String, dynamic>>.from(detail['directions'] ?? const []);
                final dir = directions.isNotEmpty
                    ? directions[_directionIndex.clamp(0, directions.length - 1)]
                    : <String, dynamic>{};
                _openReport(detail, dir);
              },
            ),
            IconButton(
              icon: Icon(_viewMode == _LineViewMode.map
                  ? Icons.format_list_bulleted_rounded
                  : Icons.map_rounded),
              tooltip: _viewMode == _LineViewMode.map ? l10n.linesViewList : l10n.linesViewMap,
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == _LineViewMode.map
                      ? _LineViewMode.list
                      : _LineViewMode.map;
                });
              },
            ),
          ],
        ],
      ),
      bottomNavigationBar: const BannerAdPlaceholder(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? ErrorState(message: l10n.linesLoadFailed, onRetry: _load)
              : _buildDetail(l10n, detail!),
    );
  }

  Widget _buildDetail(AppLocalizations l10n, Map<String, dynamic> detail) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final directions = List<Map<String, dynamic>>.from(detail['directions'] ?? const []);
    if (directions.isEmpty) {
      return ErrorState(message: l10n.linesLoadFailed, onRetry: _load);
    }
    final index = _directionIndex.clamp(0, directions.length - 1);
    final direction = directions[index];
    final stops = List<Map<String, dynamic>>.from(direction['stops'] ?? const []);
    final isMetro = TransitModes.isRail(detail['vehicle_type'] as String?);
    final modeColor = TransitModes.color(detail['vehicle_type'] as String?);

    return Column(
      children: [
        _header(l10n, detail, direction, isMetro),
        if (directions.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<int>(
              segments: [
                for (int i = 0; i < directions.length; i++)
                  ButtonSegment<int>(
                    value: i,
                    label: Text(
                      _towardsLabel(l10n, directions, i, isArabic),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.15),
                    ),
                  ),
              ],
              selected: {index},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() {
                  _directionIndex = s.first;
                  _selectedStopIndex = null;
                });
                if (_viewMode == _LineViewMode.map) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final d = directions[_directionIndex.clamp(0, directions.length - 1)];
                    _fitRouteBounds(_extractCoords(d));
                  });
                }
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<_LineViewMode>(
                  segments: [
                    ButtonSegment<_LineViewMode>(
                      value: _LineViewMode.list,
                      icon: const Icon(Icons.format_list_bulleted_rounded, size: 17),
                      label: Text(l10n.linesViewList, style: const TextStyle(fontSize: 12.5)),
                    ),
                    ButtonSegment<_LineViewMode>(
                      value: _LineViewMode.map,
                      icon: const Icon(Icons.map_rounded, size: 17),
                      label: Text(l10n.linesViewMap, style: const TextStyle(fontSize: 12.5)),
                    ),
                  ],
                  selected: {_viewMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    setState(() {
                      _viewMode = s.first;
                    });
                    if (_viewMode == _LineViewMode.map) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _fitRouteBounds(_extractCoords(direction));
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _viewMode == _LineViewMode.list
              ? _stopList(l10n, stops, isArabic, modeColor)
              : _mapView(l10n, detail, direction, stops, isArabic, modeColor),
        ),
      ],
    );
  }

  String _cleanStationName(String raw, bool isArabic) {
    var s = raw.trim();
    if (isArabic &&
        (s == 'Moushir Tantawi' ||
            s.contains('Moushir Tantawi') ||
            s.contains('Mosheer Tantawy'))) {
      s = s
          .replaceAll('Moushir Tantawi', 'المشير طنطاوي')
          .replaceAll('Mosheer Tantawy', 'المشير طنطاوي');
    }
    return s;
  }

  String _cleanTerminus(String raw, bool isArabic) {
    var s = _cleanStationName(raw, isArabic);
    s = s
        .replaceAll('محطة مونوريل ', '')
        .replaceAll('محطة ', '')
        .replaceAll(' Monorail Station', '')
        .replaceAll(' Station', '')
        .trim();
    return s;
  }

  String _towardsLabel(
      AppLocalizations l10n, List<Map<String, dynamic>> all, int i, bool isArabic) {
    final direction = all[i];
    final rawTowards = direction['towards']?.toString() ?? '';
    if (rawTowards.isEmpty) return '${i + 1}';

    final towards = _cleanTerminus(rawTowards, isArabic);
    final shared = all.where((d) => d['towards'] == rawTowards).length > 1;
    final rawFrom = direction['from']?.toString() ?? '';
    final from = _cleanTerminus(rawFrom, isArabic);

    if (shared && from.isNotEmpty) {
      return l10n.linesDirectionTowardsFrom(towards, from);
    }
    return l10n.linesDirectionTowards(towards);
  }

  Widget _header(AppLocalizations l10n, Map<String, dynamic> detail,
      Map<String, dynamic> direction, bool isMetro) {
    final description = (detail['description'] ?? '').toString().trim();
    final vehicle =
        InstructionFormatter.vehicleTypeLabel(l10n, detail['vehicle_type'] as String?);
    final headway = direction['typical_headway_min'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TransitModes.icon(detail['vehicle_type'] as String?),
                  size: 18,
                  color: TransitModes.color(detail['vehicle_type'] as String?)),
              const SizedBox(width: 6),
              Text(vehicle,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description,
                style: TextStyle(fontSize: 15, color: context.textPrimary, height: 1.35)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _fact(context, Icons.commit_rounded,
                  l10n.linesStopCount((direction['stops'] as List?)?.length ?? 0)),
              if (headway != null)
                _fact(context, Icons.schedule_rounded,
                    l10n.linesEveryMinutes(_formatNumber(headway))),
              _fact(context, Icons.payments_rounded,
                  _detailedFareText(detail, Localizations.localeOf(context).languageCode == 'ar', l10n)),
            ],
          ),
        ],
      ),
    );
  }

  static String _detailedFareText(
      Map<String, dynamic> detail, bool isArabic, AppLocalizations l10n) {
    final mode = (detail['vehicle_type'] as String? ?? 'bus').toLowerCase();
    final number = (detail['number'] ?? '').toString().toLowerCase();
    final desc = (detail['description'] ?? '').toString().toLowerCase();
    final fare = detail['fare_egp'];

    if (mode == 'metro' || mode.contains('subway')) {
      return isArabic
          ? '10 - 20 ج.م (1-9 محطات: 10 ج • 10-16: 12 ج • 17-23: 15 ج • 24+: 20 ج)'
          : '10 - 20 EGP (1-9 stops: 10 • 10-16: 12 • 17-23: 15 • 24+: 20)';
    } else if (mode == 'lrt') {
      return isArabic
          ? '10 - 20 ج.م (1-3 محطات: 10 ج • 4-7: 15 ج • 8+: 20 ج)'
          : '10 - 20 EGP (1-3 stops: 10 • 4-7: 15 • 8+: 20)';
    } else if (mode == 'monorail') {
      return isArabic
          ? '20 - 80 ج.م (حتى 5 محطات: 20 ج • 10: 40 ج • 15: 55 ج • الخط كاملاً: 80 ج)'
          : '20 - 80 EGP (up to 5 stops: 20 • 10: 40 • 15: 55 • full line: 80)';
    } else if (mode == 'minibus') {
      // Flat per-boarding fare -- was hardcoded to '14 EGP' here, which
      // fell out of date when the backend's FLAT_FARE_BY_VEHICLE minibus
      // figure was raised (see raptor_engine.py). Use the real current
      // value the backend sends, same as the plain-bus branch below.
      final n = fare != null ? _formatNumber(fare) : '20';
      return isArabic
          ? '$n ج.م (تذكرة موحدة للميني باص)'
          : '$n EGP (Standard flat minibus fare)';
    } else if (mode == 'microbus') {
      // Distance-based (MICROBUS_FARE_PER_KM), not a single number -- the
      // minimum is a real backend constant (MICROBUS_MIN_FARE), raised
      // 5 -> 10 without this display text ever following it.
      return isArabic
          ? '10 - 15 ج.م (تعريفة السرفيس بحسب طول المسافة)'
          : '10 - 15 EGP (Microbus fare based on distance)';
    } else if (mode == 'apm') {
      return isArabic ? 'مجاناً (مكوك مجاني بين الصالات)' : 'Free (Inter-terminal shuttle)';
    } else {
      final isAC = number.contains('mm') ||
          number.contains('m') && (number.startsWith('m') || number.startsWith('م')) ||
          desc.contains('مواصلات مصر') ||
          desc.contains('مكيف');
      if (isAC) {
        return isArabic ? '17 - 20 ج.م (أتوبيس مكيف)' : '17 - 20 EGP (Air-conditioned bus)';
      }
      if (fare != null) {
        return isArabic
            ? '${_formatNumber(fare)} ج.م (تذكرة موحدة للنقل العام)'
            : '${_formatNumber(fare)} EGP (Standard CTA bus fare)';
      }
      // Fallback only (fare_egp missing/null, e.g. an old cached response) --
      // matches FLAT_FARE_BY_VEHICLE['bus'] in raptor_engine.py (20 EGP,
      // the project owner's direct correction, see that file's comment),
      // and LinesScreen._fareForRoute's matching fallback for the same
      // reason this whole fix exists: the two screens must not disagree.
      return isArabic ? '20 ج.م (تذكرة موحدة للنقل العام)' : '20 EGP (Standard CTA bus fare)';
    }
  }

  static String _formatNumber(dynamic value) {
    final n = InstructionFormatter.asNum(value)?.toDouble() ?? 0.0;
    return n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);
  }

  Widget _fact(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              style: TextStyle(fontSize: 12.5, color: context.textSecondary)),
        ),
      ],
    );
  }

  List<LatLng> _extractCoords(Map<String, dynamic> direction) =>
      LineDetailScreen.extractCoords(direction);

  void _fitRouteBounds(List<LatLng> coords) {
    if (coords.isEmpty || _mapController == null) return;
    if (coords.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(coords.first, 15),
      );
      return;
    }
    double minLat = 90, maxLat = -90, minLon = 180, maxLon = -180;
    for (final c in coords) {
      if (c.latitude < minLat) minLat = c.latitude;
      if (c.latitude > maxLat) maxLat = c.latitude;
      if (c.longitude < minLon) minLon = c.longitude;
      if (c.longitude > maxLon) maxLon = c.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 48),
    );
  }

  Widget _mapView(
    AppLocalizations l10n,
    Map<String, dynamic> detail,
    Map<String, dynamic> direction,
    List<Map<String, dynamic>> stops,
    bool isArabic,
    Color modeColor,
  ) {
    final isDark = context.isDark;
    final polylineCoords = _extractCoords(direction);

    if (_stopDotIcon == null || _cachedModeColor != modeColor) {
      _initStopDotIcons(modeColor);
    }

    final markers = <Marker>{};
    for (int i = 0; i < stops.length; i++) {
      final s = stops[i];
      final lat = InstructionFormatter.asNum(s['lat'])?.toDouble();
      final lon = InstructionFormatter.asNum(s['lon'])?.toDouble();
      if (lat == null || lon == null) continue;
      final isFirst = i == 0;
      final isLast = i == stops.length - 1;
      final isSelected = _selectedStopIndex == i;
      final name = _cleanStationName((s['name'] ?? '').toString(), isArabic);
      final note = s['note']?.toString();

      BitmapDescriptor icon;
      Offset anchor;
      int zIndex;

      if (isFirst) {
        icon = _originIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        anchor = MapMarkerService.centerAnchor;
        zIndex = isSelected ? 20 : 10;
      } else if (isLast) {
        icon = _destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        anchor = MapMarkerService.pinAnchor;
        zIndex = isSelected ? 20 : 10;
      } else {
        if (isSelected && _selectedStopDotIcon != null) {
          icon = _selectedStopDotIcon!;
          anchor = MapMarkerService.centerAnchor;
          zIndex = 15;
        } else if (_stopDotIcon != null) {
          icon = _stopDotIcon!;
          anchor = MapMarkerService.centerAnchor;
          zIndex = 2;
        } else {
          // Skip intermediate stop markers until custom dot icon is ready.
          // Never clutter the map with giant default balloon pins!
          continue;
        }
      }

      markers.add(
        Marker(
          markerId: MarkerId('stop_${s['stop_id'] ?? i}'),
          position: LatLng(lat, lon),
          icon: icon,
          anchor: anchor,
          zIndexInt: zIndex,
          infoWindow: (isFirst || isLast)
              ? InfoWindow(
                  title: '${i + 1}. $name',
                  snippet: note,
                )
              : InfoWindow.noText,
          onTap: () {
            setState(() {
              _selectedStopIndex = i;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(lat, lon)),
            );
          },
        ),
      );
    }

    final polylines = polylineCoords.isNotEmpty
        ? {
            // Soft background casing stroke for readability
            Polyline(
              polylineId: PolylineId('route_${widget.routeId}_${_directionIndex}_casing'),
              points: polylineCoords,
              color: modeColor.withValues(alpha: 0.35),
              width: 9,
            ),
            // Solid main route polyline
            Polyline(
              polylineId: PolylineId('route_${widget.routeId}_$_directionIndex'),
              points: polylineCoords,
              color: modeColor,
              width: 5,
            ),
          }
        : <Polyline>{};

    final defaultCenter = polylineCoords.isNotEmpty
        ? polylineCoords.first
        : const LatLng(30.0444, 31.2357);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: defaultCenter, zoom: 12),
          polylines: polylines,
          markers: markers,
          style: isDark ? darkMapStyleJson : null,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitRouteBounds(polylineCoords);
            });
          },
          onTap: (_) {
            if (_selectedStopIndex != null) {
              setState(() => _selectedStopIndex = null);
            }
          },
        ),
        Positioned(
          top: 14,
          right: isArabic ? null : 14,
          left: isArabic ? 14 : null,
          child: FloatingActionButton.small(
            heroTag: 'fit_line_route_btn',
            backgroundColor: context.surfaceCard,
            foregroundColor: AppColors.primaryTeal,
            elevation: 3,
            tooltip: l10n.linesFitRoute,
            onPressed: () => _fitRouteBounds(polylineCoords),
            child: const Icon(Icons.crop_free_rounded, size: 20),
          ),
        ),
        if (_selectedStopIndex != null && _selectedStopIndex! < stops.length)
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: _selectedStopCard(
              stops[_selectedStopIndex!],
              _selectedStopIndex!,
              stops.length,
              isArabic,
              modeColor,
            ),
          ),
      ],
    );
  }

  Widget _selectedStopCard(
    Map<String, dynamic> stop,
    int index,
    int totalCount,
    bool isArabic,
    Color modeColor,
  ) {
    final name = _cleanStationName((stop['name'] ?? '').toString(), isArabic);
    final note = stop['note']?.toString();
    final isFirst = index == 0;
    final isLast = index == totalCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.45 : 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isFirst
                      ? Colors.green
                      : (isLast ? Colors.red : modeColor))
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isFirst ? Colors.green : (isLast ? Colors.red : modeColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: context.textSecondary,
            onPressed: () => setState(() => _selectedStopIndex = null),
          ),
        ],
      ),
    );
  }

  /// A timeline rather than a plain list: the line down the left is the
  /// thing that makes "in order" readable at a glance, and the first and
  /// last stops are marked because those are the two a rider checks first.
  Widget _stopList(
    AppLocalizations l10n,
    List<Map<String, dynamic>> stops,
    bool isArabic,
    Color modeColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: stops.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.linesStopsInOrder.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: context.textSecondary),
            ),
          );
        }
        if (i == stops.length + 1) {
          final detail = _detail;
          final directions = List<Map<String, dynamic>>.from(detail?['directions'] ?? const []);
          final dir = directions.isNotEmpty
              ? directions[_directionIndex.clamp(0, directions.length - 1)]
              : <String, dynamic>{};
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: detail == null ? null : () => _openReport(detail, dir),
                icon: Icon(Icons.flag_outlined, size: 16, color: context.textSecondary),
                label: Text(
                  l10n.reportAnIssueWithThisLine,
                  style: TextStyle(color: context.textSecondary, fontSize: 12.5),
                ),
              ),
            ),
          );
        }
        final index = i - 1;
        final isFirst = index == 0;
        final isLast = index == stops.length - 1;
        final name = _cleanStationName((stops[index]['name'] ?? '').toString(), isArabic);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirst
                            ? Colors.transparent
                            : modeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    Container(
                      width: isFirst || isLast ? 13 : 9,
                      height: isFirst || isLast ? 13 : 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst || isLast ? modeColor : context.surfaceCard,
                        border: Border.all(color: modeColor, width: 2),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast
                            ? Colors.transparent
                            : modeColor.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.3,
                      fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Text('${index + 1}',
                    style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }
}

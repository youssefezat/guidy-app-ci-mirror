import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/places_service.dart';
import '../services/maps_link_parser.dart';
import 'RouteOptionsScreen.dart';
import 'LocationPickerScreen.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/search_history_service.dart';
import '../widgets/banner_ad_placeholder.dart';

class LocationSearchScreen extends StatefulWidget {
  final Map<String, dynamic>? initialStartLocation;
  final Map<String, dynamic>? initialEndLocation; // Supports Home/Work Hotkeys

  const LocationSearchScreen({super.key, this.initialStartLocation, this.initialEndLocation});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();

  Map<String, dynamic>? _selectedStart;
  Map<String, dynamic>? _selectedEnd;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentSearches = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  bool _isEditingStart = false;
  // Google Places session token -- covers one search's worth of
  // keystrokes plus the terminating Place Details call, which is what
  // makes Places billing cheap (see places_service.dart). null means
  // "no search in progress"; a fresh one is generated on the first
  // keystroke of each new search and cleared again once a selection
  // resolves or the field is cleared. Never reused across two searches.
  String? _sessionToken;
  // Incremented on every new search; a response only gets applied if it's
  // still the most recent one issued. Without this, a slower response to
  // an OLDER (shorter/partial) query can arrive after a faster response
  // to a NEWER query and silently overwrite the good results with
  // incomplete ones -- this was the actual cause of results appearing to
  // randomly "cut off" on some searches.
  int _searchRequestId = 0;
  /// The exact text the results on screen belong to. "No places found" is
  /// only honest when a search has actually come back for what is currently
  /// typed -- otherwise it flashes during the debounce, and (before the
  /// fields stopped holding their selection as text) it stayed on screen
  /// after both places were chosen, which read as "your choices are wrong".
  String _resultsForQuery = '';

  @override
  void initState() {
    super.initState();
    SearchHistoryService.getRecent().then((recent) {
      if (mounted) setState(() => _recentSearches = recent);
    });

    // Deliberately NOT written into the controllers. A chosen place is
    // shown as the field's hint instead, so the first keystroke replaces
    // it -- previously "My Current Location" sat there as real text and
    // had to be deleted character by character before you could type a
    // different starting point.
    _selectedStart = widget.initialStartLocation;
    _selectedEnd = widget.initialEndLocation;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_selectedStart == null) {
        _startFocusNode.requestFocus();
      } else if (_selectedEnd == null) {
        _endFocusNode.requestFocus();
      }
    });
    
    _startFocusNode.addListener(() {
      if (_startFocusNode.hasFocus) setState(() => _isEditingStart = true);
    });
    
    _endFocusNode.addListener(() {
      if (_endFocusNode.hasFocus) setState(() => _isEditingStart = false);
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (query.isEmpty) {
      // Abandoning whatever search was in progress -- discard the
      // session token rather than let it get reused for an unrelated
      // future search (a reused token bills as if there were no session
      // token at all, i.e. every keystroke individually).
      _sessionToken = null;
      setState(() {
        _searchResults = [];
        _resultsForQuery = '';
        _isLoading = false;
      });
      return;
    }

    // A pasted Google Maps link or raw "lat,lng" is already a precise,
    // resolved location -- skip Places entirely (no point spending a
    // session on it, and a URL isn't a meaningful Autocomplete query
    // anyway) and resolve it directly instead.
    if (MapsLinkParser.looksLikeMapsInput(query)) {
      _handlePastedMapsLink(query);
      return;
    }

    // One token per search, generated on its first keystroke -- not
    // regenerated on every keystroke, which is what actually makes this
    // a "session" for billing purposes.
    // Nothing below the minimum ever reaches the network, so don't show a
    // spinner for a request that will not be made. Clearing the results
    // also matches what the rider sees: backspacing past three characters
    // means the old suggestions no longer match what is in the field.
    if (PlacesService.isQueryTooShort(query)) {
      setState(() {
        _searchResults = [];
        _resultsForQuery = '';
        _isLoading = false;
      });
      return;
    }

    _sessionToken ??= PlacesService.startSession();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final int requestId = ++_searchRequestId;
      setState(() => _isLoading = true);
      try {
        final results = await PlacesService.autocomplete(query, _sessionToken!);
        if (mounted && requestId == _searchRequestId) {
          setState(() {
            _searchResults = results;
            _resultsForQuery = query;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted && requestId == _searchRequestId) setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _handlePastedMapsLink(String text) async {
    // Captured before the awaits: reading localizations off `context`
    // after an async gap is the pattern that produces a use-after-dispose.
    final l10n = AppLocalizations.of(context);
    final String lang = Localizations.localeOf(context).languageCode;
    final int requestId = ++_searchRequestId;
    setState(() => _isLoading = true);
    final parsed = await MapsLinkParser.parse(text);
    if (!mounted || requestId != _searchRequestId) return;

    if (parsed == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noSearchResultsFound)),
        );
      }
      return;
    }

    final name = parsed.name ?? await MapsLinkParser.reverseGeocodeName(parsed.lat, parsed.lon,
            fallbackLabel: l10n.pinnedLocation, lang: lang);
    if (!mounted || requestId != _searchRequestId) return;
    setState(() => _isLoading = false);
    _selectLocation({'name': name, 'full_name': name, 'lat': parsed.lat, 'lon': parsed.lon});
  }

  Future<void> _selectLocation(Map<String, dynamic> location) async {
    final l10n = AppLocalizations.of(context);

    // Recent-search entries (and "my current location") already carry
    // real coordinates from local storage/GPS -- resolving them again
    // through Place Details would be a wasted billable call for data we
    // already have. Only fresh Autocomplete predictions (identified by
    // having a placeId and no coordinates yet) need resolving.
    Map<String, dynamic> resolved;
    if (location['lat'] != null && location['lon'] != null) {
      resolved = location;
    } else {
      final sessionToken = _sessionToken;
      // Session ends here regardless of outcome -- the next search (even
      // a retry after a failed lookup below) starts a fresh one rather
      // than reusing this one, since reuse defeats the billing benefit.
      _sessionToken = null;

      setState(() => _isLoading = true);
      final coords = sessionToken == null
          ? null
          : await PlacesService.getPlaceDetails(location['placeId'], sessionToken);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (coords == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noSearchResultsFound)),
        );
        return;
      }
      resolved = {...location, 'lat': coords['lat'], 'lon': coords['lon']};
    }

    SearchHistoryService.addSearch(resolved['name'], resolved['lat'], resolved['lon']);
    setState(() {
      if (_isEditingStart) {
        _selectedStart = resolved;
        _startController.clear();
        _endFocusNode.requestFocus();
      } else {
        _selectedEnd = resolved;
        _endController.clear();
        _endFocusNode.unfocus();
      }
      _searchResults = [];
    });
  }

  Future<void> _fetchCurrentLocationForStart() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _selectedStart = {
          'name': l10n.myCurrentLocation,
          'lat': position.latitude,
          'lon': position.longitude,
        };
        _startController.clear();
        _isLoading = false;
        _endFocusNode.requestFocus();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.gpsFetchFailed)));
      }
    }
  }

  void _calculateRoute() {
    if (_selectedStart == null || _selectedEnd == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RouteOptionsScreen(
        startLat: _selectedStart!['lat'],
        startLon: _selectedStart!['lon'],
        startName: _selectedStart!['name'],
        endLat: _selectedEnd!['lat'],
        endLon: _selectedEnd!['lon'],
        endName: _selectedEnd!['name'],
      )),
    );
  }

  Future<void> _openMapPinDropper({required bool forStart}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(pickOnly: true),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (forStart) {
          _selectedStart = result;
          _startController.clear();
          _endFocusNode.requestFocus();
        } else {
          _selectedEnd = result;
          _endController.clear();
          _endFocusNode.unfocus();
        }
        _searchResults = [];
      });
      SearchHistoryService.addSearch(
        result['name']?.toString() ?? 'Pinned Location',
        (result['lat'] as num).toDouble(),
        (result['lon'] as num).toDouble(),
      );
    }
  }

  Widget _buildResultsArea(AppLocalizations l10n) {
    final activeController = _isEditingStart ? _startController : _endController;
    final hasQuery = activeController.text.isNotEmpty;

    // No query typed in the focused field yet -- show recent searches
    // (previous, correct behavior for the "just opened this screen" case).
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final mapPinTile = ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.15),
        child: const Icon(Icons.pin_drop, color: AppColors.primaryTeal),
      ),
      title: Text(
        _isEditingStart
            ? (isAr ? 'تحديد نقطة البداية على الخريطة' : 'Drop pin for pickup location')
            : (isAr ? 'تحديد الوجهة على الخريطة' : 'Drop pin for destination'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
      ),
      subtitle: Text(
        isAr ? 'اضغط لتحديد الموقع بدقة على الخريطة' : 'Tap to select an exact point on the map',
        style: TextStyle(fontSize: 12, color: context.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.primaryTeal),
      onTap: () => _openMapPinDropper(forStart: _isEditingStart),
    );

    if (!hasQuery) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          mapPinTile,
          const Divider(height: 20),
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.recentSearchesLabel.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textSecondary, letterSpacing: 0.6)),
                TextButton(
                  onPressed: () async {
                    await SearchHistoryService.clear();
                    if (mounted) setState(() => _recentSearches = []);
                  },
                  child: Text(l10n.clearHistoryLabel, style: const TextStyle(color: AppColors.primaryTeal)),
                ),
              ],
            ),
            ..._recentSearches.map((place) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.fieldFill,
                    child: Icon(Icons.history, color: context.textSecondary),
                  ),
                  title: Text(place['name'], style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
                  onTap: () => _selectLocation(place),
                )),
          ],
        ],
      );
    }

    if (hasQuery &&
        _resultsForQuery == activeController.text &&
        _searchResults.isEmpty &&
        !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.noSearchResultsFound,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openMapPinDropper(forStart: _isEditingStart),
                icon: const Icon(Icons.pin_drop_outlined, color: Colors.white),
                label: Text(
                  isAr ? 'تحديد الموقع على الخريطة' : 'Drop pin on map',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              mapPinTile,
              const Divider(height: 16),
            ],
          );
        }
        final place = _searchResults[index - 1];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: context.fieldFill,
            child: Icon(Icons.location_on, color: context.textSecondary),
          ),
          title: Text(place['name'], style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
          subtitle: Text(place['full_name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.textSecondary)),
          onTap: () => _selectLocation(place),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdPlaceholder(),
      backgroundColor: context.surfaceCard,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceCard,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: context.textPrimary),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: context.fieldFill, borderRadius: BorderRadius.circular(10)),
                          child: TextField(
                            controller: _startController,
                            focusNode: _startFocusNode,
                            onChanged: _onSearchChanged,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              // The chosen place lives in the hint, styled
                              // like a real value. Typing replaces it; there
                              // is nothing to delete first.
                              hintText: _selectedStart?['name'] ?? l10n.pickupLocation,
                              hintStyle: TextStyle(
                                color: _selectedStart != null
                                    ? context.textSecondary.withValues(alpha: 0.85)
                                    : context.textSecondary.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(Icons.circle, size: 12, color: Colors.blue),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.my_location, color: context.textSecondary, size: 20),
                                    tooltip: l10n.useCurrentLocationTooltip,
                                    onPressed: _fetchCurrentLocationForStart,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.pin_drop_outlined, color: AppColors.primaryTeal, size: 20),
                                    tooltip: l10n.pinnedLocation,
                                    onPressed: () => _openMapPinDropper(forStart: true),
                                  ),
                                ],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(color: context.fieldFill, borderRadius: BorderRadius.circular(10)),
                          child: TextField(
                            controller: _endController,
                            focusNode: _endFocusNode,
                            onChanged: _onSearchChanged,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: _selectedEnd?['name'] ?? l10n.whereTo,
                              hintStyle: TextStyle(
                                color: _selectedEnd != null
                                    ? context.textSecondary.withValues(alpha: 0.85)
                                    : context.textSecondary.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Icon(Icons.square, size: 12, color: context.textPrimary),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedEnd != null)
                                    IconButton(
                                      icon: Icon(Icons.close, color: context.textSecondary, size: 18),
                                      tooltip: l10n.clearHistoryLabel,
                                      onPressed: () => setState(() {
                                        _selectedEnd = null;
                                        _endController.clear();
                                        _searchResults = [];
                                      }),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.pin_drop_outlined, color: AppColors.primaryTeal, size: 20),
                                    tooltip: l10n.pinnedLocation,
                                    onPressed: () => _openMapPinDropper(forStart: false),
                                  ),
                                ],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading) const LinearProgressIndicator(color: AppColors.primaryTeal),

            Expanded(
              child: _buildResultsArea(l10n),
            ),

            if (_selectedStart != null && _selectedEnd != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceCard,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ]
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _calculateRoute,
                    child: Text(
                      l10n.findRoutes,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
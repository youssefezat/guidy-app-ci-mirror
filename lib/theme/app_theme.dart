import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Official Guidy brand palette, verified pixel-for-pixel against the source
/// assets in Guidy Assets (Horizontal Logo.svg, Vertical logo.svg, icon 1/2/3/4.svg,
/// and c1.ai / aaaaa.jpg).
///
/// Brand Color Specification:
/// - Brand Navy:  #0B3D71 (Primary corporate identity, "Guidy" wordmark, outer bus body)
/// - Brand Blue:  #2DA3E3 (Transit flow, bus window, navigation chevron, live routes)
/// - Brand Amber: #FFBC70 (Bus wheel, route light trails, warm savings accent)
///
/// Typography:
/// - Latin: Nunito Sans (Google Fonts)
/// - Arabic: Almarai (Google Fonts)
class AppColors {
  AppColors._();

  // Canonical Brand Triad
  static const Color brandNavy = Color(0xFF0B3D71);   // Brand Deep Navy (corporate anchor)
  static const Color brandBlue = Color(0xFF2DA3E3);   // Brand Sky Blue (transit movement)
  static const Color brandAmber = Color(0xFFFFBC70);  // Brand Golden Amber / Peach (warm accent, wheel)

  // Accessible warm accent variants for text / high-contrast icons
  static const Color brandAmberDark = Color(0xFFE88916);
  static const Color brandAmberLight = Color(0xFFFFF4E5);

  // Backward-compatible aliases for existing call sites
  static const Color primaryTeal = brandBlue;
  static const Color transitBlue = brandBlue;
  static const Color deepPetrol = brandNavy;
  static const Color gold = brandAmber;
  static const Color supportingPeach = brandAmber;

  // Additional supporting colors from brand guide
  static const Color supportingSlate = Color(0xFF5C7A99);
  static const Color supportingMint = Color(0xFFDCFCE7);
  static const Color supportingGreen = Color(0xFF2ECC71); // Clean on-time transit green

  // Surfaces: Light Mode (crisp neutral canvas eliminating murky blue cast)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;

  // Surfaces: Dark Mode (sophisticated obsidian slate with subtle navy undertone;
  // completely eliminates the blinding, oversaturated blue wash where cards were previously #0B3D71)
  static const Color darkBackground = Color(0xFF0F1722);
  static const Color darkSurface = Color(0xFF182230);
  static const Color darkSurfaceElevated = Color(0xFF223042);

  // Official Brand Gradient with harmonious blue-to-gold radiance
  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      brandNavy,
      Color(0xFF14548E),
      Color(0xFF1C75B0),
      Color(0xFFDC973C),
      brandAmber,
    ],
    stops: [0.0, 0.28, 0.58, 0.80, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Elegant brand hero card gradient with tasteful, warm gold presence
  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [
      brandNavy,
      Color(0xFF135086),
      Color(0xFF1C75B0),
      Color(0xFFD69339),
      Color(0xFFF9BD6C),
    ],
    stops: [0.0, 0.30, 0.60, 0.82, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 2-Color Subtle Header Gradient
  static const LinearGradient headerGradient = LinearGradient(
    colors: [brandNavy, Color(0xFF19497D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Nunito Sans for Latin script, Almarai for Arabic -- matching the brand
/// guide exactly. Google Fonts serves both, so no font files need to be
/// bundled as assets; GoogleFonts caches them on first load.
TextTheme _brandTextTheme(Locale locale, TextTheme base) {
  return locale.languageCode == 'ar'
      ? GoogleFonts.almaraiTextTheme(base)
      : GoogleFonts.nunitoSansTextTheme(base);
}

class AppTheme {
  AppTheme._();

  static ThemeData light(Locale locale) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brandBlue,
      secondary: AppColors.brandAmberDark,
      tertiary: AppColors.brandNavy,
      surface: AppColors.lightSurface,
      error: Colors.redAccent,
    );

    final textTheme = _brandTextTheme(
      locale,
      ThemeData.light().textTheme.apply(bodyColor: const Color(0xFF0B1B2B), displayColor: const Color(0xFF0B1B2B)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: const Color(0xFF0B1B2B),
        iconTheme: const IconThemeData(color: Color(0xFF0B1B2B)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: const Color(0xFF0B1B2B), fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      cardColor: AppColors.lightSurface,
      dividerColor: Colors.black12,
      iconTheme: const IconThemeData(color: Color(0xFF0B1B2B)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: Colors.black45, fontFamily: textTheme.bodyMedium?.fontFamily),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.brandBlue),
    );
  }

  static ThemeData dark(Locale locale) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.brandBlue,
      secondary: AppColors.brandAmber,
      tertiary: AppColors.brandNavy,
      surface: AppColors.darkSurface,
      error: Colors.redAccent.shade100,
    );

    final textTheme = _brandTextTheme(
      locale,
      ThemeData.dark().textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      cardColor: AppColors.darkSurface,
      dividerColor: Colors.white12,
      iconTheme: const IconThemeData(color: Colors.white70),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: Colors.white38, fontFamily: textTheme.bodyMedium?.fontFamily),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.brandBlue),
    );
  }
}

/// Google Maps' own "Night" style, applied via GoogleMap(style: ...) whenever
/// the app is in dark mode. Tuned to match the elegant obsidian slate
/// (AppColors.darkBackground, #0F1722) and card surfaces (#182230) rather than
/// the old oversaturated blue palette.
const String darkMapStyleJson = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#111823"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ea6be"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0f1722"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#2c3b4e"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#c5d5e6"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#7691ac"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#13212b"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#53796f"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1c2635"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8ea6be"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#223042"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2a3d54"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#d7e4f1"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#223042"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#c5d5e6"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1d2e"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3b587a"}]}
]
''';

/// Small helpers so screens don't have to repeat `Theme.of(context)...`
/// boilerplate everywhere they need to branch on light vs dark.
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Primary body/heading text color for the current theme.
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0B1B2B);

  /// Secondary/caption text color for the current theme.
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  /// Fill color for search bars, input pills, and similar "sunken" containers.
  Color get fieldFill => isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9);

  /// Card/sheet surface color that sits above the scaffold background.
  Color get surfaceCard => isDark ? AppColors.darkSurface : Colors.white;

  /// Accent amber for warm highlights, savings chips, and badges.
  Color get accentAmber => isDark ? AppColors.brandAmber : AppColors.brandAmberDark;
}


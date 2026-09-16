// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Navigate Egypt with intelligence';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String goodMorningUser(String name) {
    return 'Good morning, $name';
  }

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String goodAfternoonUser(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String get goodEvening => 'Good Evening';

  @override
  String goodEveningUser(String name) {
    return 'Good evening, $name';
  }

  @override
  String get goodNight => 'Good Night';

  @override
  String goodNightUser(String name) {
    return 'Good night, $name';
  }

  @override
  String get whereTo => 'Where to?';

  @override
  String get quickAccessHome => 'Home';

  @override
  String get quickAccessWork => 'Work';

  @override
  String get quickAccessSaved => 'Saved';

  @override
  String routingTo(String name) {
    return 'Routing to $name...';
  }

  @override
  String get gpsRequiredToRoute => 'Ensure GPS is enabled to route.';

  @override
  String resettingLocation(String key) {
    return 'Resetting $key location...';
  }

  @override
  String get locationUnavailable =>
      'Could not get location. Ensure GPS is enabled.';

  @override
  String setLocationTitle(String key) {
    return 'Set $key';
  }

  @override
  String locationSavedAs(String key, String name) {
    return '$key saved as $name';
  }

  @override
  String get searchOrTapMap => 'Search or tap map...';

  @override
  String saveAsKey(String key) {
    return 'Save as $key';
  }

  @override
  String get pickupLocation => 'Pickup Location';

  @override
  String get gpsFetchFailed => 'Failed to get GPS location.';

  @override
  String get findRoutes => 'Find Routes';

  @override
  String get routeOptionsTitle => 'Route Options';

  @override
  String get routeCalculationFailed => 'Could not calculate route.';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get availableRoutes => 'Available Routes';

  @override
  String get statDuration => 'Duration';

  @override
  String get statFare => 'Fare';

  @override
  String get statCrowds => 'Crowds';

  @override
  String get statDistance => 'Distance';

  @override
  String routeTimeBreakdown(String riding, String wait) {
    return '$riding min travelling · about $wait min waiting';
  }

  @override
  String stepWaitHint(String wait) {
    return 'Wait about $wait min';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String fareEgp(String amount) {
    return '$amount EGP';
  }

  @override
  String alsoWorksLabel(String routes) {
    return 'Also works: $routes';
  }

  @override
  String routeEveryMinutes(String route, String minutes) {
    return '$route (~every $minutes min)';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get navNowLabel => 'Now';

  @override
  String get navOtherVehicles => 'Other vehicles';

  @override
  String get navAlsoServing => 'Also serving this leg';

  @override
  String get navYourRoute => 'Your route';

  @override
  String navMinutesAway(String minutes) {
    return '~$minutes min away';
  }

  @override
  String get navArrivingNow => 'Arriving now';

  @override
  String navEveryMinutes(String minutes) {
    return 'every ~$minutes min';
  }

  @override
  String get navNoLiveData => 'No live data yet';

  @override
  String get navLocationOff => 'Location is off — the map won\'t follow you.';

  @override
  String get navLocationBlocked =>
      'Location is blocked for Guidy. Turn it on in Settings to follow the route live.';

  @override
  String get navLocationLost => 'Lost GPS signal. Your route is still below.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinGuidyToday => 'Join Guidy today';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordCreateHint => 'Create a password (min. 6 chars)';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get noAccountPrompt => 'Don\'t have an account? ';

  @override
  String get hasAccountPrompt => 'Already have an account? ';

  @override
  String get fillBothFields => 'Please fill in both fields';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get signInFailed => 'Sign in failed';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String get incorrectCredentials => 'Incorrect email or password.';

  @override
  String get checkInternet => 'Check your internet connection.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get emailAlreadyRegistered => 'This email is already registered.';

  @override
  String get languageSwitcherTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get calculatingDistance => 'Calculating...';

  @override
  String get youHaveArrived => 'You have arrived!';

  @override
  String arrivingAt(String station) {
    return 'Arriving at $station...';
  }

  @override
  String distanceKmTo(String distance, String station) {
    return '$distance km to $station';
  }

  @override
  String distanceMTo(String distance, String station) {
    return '$distance m to $station';
  }

  @override
  String stepOf(int index, int total) {
    return 'Step $index of $total';
  }

  @override
  String get myCurrentLocation => 'My Current Location';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get darkModeLabel => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Overrides your device\'s system setting';

  @override
  String get accountSectionLabel => 'Account';

  @override
  String get preferencesSectionLabel => 'Preferences';

  @override
  String get logOut => 'Log Out';

  @override
  String get quickDestinationsLabel => 'Quick Destinations';

  @override
  String get adPlaceholderLabel => 'Advertisement';

  @override
  String get navHome => 'Home';

  @override
  String get navSettings => 'Settings';

  @override
  String get contactUsLabel => 'Contact Us';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithFacebook => 'Continue with Facebook';

  @override
  String get orDivider => 'or';

  @override
  String get socialSignInFailed => 'Couldn\'t sign in. Please try again.';

  @override
  String get onboardingTitle1 => 'Built for Cairo\'s real transit';

  @override
  String get onboardingBody1 =>
      'Metro, buses, and microbuses — including routes Google Maps doesn\'t cover.';

  @override
  String get onboardingTitle2 => 'Real fares, not guesses';

  @override
  String get onboardingBody2 => 'Know what you\'ll pay before you go.';

  @override
  String get onboardingTitle3 => 'Your data, your call';

  @override
  String get onboardingBody3 =>
      'We only use your location to find nearby stops and calculate routes for you.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get savedPlacesTitle => 'Saved Places';

  @override
  String get addPlaceButton => 'Add a place';

  @override
  String get noSavedPlacesYet => 'No saved places yet. Tap below to add one.';

  @override
  String get deletePlaceConfirmTitle => 'Remove this place?';

  @override
  String get deletePlaceConfirmBody => 'You can always add it again later.';

  @override
  String get placeNameHint => 'Name (e.g. Gym, Mosque)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get removeButton => 'Remove';

  @override
  String get noSearchResultsFound => 'No places found. Try a different search.';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get guestLabel => 'Guest';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmBody =>
      'This permanently deletes your account and can\'t be undone.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get reauthRequiredTitle => 'Please sign in again';

  @override
  String get reauthRequiredBody =>
      'For your security, confirm it\'s you before we delete your account.';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get deleteAccountFailed =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get recentSearchesLabel => 'Recent';

  @override
  String get clearHistoryLabel => 'Clear';

  @override
  String get shareRouteButton => 'Share this route';

  @override
  String shareRouteText(
    String start,
    String end,
    String duration,
    String price,
  ) {
    return '$start to $end via Guidy: $duration min, $price';
  }

  @override
  String get retryButton => 'Retry';

  @override
  String get somethingWentWrongTitle => 'Something went wrong';

  @override
  String get rateGuidyLabel => 'Rate Guidy';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get supportSectionLabel => 'Support';

  @override
  String get useCurrentLocationTooltip => 'Use my current location';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get closeMapTooltip => 'Close';

  @override
  String get centerOnMyLocationTooltip => 'Center on my location';

  @override
  String get languageSelectorTooltip => 'Change language';

  @override
  String get removePlaceTooltip => 'Remove this place';

  @override
  String get vehicleBus => 'Bus';

  @override
  String get vehicleMinibus => 'Minibus';

  @override
  String get vehicleMicrobus => 'Microbus';

  @override
  String get vehicleMetro => 'Metro';

  @override
  String get vehicleMonorail => 'Monorail';

  @override
  String get vehicleLrt => 'LRT';

  @override
  String get vehicleTram => 'Tram';

  @override
  String get vehicleAirportShuttle => 'Airport Shuttle';

  @override
  String get vehicleWalk => 'Walk';

  @override
  String get routeTierRecommended => 'Recommended';

  @override
  String get routeTierFastest => 'Fastest';

  @override
  String get routeTierRegular => 'Regular';

  @override
  String get routeTierCheapest => 'Cheapest';

  @override
  String get routeTierAlternative => 'Alternative';

  @override
  String get routeTierWalk => 'Walk';

  @override
  String get crowdLow => 'Low';

  @override
  String get crowdMedium => 'Medium';

  @override
  String get crowdHigh => 'High';

  @override
  String get instrWalkToStationTitle => 'Walk to Station';

  @override
  String instrWalkToStationSubtitle(String distance, String station) {
    return 'Walk ${distance}m to $station';
  }

  @override
  String get instrWalkToTransferTitle => 'Walk to Transfer';

  @override
  String instrWalkToTransferSubtitle(String station) {
    return 'Walk to the next stop near $station';
  }

  @override
  String get instrContinueWalkTitle => 'Walking';

  @override
  String get instrContinueWalkSubtitle => 'Continue on foot';

  @override
  String instrBoardTitleWithVehicle(String vehicleType) {
    return 'Board $vehicleType';
  }

  @override
  String instrBoardWithNumber(String vehicleType, String routeNumber) {
    return '$vehicleType $routeNumber';
  }

  @override
  String instrBoardGeneral(String vehicleType, String routeDescription) {
    return '$vehicleType towards $routeDescription';
  }

  @override
  String get instrTransferTitle => 'Transfer';

  @override
  String get instrArriveTitle => 'Arrive & Disembark';

  @override
  String instrArriveSubtitle(String station) {
    return 'Get off at $station';
  }

  @override
  String get instrWalkToDestinationTitle => 'Walk to Destination';

  @override
  String instrWalkToDestinationSubtitle(String distance) {
    return 'Walk ${distance}m to your destination';
  }

  @override
  String get fareEstimateNote => 'Fares are estimates and may vary';

  @override
  String get tripRecapTitle => 'Trip Overview';

  @override
  String get tripStepsLabel => 'Steps';

  @override
  String get fareTotalLabel => 'Total Fare';

  @override
  String get startNavigationButton => 'Start Navigation';

  @override
  String get navLines => 'Lines';

  @override
  String get navMetro => 'Metro';

  @override
  String get linesTitle => 'Bus & Minibus Lines';

  @override
  String get linesSearchHint => 'Line number, or where it goes';

  @override
  String get linesSearchPrompt =>
      'Search a line number like 65, or a place like Maadi.';

  @override
  String get linesNoResults => 'No lines match that search.';

  @override
  String get linesTapHint => 'Tap a line to see every stop it makes.';

  @override
  String linesStopCount(int count) {
    return '$count stops';
  }

  @override
  String linesEveryMinutes(String minutes) {
    return 'Every ~$minutes min';
  }

  @override
  String linesDirectionTowards(String terminus) {
    return 'Towards $terminus';
  }

  @override
  String get linesStopsInOrder => 'Stops in order';

  @override
  String get linesFareLabel => 'Fare per ride';

  @override
  String get linesMetroFareNote =>
      'Metro fare depends on how many stations you ride.';

  @override
  String get linesFilterAll => 'All';

  @override
  String get linesLoadFailed => 'Couldn\'t load lines right now.';

  @override
  String get linesViewList => 'Stops';

  @override
  String get linesViewMap => 'Map';

  @override
  String get linesFitRoute => 'Fit Route';

  @override
  String get metroTitle => 'Metro Planner';

  @override
  String get metroSubtitle => 'Metro only — no buses, no walking legs.';

  @override
  String get metroFromLabel => 'From';

  @override
  String get metroToLabel => 'To';

  @override
  String get metroPickStation => 'Choose a station';

  @override
  String get metroPlanButton => 'Show metro route';

  @override
  String get metroSameStationError => 'Pick two different stations.';

  @override
  String get metroNoPathError =>
      'We couldn\'t find a metro-only route between those two.';

  @override
  String get metroSearchStationHint => 'Search stations';

  @override
  String metroChangeAt(String station) {
    return 'Change at $station';
  }

  @override
  String metroChangeTo(String line) {
    return 'Change to $line';
  }

  @override
  String metroChangesCount(int count) {
    return '$count changes';
  }

  @override
  String get metroNoChanges => 'Direct — no changes';

  @override
  String get metroInterchangeBadge => 'Interchange';

  @override
  String metroRideStops(int count) {
    return 'Ride $count stops';
  }

  @override
  String get metroSwapTooltip => 'Swap start and destination';

  @override
  String metroLinesServing(String lines) {
    return 'Lines: $lines';
  }

  @override
  String get metroStationsLoadFailed => 'Couldn\'t load the station list.';

  @override
  String get linesMicrobusFareNote =>
      'Microbus fares depend on how far you ride.';

  @override
  String get navOverviewTooltip => 'Show the whole trip';

  @override
  String get navRecenterTooltip => 'Re-center on me';

  @override
  String tripRouteHeading(String start, String end) {
    return '$start to $end';
  }

  @override
  String get fareFree => 'Free';

  @override
  String get pinnedLocation => 'Pinned location';

  @override
  String get serverUnreachable =>
      'Could not reach the Guidy server. Check your connection and try again.';

  @override
  String get errorOutsideCoverage =>
      'That place is outside the area Guidy covers.';

  @override
  String get errorNoRouteFound =>
      'We couldn\'t find a way to get there. It may be outside our coverage.';

  @override
  String get errorNoServiceThisHour =>
      'Nothing is running at this hour. Most routes here run about 06:00 to 23:00 — try again during service hours.';

  @override
  String linesDirectionTowardsFrom(String terminus, String origin) {
    return 'Towards $terminus, from $origin';
  }

  @override
  String get reportTooltip => 'Report this route';

  @override
  String get reportEntryPoint => 'Something wrong with this route?';

  @override
  String get reportTitle => 'Report this route';

  @override
  String get reportIntro =>
      'Our route data comes from open sources, and riders know it better than we do. Tell us what\'s wrong and we\'ll fix it for everyone.';

  @override
  String get reportWhichPart => 'Which part is wrong?';

  @override
  String get reportSelectAll => 'Select all';

  @override
  String get reportClearSelection => 'Clear';

  @override
  String get reportWholeRouteNote =>
      'You\'ve selected every step, so this goes in as a report about the whole route.';

  @override
  String get reportReasonLabel => 'What\'s the problem?';

  @override
  String get reportReasonRouteDoesNotExist => 'This route doesn\'t exist';

  @override
  String get reportReasonWrongStop => 'Wrong stop or station';

  @override
  String get reportReasonBadTiming => 'Times are wrong';

  @override
  String get reportReasonWrongFare => 'Fare is wrong';

  @override
  String get reportReasonBetterRoute => 'I know a better way';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportCommentLabel => 'Tell us more';

  @override
  String get reportCommentHintGeneral =>
      'Optional — anything that helps us check it.';

  @override
  String get reportCommentHintBetterRoute =>
      'Which route would you take instead?';

  @override
  String get reportCommentRequired =>
      'Please tell us a bit more so we can act on it.';

  @override
  String get reportSelectSomething => 'Pick at least one step to report.';

  @override
  String get reportPickReason => 'Pick what\'s wrong with it.';

  @override
  String get reportSubmit => 'Send report';

  @override
  String get reportSent => 'Thanks — your report was sent.';

  @override
  String get reportQueued =>
      'Saved. We\'ll send it as soon as you\'re back online.';

  @override
  String get reportFailed => 'Couldn\'t send that report. Please try again.';

  @override
  String get reportSignInRequired => 'Sign in to send a report.';

  @override
  String get routeTierPartial => 'Gets you close';

  @override
  String partialUncoveredNotice(String distance) {
    return 'This doesn\'t reach your destination. The last $distance isn\'t covered by any route we know yet.';
  }

  @override
  String partialLastCoveredStop(String stop) {
    return 'Last stop we cover: $stop';
  }

  @override
  String nearestHubsHint(String origin, String destination) {
    return 'The closest places we do cover are $origin near your start, and $destination near your destination.';
  }

  @override
  String get reportMissingRouteButton => 'Tell us what\'s missing';

  @override
  String get reportMissingRouteTitle => 'Which route should be here?';

  @override
  String get reportMissingRouteIntro =>
      'Our data is incomplete for this trip. If you know a bus, minibus or microbus that makes it, tell us and we\'ll add it for everyone.';

  @override
  String get reportMissingRouteHint =>
      'e.g. minibus 37 from Kilo 4 & Half to Kafr Tohormos';

  @override
  String get excludeMetro => 'Exclude Metro';

  @override
  String get onlyRouteDisclaimer =>
      'This is currently the only known transit route serving this trip.';

  @override
  String get filterMinWalk => 'Minimum Walk';

  @override
  String get filterMinTransfers => 'Fewest Transfers';

  @override
  String get railMapTitle => 'Rail Network Map';

  @override
  String get shareTripTooltip => 'Share Trip';

  @override
  String get navFitRouteTooltip => 'Route Overview';

  @override
  String get navStopAlarmTooltip => 'Stop Proximity Alert';

  @override
  String get navStopAlarmOn => 'Stop alert active';

  @override
  String get navStopAlarmOff => 'Stop alert disabled';

  @override
  String navStopAlarmAlert(String station) {
    return 'Prepare to get off! Next stop: $station';
  }

  @override
  String get metroTicketTitle => 'Metro Ticket Counter';

  @override
  String get navStopAlarmActiveToast =>
      'Stop alert: Active (vibrates 400m before your stop)';

  @override
  String get navStopAlarmDisabledToast => 'Stop alert: Disabled';

  @override
  String get navRecenterFinding => 'Finding your location...';

  @override
  String get navRecenterSuccess => 'Centered on your location';

  @override
  String get navRecenterFallback => 'GPS unavailable, centered on trip start';

  @override
  String get navOverviewToast => 'Full route overview';

  @override
  String get savedTripsTitle => 'Saved Commutes';

  @override
  String get savedTripsEmpty =>
      'No saved commutes yet. Save frequent trips for instant offline navigation.';

  @override
  String get saveTripTooltip => 'Save Route';

  @override
  String get tripSavedToast => 'Saved to your offline commutes';

  @override
  String get tripRemovedToast => 'Removed from saved commutes';

  @override
  String get offlineModeNotice => 'Offline Mode — displaying saved route';

  @override
  String get offlineBadge => 'Offline';

  @override
  String get savedTripsHomeSubtitle =>
      'Daily commutes with 1 tap, zero data required';

  @override
  String get viewModeList => 'Route List';

  @override
  String get viewModeCompare => 'Quick Compare';

  @override
  String get compareFastest => 'Fastest';

  @override
  String get compareCheapest => 'Cheapest';

  @override
  String get compareLeastWalk => 'Least Walk';

  @override
  String get compareDirect => 'Direct';

  @override
  String get directRouteNoTransfers => 'Direct transit';

  @override
  String transfersCountBadge(int count) {
    return '$count transfers';
  }

  @override
  String walkMetersBadge(String meters) {
    return '$meters m walk';
  }

  @override
  String get quickReportTitle => 'Report Commute Conditions';

  @override
  String get quickReportSubtitle =>
      'Help fellow commuters know live transit status';

  @override
  String get reportCategoryTraffic => 'Traffic standstill / Severe jam';

  @override
  String get reportCategoryMissing => 'Bus delayed or missing';

  @override
  String get reportCategoryCrowd => 'Severe vehicle or stop crowding';

  @override
  String get reportCategoryFare => 'Microbus driver / collector increased fare';

  @override
  String get reportCategoryDiversion => 'Route diverted / Roadblock';

  @override
  String get reportThanksToast =>
      'Thank you — your report helps fellow commuters!';

  @override
  String get reportNotePlaceholder => 'Any extra details? (Optional)';

  @override
  String get budgetTitle => 'Commute Cost Calculator';

  @override
  String get budgetSubtitle =>
      'Track monthly transit expenses and save with Metro subscriptions';

  @override
  String get dailyCostLabel => 'Daily round-trip cost';

  @override
  String get commuteDaysPerWeek => 'Commute days per week';

  @override
  String commuteDaysCount(int days, int total) {
    return '$days days ($total trips per month)';
  }

  @override
  String get monthlyCostLabel => 'Total monthly transit cost';

  @override
  String get metroSubscriptionSavingsTitle => 'Save with Metro Subscriptions';

  @override
  String metroSubscriptionSavingsSubtitle(String amount) {
    return 'A 1-stage monthly subscription saves $amount EGP every month!';
  }

  @override
  String get subTierPublic => 'General Public';

  @override
  String get subTierStudents => 'Students (90% discount)';

  @override
  String get subTierElderly => 'Senior Citizens';

  @override
  String subCostPerMonth(String cost) {
    return '$cost EGP / month';
  }

  @override
  String monthlySavings(String amount) {
    return 'Save $amount EGP / mo';
  }

  @override
  String get metroOfficesTitle => 'Metro Subscription Offices';

  @override
  String get metroOfficesList =>
      'Attaba, Al-Shohadaa, Adly Mansour, Sadat, Cairo University';

  @override
  String get walkManeuverStraight => 'Continue straight';

  @override
  String get walkManeuverRight => 'Turn right';

  @override
  String get walkManeuverLeft => 'Turn left';

  @override
  String get walkManeuverUTurn => 'Make a U-turn';

  @override
  String walkInDistance(String distance, String action) {
    return 'In $distance $action';
  }

  @override
  String walkApproachingBoarding(String station) {
    return 'Approaching boarding stop ($station)';
  }

  @override
  String get walkAtDestination => 'You have arrived at your destination';

  @override
  String get metroNetworkMapTitle => 'Cairo Rail & Metro Network';

  @override
  String get metroNetworkMapButton => 'Network Map';

  @override
  String get schematicDiagramTab => 'Schematic Map';

  @override
  String get stationDirectoryTab => 'Station Directory';

  @override
  String get interchangeTag => 'Interchange';

  @override
  String get navHistory => 'Trips';

  @override
  String get historyTitle => 'Trip History & Savings';

  @override
  String get historySubtitle => 'Your commute tracking & savings';

  @override
  String get totalMoneySaved => 'Money Saved';

  @override
  String get totalTimeSaved => 'Time Saved';

  @override
  String get totalTripsCount => 'Trips Taken';

  @override
  String get co2Prevented => 'CO₂ Avoided';

  @override
  String get savingsComparedToTaxi => 'vs taxis & ride-hails';

  @override
  String get timeSavedBypassing => 'bypassing road traffic';

  @override
  String get emptyHistoryTitle => 'No Trips Logged Yet';

  @override
  String get emptyHistorySubtitle =>
      'Start navigating or plan a trip with Guidy to see your cumulative money, time, and carbon savings!';

  @override
  String get planTripButton => 'Plan a Trip';

  @override
  String get loadDemoTripsButton => 'View Sample Savings';

  @override
  String get repeatTripAction => 'Take Trip Again';

  @override
  String get clearHistoryConfirm => 'Clear all trip history?';

  @override
  String get clearHistoryAction => 'Clear History';

  @override
  String get clearHistorySuccess => 'Trip history cleared';

  @override
  String get tripDeletedToast => 'Trip removed from history';

  @override
  String get savingsCalculationInfoTitle => 'How Savings are Calculated';

  @override
  String get savingsCalculationInfo =>
      'Savings are calculated based on your personal route choice: when you choose the Fastest route, we calculate the minutes you saved compared to slower alternatives, and when you choose the Cheapest route, we calculate the money you saved compared to more expensive alternatives.';

  @override
  String get filterAll => 'All';

  @override
  String get filterThisWeek => 'This Week';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get filterMetro => 'Metro';

  @override
  String get filterBus => 'Bus';

  @override
  String get filterMicrobus => 'Microbus';

  @override
  String minsSavedShort(String mins) {
    return '${mins}m saved';
  }

  @override
  String hoursMinsSavedShort(String hours, String mins) {
    return '${hours}h ${mins}m saved';
  }

  @override
  String moneySavedShort(String amount) {
    return '$amount EGP saved';
  }

  @override
  String get sampleTripsLoadedToast => 'Sample Cairo commutes loaded!';

  @override
  String get reportLineTitle => 'Report Line Issue';

  @override
  String get reportMetroTitle => 'Report Metro Issue';

  @override
  String get reportReasonLineDoesNotExist =>
      'Line does not exist or discontinued';

  @override
  String get reportReasonLineWrongPath =>
      'Route diversion or different streets';

  @override
  String get reportReasonLineWrongStop => 'Wrong stop sequence or missing stop';

  @override
  String get reportReasonLineWrongFare => 'Incorrect fare';

  @override
  String get reportReasonLineBadTiming => 'Inaccurate schedule or frequency';

  @override
  String get reportReasonMetroStationClosed =>
      'Station closed or out of service';

  @override
  String get reportReasonMetroWrongTransfer => 'Incorrect transfer instruction';

  @override
  String get reportReasonMetroWrongFare => 'Incorrect ticket fare';

  @override
  String get reportReasonMetroDelay => 'Significant delay or disruption';

  @override
  String get reportPickStopOptional => 'Select affected stop (optional)';

  @override
  String get reportAllStopsOption => 'General line issue (entire route)';

  @override
  String get reportActionSubmit => 'Submit Report';

  @override
  String get reportActionCancel => 'Cancel';

  @override
  String get reportLineSuccessToast =>
      'Thank you! Your report has been submitted to improve the network.';

  @override
  String get reportCommentHint =>
      'Add details (e.g. actual fare, detour street, etc.)';

  @override
  String get reportAnIssueWithThisLine => 'Report an issue with this line';

  @override
  String get reportAnIssueWithMetro => 'Report an issue with this metro route';

  @override
  String get reportCategoryOther => 'Other issue';

  @override
  String get reportReasonPrompt => 'What is the problem?';

  @override
  String get recentTripsTitle => 'Recent Trips';

  @override
  String get recentTripsSubtitle =>
      'Trips you\'ve taken, their cost and duration';

  @override
  String get noRecentTripsYet =>
      'No trips taken yet. Take a ride and it will appear here!';

  @override
  String get customizeRouteCardTitle => 'Customize Your Route';

  @override
  String get customizeRouteCardSubtitle =>
      'Choose the vehicle you prefer on this route';

  @override
  String get customizeSelectVehiclePrompt => 'Available Vehicles';

  @override
  String get customizeEstimatedDuration => 'Est. Duration';

  @override
  String get customizeEstimatedFare => 'Est. Fare';

  @override
  String get customizeViewRouteAction => 'View This Route';

  @override
  String moneySavedPill(String amount) {
    return 'Saved $amount EGP';
  }

  @override
  String timeSavedPill(String minutes) {
    return 'Saved $minutes min';
  }

  @override
  String get tripDetailFarePaid => 'Fare Paid';

  @override
  String get tripDetailVsTaxi => 'vs Taxi / Uber';

  @override
  String get tripDetailVsTraffic => 'vs Traffic';

  @override
  String get tripDetailOpenRecap => 'View Trip Details';

  @override
  String get budgetScreenHeader => 'Transit Budget & Metro Pass Savings';

  @override
  String get budgetHowItWorksTitle => 'How this Calculator Works';

  @override
  String get budgetHowItWorksBody =>
      'Buying single paper tickets every day adds up quickly! A monthly Cairo Metro smart card pass offers unlimited rides for a fixed discounted rate (up to 90% off for students). Set your routine to see your net savings.';

  @override
  String get budgetCommuterCategory => 'Commuter Category';

  @override
  String budgetRoutineTrips(String trips) {
    return '$trips trips/month (2 trips/day)';
  }

  @override
  String get budgetStageHeader => 'Metro Stage / Trip Distance';

  @override
  String get budgetSingleTicketsMonthly =>
      'Monthly Out-of-Pocket (Single Tickets)';

  @override
  String historySavedTimeExplanation(String minutes) {
    return 'Chose Fastest & saved $minutes min';
  }

  @override
  String historySavedMoneyExplanation(String amount) {
    return 'Chose Cheapest & saved $amount EGP';
  }

  @override
  String get historyCustomizedChoice => 'Customized route chosen';

  @override
  String get chooseOnMap => 'Choose on Map';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get pinDropped => 'Pinned Location';
}

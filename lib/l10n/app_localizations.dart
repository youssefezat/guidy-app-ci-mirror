import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Navigate Egypt with intelligence'**
  String get appTagline;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodMorningUser.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorningUser(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodAfternoonUser.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String goodAfternoonUser(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodEveningUser.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String goodEveningUser(String name);

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @goodNightUser.
  ///
  /// In en, this message translates to:
  /// **'Good night, {name}'**
  String goodNightUser(String name);

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @quickAccessHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get quickAccessHome;

  /// No description provided for @quickAccessWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get quickAccessWork;

  /// No description provided for @quickAccessSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get quickAccessSaved;

  /// No description provided for @routingTo.
  ///
  /// In en, this message translates to:
  /// **'Routing to {name}...'**
  String routingTo(String name);

  /// No description provided for @gpsRequiredToRoute.
  ///
  /// In en, this message translates to:
  /// **'Ensure GPS is enabled to route.'**
  String get gpsRequiredToRoute;

  /// No description provided for @resettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Resetting {key} location...'**
  String resettingLocation(String key);

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get location. Ensure GPS is enabled.'**
  String get locationUnavailable;

  /// No description provided for @setLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Set {key}'**
  String setLocationTitle(String key);

  /// No description provided for @locationSavedAs.
  ///
  /// In en, this message translates to:
  /// **'{key} saved as {name}'**
  String locationSavedAs(String key, String name);

  /// No description provided for @searchOrTapMap.
  ///
  /// In en, this message translates to:
  /// **'Search or tap map...'**
  String get searchOrTapMap;

  /// No description provided for @saveAsKey.
  ///
  /// In en, this message translates to:
  /// **'Save as {key}'**
  String saveAsKey(String key);

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// No description provided for @gpsFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get GPS location.'**
  String get gpsFetchFailed;

  /// No description provided for @findRoutes.
  ///
  /// In en, this message translates to:
  /// **'Find Routes'**
  String get findRoutes;

  /// No description provided for @routeOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Options'**
  String get routeOptionsTitle;

  /// No description provided for @routeCalculationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate route.'**
  String get routeCalculationFailed;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @availableRoutes.
  ///
  /// In en, this message translates to:
  /// **'Available Routes'**
  String get availableRoutes;

  /// No description provided for @statDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get statDuration;

  /// No description provided for @statFare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get statFare;

  /// No description provided for @statCrowds.
  ///
  /// In en, this message translates to:
  /// **'Crowds'**
  String get statCrowds;

  /// No description provided for @statDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get statDistance;

  /// No description provided for @routeTimeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{riding} min travelling · about {wait} min waiting'**
  String routeTimeBreakdown(String riding, String wait);

  /// No description provided for @stepWaitHint.
  ///
  /// In en, this message translates to:
  /// **'Wait about {wait} min'**
  String stepWaitHint(String wait);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(String minutes);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @fareEgp.
  ///
  /// In en, this message translates to:
  /// **'{amount} EGP'**
  String fareEgp(String amount);

  /// No description provided for @alsoWorksLabel.
  ///
  /// In en, this message translates to:
  /// **'Also works: {routes}'**
  String alsoWorksLabel(String routes);

  /// No description provided for @routeEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'{route} (~every {minutes} min)'**
  String routeEveryMinutes(String route, String minutes);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @navNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get navNowLabel;

  /// No description provided for @navOtherVehicles.
  ///
  /// In en, this message translates to:
  /// **'Other vehicles'**
  String get navOtherVehicles;

  /// No description provided for @navAlsoServing.
  ///
  /// In en, this message translates to:
  /// **'Also serving this leg'**
  String get navAlsoServing;

  /// No description provided for @navYourRoute.
  ///
  /// In en, this message translates to:
  /// **'Your route'**
  String get navYourRoute;

  /// No description provided for @navMinutesAway.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min away'**
  String navMinutesAway(String minutes);

  /// No description provided for @navArrivingNow.
  ///
  /// In en, this message translates to:
  /// **'Arriving now'**
  String get navArrivingNow;

  /// No description provided for @navEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'every ~{minutes} min'**
  String navEveryMinutes(String minutes);

  /// No description provided for @navNoLiveData.
  ///
  /// In en, this message translates to:
  /// **'No live data yet'**
  String get navNoLiveData;

  /// No description provided for @navLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off — the map won\'t follow you.'**
  String get navLocationOff;

  /// No description provided for @navLocationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for Guidy. Turn it on in Settings to follow the route live.'**
  String get navLocationBlocked;

  /// No description provided for @navLocationLost.
  ///
  /// In en, this message translates to:
  /// **'Lost GPS signal. Your route is still below.'**
  String get navLocationLost;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinGuidyToday.
  ///
  /// In en, this message translates to:
  /// **'Join Guidy today'**
  String get joinGuidyToday;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameHint;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password (min. 6 chars)'**
  String get passwordCreateHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordHint;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountPrompt;

  /// No description provided for @hasAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get hasAccountPrompt;

  /// No description provided for @fillBothFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields'**
  String get fillBothFields;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get signInFailed;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// No description provided for @incorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get incorrectCredentials;

  /// No description provided for @checkInternet.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection.'**
  String get checkInternet;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyRegistered;

  /// No description provided for @languageSwitcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSwitcherTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @calculatingDistance.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculatingDistance;

  /// No description provided for @youHaveArrived.
  ///
  /// In en, this message translates to:
  /// **'You have arrived!'**
  String get youHaveArrived;

  /// No description provided for @arrivingAt.
  ///
  /// In en, this message translates to:
  /// **'Arriving at {station}...'**
  String arrivingAt(String station);

  /// No description provided for @distanceKmTo.
  ///
  /// In en, this message translates to:
  /// **'{distance} km to {station}'**
  String distanceKmTo(String distance, String station);

  /// No description provided for @distanceMTo.
  ///
  /// In en, this message translates to:
  /// **'{distance} m to {station}'**
  String distanceMTo(String distance, String station);

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {index} of {total}'**
  String stepOf(int index, int total);

  /// No description provided for @myCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'My Current Location'**
  String get myCurrentLocation;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overrides your device\'s system setting'**
  String get darkModeSubtitle;

  /// No description provided for @accountSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionLabel;

  /// No description provided for @preferencesSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSectionLabel;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @quickDestinationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick Destinations'**
  String get quickDestinationsLabel;

  /// No description provided for @adPlaceholderLabel.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get adPlaceholderLabel;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @contactUsLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUsLabel;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get continueWithFacebook;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @socialSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Please try again.'**
  String get socialSignInFailed;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Built for Cairo\'s real transit'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Metro, buses, and microbuses — including routes Google Maps doesn\'t cover.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Real fares, not guesses'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Know what you\'ll pay before you go.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Your data, your call'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'We only use your location to find nearby stops and calculate routes for you.'**
  String get onboardingBody3;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @savedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Places'**
  String get savedPlacesTitle;

  /// No description provided for @addPlaceButton.
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get addPlaceButton;

  /// No description provided for @noSavedPlacesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet. Tap below to add one.'**
  String get noSavedPlacesYet;

  /// No description provided for @deletePlaceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this place?'**
  String get deletePlaceConfirmTitle;

  /// No description provided for @deletePlaceConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You can always add it again later.'**
  String get deletePlaceConfirmBody;

  /// No description provided for @placeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Gym, Mosque)'**
  String get placeNameHint;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @noSearchResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No places found. Try a different search.'**
  String get noSearchResultsFound;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @guestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestLabel;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and can\'t be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @reauthRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get reauthRequiredTitle;

  /// No description provided for @reauthRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'For your security, confirm it\'s you before we delete your account.'**
  String get reauthRequiredBody;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @recentSearchesLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentSearchesLabel;

  /// No description provided for @clearHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearHistoryLabel;

  /// No description provided for @shareRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Share this route'**
  String get shareRouteButton;

  /// No description provided for @shareRouteText.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end} via Guidy: {duration} min, {price}'**
  String shareRouteText(
    String start,
    String end,
    String duration,
    String price,
  );

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @somethingWentWrongTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrongTitle;

  /// No description provided for @rateGuidyLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate Guidy'**
  String get rateGuidyLabel;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// No description provided for @supportSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSectionLabel;

  /// No description provided for @useCurrentLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentLocationTooltip;

  /// No description provided for @showPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// No description provided for @hidePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// No description provided for @closeMapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeMapTooltip;

  /// No description provided for @centerOnMyLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get centerOnMyLocationTooltip;

  /// No description provided for @languageSelectorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get languageSelectorTooltip;

  /// No description provided for @removePlaceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove this place'**
  String get removePlaceTooltip;

  /// No description provided for @vehicleBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get vehicleBus;

  /// No description provided for @vehicleMinibus.
  ///
  /// In en, this message translates to:
  /// **'Minibus'**
  String get vehicleMinibus;

  /// No description provided for @vehicleMicrobus.
  ///
  /// In en, this message translates to:
  /// **'Microbus'**
  String get vehicleMicrobus;

  /// No description provided for @vehicleMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get vehicleMetro;

  /// No description provided for @vehicleMonorail.
  ///
  /// In en, this message translates to:
  /// **'Monorail'**
  String get vehicleMonorail;

  /// No description provided for @vehicleLrt.
  ///
  /// In en, this message translates to:
  /// **'LRT'**
  String get vehicleLrt;

  /// No description provided for @vehicleTram.
  ///
  /// In en, this message translates to:
  /// **'Tram'**
  String get vehicleTram;

  /// No description provided for @vehicleAirportShuttle.
  ///
  /// In en, this message translates to:
  /// **'Airport Shuttle'**
  String get vehicleAirportShuttle;

  /// No description provided for @vehicleWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get vehicleWalk;

  /// No description provided for @routeTierRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get routeTierRecommended;

  /// No description provided for @routeTierFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get routeTierFastest;

  /// No description provided for @routeTierRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get routeTierRegular;

  /// No description provided for @routeTierCheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get routeTierCheapest;

  /// No description provided for @routeTierAlternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get routeTierAlternative;

  /// No description provided for @routeTierWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get routeTierWalk;

  /// No description provided for @crowdLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get crowdLow;

  /// No description provided for @crowdMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get crowdMedium;

  /// No description provided for @crowdHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get crowdHigh;

  /// No description provided for @instrWalkToStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk to Station'**
  String get instrWalkToStationTitle;

  /// No description provided for @instrWalkToStationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Walk {distance}m to {station}'**
  String instrWalkToStationSubtitle(String distance, String station);

  /// No description provided for @instrWalkToTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk to Transfer'**
  String get instrWalkToTransferTitle;

  /// No description provided for @instrWalkToTransferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Walk to the next stop near {station}'**
  String instrWalkToTransferSubtitle(String station);

  /// No description provided for @instrContinueWalkTitle.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get instrContinueWalkTitle;

  /// No description provided for @instrContinueWalkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue on foot'**
  String get instrContinueWalkSubtitle;

  /// No description provided for @instrBoardTitleWithVehicle.
  ///
  /// In en, this message translates to:
  /// **'Board {vehicleType}'**
  String instrBoardTitleWithVehicle(String vehicleType);

  /// No description provided for @instrBoardWithNumber.
  ///
  /// In en, this message translates to:
  /// **'{vehicleType} {routeNumber}'**
  String instrBoardWithNumber(String vehicleType, String routeNumber);

  /// No description provided for @instrBoardGeneral.
  ///
  /// In en, this message translates to:
  /// **'{vehicleType} towards {routeDescription}'**
  String instrBoardGeneral(String vehicleType, String routeDescription);

  /// No description provided for @instrTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get instrTransferTitle;

  /// No description provided for @instrArriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrive & Disembark'**
  String get instrArriveTitle;

  /// No description provided for @instrArriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get off at {station}'**
  String instrArriveSubtitle(String station);

  /// No description provided for @instrWalkToDestinationTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk to Destination'**
  String get instrWalkToDestinationTitle;

  /// No description provided for @instrWalkToDestinationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Walk {distance}m to your destination'**
  String instrWalkToDestinationSubtitle(String distance);

  /// No description provided for @fareEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Fares are estimates and may vary'**
  String get fareEstimateNote;

  /// No description provided for @tripRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Overview'**
  String get tripRecapTitle;

  /// No description provided for @tripStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get tripStepsLabel;

  /// No description provided for @fareTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Fare'**
  String get fareTotalLabel;

  /// No description provided for @startNavigationButton.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigationButton;

  /// No description provided for @navLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get navLines;

  /// No description provided for @navMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get navMetro;

  /// No description provided for @linesTitle.
  ///
  /// In en, this message translates to:
  /// **'Bus & Minibus Lines'**
  String get linesTitle;

  /// No description provided for @linesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Line number, or where it goes'**
  String get linesSearchHint;

  /// No description provided for @linesSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search a line number like 65, or a place like Maadi.'**
  String get linesSearchPrompt;

  /// No description provided for @linesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No lines match that search.'**
  String get linesNoResults;

  /// No description provided for @linesTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a line to see every stop it makes.'**
  String get linesTapHint;

  /// No description provided for @linesStopCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String linesStopCount(int count);

  /// No description provided for @linesEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every ~{minutes} min'**
  String linesEveryMinutes(String minutes);

  /// No description provided for @linesDirectionTowards.
  ///
  /// In en, this message translates to:
  /// **'Towards {terminus}'**
  String linesDirectionTowards(String terminus);

  /// No description provided for @linesStopsInOrder.
  ///
  /// In en, this message translates to:
  /// **'Stops in order'**
  String get linesStopsInOrder;

  /// No description provided for @linesFareLabel.
  ///
  /// In en, this message translates to:
  /// **'Fare per ride'**
  String get linesFareLabel;

  /// No description provided for @linesMetroFareNote.
  ///
  /// In en, this message translates to:
  /// **'Metro fare depends on how many stations you ride.'**
  String get linesMetroFareNote;

  /// No description provided for @linesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get linesFilterAll;

  /// No description provided for @linesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load lines right now.'**
  String get linesLoadFailed;

  /// No description provided for @linesViewList.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get linesViewList;

  /// No description provided for @linesViewMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get linesViewMap;

  /// No description provided for @linesFitRoute.
  ///
  /// In en, this message translates to:
  /// **'Fit Route'**
  String get linesFitRoute;

  /// No description provided for @metroTitle.
  ///
  /// In en, this message translates to:
  /// **'Metro Planner'**
  String get metroTitle;

  /// No description provided for @metroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Metro only — no buses, no walking legs.'**
  String get metroSubtitle;

  /// No description provided for @metroFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get metroFromLabel;

  /// No description provided for @metroToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get metroToLabel;

  /// No description provided for @metroPickStation.
  ///
  /// In en, this message translates to:
  /// **'Choose a station'**
  String get metroPickStation;

  /// No description provided for @metroPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Show metro route'**
  String get metroPlanButton;

  /// No description provided for @metroSameStationError.
  ///
  /// In en, this message translates to:
  /// **'Pick two different stations.'**
  String get metroSameStationError;

  /// No description provided for @metroNoPathError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a metro-only route between those two.'**
  String get metroNoPathError;

  /// No description provided for @metroSearchStationHint.
  ///
  /// In en, this message translates to:
  /// **'Search stations'**
  String get metroSearchStationHint;

  /// No description provided for @metroChangeAt.
  ///
  /// In en, this message translates to:
  /// **'Change at {station}'**
  String metroChangeAt(String station);

  /// No description provided for @metroChangeTo.
  ///
  /// In en, this message translates to:
  /// **'Change to {line}'**
  String metroChangeTo(String line);

  /// No description provided for @metroChangesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} changes'**
  String metroChangesCount(int count);

  /// No description provided for @metroNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Direct — no changes'**
  String get metroNoChanges;

  /// No description provided for @metroInterchangeBadge.
  ///
  /// In en, this message translates to:
  /// **'Interchange'**
  String get metroInterchangeBadge;

  /// No description provided for @metroRideStops.
  ///
  /// In en, this message translates to:
  /// **'Ride {count} stops'**
  String metroRideStops(int count);

  /// No description provided for @metroSwapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap start and destination'**
  String get metroSwapTooltip;

  /// No description provided for @metroLinesServing.
  ///
  /// In en, this message translates to:
  /// **'Lines: {lines}'**
  String metroLinesServing(String lines);

  /// No description provided for @metroStationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the station list.'**
  String get metroStationsLoadFailed;

  /// No description provided for @linesMicrobusFareNote.
  ///
  /// In en, this message translates to:
  /// **'Microbus fares depend on how far you ride.'**
  String get linesMicrobusFareNote;

  /// No description provided for @navOverviewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show the whole trip'**
  String get navOverviewTooltip;

  /// No description provided for @navRecenterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Re-center on me'**
  String get navRecenterTooltip;

  /// No description provided for @tripRouteHeading.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String tripRouteHeading(String start, String end);

  /// No description provided for @fareFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get fareFree;

  /// No description provided for @pinnedLocation.
  ///
  /// In en, this message translates to:
  /// **'Pinned location'**
  String get pinnedLocation;

  /// No description provided for @serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Guidy server. Check your connection and try again.'**
  String get serverUnreachable;

  /// No description provided for @errorOutsideCoverage.
  ///
  /// In en, this message translates to:
  /// **'That place is outside the area Guidy covers.'**
  String get errorOutsideCoverage;

  /// No description provided for @errorNoRouteFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a way to get there. It may be outside our coverage.'**
  String get errorNoRouteFound;

  /// No description provided for @errorNoServiceThisHour.
  ///
  /// In en, this message translates to:
  /// **'Nothing is running at this hour. Most routes here run about 06:00 to 23:00 — try again during service hours.'**
  String get errorNoServiceThisHour;

  /// No description provided for @linesDirectionTowardsFrom.
  ///
  /// In en, this message translates to:
  /// **'Towards {terminus}, from {origin}'**
  String linesDirectionTowardsFrom(String terminus, String origin);

  /// No description provided for @reportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report this route'**
  String get reportTooltip;

  /// No description provided for @reportEntryPoint.
  ///
  /// In en, this message translates to:
  /// **'Something wrong with this route?'**
  String get reportEntryPoint;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this route'**
  String get reportTitle;

  /// No description provided for @reportIntro.
  ///
  /// In en, this message translates to:
  /// **'Our route data comes from open sources, and riders know it better than we do. Tell us what\'s wrong and we\'ll fix it for everyone.'**
  String get reportIntro;

  /// No description provided for @reportWhichPart.
  ///
  /// In en, this message translates to:
  /// **'Which part is wrong?'**
  String get reportWhichPart;

  /// No description provided for @reportSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get reportSelectAll;

  /// No description provided for @reportClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get reportClearSelection;

  /// No description provided for @reportWholeRouteNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ve selected every step, so this goes in as a report about the whole route.'**
  String get reportWholeRouteNote;

  /// No description provided for @reportReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s the problem?'**
  String get reportReasonLabel;

  /// No description provided for @reportReasonRouteDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'This route doesn\'t exist'**
  String get reportReasonRouteDoesNotExist;

  /// No description provided for @reportReasonWrongStop.
  ///
  /// In en, this message translates to:
  /// **'Wrong stop or station'**
  String get reportReasonWrongStop;

  /// No description provided for @reportReasonBadTiming.
  ///
  /// In en, this message translates to:
  /// **'Times are wrong'**
  String get reportReasonBadTiming;

  /// No description provided for @reportReasonWrongFare.
  ///
  /// In en, this message translates to:
  /// **'Fare is wrong'**
  String get reportReasonWrongFare;

  /// No description provided for @reportReasonBetterRoute.
  ///
  /// In en, this message translates to:
  /// **'I know a better way'**
  String get reportReasonBetterRoute;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get reportCommentLabel;

  /// No description provided for @reportCommentHintGeneral.
  ///
  /// In en, this message translates to:
  /// **'Optional — anything that helps us check it.'**
  String get reportCommentHintGeneral;

  /// No description provided for @reportCommentHintBetterRoute.
  ///
  /// In en, this message translates to:
  /// **'Which route would you take instead?'**
  String get reportCommentHintBetterRoute;

  /// No description provided for @reportCommentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please tell us a bit more so we can act on it.'**
  String get reportCommentRequired;

  /// No description provided for @reportSelectSomething.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one step to report.'**
  String get reportSelectSomething;

  /// No description provided for @reportPickReason.
  ///
  /// In en, this message translates to:
  /// **'Pick what\'s wrong with it.'**
  String get reportPickReason;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSubmit;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your report was sent.'**
  String get reportSent;

  /// No description provided for @reportQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved. We\'ll send it as soon as you\'re back online.'**
  String get reportQueued;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send that report. Please try again.'**
  String get reportFailed;

  /// No description provided for @reportSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send a report.'**
  String get reportSignInRequired;

  /// No description provided for @routeTierPartial.
  ///
  /// In en, this message translates to:
  /// **'Gets you close'**
  String get routeTierPartial;

  /// No description provided for @partialUncoveredNotice.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t reach your destination. The last {distance} isn\'t covered by any route we know yet.'**
  String partialUncoveredNotice(String distance);

  /// No description provided for @partialLastCoveredStop.
  ///
  /// In en, this message translates to:
  /// **'Last stop we cover: {stop}'**
  String partialLastCoveredStop(String stop);

  /// No description provided for @nearestHubsHint.
  ///
  /// In en, this message translates to:
  /// **'The closest places we do cover are {origin} near your start, and {destination} near your destination.'**
  String nearestHubsHint(String origin, String destination);

  /// No description provided for @reportMissingRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s missing'**
  String get reportMissingRouteButton;

  /// No description provided for @reportMissingRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Which route should be here?'**
  String get reportMissingRouteTitle;

  /// No description provided for @reportMissingRouteIntro.
  ///
  /// In en, this message translates to:
  /// **'Our data is incomplete for this trip. If you know a bus, minibus or microbus that makes it, tell us and we\'ll add it for everyone.'**
  String get reportMissingRouteIntro;

  /// No description provided for @reportMissingRouteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. minibus 37 from Kilo 4 & Half to Kafr Tohormos'**
  String get reportMissingRouteHint;

  /// No description provided for @excludeMetro.
  ///
  /// In en, this message translates to:
  /// **'Exclude Metro'**
  String get excludeMetro;

  /// No description provided for @onlyRouteDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is currently the only known transit route serving this trip.'**
  String get onlyRouteDisclaimer;

  /// No description provided for @filterMinWalk.
  ///
  /// In en, this message translates to:
  /// **'Minimum Walk'**
  String get filterMinWalk;

  /// No description provided for @filterMinTransfers.
  ///
  /// In en, this message translates to:
  /// **'Fewest Transfers'**
  String get filterMinTransfers;

  /// No description provided for @railMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Rail Network Map'**
  String get railMapTitle;

  /// No description provided for @shareTripTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share Trip'**
  String get shareTripTooltip;

  /// No description provided for @navFitRouteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Route Overview'**
  String get navFitRouteTooltip;

  /// No description provided for @navStopAlarmTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop Proximity Alert'**
  String get navStopAlarmTooltip;

  /// No description provided for @navStopAlarmOn.
  ///
  /// In en, this message translates to:
  /// **'Stop alert active'**
  String get navStopAlarmOn;

  /// No description provided for @navStopAlarmOff.
  ///
  /// In en, this message translates to:
  /// **'Stop alert disabled'**
  String get navStopAlarmOff;

  /// No description provided for @navStopAlarmAlert.
  ///
  /// In en, this message translates to:
  /// **'Prepare to get off! Next stop: {station}'**
  String navStopAlarmAlert(String station);

  /// No description provided for @metroTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Metro Ticket Counter'**
  String get metroTicketTitle;

  /// No description provided for @navStopAlarmActiveToast.
  ///
  /// In en, this message translates to:
  /// **'Stop alert: Active (vibrates 400m before your stop)'**
  String get navStopAlarmActiveToast;

  /// No description provided for @navStopAlarmDisabledToast.
  ///
  /// In en, this message translates to:
  /// **'Stop alert: Disabled'**
  String get navStopAlarmDisabledToast;

  /// No description provided for @navRecenterFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get navRecenterFinding;

  /// No description provided for @navRecenterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Centered on your location'**
  String get navRecenterSuccess;

  /// No description provided for @navRecenterFallback.
  ///
  /// In en, this message translates to:
  /// **'GPS unavailable, centered on trip start'**
  String get navRecenterFallback;

  /// No description provided for @navOverviewToast.
  ///
  /// In en, this message translates to:
  /// **'Full route overview'**
  String get navOverviewToast;

  /// No description provided for @savedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Commutes'**
  String get savedTripsTitle;

  /// No description provided for @savedTripsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved commutes yet. Save frequent trips for instant offline navigation.'**
  String get savedTripsEmpty;

  /// No description provided for @saveTripTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save Route'**
  String get saveTripTooltip;

  /// No description provided for @tripSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved to your offline commutes'**
  String get tripSavedToast;

  /// No description provided for @tripRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved commutes'**
  String get tripRemovedToast;

  /// No description provided for @offlineModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode — displaying saved route'**
  String get offlineModeNotice;

  /// No description provided for @offlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineBadge;

  /// No description provided for @savedTripsHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily commutes with 1 tap, zero data required'**
  String get savedTripsHomeSubtitle;

  /// No description provided for @viewModeList.
  ///
  /// In en, this message translates to:
  /// **'Route List'**
  String get viewModeList;

  /// No description provided for @viewModeCompare.
  ///
  /// In en, this message translates to:
  /// **'Quick Compare'**
  String get viewModeCompare;

  /// No description provided for @compareFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get compareFastest;

  /// No description provided for @compareCheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get compareCheapest;

  /// No description provided for @compareLeastWalk.
  ///
  /// In en, this message translates to:
  /// **'Least Walk'**
  String get compareLeastWalk;

  /// No description provided for @compareDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get compareDirect;

  /// No description provided for @directRouteNoTransfers.
  ///
  /// In en, this message translates to:
  /// **'Direct transit'**
  String get directRouteNoTransfers;

  /// No description provided for @transfersCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} transfers'**
  String transfersCountBadge(int count);

  /// No description provided for @walkMetersBadge.
  ///
  /// In en, this message translates to:
  /// **'{meters} m walk'**
  String walkMetersBadge(String meters);

  /// No description provided for @quickReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Commute Conditions'**
  String get quickReportTitle;

  /// No description provided for @quickReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help fellow commuters know live transit status'**
  String get quickReportSubtitle;

  /// No description provided for @reportCategoryTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic standstill / Severe jam'**
  String get reportCategoryTraffic;

  /// No description provided for @reportCategoryMissing.
  ///
  /// In en, this message translates to:
  /// **'Bus delayed or missing'**
  String get reportCategoryMissing;

  /// No description provided for @reportCategoryCrowd.
  ///
  /// In en, this message translates to:
  /// **'Severe vehicle or stop crowding'**
  String get reportCategoryCrowd;

  /// No description provided for @reportCategoryFare.
  ///
  /// In en, this message translates to:
  /// **'Microbus driver / collector increased fare'**
  String get reportCategoryFare;

  /// No description provided for @reportCategoryDiversion.
  ///
  /// In en, this message translates to:
  /// **'Route diverted / Roadblock'**
  String get reportCategoryDiversion;

  /// No description provided for @reportThanksToast.
  ///
  /// In en, this message translates to:
  /// **'Thank you — your report helps fellow commuters!'**
  String get reportThanksToast;

  /// No description provided for @reportNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Any extra details? (Optional)'**
  String get reportNotePlaceholder;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Commute Cost Calculator'**
  String get budgetTitle;

  /// No description provided for @budgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track monthly transit expenses and save with Metro subscriptions'**
  String get budgetSubtitle;

  /// No description provided for @dailyCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily round-trip cost'**
  String get dailyCostLabel;

  /// No description provided for @commuteDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Commute days per week'**
  String get commuteDaysPerWeek;

  /// No description provided for @commuteDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days ({total} trips per month)'**
  String commuteDaysCount(int days, int total);

  /// No description provided for @monthlyCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Total monthly transit cost'**
  String get monthlyCostLabel;

  /// No description provided for @metroSubscriptionSavingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Save with Metro Subscriptions'**
  String get metroSubscriptionSavingsTitle;

  /// No description provided for @metroSubscriptionSavingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A 1-stage monthly subscription saves {amount} EGP every month!'**
  String metroSubscriptionSavingsSubtitle(String amount);

  /// No description provided for @subTierPublic.
  ///
  /// In en, this message translates to:
  /// **'General Public'**
  String get subTierPublic;

  /// No description provided for @subTierStudents.
  ///
  /// In en, this message translates to:
  /// **'Students (90% discount)'**
  String get subTierStudents;

  /// No description provided for @subTierElderly.
  ///
  /// In en, this message translates to:
  /// **'Senior Citizens'**
  String get subTierElderly;

  /// No description provided for @subCostPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{cost} EGP / month'**
  String subCostPerMonth(String cost);

  /// No description provided for @monthlySavings.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} EGP / mo'**
  String monthlySavings(String amount);

  /// No description provided for @metroOfficesTitle.
  ///
  /// In en, this message translates to:
  /// **'Metro Subscription Offices'**
  String get metroOfficesTitle;

  /// No description provided for @metroOfficesList.
  ///
  /// In en, this message translates to:
  /// **'Attaba, Al-Shohadaa, Adly Mansour, Sadat, Cairo University'**
  String get metroOfficesList;

  /// No description provided for @walkManeuverStraight.
  ///
  /// In en, this message translates to:
  /// **'Continue straight'**
  String get walkManeuverStraight;

  /// No description provided for @walkManeuverRight.
  ///
  /// In en, this message translates to:
  /// **'Turn right'**
  String get walkManeuverRight;

  /// No description provided for @walkManeuverLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn left'**
  String get walkManeuverLeft;

  /// No description provided for @walkManeuverUTurn.
  ///
  /// In en, this message translates to:
  /// **'Make a U-turn'**
  String get walkManeuverUTurn;

  /// No description provided for @walkInDistance.
  ///
  /// In en, this message translates to:
  /// **'In {distance} {action}'**
  String walkInDistance(String distance, String action);

  /// No description provided for @walkApproachingBoarding.
  ///
  /// In en, this message translates to:
  /// **'Approaching boarding stop ({station})'**
  String walkApproachingBoarding(String station);

  /// No description provided for @walkAtDestination.
  ///
  /// In en, this message translates to:
  /// **'You have arrived at your destination'**
  String get walkAtDestination;

  /// No description provided for @metroNetworkMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Cairo Rail & Metro Network'**
  String get metroNetworkMapTitle;

  /// No description provided for @metroNetworkMapButton.
  ///
  /// In en, this message translates to:
  /// **'Network Map'**
  String get metroNetworkMapButton;

  /// No description provided for @schematicDiagramTab.
  ///
  /// In en, this message translates to:
  /// **'Schematic Map'**
  String get schematicDiagramTab;

  /// No description provided for @stationDirectoryTab.
  ///
  /// In en, this message translates to:
  /// **'Station Directory'**
  String get stationDirectoryTab;

  /// No description provided for @interchangeTag.
  ///
  /// In en, this message translates to:
  /// **'Interchange'**
  String get interchangeTag;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navHistory;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip History & Savings'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your commute tracking & savings'**
  String get historySubtitle;

  /// No description provided for @totalMoneySaved.
  ///
  /// In en, this message translates to:
  /// **'Money Saved'**
  String get totalMoneySaved;

  /// No description provided for @totalTimeSaved.
  ///
  /// In en, this message translates to:
  /// **'Time Saved'**
  String get totalTimeSaved;

  /// No description provided for @totalTripsCount.
  ///
  /// In en, this message translates to:
  /// **'Trips Taken'**
  String get totalTripsCount;

  /// No description provided for @co2Prevented.
  ///
  /// In en, this message translates to:
  /// **'CO₂ Avoided'**
  String get co2Prevented;

  /// No description provided for @savingsComparedToTaxi.
  ///
  /// In en, this message translates to:
  /// **'vs taxis & ride-hails'**
  String get savingsComparedToTaxi;

  /// No description provided for @timeSavedBypassing.
  ///
  /// In en, this message translates to:
  /// **'bypassing road traffic'**
  String get timeSavedBypassing;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No Trips Logged Yet'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start navigating or plan a trip with Guidy to see your cumulative money, time, and carbon savings!'**
  String get emptyHistorySubtitle;

  /// No description provided for @planTripButton.
  ///
  /// In en, this message translates to:
  /// **'Plan a Trip'**
  String get planTripButton;

  /// No description provided for @loadDemoTripsButton.
  ///
  /// In en, this message translates to:
  /// **'View Sample Savings'**
  String get loadDemoTripsButton;

  /// No description provided for @repeatTripAction.
  ///
  /// In en, this message translates to:
  /// **'Take Trip Again'**
  String get repeatTripAction;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all trip history?'**
  String get clearHistoryConfirm;

  /// No description provided for @clearHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistoryAction;

  /// No description provided for @clearHistorySuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip history cleared'**
  String get clearHistorySuccess;

  /// No description provided for @tripDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Trip removed from history'**
  String get tripDeletedToast;

  /// No description provided for @savingsCalculationInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'How Savings are Calculated'**
  String get savingsCalculationInfoTitle;

  /// No description provided for @savingsCalculationInfo.
  ///
  /// In en, this message translates to:
  /// **'Savings are calculated based on your personal route choice: when you choose the Fastest route, we calculate the minutes you saved compared to slower alternatives, and when you choose the Cheapest route, we calculate the money you saved compared to more expensive alternatives.'**
  String get savingsCalculationInfo;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get filterThisWeek;

  /// No description provided for @filterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get filterThisMonth;

  /// No description provided for @filterMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get filterMetro;

  /// No description provided for @filterBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get filterBus;

  /// No description provided for @filterMicrobus.
  ///
  /// In en, this message translates to:
  /// **'Microbus'**
  String get filterMicrobus;

  /// No description provided for @minsSavedShort.
  ///
  /// In en, this message translates to:
  /// **'{mins}m saved'**
  String minsSavedShort(String mins);

  /// No description provided for @hoursMinsSavedShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {mins}m saved'**
  String hoursMinsSavedShort(String hours, String mins);

  /// No description provided for @moneySavedShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} EGP saved'**
  String moneySavedShort(String amount);

  /// No description provided for @sampleTripsLoadedToast.
  ///
  /// In en, this message translates to:
  /// **'Sample Cairo commutes loaded!'**
  String get sampleTripsLoadedToast;

  /// No description provided for @reportLineTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Line Issue'**
  String get reportLineTitle;

  /// No description provided for @reportMetroTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Metro Issue'**
  String get reportMetroTitle;

  /// No description provided for @reportReasonLineDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Line does not exist or discontinued'**
  String get reportReasonLineDoesNotExist;

  /// No description provided for @reportReasonLineWrongPath.
  ///
  /// In en, this message translates to:
  /// **'Route diversion or different streets'**
  String get reportReasonLineWrongPath;

  /// No description provided for @reportReasonLineWrongStop.
  ///
  /// In en, this message translates to:
  /// **'Wrong stop sequence or missing stop'**
  String get reportReasonLineWrongStop;

  /// No description provided for @reportReasonLineWrongFare.
  ///
  /// In en, this message translates to:
  /// **'Incorrect fare'**
  String get reportReasonLineWrongFare;

  /// No description provided for @reportReasonLineBadTiming.
  ///
  /// In en, this message translates to:
  /// **'Inaccurate schedule or frequency'**
  String get reportReasonLineBadTiming;

  /// No description provided for @reportReasonMetroStationClosed.
  ///
  /// In en, this message translates to:
  /// **'Station closed or out of service'**
  String get reportReasonMetroStationClosed;

  /// No description provided for @reportReasonMetroWrongTransfer.
  ///
  /// In en, this message translates to:
  /// **'Incorrect transfer instruction'**
  String get reportReasonMetroWrongTransfer;

  /// No description provided for @reportReasonMetroWrongFare.
  ///
  /// In en, this message translates to:
  /// **'Incorrect ticket fare'**
  String get reportReasonMetroWrongFare;

  /// No description provided for @reportReasonMetroDelay.
  ///
  /// In en, this message translates to:
  /// **'Significant delay or disruption'**
  String get reportReasonMetroDelay;

  /// No description provided for @reportPickStopOptional.
  ///
  /// In en, this message translates to:
  /// **'Select affected stop (optional)'**
  String get reportPickStopOptional;

  /// No description provided for @reportAllStopsOption.
  ///
  /// In en, this message translates to:
  /// **'General line issue (entire route)'**
  String get reportAllStopsOption;

  /// No description provided for @reportActionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportActionSubmit;

  /// No description provided for @reportActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reportActionCancel;

  /// No description provided for @reportLineSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your report has been submitted to improve the network.'**
  String get reportLineSuccessToast;

  /// No description provided for @reportCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add details (e.g. actual fare, detour street, etc.)'**
  String get reportCommentHint;

  /// No description provided for @reportAnIssueWithThisLine.
  ///
  /// In en, this message translates to:
  /// **'Report an issue with this line'**
  String get reportAnIssueWithThisLine;

  /// No description provided for @reportAnIssueWithMetro.
  ///
  /// In en, this message translates to:
  /// **'Report an issue with this metro route'**
  String get reportAnIssueWithMetro;

  /// No description provided for @reportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other issue'**
  String get reportCategoryOther;

  /// No description provided for @reportReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'What is the problem?'**
  String get reportReasonPrompt;

  /// No description provided for @recentTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Trips'**
  String get recentTripsTitle;

  /// No description provided for @recentTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trips you\'ve taken, their cost and duration'**
  String get recentTripsSubtitle;

  /// No description provided for @noRecentTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips taken yet. Take a ride and it will appear here!'**
  String get noRecentTripsYet;

  /// No description provided for @customizeRouteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Your Route'**
  String get customizeRouteCardTitle;

  /// No description provided for @customizeRouteCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the vehicle you prefer on this route'**
  String get customizeRouteCardSubtitle;

  /// No description provided for @customizeSelectVehiclePrompt.
  ///
  /// In en, this message translates to:
  /// **'Available Vehicles'**
  String get customizeSelectVehiclePrompt;

  /// No description provided for @customizeEstimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Est. Duration'**
  String get customizeEstimatedDuration;

  /// No description provided for @customizeEstimatedFare.
  ///
  /// In en, this message translates to:
  /// **'Est. Fare'**
  String get customizeEstimatedFare;

  /// No description provided for @customizeViewRouteAction.
  ///
  /// In en, this message translates to:
  /// **'View This Route'**
  String get customizeViewRouteAction;

  /// No description provided for @moneySavedPill.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount} EGP'**
  String moneySavedPill(String amount);

  /// No description provided for @timeSavedPill.
  ///
  /// In en, this message translates to:
  /// **'Saved {minutes} min'**
  String timeSavedPill(String minutes);

  /// No description provided for @tripDetailFarePaid.
  ///
  /// In en, this message translates to:
  /// **'Fare Paid'**
  String get tripDetailFarePaid;

  /// No description provided for @tripDetailVsTaxi.
  ///
  /// In en, this message translates to:
  /// **'vs Taxi / Uber'**
  String get tripDetailVsTaxi;

  /// No description provided for @tripDetailVsTraffic.
  ///
  /// In en, this message translates to:
  /// **'vs Traffic'**
  String get tripDetailVsTraffic;

  /// No description provided for @tripDetailOpenRecap.
  ///
  /// In en, this message translates to:
  /// **'View Trip Details'**
  String get tripDetailOpenRecap;

  /// No description provided for @budgetScreenHeader.
  ///
  /// In en, this message translates to:
  /// **'Transit Budget & Metro Pass Savings'**
  String get budgetScreenHeader;

  /// No description provided for @budgetHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How this Calculator Works'**
  String get budgetHowItWorksTitle;

  /// No description provided for @budgetHowItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'Buying single paper tickets every day adds up quickly! A monthly Cairo Metro smart card pass offers unlimited rides for a fixed discounted rate (up to 90% off for students). Set your routine to see your net savings.'**
  String get budgetHowItWorksBody;

  /// No description provided for @budgetCommuterCategory.
  ///
  /// In en, this message translates to:
  /// **'Commuter Category'**
  String get budgetCommuterCategory;

  /// No description provided for @budgetRoutineTrips.
  ///
  /// In en, this message translates to:
  /// **'{trips} trips/month (2 trips/day)'**
  String budgetRoutineTrips(String trips);

  /// No description provided for @budgetStageHeader.
  ///
  /// In en, this message translates to:
  /// **'Metro Stage / Trip Distance'**
  String get budgetStageHeader;

  /// No description provided for @budgetSingleTicketsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly Out-of-Pocket (Single Tickets)'**
  String get budgetSingleTicketsMonthly;

  /// No description provided for @historySavedTimeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Chose Fastest & saved {minutes} min'**
  String historySavedTimeExplanation(String minutes);

  /// No description provided for @historySavedMoneyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Chose Cheapest & saved {amount} EGP'**
  String historySavedMoneyExplanation(String amount);

  /// No description provided for @historyCustomizedChoice.
  ///
  /// In en, this message translates to:
  /// **'Customized route chosen'**
  String get historyCustomizedChoice;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on Map'**
  String get chooseOnMap;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @pinDropped.
  ///
  /// In en, this message translates to:
  /// **'Pinned Location'**
  String get pinDropped;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

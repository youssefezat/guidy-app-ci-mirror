// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTagline => 'رفيقك في مواصلات مصر';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String goodMorningUser(String name) {
    return 'صباح الخير يا $name';
  }

  @override
  String get goodAfternoon => 'نهارك سعيد';

  @override
  String goodAfternoonUser(String name) {
    return 'نهارك سعيد يا $name';
  }

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String goodEveningUser(String name) {
    return 'مساء الخير يا $name';
  }

  @override
  String get goodNight => 'مساء الخير';

  @override
  String goodNightUser(String name) {
    return 'مساء الخير يا $name';
  }

  @override
  String get whereTo => 'رايح فين؟';

  @override
  String get quickAccessHome => 'البيت';

  @override
  String get quickAccessWork => 'الشغل';

  @override
  String get quickAccessSaved => 'محفوظ';

  @override
  String routingTo(String name) {
    return 'بنوصلك لـ $name...';
  }

  @override
  String get gpsRequiredToRoute => 'لازم تشغل الـ GPS عشان نقدر نوصلك.';

  @override
  String resettingLocation(String key) {
    return 'بنغيّر مكان $key...';
  }

  @override
  String get locationUnavailable =>
      'معرفناش نجيب مكانك. اتأكد إن الـ GPS شغال.';

  @override
  String setLocationTitle(String key) {
    return 'حدد مكان $key';
  }

  @override
  String locationSavedAs(String key, String name) {
    return 'اتحفظ $key باسم $name';
  }

  @override
  String get searchOrTapMap => 'دوّر أو دوس على الخريطة...';

  @override
  String saveAsKey(String key) {
    return 'احفظ كـ $key';
  }

  @override
  String get pickupLocation => 'منين؟';

  @override
  String get gpsFetchFailed => 'معرفناش نجيب موقعك بالـ GPS.';

  @override
  String get findRoutes => 'دوّر على مواصلة';

  @override
  String get routeOptionsTitle => 'خيارات الرحلة';

  @override
  String get routeCalculationFailed => 'معرفناش نحسب الطريق.';

  @override
  String errorPrefix(String message) {
    return 'في مشكلة: $message';
  }

  @override
  String get availableRoutes => 'المواصلات المتاحة';

  @override
  String get statDuration => 'المدة';

  @override
  String get statFare => 'السعر';

  @override
  String get statCrowds => 'الزحمة';

  @override
  String get statDistance => 'المسافة';

  @override
  String routeTimeBreakdown(String riding, String wait) {
    return '$riding دقيقة ركوب · حوالي $wait دقيقة انتظار';
  }

  @override
  String stepWaitHint(String wait) {
    return 'استنى حوالي $wait دقيقة';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String distanceKm(String km) {
    return '$km كم';
  }

  @override
  String fareEgp(String amount) {
    return '$amount جنيه';
  }

  @override
  String alsoWorksLabel(String routes) {
    return 'كمان ينفع: $routes';
  }

  @override
  String routeEveryMinutes(String route, String minutes) {
    return '$route كل $minutes دقيقة تقريبًا';
  }

  @override
  String get listSeparator => '، ';

  @override
  String get navNowLabel => 'دلوقتي';

  @override
  String get navOtherVehicles => 'مواصلات تانية';

  @override
  String get navAlsoServing => 'مواصلات تانية على نفس الخط';

  @override
  String get navYourRoute => 'خطك';

  @override
  String navMinutesAway(String minutes) {
    return 'جاي بعد $minutes دقيقة تقريبًا';
  }

  @override
  String get navArrivingNow => 'جاي دلوقتي';

  @override
  String navEveryMinutes(String minutes) {
    return 'كل $minutes دقيقة تقريبًا';
  }

  @override
  String get navNoLiveData => 'مفيش بيانات مباشرة لسه';

  @override
  String get navLocationOff => 'الموقع مقفول — الخريطة مش هتتحرك معاك.';

  @override
  String get navLocationBlocked =>
      'الموقع محجوب لجايدي. افتحه من الإعدادات عشان تتابع الخط مباشرة.';

  @override
  String get navLocationLost => 'الإشارة ضاعت. خطواتك لسه تحت.';

  @override
  String get createAccount => 'اعمل حساب';

  @override
  String get joinGuidyToday => 'انضم لـ Guidy دلوقتي';

  @override
  String get nameLabel => 'الاسم بالكامل';

  @override
  String get nameHint => 'اكتب اسمك';

  @override
  String get emailLabel => 'الإيميل';

  @override
  String get emailHint => 'اكتب إيميلك';

  @override
  String get passwordLabel => 'الباسورد';

  @override
  String get passwordHint => 'اكتب الباسورد';

  @override
  String get passwordCreateHint => 'اعمل باسورد (6 حروف على الأقل)';

  @override
  String get confirmPasswordLabel => 'تأكيد الباسورد';

  @override
  String get confirmPasswordHint => 'أكد الباسورد';

  @override
  String get signIn => 'دخول';

  @override
  String get signUp => 'تسجيل';

  @override
  String get noAccountPrompt => 'مش عندك حساب؟ ';

  @override
  String get hasAccountPrompt => 'عندك حساب بالفعل؟ ';

  @override
  String get fillBothFields => 'لازم تملى الخانتين';

  @override
  String get fillAllFields => 'لازم تملى كل الخانات';

  @override
  String get invalidEmail => 'اكتب إيميل صحيح';

  @override
  String get signInFailed => 'الدخول فشل';

  @override
  String get signUpFailed => 'التسجيل فشل';

  @override
  String get incorrectCredentials => 'الإيميل أو الباسورد غلط.';

  @override
  String get checkInternet => 'اتأكد من النت عندك.';

  @override
  String get passwordTooShort => 'الباسورد لازم يكون 6 حروف على الأقل';

  @override
  String get passwordsDontMatch => 'الباسوردين مش زي بعض';

  @override
  String get emailAlreadyRegistered => 'الإيميل ده متسجل قبل كده.';

  @override
  String get languageSwitcherTitle => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get calculatingDistance => 'بنحسب المسافة...';

  @override
  String get youHaveArrived => 'وصلت!';

  @override
  String arrivingAt(String station) {
    return 'واصل عند $station...';
  }

  @override
  String distanceKmTo(String distance, String station) {
    return '$distance كم لحد $station';
  }

  @override
  String distanceMTo(String distance, String station) {
    return '$distance متر لحد $station';
  }

  @override
  String stepOf(int index, int total) {
    return 'خطوة $index من $total';
  }

  @override
  String get myCurrentLocation => 'موقعي الحالي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get darkModeLabel => 'الوضع الليلي';

  @override
  String get darkModeSubtitle => 'بيغيّر وضع التطبيق مهما كان إعداد موبايلك';

  @override
  String get accountSectionLabel => 'الحساب';

  @override
  String get preferencesSectionLabel => 'التفضيلات';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get quickDestinationsLabel => 'وجهات سريعة';

  @override
  String get adPlaceholderLabel => 'إعلان';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get contactUsLabel => 'تواصل معانا';

  @override
  String get continueWithGoogle => 'الدخول بحساب Google';

  @override
  String get continueWithFacebook => 'الدخول بحساب Facebook';

  @override
  String get orDivider => 'أو';

  @override
  String get socialSignInFailed => 'معرفناش نسجل دخولك. جرب تاني.';

  @override
  String get onboardingTitle1 => 'اتعمل خصيصي لمواصلات القاهرة الحقيقية';

  @override
  String get onboardingBody1 =>
      'مترو، أتوبيسات، وميكروباصات — حتى الخطوط اللي مش موجودة في Google Maps.';

  @override
  String get onboardingTitle2 => 'أسعار حقيقية مش تخمين';

  @override
  String get onboardingBody2 => 'اعرف هتدفع كام قبل ما تتحرك.';

  @override
  String get onboardingTitle3 => 'بياناتك، قرارك';

  @override
  String get onboardingBody3 =>
      'بنستخدم موقعك بس عشان نلاقي أقرب محطة ونحسبلك الطريق.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingGetStarted => 'يلا نبدأ';

  @override
  String get savedPlacesTitle => 'الأماكن المحفوظة';

  @override
  String get addPlaceButton => 'ضيف مكان';

  @override
  String get noSavedPlacesYet =>
      'لسه مفيش أماكن محفوظة. دوس تحت عشان تضيف واحد.';

  @override
  String get deletePlaceConfirmTitle => 'تشيل المكان ده؟';

  @override
  String get deletePlaceConfirmBody => 'تقدر تضيفه تاني في أي وقت.';

  @override
  String get placeNameHint => 'الاسم (زي: الجيم، المسجد)';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get removeButton => 'شيل';

  @override
  String get noSearchResultsFound => 'معلقناش على حاجة. جرب تدور بطريقة تانية.';

  @override
  String get continueAsGuest => 'كمل كضيف';

  @override
  String get guestLabel => 'ضيف';

  @override
  String get deleteAccountButton => 'احذف الحساب';

  @override
  String get deleteAccountConfirmTitle => 'متأكد إنك عايز تحذف حسابك؟';

  @override
  String get deleteAccountConfirmBody => 'الخطوة دي نهائية ومش هينفع ترجعها.';

  @override
  String get deleteButton => 'احذف';

  @override
  String get reauthRequiredTitle => 'سجل دخولك تاني';

  @override
  String get reauthRequiredBody =>
      'علشان أمانك، أكد إنك إنت قبل ما نحذف حسابك.';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get deleteAccountFailed => 'معرفناش نحذف حسابك. جرب تاني.';

  @override
  String get recentSearchesLabel => 'الأخيرة';

  @override
  String get clearHistoryLabel => 'امسح';

  @override
  String get shareRouteButton => 'شارك الطريق ده';

  @override
  String shareRouteText(
    String start,
    String end,
    String duration,
    String price,
  ) {
    return '$start لـ $end عن طريق Guidy: $duration دقيقة، $price';
  }

  @override
  String get retryButton => 'حاول تاني';

  @override
  String get somethingWentWrongTitle => 'حصلت مشكلة';

  @override
  String get rateGuidyLabel => 'قيّم Guidy';

  @override
  String get privacyPolicyLabel => 'سياسة الخصوصية';

  @override
  String get supportSectionLabel => 'الدعم';

  @override
  String get useCurrentLocationTooltip => 'استخدم موقعي الحالي';

  @override
  String get showPasswordTooltip => 'اظهر الباسورد';

  @override
  String get hidePasswordTooltip => 'اخفي الباسورد';

  @override
  String get closeMapTooltip => 'قفل';

  @override
  String get centerOnMyLocationTooltip => 'روح لموقعي';

  @override
  String get languageSelectorTooltip => 'غيّر اللغة';

  @override
  String get removePlaceTooltip => 'شيل المكان ده';

  @override
  String get vehicleBus => 'أتوبيس';

  @override
  String get vehicleMinibus => 'ميني باص';

  @override
  String get vehicleMicrobus => 'ميكروباص';

  @override
  String get vehicleMetro => 'المترو';

  @override
  String get vehicleMonorail => 'المونوريل';

  @override
  String get vehicleLrt => 'القطار الكهربائي الخفيف';

  @override
  String get vehicleTram => 'الترام';

  @override
  String get vehicleAirportShuttle => 'مكوك المطار';

  @override
  String get vehicleWalk => 'مشي';

  @override
  String get routeTierRecommended => 'الموصى به';

  @override
  String get routeTierFastest => 'الأسرع';

  @override
  String get routeTierRegular => 'عادي';

  @override
  String get routeTierCheapest => 'الأرخص';

  @override
  String get routeTierAlternative => 'سكة تانية';

  @override
  String get routeTierWalk => 'مشي';

  @override
  String get crowdLow => 'قليلة';

  @override
  String get crowdMedium => 'متوسطة';

  @override
  String get crowdHigh => 'كتير';

  @override
  String get instrWalkToStationTitle => 'امشي للمحطة';

  @override
  String instrWalkToStationSubtitle(String distance, String station) {
    return 'امشي $distance متر لحد $station';
  }

  @override
  String get instrWalkToTransferTitle => 'امشي لمحطة التغيير';

  @override
  String instrWalkToTransferSubtitle(String station) {
    return 'امشي للمحطة اللي جاية قرب $station';
  }

  @override
  String get instrContinueWalkTitle => 'بتمشي';

  @override
  String get instrContinueWalkSubtitle => 'كمل مشي';

  @override
  String instrBoardTitleWithVehicle(String vehicleType) {
    return 'اركب $vehicleType';
  }

  @override
  String instrBoardWithNumber(String vehicleType, String routeNumber) {
    return '$vehicleType رقم $routeNumber';
  }

  @override
  String instrBoardGeneral(String vehicleType, String routeDescription) {
    return '$vehicleType رايح $routeDescription';
  }

  @override
  String get instrTransferTitle => 'غيّر مواصلة';

  @override
  String get instrArriveTitle => 'وصلت، انزل';

  @override
  String instrArriveSubtitle(String station) {
    return 'انزل عند $station';
  }

  @override
  String get instrWalkToDestinationTitle => 'امشي لوجهتك';

  @override
  String instrWalkToDestinationSubtitle(String distance) {
    return 'امشي $distance متر لحد وجهتك';
  }

  @override
  String get fareEstimateNote => 'الأسعار تقريبية وممكن تختلف';

  @override
  String get tripRecapTitle => 'نظرة على الرحلة';

  @override
  String get tripStepsLabel => 'الخطوات';

  @override
  String get fareTotalLabel => 'إجمالي السعر';

  @override
  String get startNavigationButton => 'ابدأ الرحلة';

  @override
  String get navLines => 'الخطوط';

  @override
  String get navMetro => 'المترو';

  @override
  String get linesTitle => 'خطوط الأتوبيس والميكروباص';

  @override
  String get linesSearchHint => 'رقم الخط، أو المنطقة اللي بيعدي منها';

  @override
  String get linesSearchPrompt =>
      'ابحث برقم الخط زي 65، أو باسم مكان زي المعادي.';

  @override
  String get linesNoResults => 'مفيش خطوط مطابقة للبحث.';

  @override
  String get linesTapHint => 'دوس على أي خط تشوف كل محطاته.';

  @override
  String linesStopCount(int count) {
    return '$count محطة';
  }

  @override
  String linesEveryMinutes(String minutes) {
    return 'كل ~$minutes دقيقة';
  }

  @override
  String linesDirectionTowards(String terminus) {
    return 'باتجاه $terminus';
  }

  @override
  String get linesStopsInOrder => 'المحطات بالترتيب';

  @override
  String get linesFareLabel => 'سعر الركوبة';

  @override
  String get linesMetroFareNote =>
      'تذكرة المترو بتتحسب على عدد المحطات اللي هتركبها.';

  @override
  String get linesFilterAll => 'الكل';

  @override
  String get linesLoadFailed => 'مش قادرين نحمّل الخطوط دلوقتي.';

  @override
  String get linesViewList => 'المحطات';

  @override
  String get linesViewMap => 'الخريطة';

  @override
  String get linesFitRoute => 'ضبط المسار';

  @override
  String get metroTitle => 'مخطط المترو';

  @override
  String get metroSubtitle => 'مترو بس — من غير أتوبيسات ولا مشي.';

  @override
  String get metroFromLabel => 'من';

  @override
  String get metroToLabel => 'إلى';

  @override
  String get metroPickStation => 'اختر محطة';

  @override
  String get metroPlanButton => 'اعرض خط المترو';

  @override
  String get metroSameStationError => 'اختر محطتين مختلفتين.';

  @override
  String get metroNoPathError => 'مفيش طريق بالمترو لوحده بين المحطتين دول.';

  @override
  String get metroSearchStationHint => 'ابحث عن محطة';

  @override
  String metroChangeAt(String station) {
    return 'غيّر عند $station';
  }

  @override
  String metroChangeTo(String line) {
    return 'غيّر لخط $line';
  }

  @override
  String metroChangesCount(int count) {
    return '$count تغيير';
  }

  @override
  String get metroNoChanges => 'مباشر — من غير تغيير';

  @override
  String get metroInterchangeBadge => 'محطة تبديل';

  @override
  String metroRideStops(int count) {
    return 'اركب $count محطة';
  }

  @override
  String get metroSwapTooltip => 'بدّل البداية والوجهة';

  @override
  String metroLinesServing(String lines) {
    return 'الخطوط: $lines';
  }

  @override
  String get metroStationsLoadFailed => 'مش قادرين نحمّل قائمة المحطات.';

  @override
  String get linesMicrobusFareNote =>
      'أجرة الميكروباص بتعتمد على المسافة اللي هتركبها.';

  @override
  String get navOverviewTooltip => 'اعرض الرحلة كلها';

  @override
  String get navRecenterTooltip => 'رجّعني لمكاني';

  @override
  String tripRouteHeading(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get fareFree => 'مجاناً';

  @override
  String get pinnedLocation => 'موقع محدد على الخريطة';

  @override
  String get serverUnreachable =>
      'مش قادرين نوصل لسيرفر Guidy. اطمن على الإنترنت وجرب تاني.';

  @override
  String get errorOutsideCoverage =>
      'المكان ده بره المنطقة اللي Guidy بيغطيها.';

  @override
  String get errorNoRouteFound =>
      'مش لاقيين طريق للمكان ده. يمكن يكون بره تغطيتنا.';

  @override
  String get errorNoServiceThisHour =>
      'مفيش مواصلات شغالة في الوقت ده. أغلب الخطوط بتشتغل من حوالي ٦ الصبح لـ١١ بالليل — جرب تاني في المواعيد دي.';

  @override
  String linesDirectionTowardsFrom(String terminus, String origin) {
    return 'باتجاه $terminus، من $origin';
  }

  @override
  String get reportTooltip => 'بلّغ عن الطريق ده';

  @override
  String get reportEntryPoint => 'في حاجة غلط في الطريق ده؟';

  @override
  String get reportTitle => 'بلّغ عن الطريق ده';

  @override
  String get reportIntro =>
      'بيانات الخطوط عندنا جاية من مصادر مفتوحة، وانت عارف الشارع أحسن مننا. قولنا إيه الغلط وإحنا هنظبطه للكل.';

  @override
  String get reportWhichPart => 'أنهي جزء فيه مشكلة؟';

  @override
  String get reportSelectAll => 'اختار الكل';

  @override
  String get reportClearSelection => 'امسح الاختيار';

  @override
  String get reportWholeRouteNote =>
      'انت اخترت كل الخطوات، يعني البلاغ هيتبعت على الطريق كله.';

  @override
  String get reportReasonLabel => 'المشكلة إيه؟';

  @override
  String get reportReasonRouteDoesNotExist => 'الخط ده مش موجود';

  @override
  String get reportReasonWrongStop => 'الموقف أو المحطة غلط';

  @override
  String get reportReasonBadTiming => 'المواعيد غلط';

  @override
  String get reportReasonWrongFare => 'الأجرة غلط';

  @override
  String get reportReasonBetterRoute => 'أنا عارف طريق أحسن';

  @override
  String get reportReasonOther => 'حاجة تانية';

  @override
  String get reportCommentLabel => 'قولنا أكتر';

  @override
  String get reportCommentHintGeneral => 'اختياري — أي حاجة تساعدنا نراجع.';

  @override
  String get reportCommentHintBetterRoute => 'هتروح إزاي بدل كده؟';

  @override
  String get reportCommentRequired => 'اكتبلنا شوية تفاصيل عشان نقدر نتصرف.';

  @override
  String get reportSelectSomething => 'اختار خطوة واحدة على الأقل.';

  @override
  String get reportPickReason => 'اختار المشكلة إيه.';

  @override
  String get reportSubmit => 'ابعت البلاغ';

  @override
  String get reportSent => 'شكراً — بلاغك وصلنا.';

  @override
  String get reportQueued => 'حفظناه. هنبعته أول ما النت يرجع.';

  @override
  String get reportFailed => 'مش قادرين نبعت البلاغ. جرب تاني.';

  @override
  String get reportSignInRequired => 'سجّل دخولك عشان تبعت بلاغ.';

  @override
  String get routeTierPartial => 'يقرّبك من وجهتك';

  @override
  String partialUncoveredNotice(String distance) {
    return 'ده مش بيوصل لوجهتك. آخر $distance مفيش خط نعرفه بيغطّيها لحد دلوقتي.';
  }

  @override
  String partialLastCoveredStop(String stop) {
    return 'آخر محطة بنغطّيها: $stop';
  }

  @override
  String nearestHubsHint(String origin, String destination) {
    return 'أقرب الأماكن اللي بنغطّيها: $origin جنب نقطة البداية، و$destination جنب وجهتك.';
  }

  @override
  String get reportMissingRouteButton => 'قوللنا الناقص إيه';

  @override
  String get reportMissingRouteTitle => 'أنهي خط المفروض يكون هنا؟';

  @override
  String get reportMissingRouteIntro =>
      'بياناتنا ناقصة في الرحلة دي. لو تعرف أتوبيس أو ميني باص أو ميكروباص بيوصل، اكتبه وهنضيفه للكل.';

  @override
  String get reportMissingRouteHint =>
      'مثلاً: ميني باص ٣٧ من الكيلو أربعة و نص لكفر طهرمس';

  @override
  String get excludeMetro => 'من غير مترو';

  @override
  String get onlyRouteDisclaimer =>
      'ده الطريق الوحيد اللي نعرفه حالياً للمشوار ده.';

  @override
  String get filterMinWalk => 'أقل مشي';

  @override
  String get filterMinTransfers => 'أقل تحويلات';

  @override
  String get railMapTitle => 'خريطة شبكة القطارات والمترو';

  @override
  String get shareTripTooltip => 'مشاركة المشوار';

  @override
  String get navFitRouteTooltip => 'المسار كامل';

  @override
  String get navStopAlarmTooltip => 'تنبيه النزول';

  @override
  String get navStopAlarmOn => 'تنبيه النزول شغال';

  @override
  String get navStopAlarmOff => 'تنبيه النزول مطفي';

  @override
  String navStopAlarmAlert(String station) {
    return 'استعد للنزول! محطتك القادمة: $station';
  }

  @override
  String get metroTicketTitle => 'شباك تذاكر المترو';

  @override
  String get navStopAlarmActiveToast =>
      'تنبيه النزول: شغال (الموبايل هيهتز قبل محطتك بـ 400م)';

  @override
  String get navStopAlarmDisabledToast => 'تنبيه النزول: مقفول';

  @override
  String get navRecenterFinding => 'جاري تحديد موقعك...';

  @override
  String get navRecenterSuccess => 'رجعناك لمكانك';

  @override
  String get navRecenterFallback => 'معرفناش نحدد موقعك، رجعناك لبداية الرحلة';

  @override
  String get navOverviewToast => 'نظرة عامة على خط السير';

  @override
  String get savedTripsTitle => 'رحلاتي المحفوظة';

  @override
  String get savedTripsEmpty =>
      'لسه ما حفظتش أي رحلات. احفظ مشاويرك المتكررة عشان تشوفها من غير نت.';

  @override
  String get saveTripTooltip => 'حفظ المشوار';

  @override
  String get tripSavedToast => 'اتحفظت في رحلاتك المحفوظة';

  @override
  String get tripRemovedToast => 'اتمسحت من رحلاتك المحفوظة';

  @override
  String get offlineModeNotice => 'وضع عدم الاتصال — بنعرض المسار المحفوظ';

  @override
  String get offlineBadge => 'أوفلاين';

  @override
  String get savedTripsHomeSubtitle => 'مشاويرك اليومية بضغطة واحدة ومن غير نت';

  @override
  String get viewModeList => 'قائمة المسارات';

  @override
  String get viewModeCompare => 'مقارنة سريعة';

  @override
  String get compareFastest => 'الأسرع';

  @override
  String get compareCheapest => 'الأوفر';

  @override
  String get compareLeastWalk => 'أقل مشي';

  @override
  String get compareDirect => 'مباشر';

  @override
  String get directRouteNoTransfers => 'مباشر بدون تحويل';

  @override
  String transfersCountBadge(int count) {
    return '$count تحويلات';
  }

  @override
  String walkMetersBadge(String meters) {
    return '$meters متر مشي';
  }

  @override
  String get quickReportTitle => 'إبلاغ عن حالة الطريق';

  @override
  String get quickReportSubtitle =>
      'ساعد ركاب تانيين يعرفوا ظروف المشوار دلوقتي';

  @override
  String get reportCategoryTraffic => 'الطريق واقف / زحمة مش طبيعية';

  @override
  String get reportCategoryMissing => 'الأتوبيس ما جاش / اتأخر كتير';

  @override
  String get reportCategoryCrowd => 'المحطة أو العربية زحمة جداً';

  @override
  String get reportCategoryFare => 'سواق الميكروباص / المحصل زوّد الأجرة';

  @override
  String get reportCategoryDiversion => 'المسار اتغير أو في تحويلة';

  @override
  String get reportThanksToast => 'شكراً — بلاغك اتسجل وهينبه باقي الركاب!';

  @override
  String get reportNotePlaceholder => 'أي تفاصيل زيادة تحب تضيفها؟ (اختياري)';

  @override
  String get budgetTitle => 'حاسبة مصاريف المواصلات';

  @override
  String get budgetSubtitle =>
      'احسب مصاريف مواصلاتك الشهرية ووفر مع اشتراك المترو';

  @override
  String get dailyCostLabel => 'تكلفة المشوار يومياً (ذهاب وعودة)';

  @override
  String get commuteDaysPerWeek => 'أيام النزول في الأسبوع';

  @override
  String commuteDaysCount(int days, int total) {
    return '$days أيام ($total مشوار في الشهر)';
  }

  @override
  String get monthlyCostLabel => 'إجمالي المصاريف شهرياً';

  @override
  String get metroSubscriptionSavingsTitle => 'وفر مع اشتراك المترو';

  @override
  String metroSubscriptionSavingsSubtitle(String amount) {
    return 'لو عملت اشتراك شهري مرحلة واحدة، هتوفر $amount ج.م كل شهر!';
  }

  @override
  String get subTierPublic => 'جمهور عادي';

  @override
  String get subTierStudents => 'طلبة (خصم 90%)';

  @override
  String get subTierElderly => 'كبار السن';

  @override
  String subCostPerMonth(String cost) {
    return '$cost ج.م / شهر';
  }

  @override
  String monthlySavings(String amount) {
    return 'توفير $amount ج.م شهرياً';
  }

  @override
  String get metroOfficesTitle => 'مكاتب الاشتراكات في محطات المترو';

  @override
  String get metroOfficesList =>
      'العتبة، الشهداء، عدلي منصور، أنور السادات، جامعة القاهرة';

  @override
  String get walkManeuverStraight => 'كمّل على طول';

  @override
  String get walkManeuverRight => 'ادخل يمين';

  @override
  String get walkManeuverLeft => 'ادخل شمال';

  @override
  String get walkManeuverUTurn => 'لف وارجع';

  @override
  String walkInDistance(String distance, String action) {
    return 'بعد $distance $action';
  }

  @override
  String walkApproachingBoarding(String station) {
    return 'قرّبت من محطة الركوب ($station)';
  }

  @override
  String get walkAtDestination => 'وصلت لوجهتك';

  @override
  String get metroNetworkMapTitle => 'خريطة شبكة المترو والقطارات';

  @override
  String get metroNetworkMapButton => 'خريطة الشبكة';

  @override
  String get schematicDiagramTab => 'مخطط الشبكة';

  @override
  String get stationDirectoryTab => 'دليل المحطات';

  @override
  String get interchangeTag => 'محطة تبادلية';

  @override
  String get navHistory => 'رحلاتي';

  @override
  String get historyTitle => 'سجل الرحلات والتوفير';

  @override
  String get historySubtitle => 'سجل مشاويرك وحساب التوفير';

  @override
  String get totalMoneySaved => 'إجمالي التوفير';

  @override
  String get totalTimeSaved => 'الوقت الموفَّر';

  @override
  String get totalTripsCount => 'عدد الرحلات';

  @override
  String get co2Prevented => 'انبعاثات وفّرتها';

  @override
  String get savingsComparedToTaxi => 'مقارنة بالتاكسي وأوبر';

  @override
  String get timeSavedBypassing => 'بتفادي زحمة الكباري والطرق';

  @override
  String get emptyHistoryTitle => 'لسة ما عملتش مشاوير';

  @override
  String get emptyHistorySubtitle =>
      'ابدأ مشوارك أو خطط لسكة جديدة مع جيدي، وأول ما تتحرك هتلاقي مشاويرك وفلوسك اللي وفرتها متسجلة هنا!';

  @override
  String get planTripButton => 'خطط لمشوارك';

  @override
  String get loadDemoTripsButton => 'عرض نموذج توفير تجريبي';

  @override
  String get repeatTripAction => 'كرر السكة';

  @override
  String get clearHistoryConfirm => 'عايز تمسح كل مشاويرك اللي فاتت؟';

  @override
  String get clearHistoryAction => 'امسح السجل';

  @override
  String get clearHistorySuccess => 'مسحنا سجل المشاوير خلاص';

  @override
  String get tripDeletedToast => 'شيلنا المشوار من السجل';

  @override
  String get savingsCalculationInfoTitle => 'بنحسب التوفير إزاي؟';

  @override
  String get savingsCalculationInfo =>
      'بنحسب التوفير على أساس اختيارك انت بين السكك المتاحة: لما تختار السكة الأسرع بنحسب كام دقيقة وفّرتها مقارنة بباقي الخيارات، ولما تختار السكة الأوفر بنحسب كام جنيه وفّرته مقارنة بالخيارات التانية الأغلى.';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterThisWeek => 'الأسبوع ده';

  @override
  String get filterThisMonth => 'الشهر ده';

  @override
  String get filterMetro => 'مترو';

  @override
  String get filterBus => 'أتوبيس';

  @override
  String get filterMicrobus => 'ميكروباص';

  @override
  String minsSavedShort(String mins) {
    return 'وفّرت $mins دقيقة';
  }

  @override
  String hoursMinsSavedShort(String hours, String mins) {
    return 'وفّرت $hours ساعة و $mins د';
  }

  @override
  String moneySavedShort(String amount) {
    return 'وفّرت $amount ج.م';
  }

  @override
  String get sampleTripsLoadedToast => 'حمّلنا مشاوير تجريبية';

  @override
  String get reportLineTitle => 'بلّغ عن مشكلة في الخط';

  @override
  String get reportMetroTitle => 'بلّغ عن مشكلة في المترو';

  @override
  String get reportReasonLineDoesNotExist => 'الخط مش موجود أو اتلغى';

  @override
  String get reportReasonLineWrongPath =>
      'مسار الخط اتغير أو بيعدي من شوارع تانية';

  @override
  String get reportReasonLineWrongStop => 'فيه محطة ناقصة أو ترتيب المحطات غلط';

  @override
  String get reportReasonLineWrongFare => 'الأجرة غلط';

  @override
  String get reportReasonLineBadTiming => 'المواعيد أو عدد الرحلات مش مظبوط';

  @override
  String get reportReasonMetroStationClosed => 'المحطة مقفولة أو مش شغالة';

  @override
  String get reportReasonMetroWrongTransfer => 'تعليمات التغيير بين الخطوط غلط';

  @override
  String get reportReasonMetroWrongFare => 'سعر التذكرة غلط';

  @override
  String get reportReasonMetroDelay => 'فيه تأخير كبير أو عطل في الخدمة';

  @override
  String get reportPickStopOptional =>
      'اختار المحطة اللي فيها المشكلة (اختياري)';

  @override
  String get reportAllStopsOption => 'مشكلة عامة في الخط كله';

  @override
  String get reportActionSubmit => 'ابعت البلاغ';

  @override
  String get reportActionCancel => 'إلغاء';

  @override
  String get reportLineSuccessToast =>
      'شكراً! بلاغك وصلنا وهيساعدنا نظبط الشبكة للكل.';

  @override
  String get reportCommentHint =>
      'زوّدنا بتفاصيل زي الأجرة الفعلية أو اسم الشارع البديل';

  @override
  String get reportAnIssueWithThisLine => 'بلّغ عن مشكلة في الخط ده';

  @override
  String get reportAnIssueWithMetro => 'بلّغ عن مشكلة في رحلة المترو';

  @override
  String get reportCategoryOther => 'مشكلة تانية';

  @override
  String get reportReasonPrompt => 'المشكلة إيه؟';

  @override
  String get recentTripsTitle => 'مشاويرك الأخيرة';

  @override
  String get recentTripsSubtitle =>
      'مشاويرك اللي عملتها، تكلفتها والوقت اللي أخدته';

  @override
  String get noRecentTripsYet =>
      'لسة ما عملتش مشاوير.. أول ما تتحرك هتلاقي مشاويرك متسجلة هنا!';

  @override
  String get customizeRouteCardTitle => 'فصّل سكتك';

  @override
  String get customizeRouteCardSubtitle =>
      'اختر وسيلة المواصلات اللي تريحك في السكة دي';

  @override
  String get customizeSelectVehiclePrompt => 'المركبات المتاحة';

  @override
  String get customizeEstimatedDuration => 'الوقت المتوقع';

  @override
  String get customizeEstimatedFare => 'الأجرة التقديرية';

  @override
  String get customizeViewRouteAction => 'عرض السكة دي';

  @override
  String moneySavedPill(String amount) {
    return 'وفّرت $amount ج.م';
  }

  @override
  String timeSavedPill(String minutes) {
    return 'وفّرت $minutes دقيقة';
  }

  @override
  String get tripDetailFarePaid => 'الأجرة المدفوعة';

  @override
  String get tripDetailVsTaxi => 'مقارنة بالتاكسي وأوبر';

  @override
  String get tripDetailVsTraffic => 'مقارنة بزحمة الشوارع';

  @override
  String get tripDetailOpenRecap => 'تفاصيل المشوار';

  @override
  String get budgetScreenHeader =>
      'احسب مصاريف مواصلاتك وشوف هتوفر كام باشتراك المترو';

  @override
  String get budgetHowItWorksTitle => 'الحاسبة دي بتشتغل إزاي؟';

  @override
  String get budgetHowItWorksBody =>
      'تذاكر المترو الفردية كل يوم بتسحب من جيبك كتير! باشتراك المترو الشهري هتركب براحتك بسعر ثابت ورخيص جداً (وبالذات للطلبة وكبار السن). ظبط مشاويرك وشوف هتوفر كام في جيبك.';

  @override
  String get budgetCommuterCategory => 'نوع الراكب';

  @override
  String budgetRoutineTrips(String trips) {
    return '$trips مشوار في الشهر (مشوارين رايح جاي كل يوم)';
  }

  @override
  String get budgetStageHeader => 'المرحلة / عدد المحطات اللي بتركبها';

  @override
  String get budgetSingleTicketsMonthly => 'تكلفة التذاكر الفردية شهرياً';

  @override
  String historySavedTimeExplanation(String minutes) {
    return 'اخترت الأسرع ووفرت $minutes دقيقة';
  }

  @override
  String historySavedMoneyExplanation(String amount) {
    return 'اخترت الأوفر ووفرت $amount جنيه';
  }

  @override
  String get historyCustomizedChoice => 'سكة مفصّلة على مزاجك';

  @override
  String get chooseOnMap => 'حدد على الخريطة';

  @override
  String get confirmLocation => 'تأكيد المكان';

  @override
  String get pinDropped => 'نقطة محددة على الخريطة';
}

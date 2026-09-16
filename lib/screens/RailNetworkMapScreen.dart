import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../services/map_marker_service.dart';
import '../widgets/metro_report_sheet.dart';
import 'CommuteBudgetScreen.dart';

/// Interactive map and diagram of Greater Cairo's rapid transit rail network:
/// - Metro Line 1 (Helwan <-> New El Marg)
/// - Metro Line 2 (Shubra El Kheima <-> El Mounib)
/// - Metro Line 3 (Rod El Farag / Cairo Univ <-> Adly Mansour)
/// - Monorail East Nile (Cairo Stadium <-> New Administrative Capital)
/// - LRT Capital Train (Adly Mansour <-> City of Arts & Culture / Knowledge City)
class RailNetworkMapScreen extends StatefulWidget {
  final bool initialRealMap;

  const RailNetworkMapScreen({
    super.key,
    this.initialRealMap = true,
  });

  @override
  State<RailNetworkMapScreen> createState() => _RailNetworkMapScreenState();
}

class _SchematicStation {
  final String name;
  final String nameEn;
  final Offset offset;
  final List<String> lines;
  final bool isInterchange;

  const _SchematicStation({
    required this.name,
    required this.nameEn,
    required this.offset,
    required this.lines,
    this.isInterchange = false,
  });
}

class _RailMapStation {
  final String name;
  final String nameEn;
  final LatLng position;
  final List<String> lines;
  final bool isInterchange;

  const _RailMapStation({
    required this.name,
    required this.nameEn,
    required this.position,
    required this.lines,
    this.isInterchange = false,
  });
}

class _RailNetworkMapScreenState extends State<RailNetworkMapScreen> with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late TabController _tabController;
  GoogleMapController? _googleMapController;
  late bool _isRealMap;
  String? _selectedStation;
  String? _selectedLine;
  String _searchQuery = '';

  static final List<_SchematicStation> _schematicStations = [
    const _SchematicStation(name: 'السادات', nameEn: 'Sadat', offset: Offset(420, 510), lines: ['L1', 'L2'], isInterchange: true),
    const _SchematicStation(name: 'الشهداء', nameEn: 'Al-Shohadaa', offset: Offset(420, 370), lines: ['L1', 'L2'], isInterchange: true),
    const _SchematicStation(name: 'ناصر', nameEn: 'Nasser', offset: Offset(420, 460), lines: ['L1', 'L3'], isInterchange: true),
    const _SchematicStation(name: 'العتبة', nameEn: 'Attaba', offset: Offset(480, 430), lines: ['L2', 'L3'], isInterchange: true),
    const _SchematicStation(name: 'جامعة القاهرة', nameEn: 'Cairo Univ', offset: Offset(240, 640), lines: ['L2', 'L3'], isInterchange: true),
    const _SchematicStation(name: 'استاد القاهرة', nameEn: 'Cairo Stadium', offset: Offset(720, 310), lines: ['L3', 'MONORAIL'], isInterchange: true),
    const _SchematicStation(name: 'عدلي منصور', nameEn: 'Adly Mansour', offset: Offset(1060, 140), lines: ['L3', 'LRT'], isInterchange: true),
    const _SchematicStation(name: 'حلوان', nameEn: 'Helwan', offset: Offset(480, 1080), lines: ['L1']),
    const _SchematicStation(name: 'المعادي', nameEn: 'Maadi', offset: Offset(460, 850), lines: ['L1']),
    const _SchematicStation(name: 'دار السلام', nameEn: 'Dar El-Salam', offset: Offset(450, 760), lines: ['L1']),
    const _SchematicStation(name: 'مار جرجس', nameEn: 'Mar Girgis', offset: Offset(435, 680), lines: ['L1']),
    const _SchematicStation(name: 'سعد زغلول', nameEn: 'Saad Zaghloul', offset: Offset(420, 560), lines: ['L1']),
    const _SchematicStation(name: 'أحمد عرابي', nameEn: 'Orabi', offset: Offset(420, 415), lines: ['L1']),
    const _SchematicStation(name: 'غمرة', nameEn: 'Ghamra', offset: Offset(460, 320), lines: ['L1']),
    const _SchematicStation(name: 'سراي القبة', nameEn: 'Saray El-Qobba', offset: Offset(550, 230), lines: ['L1']),
    const _SchematicStation(name: 'المطرية', nameEn: 'Matareya', offset: Offset(620, 160), lines: ['L1']),
    const _SchematicStation(name: 'المرج الجديدة', nameEn: 'New El-Marg', offset: Offset(730, 60), lines: ['L1']),
    const _SchematicStation(name: 'شبرا الخيمة', nameEn: 'Shubra El-Kheima', offset: Offset(260, 160), lines: ['L2']),
    const _SchematicStation(name: 'المظلات', nameEn: 'Mezallat', offset: Offset(300, 220), lines: ['L2']),
    const _SchematicStation(name: 'روض الفرج', nameEn: 'Rod El-Farag', offset: Offset(350, 310), lines: ['L2']),
    const _SchematicStation(name: 'محمد نجيب', nameEn: 'Mohamed Naguib', offset: Offset(450, 470), lines: ['L2']),
    const _SchematicStation(name: 'الأوبرا', nameEn: 'Opera', offset: Offset(360, 540), lines: ['L2']),
    const _SchematicStation(name: 'الدقي', nameEn: 'Dokki', offset: Offset(320, 570), lines: ['L2']),
    const _SchematicStation(name: 'البحوث', nameEn: 'El-Bohooth', offset: Offset(280, 600), lines: ['L2']),
    const _SchematicStation(name: 'الجيزة', nameEn: 'Giza', offset: Offset(240, 750), lines: ['L2']),
    const _SchematicStation(name: 'ساقية مكي', nameEn: 'Sakiat Mekki', offset: Offset(240, 850), lines: ['L2']),
    const _SchematicStation(name: 'المنيب', nameEn: 'El-Mounib', offset: Offset(240, 960), lines: ['L2']),
    const _SchematicStation(name: 'محور روض الفرج', nameEn: 'Rod El-Farag Corridor', offset: Offset(130, 310), lines: ['L3']),
    const _SchematicStation(name: 'إمبابة', nameEn: 'Imbaba', offset: Offset(230, 410), lines: ['L3']),
    const _SchematicStation(name: 'جامعة الدول', nameEn: 'Gameat El-Dowal', offset: Offset(270, 560), lines: ['L3']),
    const _SchematicStation(name: 'الكيت كات', nameEn: 'Kit Kat', offset: Offset(310, 490), lines: ['L3']),
    const _SchematicStation(name: 'صفاء حجازي', nameEn: 'Safaa Hegazy', offset: Offset(350, 475), lines: ['L3']),
    const _SchematicStation(name: 'ماسبيرو', nameEn: 'Maspero', offset: Offset(385, 465), lines: ['L3']),
    const _SchematicStation(name: 'العباسية', nameEn: 'Abbassiya', offset: Offset(630, 350), lines: ['L3']),
    const _SchematicStation(name: 'كلية البنات', nameEn: 'Koleyet El-Banat', offset: Offset(760, 290), lines: ['L3']),
    const _SchematicStation(name: 'الأهرام', nameEn: 'Al-Ahram', offset: Offset(800, 270), lines: ['L3']),
    const _SchematicStation(name: 'ميدان هليوبوليس', nameEn: 'Heliopolis', offset: Offset(860, 235), lines: ['L3']),
    const _SchematicStation(name: 'ألف مسكن', nameEn: 'Alf Maskan', offset: Offset(900, 210), lines: ['L3']),
    const _SchematicStation(name: 'هشام بركات', nameEn: 'Hesham Barakat', offset: Offset(960, 180), lines: ['L3']),
    const _SchematicStation(name: 'الحي السابع', nameEn: '7th District', offset: Offset(790, 430), lines: ['MONORAIL']),
    const _SchematicStation(name: 'المشير طنطاوي', nameEn: 'Tantawy', offset: Offset(870, 540), lines: ['MONORAIL']),
    const _SchematicStation(name: 'كايرو فيستيفال', nameEn: 'CFC', offset: Offset(930, 620), lines: ['MONORAIL']),
    const _SchematicStation(name: 'الجامعة الأمريكية', nameEn: 'AUC New Cairo', offset: Offset(1020, 740), lines: ['MONORAIL']),
    const _SchematicStation(name: 'مدينة الفنون والثقافة', nameEn: 'Arts & Culture', offset: Offset(1100, 840), lines: ['MONORAIL']),
    const _SchematicStation(name: 'العبور', nameEn: 'El-Obour', offset: Offset(1130, 120), lines: ['LRT']),
    const _SchematicStation(name: 'الشروق', nameEn: 'El-Shorouk', offset: Offset(1180, 120), lines: ['LRT']),
    const _SchematicStation(name: 'بدر', nameEn: 'Badr City', offset: Offset(1230, 120), lines: ['LRT']),
    const _SchematicStation(name: 'مطار العاصمة', nameEn: 'Capital Airport', offset: Offset(1230, 170), lines: ['LRT']),
    const _SchematicStation(name: 'الفنون والثقافة (القطار)', nameEn: 'Arts & Culture LRT', offset: Offset(1230, 230), lines: ['LRT']),
  ];

  static const List<Map<String, dynamic>> _lines = [
    {
      'id': 'L1',
      'nameAr': 'الخط الأول (المرج - حلوان)',
      'nameEn': 'Line 1 (Helwan - New El Marg)',
      'color': Color(0xFF0077E6), // High-visibility Electric Cobalt Blue
      'stations': [
        'حلوان', 'عين حلوان', 'المعصرة', 'طرة البلد', 'كوتسيكا', 'المعادي',
        'ثكنات المعادي', 'دار السلام', 'الزهراء', 'مار جرجس', 'الملك الصالح',
        'السيدة زينب', 'سعد زغلول', 'السادات', 'جمال عبد الناصر', 'أحمد عرابي',
        'الشهداء', 'غمرة', 'الدمرداش', 'منشية الصدر', 'كوبري القبة', 'حمامات القبة',
        'سراي القبة', 'حدائق الزيتون', 'حلمية الزيتون', 'المطرية', 'عين شمس',
        'عزبة النخل', 'المرج', 'المرج الجديدة'
      ]
    },
    {
      'id': 'L2',
      'nameAr': 'الخط الثاني (شبرا الخيمة - المنيب)',
      'nameEn': 'Line 2 (Shubra - El Mounib)',
      'color': Color(0xFFE76F51),
      'stations': [
        'شبرا الخيمة', 'كلية الزراعة', 'المظلات', 'الخلفاوي', 'سانت تريزا',
        'روض الفرج', 'مسرة', 'الشهداء', 'العتبة', 'محمد نجيب', 'السادات',
        'الأوبرا', 'الدقي', 'البحوث', 'جامعة القاهرة', 'فيصل', 'الجيزة',
        'ضواحي الجيزة', 'ساقية مكي', 'المنيب'
      ]
    },
    {
      'id': 'L3',
      'nameAr': 'الخط الثالث (عدلي منصور - روض الفرج / جامعة القاهرة)',
      'nameEn': 'Line 3 (Adly Mansour - Rod El Farag / Cairo Univ)',
      'color': Color(0xFF2A9D8F),
      'stations': [
        'عدلي منصور', 'الهايكستب', 'عمر بن الخطاب', 'قباء', 'هشام بركات',
        'النزهة', 'نادي الشمس', 'ألف مسكن', 'ميدان هليوبوليس', 'هارون',
        'الأهرام', 'كلية البنات', 'استاد القاهرة', 'أرض المعارض', 'العباسية',
        'عبده باشا', 'الجيش', 'باب الشعرية', 'العتبة', 'ناصر', 'ماسبيرو',
        'صفاء حجازي', 'الكيت كات', 'السودان', 'إمبابة', 'البوهي', 'القومية',
        'الدائري', 'محور روض الفرج', 'التوفيقية', 'وادي النيل', 'جامعة الدول',
        'بولاق الدكرور', 'جامعة القاهرة'
      ]
    },
    {
      'id': 'MONORAIL',
      'nameAr': 'مونوريل شرق النيل (الاستاد - العاصمة الإدارية)',
      'nameEn': 'East Nile Monorail (Stadium - New Capital)',
      'color': Color(0xFF9C27B0),
      'stations': [
        'استاد القاهرة', 'هشام بركات', 'نوري خطاب', 'الحي السابع', 'ذاكر حسين',
        'المنطقة الحرة', 'المشير طنطاوي', 'كايرو فيستيفال', 'الشويفات', 'المستشفى الجوي',
        'حي النرجس', 'المستثمرين', 'الأندلس', 'الجامعة الأمريكية', 'بيت الوطن',
        'مسجد الفتاح العليم', 'الحي السكني R2', 'الدائري الإقليمي', 'فندق الماسة',
        'الحي الحكومي', 'مدينة الثقافة والفنون'
      ]
    },
    {
      'id': 'LRT',
      'nameAr': 'القطار الكهربائي الخفيف (عدلي منصور - الفنون والثقافة)',
      'nameEn': 'LRT Capital Train (Adly Mansour - Arts & Culture)',
      'color': Color(0xFF00897B),
      'stations': [
        'عدلي منصور', 'العبور', 'المستقبل', 'الشروق', 'نيو هليوبوليس',
        'بدر', 'الروبيكي', 'حدائق العاصمة', 'مطار العاصمة', 'مدينة الفنون والثقافة'
      ]
    },
  ];

  static const Map<String, List<LatLng>> _lineCoordsMap = {
    'L1': [
      LatLng(29.8490, 31.3340),
      LatLng(29.8624, 31.3288),
      LatLng(29.8780, 31.3200),
      LatLng(29.8940, 31.3090),
      LatLng(29.9056, 31.3005),
      LatLng(29.9180, 31.2940),
      LatLng(29.9328, 31.2863),
      LatLng(29.9431, 31.2778),
      LatLng(29.9515, 31.2638),
      LatLng(29.9583, 31.2589),
      LatLng(29.9605, 31.2570),
      LatLng(29.9720, 31.2460),
      LatLng(29.9868, 31.2323),
      LatLng(30.0062, 31.2312),
      LatLng(30.0065, 31.2301),
      LatLng(30.0175, 31.2305),
      LatLng(30.0298, 31.2346),
      LatLng(30.0366, 31.2375),
      LatLng(30.0444, 31.2357),
      LatLng(30.0532, 31.2398),
      LatLng(30.0573, 31.2435),
      LatLng(30.0617, 31.2497),
      LatLng(30.0691, 31.2657),
      LatLng(30.0768, 31.2778),
      LatLng(30.0827, 31.2866),
      LatLng(30.0874, 31.2938),
      LatLng(30.0917, 31.3001),
      LatLng(30.0984, 31.3087),
      LatLng(30.1066, 31.3129),
      LatLng(30.1147, 31.3150),
      LatLng(30.1215, 31.3142),
      LatLng(30.1311, 31.3197),
      LatLng(30.1408, 31.3255),
      LatLng(30.1524, 31.3354),
      LatLng(30.1643, 31.3385),
    ],
    'L2': [
      LatLng(30.1226, 31.2450),
      LatLng(30.1138, 31.2483),
      LatLng(30.1047, 31.2464),
      LatLng(30.0983, 31.2458),
      LatLng(30.0886, 31.2456),
      LatLng(30.0808, 31.2453),
      LatLng(30.0706, 31.2461),
      LatLng(30.0617, 31.2497),
      LatLng(30.0526, 31.2468),
      LatLng(30.0453, 31.2439),
      LatLng(30.0444, 31.2357),
      LatLng(30.0422, 31.2248),
      LatLng(30.0384, 31.2122),
      LatLng(30.0360, 31.2003),
      LatLng(30.0267, 31.2012),
      LatLng(30.0172, 31.2045),
      LatLng(30.0107, 31.2071),
      LatLng(30.0049, 31.2088),
      LatLng(29.9958, 31.2088),
      LatLng(29.9815, 31.2120),
    ],
    'L3': [
      LatLng(30.0754, 31.1895),
      LatLng(30.0750, 31.2010),
      LatLng(30.0738, 31.2105),
      LatLng(30.0712, 31.2185),
      LatLng(30.0682, 31.2198),
      LatLng(30.0614, 31.2172),
      LatLng(30.0619, 31.2136),
      LatLng(30.0618, 31.2223),
      LatLng(30.0560, 31.2335),
      LatLng(30.0532, 31.2398),
      LatLng(30.0526, 31.2468),
      LatLng(30.0534, 31.2568),
      LatLng(30.0568, 31.2672),
      LatLng(30.0637, 31.2778),
      LatLng(30.0686, 31.2858),
      LatLng(30.0725, 31.3023),
      LatLng(30.0716, 31.3177),
      LatLng(30.0825, 31.3289),
      LatLng(30.0912, 31.3275),
      LatLng(30.0988, 31.3335),
      LatLng(30.1075, 31.3415),
      LatLng(30.1172, 31.3435),
      LatLng(30.1245, 31.3485),
      LatLng(30.1315, 31.3562),
      LatLng(30.1378, 31.3695),
      LatLng(30.1415, 31.3812),
      LatLng(30.1448, 31.3935),
      LatLng(30.1465, 31.4080),
      LatLng(30.1478, 31.4218),
    ],
    'MONORAIL': [
      LatLng(30.0716, 31.3177),
      LatLng(30.0635, 31.3219),
      LatLng(30.0538, 31.3248),
      LatLng(30.0438, 31.3309),
      LatLng(30.0455, 31.3464),
      LatLng(30.0392, 31.3555),
      LatLng(30.0192, 31.3833),
      LatLng(30.0163, 31.4090),
      LatLng(30.0163, 31.4339),
      LatLng(30.0255, 31.4599),
      LatLng(30.0254, 31.4907),
      LatLng(30.0133, 31.5196),
      LatLng(30.0270, 31.5330),
      LatLng(30.0210, 31.4980),
      LatLng(30.0250, 31.5800),
      LatLng(30.0150, 31.6400),
      LatLng(30.0120, 31.6850),
      LatLng(30.0090, 31.7100),
      LatLng(30.0070, 31.7250),
      LatLng(30.0060, 31.7310),
      LatLng(30.0055, 31.7350),
    ],
    'LRT': [
      LatLng(30.1478, 31.4218),
      LatLng(30.1629, 31.4815),
      LatLng(30.1731, 31.5541),
      LatLng(30.1795, 31.6058),
      LatLng(30.1840, 31.6527),
      LatLng(30.1752, 31.7160),
      LatLng(30.1500, 31.7200),
      LatLng(30.1300, 31.7220),
      LatLng(30.1150, 31.7250),
      LatLng(30.0055, 31.7350),
    ],
  };

  static const List<_RailMapStation> _geoStations = [
    _RailMapStation(name: 'السادات', nameEn: 'Sadat', position: LatLng(30.0444, 31.2357), lines: ['L1', 'L2'], isInterchange: true),
    _RailMapStation(name: 'الشهداء', nameEn: 'Al-Shohadaa', position: LatLng(30.0617, 31.2497), lines: ['L1', 'L2'], isInterchange: true),
    _RailMapStation(name: 'ناصر', nameEn: 'Nasser', position: LatLng(30.0532, 31.2398), lines: ['L1', 'L3'], isInterchange: true),
    _RailMapStation(name: 'العتبة', nameEn: 'Attaba', position: LatLng(30.0526, 31.2468), lines: ['L2', 'L3'], isInterchange: true),
    _RailMapStation(name: 'جامعة القاهرة', nameEn: 'Cairo Univ', position: LatLng(30.0267, 31.2012), lines: ['L2', 'L3'], isInterchange: true),
    _RailMapStation(name: 'استاد القاهرة', nameEn: 'Cairo Stadium', position: LatLng(30.0716, 31.3177), lines: ['L3', 'MONORAIL'], isInterchange: true),
    _RailMapStation(name: 'عدلي منصور', nameEn: 'Adly Mansour', position: LatLng(30.1478, 31.4218), lines: ['L3', 'LRT'], isInterchange: true),
    _RailMapStation(name: 'حلوان', nameEn: 'Helwan', position: LatLng(29.8490, 31.3340), lines: ['L1']),
    _RailMapStation(name: 'المعادي', nameEn: 'Maadi', position: LatLng(29.9583, 31.2589), lines: ['L1']),
    _RailMapStation(name: 'سعد زغلول', nameEn: 'Saad Zaghloul', position: LatLng(30.0366, 31.2375), lines: ['L1']),
    _RailMapStation(name: 'غمرة', nameEn: 'Ghamra', position: LatLng(30.0691, 31.2657), lines: ['L1']),
    _RailMapStation(name: 'سراي القبة', nameEn: 'Saray El-Qobba', position: LatLng(30.0984, 31.3087), lines: ['L1']),
    _RailMapStation(name: 'المرج الجديدة', nameEn: 'New El-Marg', position: LatLng(30.1643, 31.3385), lines: ['L1']),
    _RailMapStation(name: 'شبرا الخيمة', nameEn: 'Shubra El-Kheima', position: LatLng(30.1226, 31.2450), lines: ['L2']),
    _RailMapStation(name: 'المنيب', nameEn: 'El-Mounib', position: LatLng(29.9815, 31.2120), lines: ['L2']),
    _RailMapStation(name: 'محور روض الفرج', nameEn: 'Rod El-Farag Axis', position: LatLng(30.0754, 31.1895), lines: ['L3']),
    _RailMapStation(name: 'الكيت كات', nameEn: 'Kit Kat', position: LatLng(30.0619, 31.2136), lines: ['L3']),
    _RailMapStation(name: 'الأهرام', nameEn: 'Al-Ahram', position: LatLng(30.0912, 31.3275), lines: ['L3']),
    _RailMapStation(name: 'المشير طنطاوي', nameEn: 'Moushir Tantawi', position: LatLng(30.0192, 31.3833), lines: ['MONORAIL']),
    _RailMapStation(name: 'الجامعة الأمريكية', nameEn: 'AUC New Cairo', position: LatLng(30.0210, 31.4980), lines: ['MONORAIL']),
    _RailMapStation(name: 'مدينة الفنون والثقافة', nameEn: 'Arts & Culture', position: LatLng(30.0055, 31.7350), lines: ['MONORAIL', 'LRT'], isInterchange: true),
    _RailMapStation(name: 'الشروق', nameEn: 'El-Shorouk', position: LatLng(30.1795, 31.6058), lines: ['LRT']),
    _RailMapStation(name: 'بدر', nameEn: 'Badr City', position: LatLng(30.1752, 31.7160), lines: ['LRT']),
  ];

  static const Map<String, List<String>> _interchanges = {
    'السادات': ['L1', 'L2'],
    'الشهداء': ['L1', 'L2'],
    'العتبة': ['L2', 'L3'],
    'ناصر': ['L1', 'L3'],
    'جامعة القاهرة': ['L2', 'L3'],
    'استاد القاهرة': ['L3', 'MONORAIL'],
    'عدلي منصور': ['L3', 'LRT'],
  };

  BitmapDescriptor? _interchangeMarkerIcon;
  final Map<String, BitmapDescriptor> _lineMarkerIcons = {};

  Future<void> _loadMarkers() async {
    try {
      final transfer = await MapMarkerService.getTransferMarker();
      final icons = <String, BitmapDescriptor>{};
      for (final line in _lines) {
        final id = line['id'] as String;
        final color = line['color'] as Color;
        icons[id] = await MapMarkerService.getStationStopMarker(color: color);
      }
      if (mounted) {
        setState(() {
          _interchangeMarkerIcon = transfer;
          _lineMarkerIcons.addAll(icons);
        });
      }
    } catch (e) {
      debugPrint("Error loading rail network markers: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isRealMap = widget.initialRealMap;
    _loadMarkers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transformController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(factor, factor, 1.0));
    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    setState(() {
      _selectedStation = null;
      _selectedLine = null;
    });
    if (_isRealMap) {
      _googleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(30.0444, 31.2357),
            zoom: 11.2,
          ),
        ),
      );
    }
  }

  void _fitLine(String lineId) {
    final coords = _lineCoordsMap[lineId];
    if (coords == null || coords.isEmpty) return;

    double minLat = coords.first.latitude;
    double maxLat = coords.first.latitude;
    double minLng = coords.first.longitude;
    double maxLng = coords.first.longitude;

    for (final c in coords) {
      if (c.latitude < minLat) minLat = c.latitude;
      if (c.latitude > maxLat) maxLat = c.latitude;
      if (c.longitude < minLng) minLng = c.longitude;
      if (c.longitude > maxLng) maxLng = c.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 48),
    );
  }

  Set<Polyline> _buildPolylines(bool isDark) {
    final polylines = <Polyline>{};
    for (final line in _lines) {
      final id = line['id'] as String;
      final color = line['color'] as Color;
      final coords = _lineCoordsMap[id];
      if (coords == null || coords.isEmpty) continue;

      final isSelected = _selectedLine == null || _selectedLine == id;
      final polyColor = isSelected ? color : color.withValues(alpha: 0.22);
      final casingColor = isSelected
          ? (isDark ? const Color(0xFF1E2630) : Colors.white)
          : (isDark ? const Color(0xFF1E2630).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.25));

      polylines.add(
        Polyline(
          polylineId: PolylineId('${id}_casing'),
          points: coords,
          color: casingColor,
          width: isSelected ? 8 : 4,
          zIndex: isSelected ? 2 : 0,
        ),
      );

      polylines.add(
        Polyline(
          polylineId: PolylineId(id),
          points: coords,
          color: polyColor,
          width: isSelected ? 5 : 2,
          zIndex: isSelected ? 3 : 1,
        ),
      );
    }
    return polylines;
  }

  Set<Marker> _buildMarkers(bool isAr) {
    final markers = <Marker>{};
    for (final st in _geoStations) {
      if (_selectedLine != null && !st.lines.contains(_selectedLine)) {
        continue;
      }
      final isInterchange = st.isInterchange;
      final name = isAr ? st.name : st.nameEn;
      final linesStr = st.lines.join(' • ');
      final primaryLineId = st.lines.isNotEmpty ? st.lines.first : '';

      final icon = isInterchange
          ? (_interchangeMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow))
          : (_lineMarkerIcons[primaryLineId] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure));

      markers.add(
        Marker(
          markerId: MarkerId(st.nameEn),
          position: st.position,
          icon: icon,
          anchor: MapMarkerService.centerAnchor,
          zIndexInt: isInterchange ? 5 : 2,
          infoWindow: InfoWindow(
            title: name,
            snippet: isInterchange
                ? (isAr ? 'محطة تبادلية ($linesStr)' : 'Interchange ($linesStr)')
                : (isAr ? 'خط: $linesStr' : 'Line: $linesStr'),
            onTap: () {
              setState(() => _selectedStation = st.name);
              _showStationDetails(context, st.name, st.lines, isAr);
            },
          ),
          onTap: () {
            setState(() => _selectedStation = st.name);
            _showStationDetails(context, st.name, st.lines, isAr);
          },
        ),
      );
    }
    return markers;
  }

  Widget _buildTopControlOverlay(BuildContext context, bool isDark, bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2630).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (!_isRealMap) setState(() => _isRealMap = true);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _isRealMap ? AppColors.primaryTeal : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: _isRealMap ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAr ? 'خريطة حقيقية' : 'Real Map',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isRealMap ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_isRealMap) setState(() => _isRealMap = false);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: !_isRealMap ? AppColors.primaryTeal : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 16,
                          color: !_isRealMap ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAr ? 'مخطط تخطيطي' : 'Schematic',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !_isRealMap ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.brandAmberDark),
                    label: Text(
                      isAr ? 'دليل الأسعار والاشتراكات' : 'Fares & Pass Guide',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    backgroundColor: isDark ? const Color(0xFF263238) : Colors.amber.shade50,
                    side: BorderSide(color: AppColors.brandAmberDark.withValues(alpha: 0.5)),
                    onPressed: () => _showFareGuideSheet(context, isDark, isAr),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      isAr ? 'الكل' : 'All',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedLine == null ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selected: _selectedLine == null,
                    selectedColor: AppColors.primaryTeal,
                    onSelected: (sel) {
                      if (sel) {
                        setState(() => _selectedLine = null);
                        if (_isRealMap) {
                          _googleMapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              const CameraPosition(target: LatLng(30.0444, 31.2357), zoom: 11.2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                ..._lines.map((l) {
                  final id = l['id'] as String;
                  final color = l['color'] as Color;
                  final isSel = _selectedLine == id;
                  String shortLabel;
                  if (id == 'L1') {
                    shortLabel = isAr ? 'الخط 1' : 'Line 1';
                  } else if (id == 'L2') {
                    shortLabel = isAr ? 'الخط 2' : 'Line 2';
                  } else if (id == 'L3') {
                    shortLabel = isAr ? 'الخط 3' : 'Line 3';
                  } else if (id == 'MONORAIL') {
                    shortLabel = isAr ? 'مونوريل' : 'Monorail';
                  } else {
                    shortLabel = isAr ? 'القطار الخفيف LRT' : 'LRT Train';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      label: Text(
                        shortLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSel,
                      selectedColor: color,
                      onSelected: (sel) {
                        setState(() => _selectedLine = sel ? id : null);
                        if (sel && _isRealMap) {
                          _fitLine(id);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'خريطة شبكة قطارات ومترو القاهرة' : 'Cairo Rail & Metro Network',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTeal,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: [
            Tab(icon: const Icon(Icons.map_outlined, size: 20), text: isAr ? 'مخطط الشبكة التخطيطي' : 'Schematic Diagram'),
            Tab(icon: const Icon(Icons.format_list_bulleted_rounded, size: 20), text: isAr ? 'دليل المحطات' : 'Station Directory'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: isAr ? 'دليل أسعار التذاكر والاشتراكات' : 'Fare & Ticket Guide',
            onPressed: () => _showFareGuideSheet(context, isDark, isAr),
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: isAr ? 'إعادة ضبط المنظور' : 'Reset View',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Tab 1: Interactive Real Google Map or Vector Schematic Map
          _isRealMap
              ? _buildRealMapView(context, isDark, isAr)
              : _buildSchematicView(context, isDark, isAr),

          // Tab 2: Searchable Line & Station Directory
          _buildDirectoryView(context, isDark, isAr),
        ],
      ),
    );
  }

  Widget _buildRealMapView(BuildContext context, bool isDark, bool isAr) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(30.0444, 31.2357),
            zoom: 11.2,
          ),
          onMapCreated: (controller) => _googleMapController = controller,
          polylines: _buildPolylines(isDark),
          markers: _buildMarkers(isAr),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),

        // Top Controls Overlay
        Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: _buildTopControlOverlay(context, isDark, isAr),
        ),

        // Floating Map Controls
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'real_map_recenter',
                backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
                foregroundColor: AppColors.primaryTeal,
                tooltip: isAr ? 'إعادة ضبط المنظور' : 'Recenter Cairo',
                onPressed: () {
                  _googleMapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      const CameraPosition(target: LatLng(30.0444, 31.2357), zoom: 11.2),
                    ),
                  );
                },
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'real_map_zoom_in',
                backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
                foregroundColor: AppColors.primaryTeal,
                onPressed: () => _googleMapController?.animateCamera(CameraUpdate.zoomIn()),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'real_map_zoom_out',
                backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
                foregroundColor: AppColors.primaryTeal,
                onPressed: () => _googleMapController?.animateCamera(CameraUpdate.zoomOut()),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchematicView(BuildContext context, bool isDark, bool isAr) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.45,
          maxScale: 3.5,
          boundaryMargin: const EdgeInsets.all(350),
          constrained: false,
          child: GestureDetector(
            onTapUp: (details) {
              final tapPos = details.localPosition;
              for (final st in _schematicStations) {
                if ((st.offset - tapPos).distance <= 28) {
                  setState(() => _selectedStation = st.name);
                  _showStationDetails(context, st.name, st.lines, isAr);
                  return;
                }
              }
            },
            child: CustomPaint(
              size: const Size(1320, 1180),
              painter: _CairoRailSchematicPainter(
                stations: _schematicStations,
                selectedStation: _selectedStation,
                isDark: isDark,
                isAr: isAr,
              ),
            ),
          ),
        ),

        // Top Controls Overlay
        Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: _buildTopControlOverlay(context, isDark, isAr),
        ),

        // Floating Zoom Controls
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'schematic_zoom_in',
                backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
                foregroundColor: AppColors.primaryTeal,
                onPressed: () => _zoom(1.25),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'schematic_zoom_out',
                backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
                foregroundColor: AppColors.primaryTeal,
                onPressed: () => _zoom(0.8),
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'schematic_reset',
                backgroundColor: isDark ? const Color(0xFF263238) : Colors.white,
                foregroundColor: AppColors.primaryTeal,
                onPressed: _resetZoom,
                child: const Icon(Icons.restore),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryView(BuildContext context, bool isDark, bool isAr) {
    final filteredLines = _lines.map((line) {
      final stations = (line['stations'] as List<String>).where((s) {
        if (_searchQuery.trim().isEmpty) return true;
        return s.contains(_searchQuery.trim());
      }).toList();
      return {
        ...line,
        'stations': stations,
      };
    }).where((line) => (line['stations'] as List).isNotEmpty).toList();

    return Column(
      children: [
        // Search box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: isAr ? 'ابحث عن محطة في الشبكة...' : 'Search station across network...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // Interchanges quick bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: _interchanges.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                  backgroundColor: AppColors.primaryTeal,
                  label: Text(
                    e.key,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedStation = e.key;
                      _selectedLine = null;
                    });
                    _showStationDetails(context, e.key, e.value, isAr);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 12),

        // Network List with interactive station expanders
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredLines.length,
            itemBuilder: (context, idx) {
              final line = filteredLines[idx];
              final lineId = line['id'] as String;
              final lineColor = line['color'] as Color;
              final lineName = isAr ? line['nameAr'] : line['nameEn'];
              final stations = line['stations'] as List<String>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: lineColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: ExpansionTile(
                  initiallyExpanded: _searchQuery.isNotEmpty || _selectedLine == lineId,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      lineId.replaceAll('MONORAIL', 'M'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  title: Text(
                    lineName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        isAr ? '${stations.length} محطة' : '${stations.length} stations',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: lineColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: lineColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _fareSummaryForLine(lineId, isAr),
                          style: TextStyle(
                            color: lineColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: stations.asMap().entries.map((entry) {
                          final i = entry.key;
                          final station = entry.value;
                          final isInterchange = _interchanges.containsKey(station);
                          final isFirst = i == 0;
                          final isLast = i == stations.length - 1;
                          final isSelected = _selectedStation == station;

                          return InkWell(
                            onTap: () {
                              setState(() => _selectedStation = station);
                              final meetingLines = _interchanges[station] ?? [lineId];
                              _showStationDetails(context, station, meetingLines, isAr);
                            },
                            child: Container(
                              color: isSelected ? lineColor.withValues(alpha: 0.12) : Colors.transparent,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 36,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (!isFirst)
                                          Positioned(top: 0, bottom: 18, child: Container(width: 3, color: lineColor)),
                                        if (!isLast)
                                          Positioned(top: 18, bottom: 0, child: Container(width: 3, color: lineColor)),
                                        Container(
                                          width: isInterchange ? 14 : 9,
                                          height: isInterchange ? 14 : 9,
                                          decoration: BoxDecoration(
                                            color: isInterchange ? Colors.white : lineColor,
                                            shape: BoxShape.circle,
                                            border: isInterchange ? Border.all(color: lineColor, width: 3) : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      station,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isInterchange ? FontWeight.bold : FontWeight.normal,
                                        color: isInterchange ? lineColor : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  if (isInterchange)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: lineColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isAr ? 'محطة تبادلية' : 'Interchange',
                                        style: TextStyle(color: lineColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showStationDetails(BuildContext context, String station, List<String> lines, bool isAr) {
    final geoMatch = _geoStations.where((s) => s.name == station || s.nameEn == station).firstOrNull;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_railway, color: AppColors.primaryTeal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      station,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lines.length > 1
                    ? (isAr ? 'محطة تبادلية تخدم الخطوط التالية:' : 'Interchange serving:')
                    : (isAr ? 'محطة تخدم خط:' : 'Line served:'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lines.map((lid) {
                  final lineInfo = _lines.firstWhere((l) => l['id'] == lid, orElse: () => _lines.first);
                  return Chip(
                    backgroundColor: (lineInfo['color'] as Color).withValues(alpha: 0.15),
                    avatar: CircleAvatar(
                      backgroundColor: lineInfo['color'] as Color,
                      radius: 8,
                    ),
                    label: Text(
                      isAr ? lineInfo['nameAr'] : lineInfo['nameEn'],
                      style: TextStyle(color: lineInfo['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              if (geoMatch != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.pin_drop_rounded, size: 20),
                    label: Text(
                      isAr ? 'عرض المحطة على الخريطة الحقيقية' : 'View on Real Map',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedStation = station;
                        _isRealMap = true;
                      });
                      _tabController.animateTo(0);
                      _googleMapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(geoMatch.position, 14.5),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(
                    isAr ? 'الإبلاغ عن مشكلة في هذه المحطة' : 'Report an issue with this station',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    MetroReportSheet.show(
                      context,
                      station: {
                        'name': station,
                        'lines': lines,
                        'is_interchange': lines.length > 1,
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _fareSummaryForLine(String lineId, bool isAr) {
    if (lineId == 'L1' || lineId == 'L2' || lineId == 'L3') {
      return isAr ? 'التذكرة: 10 - 20 ج.م' : 'Fare: 10 - 20 EGP';
    } else if (lineId == 'LRT') {
      return isAr ? 'التذكرة: 10 - 20 ج.م' : 'Fare: 10 - 20 EGP';
    } else if (lineId.contains('MONORAIL')) {
      return isAr ? 'التذكرة: 20 - 80 ج.م' : 'Fare: 20 - 80 EGP';
    }
    return isAr ? '10 - 20 ج.م' : '10 - 20 EGP';
  }

  void _showFareGuideSheet(BuildContext context, bool isDark, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          expand: false,
          builder: (sheetCtx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryTeal, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'دليل تذاكر واشتراكات النقل السككي' : 'Cairo Rail Fares & Pass Guide',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
                            ),
                            Text(
                              isAr ? 'التعريفة الرسمية المحدثة لشبكة مترو وقطارات القاهرة' : 'Official updated Cairo Metro & Rail tariffs',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Cairo Metro Single Tickets Card
                  _buildFareSectionCard(
                    title: isAr ? 'مترو أنفاق القاهرة (الخطوط 1، 2، 3)' : 'Cairo Metro Single Tickets (Lines 1, 2, 3)',
                    color: const Color(0xFFE53935),
                    icon: Icons.subway_rounded,
                    isDark: isDark,
                    items: [
                      _FareRowItem(
                        stage: isAr ? 'المرحلة الأولى (1 - 9 محطات)' : 'Stage 1 (1 - 9 stations)',
                        price: '10 ج.م',
                        discountText: isAr ? 'كبار السن 60+: 5 ج.م | ذوي الهمم: 5 ج.م' : 'Seniors 60+: 5 EGP | Special: 5 EGP',
                      ),
                      _FareRowItem(
                        stage: isAr ? 'المرحلة الثانية (10 - 16 محطة)' : 'Stage 2 (10 - 16 stations)',
                        price: '12 ج.م',
                        discountText: isAr ? 'كبار السن 60+: 6 ج.م | ذوي الهمم: 5 ج.م' : 'Seniors 60+: 6 EGP | Special: 5 EGP',
                      ),
                      _FareRowItem(
                        stage: isAr ? 'المرحلة الثالثة (17 - 23 محطة)' : 'Stage 3 (17 - 23 stations)',
                        price: '15 ج.م',
                        discountText: isAr ? 'كبار السن 60+: 7.5 ج.م | ذوي الهمم: 5 ج.م' : 'Seniors 60+: 7.5 EGP | Special: 5 EGP',
                      ),
                      _FareRowItem(
                        stage: isAr ? 'المرحلة الرابعة (أكثر من 24 محطة)' : 'Stage 4 (24+ stations)',
                        price: '20 ج.م',
                        discountText: isAr ? 'كبار السن 60+: 10 ج.م | ذوي الهمم: 5 ج.م' : 'Seniors 60+: 10 EGP | Special: 5 EGP',
                      ),
                    ],
                    footerNote: isAr
                        ? '• كبار السن فوق 70 عاماً مجاناً بموجب بطاقة الرقم القومي.\n• تذكرة ذوي الهمم موحدة بقيمة 5 ج.م لكافة المراحل.'
                        : '• Seniors 70+ ride free with National ID.\n• Special needs tickets flat 5 EGP across all zones.',
                  ),
                  const SizedBox(height: 14),

                  // LRT & Monorail Card
                  _buildFareSectionCard(
                    title: isAr ? 'القطار الكهربائي الخفيف والمونوريل' : 'LRT & Monorail Fares',
                    color: const Color(0xFF00ACC1),
                    icon: Icons.tram_rounded,
                    isDark: isDark,
                    items: [
                      _FareRowItem(
                        stage: isAr ? 'القطار الخفيف (LRT) - حتى 3 محطات' : 'LRT - Up to 3 stations',
                        price: '10 ج.م',
                        discountText: null,
                      ),
                      _FareRowItem(
                        stage: isAr ? 'القطار الخفيف (LRT) - حتى 7 محطات' : 'LRT - Up to 7 stations',
                        price: '15 ج.م',
                        discountText: null,
                      ),
                      _FareRowItem(
                        stage: isAr ? 'القطار الخفيف (LRT) - أكثر من 7 محطات' : 'LRT - More than 7 stations',
                        price: '20 ج.م',
                        discountText: null,
                      ),
                      _FareRowItem(
                        stage: isAr ? 'مونوريل شرق وغرب النيل' : 'East & West Monorail',
                        price: '20 - 80 ج.م',
                        discountText: isAr ? 'تتدرج حسب مسافة ومحطات الرحلة' : 'Graduated based on journey distance',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Metro Subscriptions Overview Card
                  _buildFareSectionCard(
                    title: isAr ? 'اشتراكات المترو (توفير شهري وربع سنوي)' : 'Metro Subscription Passes',
                    color: const Color(0xFF1E88E5),
                    icon: Icons.card_membership_rounded,
                    isDark: isDark,
                    items: [
                      _FareRowItem(
                        stage: isAr ? 'الاشتراك الشهري العام (مرحلة واحدة)' : 'Public Monthly (Stage 1 / 1 zone)',
                        price: '390 ج.م / شهر',
                        discountText: isAr ? 'وفر أكثر من 35% مقارنة بالتذاكر اليومية' : 'Save >35% vs daily single tickets',
                      ),
                      _FareRowItem(
                        stage: isAr ? 'الاشتراك الشهري العام (مرحلتين)' : 'Public Monthly (Stage 2 / 2 zones)',
                        price: '440 ج.م / شهر',
                        discountText: null,
                      ),
                      _FareRowItem(
                        stage: isAr ? 'اشتراك الطلبة الربع سنوي' : 'Student Quarterly (3 Months)',
                        price: '150 - 300 ج.م',
                        discountText: isAr ? 'مدعوم حكومياً بنسبة تصل إلى 95%' : 'Government subsidized up to 95%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Commute budget calculator launcher button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1B3830), const Color(0xFF162529)]
                            : [AppColors.primaryTeal.withValues(alpha: 0.12), Colors.teal.shade50],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calculate_rounded, color: AppColors.primaryTeal, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'حاسبة ومقارنة اشتراكات المترو' : 'Commute Budget & Pass Calculator',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAr
                              ? 'قارن تكلفة التذاكر اليومية مع الاشتراكات الشهرية والربع سنوية واكتشف خطة التوفير الأنسب لرحلاتك.'
                              : 'Compare daily ticket expenses with monthly and quarterly passes to discover your optimal savings.',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: Text(
                              isAr ? 'فتح حاسبة الاشتراكات' : 'Open Pass Calculator',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CommuteBudgetScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFareSectionCard({
    required String title,
    required Color color,
    required IconData icon,
    required bool isDark,
    required List<_FareRowItem> items,
    String? footerNote,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252C38) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.stage,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (item.discountText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.discountText!,
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.price,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (footerNote != null) ...[
            const SizedBox(height: 6),
            Text(
              footerNote,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _FareRowItem {
  final String stage;
  final String price;
  final String? discountText;

  const _FareRowItem({
    required this.stage,
    required this.price,
    this.discountText,
  });
}

/// Custom schematic vector diagram painter for Greater Cairo rail lines
class _CairoRailSchematicPainter extends CustomPainter {
  final List<_SchematicStation> stations;
  final String? selectedStation;
  final bool isDark;
  final bool isAr;

  _CairoRailSchematicPainter({
    required this.stations,
    required this.selectedStation,
    required this.isDark,
    required this.isAr,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Grid & Nile River Corridor
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF13171F) : const Color(0xFFF8F9FA)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Stylized Nile River Ribbon
    final nilePaint = Paint()
      ..color = (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFD6E4F0)).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final nilePath = Path()
      ..moveTo(380, 1120)
      ..quadraticBezierTo(370, 750, 390, 520)
      ..quadraticBezierTo(400, 380, 370, 80);
    canvas.drawPath(nilePath, nilePaint);

    // 2. Cairo Rail Lines
    // Line 1: Blue
    _drawLine(
      canvas,
      [
        const Offset(480, 1080), // Helwan
        const Offset(460, 850),  // Maadi
        const Offset(450, 760),
        const Offset(435, 680),
        const Offset(420, 560),
        const Offset(420, 510),  // Sadat
        const Offset(420, 460),  // Nasser
        const Offset(420, 415),
        const Offset(420, 370),  // Al-Shohadaa
        const Offset(460, 320),  // Ghamra
        const Offset(550, 230),  // Saray El-Qobba
        const Offset(620, 160),  // Matareya
        const Offset(730, 60),   // New El-Marg
      ],
      const Color(0xFF0077E6),
      7.0,
    );

    // Line 2: Orange
    _drawLine(
      canvas,
      [
        const Offset(260, 160),  // Shubra
        const Offset(300, 220),
        const Offset(350, 310),  // Rod El-Farag
        const Offset(420, 370),  // Al-Shohadaa
        const Offset(480, 430),  // Attaba
        const Offset(450, 470),  // Naguib
        const Offset(420, 510),  // Sadat
        const Offset(360, 540),  // Opera
        const Offset(320, 570),  // Dokki
        const Offset(280, 600),  // Bohooth
        const Offset(240, 640),  // Cairo Univ
        const Offset(240, 750),  // Giza
        const Offset(240, 850),
        const Offset(240, 960),  // El-Mounib
      ],
      const Color(0xFFE76F51),
      7.0,
    );

    // Line 3: Green
    // Branch 1: Rod El Farag Corridor -> Kit Kat
    _drawLine(
      canvas,
      [
        const Offset(130, 310),
        const Offset(230, 410),
        const Offset(310, 490),  // Kit Kat
      ],
      const Color(0xFF2A9D8F),
      6.0,
    );

    // Branch 2: Cairo Univ -> Kit Kat
    _drawLine(
      canvas,
      [
        const Offset(240, 640),  // Cairo Univ
        const Offset(270, 560),
        const Offset(310, 490),  // Kit Kat
      ],
      const Color(0xFF2A9D8F),
      6.0,
    );

    // Main Trunk: Kit Kat -> Adly Mansour
    _drawLine(
      canvas,
      [
        const Offset(310, 490),  // Kit Kat
        const Offset(350, 475),  // Safaa Hegazy
        const Offset(385, 465),  // Maspero
        const Offset(420, 460),  // Nasser
        const Offset(480, 430),  // Attaba
        const Offset(630, 350),  // Abbassiya
        const Offset(720, 310),  // Cairo Stadium
        const Offset(760, 290),
        const Offset(800, 270),  // Al-Ahram
        const Offset(860, 235),  // Heliopolis
        const Offset(900, 210),
        const Offset(960, 180),
        const Offset(1060, 140), // Adly Mansour
      ],
      const Color(0xFF2A9D8F),
      7.0,
    );

    // Monorail: Purple
    _drawLine(
      canvas,
      [
        const Offset(720, 310),  // Cairo Stadium
        const Offset(790, 430),  // 7th District
        const Offset(870, 540),  // Tantawy
        const Offset(930, 620),  // CFC
        const Offset(1020, 740), // AUC New Cairo
        const Offset(1100, 840), // Arts & Culture
      ],
      const Color(0xFF9C6DC2),
      5.5,
    );

    // LRT Capital Train: Teal
    _drawLine(
      canvas,
      [
        const Offset(1060, 140), // Adly Mansour
        const Offset(1130, 120), // Obour
        const Offset(1180, 120), // Shorouk
        const Offset(1230, 120), // Badr
        const Offset(1230, 170), // Airport
        const Offset(1230, 230), // Arts & Culture LRT
      ],
      const Color(0xFF4DA89B),
      5.5,
    );

    // 3. Render Stations & Interchange Nodes
    for (final st in stations) {
      final isSelected = selectedStation == st.name;

      if (st.isInterchange) {
        // Large interchange concentric node
        final outerPaint = Paint()
          ..color = isDark ? Colors.white : Colors.black87
          ..style = PaintingStyle.fill;
        final innerPaint = Paint()
          ..color = isDark ? const Color(0xFF1E2630) : Colors.white
          ..style = PaintingStyle.fill;
        final corePaint = Paint()
          ..color = AppColors.primaryTeal
          ..style = PaintingStyle.fill;

        canvas.drawCircle(st.offset, 9.5, outerPaint);
        canvas.drawCircle(st.offset, 7.5, innerPaint);
        canvas.drawCircle(st.offset, 4.5, corePaint);

        if (isSelected) {
          final glowPaint = Paint()
            ..color = AppColors.primaryTeal.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6;
          canvas.drawCircle(st.offset, 15, glowPaint);
        }
      } else {
        // Regular station node
        final nodePaint = Paint()
          ..color = isDark ? Colors.white : Colors.black87
          ..style = PaintingStyle.fill;
        canvas.drawCircle(st.offset, 4.0, nodePaint);

        if (isSelected) {
          final glowPaint = Paint()
            ..color = const Color(0xFFE76F51).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5;
          canvas.drawCircle(st.offset, 10, glowPaint);
        }
      }

      // Station Text Label
      final label = isAr ? st.name : st.nameEn;
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: st.isInterchange
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: st.isInterchange ? FontWeight.bold : FontWeight.w500,
          fontSize: st.isInterchange ? 12 : 10,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      );
      textPainter.layout();

      // Position label offset to avoid obscuring the track
      final labelOffset = Offset(
        st.offset.dx + (isAr ? -textPainter.width - 8 : 8),
        st.offset.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, labelOffset);
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CairoRailSchematicPainter oldDelegate) {
    return oldDelegate.selectedStation != selectedStation ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isAr != isAr;
  }
}

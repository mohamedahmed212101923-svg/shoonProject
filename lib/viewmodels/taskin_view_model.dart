import 'dart:async';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/viewmodels/marriage/exportWivesToPdfA3.dart';
import '../services/database/soldiers_repository.dart';

class TaskinViewModel extends ChangeNotifier {
  final SoldiersRepository repository;
  String? batchId;
  Timer? _debounce;
  int _lastRequestId = 0;

  // --- حالات البيانات (Data States) ---
  List<Map<String, String>> _rawDbSoldiers = [];
  List<Map<String, String>> filteredSoldiers = [];
  bool isLoading = false;

  // --- إعدادات الفرز المتعدد (Multi-level Sorting Settings) ---
  // نستخدم قائمة لتخزين الأولويات (العنصر الأول في القائمة هو الأولوية الأولى في SQL)
  List<String> selectedSortLabels = [];
  bool isAscending = true;

  // --- إعدادات الأعمدة (Column Settings) ---
  List<String> selectedColumnLabels = [];
  List<String> soldierKeys = [];

  // --- المتحكمات (Controllers) ---
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // --- القوائم الثابتة (Constants) ---
  final List<Map<String, String>> allColumns = [
    {"label": 'رقم السجل', "key": "soldiers_unit_id"},
    {"label": 'المؤهل', "key": "soldiers_qualification"},
    {"label": 'الإدارة', "key": "soldiers_management"},
    {"label": "السلاح", "key": "soldiers_weapon"},
    {"label": "المحافظة", "key": "soldiers_city"},
    {"label": "الاتجاه", "key": "soldiers_direction"},
    {"label": "العنوان", "key": "soldiers_address"},
    {"label": 'منطقة التجنيد', "key": "soldiers_area"},
    {"label": "التخصص", "key": "soldiers_specialization"},
    {"label": 'سنة زيادة', "key": "soldiers_plus_year"},
    {"label": 'تاريخ التجنيد', "key": "soldiers_military_date"},
    {"label": 'تاريخ الضم', "key": "soldiers_income_date"},
    {"label": 'تاريخ التسريح', "key": "soldiers_end_date"},
    {"label": 'تاريخ الميلاد', "key": "soldiers_birth_date"},
    {"label": 'الرقم الثلاثى', "key": "soldiers_triple_number"},
    {"label": 'الرقم القومى', "key": "soldiers_national_number"},
    {"label": "الديانة", "key": "soldiers_religion"},
    {"label": 'فصيلة الدم', "key": "soldiers_blood_type"},
    {"label": 'اقرب الاقارب', "key": "soldiers_father_name"},
    {"label": "الوحدة", "key": "sending_area"},
    {"label": "الموقف", "key": "moqf_type"},
    {"label": "المنحة", "key": "gift_type"},
    {"label": "تاريخ الترحيل", "key": "sending_date"},
    {"label": "التبعية", "key": "sending_father_area"},
    {"label": "المهنة", "key": "soldiers_job"},
    {"label": "الفرقة", "key": "sending_note"},
    {"label": "الحالة", "key": "marital_status"},
  ];

  final List<Map<String, String>> sortOptions = [
    {"label": 'الإسم', "key": "soldiers_name"},
    {"label": 'الكتيبة', "key": "soldiers_k"},
    {"label": 'السرية', "key": "soldiers_s"},
    {"label": 'الفصيلة', "key": "soldiers_f"},
    {"label": 'رقم السجل', "key": "soldiers_unit_id"},
    {"label": 'المؤهل', "key": "soldiers_qualification"},
    {"label": 'الإدارة', "key": "soldiers_management"},
    {"label": "السلاح", "key": "soldiers_weapon"},
    {"label": "المحافظة", "key": "soldiers_city"},
    {"label": 'منطقة التجنيد', "key": "soldiers_area"},
    {"label": "التخصص", "key": "soldiers_specialization"},
    {"label": 'سنة زيادة', "key": "soldiers_plus_year"},
    {"label": "الديانة", "key": "soldiers_religion"},
    {"label": "الوحدة", "key": "sending_area"},
    {"label": "الموقف", "key": "moqf_type"},
    {"label": "المنحة", "key": "gift_type"},
    {"label": "تاريخ الترحيل", "key": "sending_date"},
    {"label": "التبعية", "key": "sending_father_area"},
    {"label": "الفرقة", "key": "sending_note"},
  ];

  // --- قوائم الخيارات المتاحة (Options) ---
  List<String> katibaOptions = [],
      sareyaOptions = [],
      fasilaOptions = [],
      mohafazaOptions = [];
  List<String> idaraOptions = [],
      silahOptions = [],
      moahelOptions = [],
      sanatZiyadaOptions = [];
  List<String> statusOptions = [],
      uniteOptions = [],
      giftOptions = [],
      sendingDateOptions = [];
  List<String> specializationOptions = [],
      incomeDateOptions = [],
      militaryDateOptions = [],
      religionOptions = [];

  List<String> fatherUniteOptions = [],
      jopOptions = [],
      leaveOptions = [],
      maritalStatusOptions = [];

  // --- القيم المختارة للفلترة (Active Filters) ---
  List<String> selectedKatiba = [],
      selectedSareya = [],
      selectedFasila = [],
      selectedMohafaza = [];
  List<String> selectedIdara = [],
      selectedSilah = [],
      selectedMoahel = [],
      selectedSanatZiyada = [];
  List<String> selectedStatus = [],
      selectedUnite = [],
      selectedGift = [],
      selectedsendingDate = [];
  List<String> selectedSpecialization = [],
      selectedIncomeDates = [],
      selectedMilitaryDates = [],
      selectedReligion = [];
  List<String> selectedFatherUnite = [],
      selectedJop = [],
      selectedLeave = [],
      selectedMaritalStatus = [];

  TaskinViewModel(this.repository, {this.batchId}) {
    _initDefaultColumns();
    if (batchId != null) _init();
  }

  // --- وظائف الترتيب المطور (Advanced Sorting Logic) ---

  // دالة تحويل الأسماء المختار إلى نص يفهمه SQL
  String get _buildOrderByString {
    if (selectedSortLabels.isEmpty) return 'soldiers_unit_id';

    // تحويل كل Label إلى Key المقابل له في SQL
    return selectedSortLabels
        .map((label) {
          return sortOptions.firstWhere((opt) => opt['label'] == label)['key'];
        })
        .join(', ');
  }

  void toggleSortOption(String label) {
    if (selectedSortLabels.contains(label)) {
      selectedSortLabels.remove(label);
    } else {
      selectedSortLabels.add(label);
    }
    fetchFilteredData(); // إعادة جلب البيانات بالترتيب الجديد
  }

  void toggleSortDirection() {
    isAscending = !isAscending;
    fetchFilteredData();
  }

  // --- وظائف البيانات (Data Fetching) ---
  Future<void> _init() async {
    await updateBatch(batchId);
  }

  void _initDefaultColumns() {
    soldierKeys = [
      'soldiers_name',
      'soldiers_number',
      'soldiers_k',
      'soldiers_s',
      'soldiers_f',
    ];
  }

  Future<void> updateBatch(String? newBatch) async {
    if (batchId == newBatch && _rawDbSoldiers.isNotEmpty) return;
    batchId = newBatch;
    repository.setBatch(newBatch);
    await fetchFilteredData();
  }

  Future<void> fetchFilteredData() async {
    final currentRequestId = ++_lastRequestId;
    isLoading = true;
    notifyListeners();

    try {
      final rows = await repository.multiFilter(
        {}, // يمكنك تمرير الفلاتر هنا لو أردت الفلترة في SQL
        orderBy: _buildOrderByString,
        isAscending: isAscending,
      );

      if (currentRequestId != _lastRequestId) return;

      _rawDbSoldiers = rows
          .map((r) => r.map((k, v) => MapEntry(k, v?.toString() ?? '')))
          .toList();

      applyFilters(isInitial: true);
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (currentRequestId == _lastRequestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Key tableKey = UniqueKey(); // المفتاح المسؤول عن إعادة ضبط الجدول
  // --- وظائف الفلترة (Filtering Logic) ---
  void applyFilters({bool isInitial = false}) {
    if (batchId == null) return;

    if (!isInitial) {
      isLoading = true;
      notifyListeners();
    }

    final query = normalizeArabic(searchController.text);

    filteredSoldiers = _rawDbSoldiers.where((s) {
      bool matches(List<String> selected, String key) =>
          selected.isEmpty || selected.contains(s[key]);

      bool dropdownsMatch =
          matches(selectedKatiba, 'soldiers_k') &&
          matches(selectedSareya, 'soldiers_s') &&
          matches(selectedFasila, 'soldiers_f') &&
          matches(selectedMohafaza, 'soldiers_city') &&
          matches(selectedIdara, 'soldiers_management') &&
          matches(selectedSilah, 'soldiers_weapon') &&
          matches(selectedMoahel, 'soldiers_qualification') &&
          matches(selectedSanatZiyada, 'soldiers_plus_year') &&
          matches(selectedStatus, 'moqf_type') &&
          matches(selectedUnite, 'sending_area') &&
          matches(selectedGift, 'gift_type') &&
          matches(selectedsendingDate, 'sending_date') &&
          matches(selectedSpecialization, 'soldiers_specialization') &&
          matches(selectedIncomeDates, 'soldiers_income_date') &&
          matches(selectedMilitaryDates, 'soldiers_military_date') &&
          matches(selectedReligion, 'soldiers_religion') &&
          matches(selectedFatherUnite, 'sending_father_area') &&
          matches(selectedMaritalStatus, 'marital_status') &&
          matches(selectedLeave, 'leave_status') &&
          matches(selectedJop, 'soldiers_job');

      if (!dropdownsMatch) return false;
      if (query.isEmpty) return true;

      final name = normalizeArabic(s['soldiers_name'] ?? '');
      final militaryNumber = normalizeArabic(s['soldiers_number'] ?? '');
      return name.contains(query) || militaryNumber.contains(query);
    }).toList();

    _refreshAllOptions();
    tableKey = UniqueKey();
    isLoading = false;
    notifyListeners();
  }

  // --- وظائف المساعدة والتبديل ---
  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => applyFilters());
    notifyListeners();
  }

  void _toggleInList(List<String> list, String value) {
    list.contains(value) ? list.remove(value) : list.add(value);
    applyFilters();
  }

  void _refreshAllOptions() {
    List<String> getDistinct(String key) =>
        filteredSoldiers
            .map((e) => e[key] ?? '')
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    katibaOptions = getDistinct('soldiers_k');
    sareyaOptions = getDistinct('soldiers_s');
    fasilaOptions = getDistinct('soldiers_f');
    mohafazaOptions = getDistinct('soldiers_city');
    idaraOptions = getDistinct('soldiers_management');
    silahOptions = getDistinct('soldiers_weapon');
    moahelOptions = getDistinct('soldiers_qualification');
    sanatZiyadaOptions = getDistinct('soldiers_plus_year');
    statusOptions = getDistinct('moqf_type');
    uniteOptions = getDistinct('sending_area');
    giftOptions = getDistinct('gift_type');
    sendingDateOptions = getDistinct('sending_date');
    specializationOptions = getDistinct('soldiers_specialization');
    incomeDateOptions = getDistinct('soldiers_income_date');
    militaryDateOptions = getDistinct('soldiers_military_date');
    religionOptions = getDistinct('soldiers_religion');
    fatherUniteOptions = getDistinct('sending_father_area');
    jopOptions = getDistinct('soldiers_job');
    maritalStatusOptions = getDistinct('marital_status');
    leaveOptions = getDistinct('leave_status');
  }

  void _clearAllFilters() {
    selectedKatiba.clear();
    selectedSareya.clear();
    selectedFasila.clear();
    selectedMohafaza.clear();
    selectedIdara.clear();
    selectedSilah.clear();
    selectedMoahel.clear();
    selectedSanatZiyada.clear();
    selectedStatus.clear();
    selectedUnite.clear();
    selectedGift.clear();
    selectedsendingDate.clear();
    selectedSpecialization.clear();
    selectedIncomeDates.clear();
    selectedMilitaryDates.clear();
    selectedReligion.clear();
    selectedFatherUnite.clear();
    selectedJop.clear();
    selectedMaritalStatus.clear();
    selectedLeave.clear();

    searchController.clear();
  }

  Future<void> resetFilters() async {
    _clearAllFilters();
    applyFilters();
  }

  void toggleKatiba(String v) => _toggleInList(selectedKatiba, v);
  void toggleSareya(String v) => _toggleInList(selectedSareya, v);
  void toggleFasila(String v) => _toggleInList(selectedFasila, v);
  void toggleMohafaza(String v) => _toggleInList(selectedMohafaza, v);
  void toggleIdara(String v) => _toggleInList(selectedIdara, v);
  void toggleSilah(String v) => _toggleInList(selectedSilah, v);
  void toggleMoahel(String v) => _toggleInList(selectedMoahel, v);
  void toggleSanatZiyada(String v) => _toggleInList(selectedSanatZiyada, v);
  void toggleStatus(String v) => _toggleInList(selectedStatus, v);
  void toggleUnite(String v) => _toggleInList(selectedUnite, v);
  void toggleGift(String v) => _toggleInList(selectedGift, v);
  void toggleSendingDate(String v) => _toggleInList(selectedsendingDate, v);
  void toggleSpecialization(String v) =>
      _toggleInList(selectedSpecialization, v);
  void toggleIncomeDate(String v) => _toggleInList(selectedIncomeDates, v);
  void toggleMilitaryDate(String v) => _toggleInList(selectedMilitaryDates, v);
  void toggleReligion(String v) => _toggleInList(selectedReligion, v);
  void toggleFatherUnit(String v) => _toggleInList(selectedFatherUnite, v);
  void toggleJop(String v) => _toggleInList(selectedJop, v);
  void toggleMaritalStatus(String v) => _toggleInList(selectedMaritalStatus, v);
  void toggleLeave(String v) => _toggleInList(selectedLeave, v);

  Future<void> exportPdfSafe() async {
    if (filteredSoldiers.isEmpty || isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      debugPrint("1. جاري تحميل الخطوط...");
      final ByteData regularData = await rootBundle.load(
        "assets/fonts/Cairo-Regular.ttf",
      );
      final ByteData boldData = await rootBundle.load(
        "assets/fonts/Cairo-Bold.ttf",
      );

      final payload = {
        'soldiers': List<Map<String, String>>.from(filteredSoldiers),
        'regularFont': regularData.buffer.asUint8List(),
        'boldFont': boldData.buffer.asUint8List(),
      };

      debugPrint("2. بدء معالجة الـ PDF (التقسيم اليدوي)...");
      // استخدام compute لضمان عدم تجمد الواجهة
      final pdfBytes = await compute(buildPdfBytes, payload);

      debugPrint("3. تم البناء، جاري فتح نافذة الحفظ...");
      final FileSaveLocation? location = await getSaveLocation(
        suggestedName: "كشف_الجنود_A3.pdf",
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PDF File', extensions: ['pdf']),
        ],
      );

      if (location == null) {
        debugPrint("تم إلغاء الحفظ");
        return;
      }

      final File file = File(location.path);
      await file.writeAsBytes(pdfBytes, flush: true);
      debugPrint("5. تم الحفظ بنجاح في: ${location.path}");
    } catch (e, s) {
      debugPrint("خطأ في التصدير: $e");
      debugPrint("StackTrace: $s");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Column Management
  void toggleColumn(String label) {
    selectedColumnLabels.contains(label)
        ? selectedColumnLabels.remove(label)
        : selectedColumnLabels.add(label);
    _updateKeysFromSelected();
    notifyListeners();
  }

  void _updateKeysFromSelected() {
    final dynamicKeys = allColumns
        .where((col) => selectedColumnLabels.contains(col["label"]))
        .map((col) => col["key"]!)
        .toList();
    soldierKeys = [
      'soldiers_name',
      'soldiers_number',
      'soldiers_k',
      'soldiers_s',
      'soldiers_f',
      ...dynamicKeys,
    ];
  }

  List<DataColumn> get soldierColumns {
    return [
      const DataColumn(label: Text('الاسم')),
      const DataColumn(label: Text('الرقم العسكرى')),
      const DataColumn(label: Text('الكتيبة')),
      const DataColumn(label: Text('السرية')),
      const DataColumn(label: Text('الفصيل')),
      ...selectedColumnLabels.map((lbl) => DataColumn(label: Text(lbl))),
    ];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}

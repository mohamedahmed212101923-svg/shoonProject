import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/services/database/batch_repository.dart';
import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:flutter_application_1/services/database/leaders_repository.dart';
import 'package:flutter_application_1/services/database/soldiers_repository.dart';
import 'package:flutter_application_1/services/database/tarhil_repo.dart';
import 'package:flutter_application_1/viewmodels/tarheel/generate_report_tamam_tarhil.dart';
import 'package:pdf/widgets.dart' as pw;

class TarhilViewModel extends ChangeNotifier {
  final SoldiersRepository repo;
  TarhilViewModel(this.repo);
  final BatchesRepository _batchesRepo = BatchesRepository(SqlDb());
  final TarhilRepo _tarhilRepo = TarhilRepo(SqlDb());

  final LeadersRepository _leadersRepo = LeadersRepository(SqlDb());
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> allSoldiers = [];
  List<Map<String, dynamic>> allSending = [];
  List<Map<String, dynamic>> filtered = [];
  List<String> excludedOptions = [];
  List<String> excludedNames = []; // بدل التحويل من IDs كل مرة
  void rebuildExcludedOptions() {
    nameToSendingId.clear();
    excludedOptions.clear();

    final source = bulkMode == "الوحدات" ? bulkDateUnits : bulkDateFatherAreas;

    if (source.isEmpty) {
      notifyListeners();
      return;
    }

    final names = <String>{};

    for (final row in allSending) {
      if (!_matchSendingDateFilter(row)) continue;
      if (!_matchKSFFilter(row)) continue;

      final key = bulkMode == "الوحدات"
          ? row['sending_area']
          : row['sending_father_area'];

      final name = row['soldiers_name']?.toString();
      final sendingId = row['sending_id'];

      if (source.contains(key) && name != null && sendingId != null) {
        names.add(name);
        nameToSendingId[name] = sendingId as int;
      }
    }

    excludedOptions = names.toList()..sort();

    // تنظيف القيم المختارة لو خرجت بره الفلتر
    excludedNames = excludedNames
        .where((n) => excludedOptions.contains(n))
        .toList();

    notifyListeners();
  }

  Map<String, dynamic>? selectedSoldier;
  DateTime? sendingDate;
  String? sendingArea;
  String? sendingFatherArea;

  String filterName = "";
  DateTime? filterDate;

  List<String> selectedFilterAreas = [];
  List<String> selectedFilterFatherAreas = [];

  List<String> filterAreasOptions = [];
  List<String> filterFatherAreasOptions = [];

  String? bulkMode;
  List<int> excludedSendingIds = []; // الأفراد المستثنون
  final TextEditingController bulkDateController =
      TextEditingController(); // حقل التاريخ

  List<String> bulkDateUnits = []; // الوحدات لتحديث التاريخ
  List<String> bulkDateFatherAreas = []; // التبعيات لتحديث التاريخ

  List<String> bulkFatherAreaUnits = [];
  String? bulkSelectedFatherArea;

  List<String> selectedKs = [];
  List<String> selectedSs = [];
  List<String> selectedFs = [];

  void toggleK(String k) {
    if (selectedKs.contains(k)) {
      selectedKs.remove(k);
      selectedSs.clear();
      selectedFs.clear();
    } else {
      selectedKs.add(k);
    }
    rebuildExcludedOptions(); // 🔥
  }

  void toggleS(String s) {
    if (selectedSs.contains(s)) {
      selectedSs.remove(s);
      selectedFs.clear();
    } else {
      selectedSs.add(s);
    }
    rebuildExcludedOptions(); // 🔥
  }

  void toggleF(String f) {
    selectedFs.contains(f) ? selectedFs.remove(f) : selectedFs.add(f);

    rebuildExcludedOptions(); // 🔥
  }

  bool _matchKSFFilter(Map<String, dynamic> row) {
    if (selectedKs.isNotEmpty && !selectedKs.contains(row['soldiers_k'])) {
      return false;
    }
    if (selectedSs.isNotEmpty && !selectedSs.contains(row['soldiers_s'])) {
      return false;
    }
    if (selectedFs.isNotEmpty && !selectedFs.contains(row['soldiers_f'])) {
      return false;
    }
    return true;
  }

  Future<Map<String, String>?> _getLeaderInfo() async {
    final allLeaders = await _leadersRepo.getLeaders();
    final leaderRecord = allLeaders.firstWhere(
      (l) => (l['leader_id'] as int) == 1,
      orElse: () => {},
    );
    if (leaderRecord.isNotEmpty) {
      return {
        'name': leaderRecord['leader_name'].toString(),
        'rank': leaderRecord['leader_rank'].toString(),
      };
    }
    return null;
  }

  List<String> areas = []; // ستحتوي على أسماء التبعيات فقط
  List<String> fatherAreas = []; // ستحتوي على أسماء الوحدات فقط

  Future<void> exportTarhilPdf({Map<String, dynamic>? extraData}) async {
    try {
      isLoading = true;
      notifyListeners();

      // 1. جلب بيانات الدفعة الحالية
      final batchData = await _batchesRepo.getById(
        int.parse(batchId.toString()),
      );

      // التأكد من وجود بيانات للدفعة
      if (batchData == null) {
        debugPrint("Error: Batch data not found");
        return;
      }

      // 2. التعديل هنا: نرسل batch_name (String) بدلاً من الـ ID 🔥
      // لأن الـ Repo الجديد أصبح يقارن أرقام الدفعات نصياً
      final Map<String, int> prevBatchCounts = await _tarhilRepo
          .getPreviousBatchNotSentCounts(batchData['batch_name'].toString());

      // 3. دمج البيانات الجديدة في الـ extraData
      final Map<String, dynamic> finalExtraData = extraData ?? {};
      finalExtraData['prevBatchCounts'] = prevBatchCounts;

      // 4. جلب بيانات القائد
      final Map<String, String>? leaderInfo = await _getLeaderInfo();

      // 5. توليد ملف الـ PDF
      final pw.Document pdf = await generateReportTamamTarhil(
        allSending,
        batchData['batch_name'],
        leaderInfo,
        finalExtraData,
      );

      // 6. حفظ الملف (باقي الكود سليم)
      final bytes = await pdf.save();

      final location = await getSaveLocation(
        suggestedName: "تقرير_تمام_الترحيلات_.pdf",
        acceptedTypeGroups: [
          const XTypeGroup(label: "PDF", extensions: ["pdf"]),
        ],
      );

      if (location != null) {
        final file = File(
          location.path.endsWith(".pdf")
              ? location.path
              : "${location.path}.pdf",
        );
        await file.writeAsBytes(bytes, flush: true);
        debugPrint("PDF saved successfully at: ${file.path}");
      }
    } catch (e) {
      debugPrint("Tarhil PDF Export Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUite() async {
    // جلب البيانات من الـ Repo (قائمة خرائط)
    final unitsData = await repo.getAllTabaeia();
    final subUnitsData = await repo.getAllUnits();

    fatherAreas = unitsData.map((e) => e['tabaeia_name'].toString()).toList();

    areas = subUnitsData.map((e) => e['units_name'].toString()).toList();
    notifyListeners();
  }

  final List<DataColumn> columns = const [
    DataColumn(label: Text("اسم الجندي")),
    DataColumn(label: Text("الرقم العسكري")),

    DataColumn(label: Text("الكتيبة")),
    DataColumn(label: Text("السرية")),
    DataColumn(label: Text("الفصيلة")),
    DataColumn(label: Text("رقم سجل")),
    DataColumn(label: Text("السلاح")),
    DataColumn(label: Text("منطقة الترحيل")),
    DataColumn(label: Text("تاريخ الترحيل")),
    DataColumn(label: Text("التبعية")),
    DataColumn(label: Text("ملاحظات")),
  ];

  final List<String> keys = [
    "soldiers_name",
    "soldiers_number",

    "soldiers_k",
    "soldiers_s",
    "soldiers_f",
    "soldiers_unit_id",
    "soldiers_weapon",
    "sending_area",
    "sending_date",
    "sending_father_area",
    "sending_note",
  ];
  // قائمة الوحدات المخصصة فقط لنافذة "تسديد التاريخ"
  // خيارات الوحدات لجزء الـ Bulk (تتبع الفلتر العلوي)
  // خيارات الوحدات (لجزء تسديد التاريخ فقط)
  List<String> get bulkDateFatherAreaOptions {
    return _applyBaseFilters()
        .map((e) => e['sending_father_area']?.toString().trim())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // خيارات التبعيات (لجزء تسديد التاريخ فقط)
  List<String> get bulkDateAreaOptions {
    return _applyBaseFilters() // دي دلوقتي شايفة (التاريخ + الكتيبة + السرية) 🔥
        .map((e) => e['sending_area']?.toString().trim())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<DropdownMenuItem<String>> get areaItems =>
      areas.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList();
  List<DropdownMenuItem<String>> get fatherAreaItems => fatherAreas
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList();

  // قوائم الفلترة (لـ MultiSelectPopup - ترجع String فقط)
  List<String> get filterAreaItems {
    final withDep = dependencyFilter.contains("له تبعية");
    final withoutDep = dependencyFilter.contains("بدون تبعية");

    // لو ولا اختيار → اعرض الكل
    if (!withDep && !withoutDep) return filterAreasOptions;

    return filterAreasOptions.where((u) {
      final hasDep = unitsWithDependency.contains(u);
      return (withDep && hasDep) || (withoutDep && !hasDep);
    }).toList();
  }

  List<String> get filterFatherAreaItems => filterFatherAreasOptions;
  void toggleDependencyFilter(String v) {
    dependencyFilter.contains(v)
        ? dependencyFilter.remove(v)
        : dependencyFilter.add(v);
    notifyListeners();
  }

  List<String> dependencyFilter = [];

  List<String> get fatherAreaValues {
    return fatherAreaItems.map((e) => e.value).whereType<String>().toList();
  }

  String? _batchId;
  String? get batchId => _batchId;

  void updateBatch(String? newBatchId) {
    if (_batchId == newBatchId) return;

    _batchId = newBatchId;

    try {
      repo.setBatch(newBatchId);
    } catch (_) {}

    // تحميل الداتا بعد ما الـ provider يخلص الـ build
    Future.microtask(load);
  }

  String dependencyMode = "without"; // without | with
  void setDependencyMode(String v) {
    dependencyMode = v;
    notifyListeners();
  }

  Set<String> get unitsWithDependency {
    final set = <String>{};

    for (final row in allSending) {
      final unit = row['sending_area']?.toString();
      final father = row['sending_father_area']?.toString();

      if (unit != null &&
          unit.isNotEmpty &&
          father != null &&
          father.isNotEmpty) {
        set.add(unit);
      }
    }
    return set;
  }

  List<String> sendingDateFilter = [];
  // القيم: "ليهم تاريخ" ، "ملهمش تاريخ"
  void toggleSendingDateFilter(String v) {
    sendingDateFilter.contains(v)
        ? sendingDateFilter.remove(v)
        : sendingDateFilter.add(v);
    notifyListeners();
  }

  bool _matchSendingDateFilter(Map<String, dynamic> row) {
    if (sendingDateFilterValue == null) return true;

    final date = row['sending_date'];
    final hasDate = date != null && date.toString().isNotEmpty;

    if (sendingDateFilterValue == "ليهم تاريخ") return hasDate;
    if (sendingDateFilterValue == "ملهمش تاريخ") return !hasDate;

    return true;
  }

  bool isPostponed = false;

  void togglePostponed() {
    isPostponed = !isPostponed;
    if (isPostponed) sendingDate = null; // مسح التاريخ لو مؤجل
    notifyListeners();
  }

  /// تنسيق التاريخ إلى "YYYY/MM/DD"
  String format(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}";

  /// استخراج القوائم الفريدة بعد جلب البيانات
  void _populateFilterOptions() {
    final areasSet = <String>{};
    final fatherAreasSet = <String>{};

    for (var row in allSending) {
      final area = row['sending_area']?.toString().trim();
      if (area != null && area.isNotEmpty) {
        areasSet.add(area);
      }
      final fatherArea = row['sending_father_area']?.toString().trim();
      if (fatherArea != null && fatherArea.isNotEmpty) {
        fatherAreasSet.add(fatherArea);
      }
    }

    filterAreasOptions = areasSet.toList()..sort();
    filterFatherAreasOptions = fatherAreasSet.toList()..sort();

    // التأكد من صلاحية القيم المختارة حالياً بعد التحديث
    selectedFilterAreas = selectedFilterAreas
        .where((v) => filterAreasOptions.contains(v))
        .toList();
    selectedFilterFatherAreas = selectedFilterFatherAreas
        .where((v) => filterFatherAreasOptions.contains(v))
        .toList();
  }

  String? selectedK; // الكتيبة
  String? selectedS; // السرية
  String? selectedF; // الفصيلة
  // 1. الدالة المساعدة لفلترة البيانات الأساسية بناءً على (التاريخ، الوحدة، التبعية)
  Iterable<Map<String, dynamic>> _applyBaseFilters() {
    return allSending.where((row) {
      // 1. فلتر التاريخ الأساسي
      if (!_matchSendingDateFilter(row)) return false;

      // 2. ربط القوائم بالكتائب المختارة 🔥
      if (selectedKs.isNotEmpty && !selectedKs.contains(row['soldiers_k'])) {
        return false;
      }

      // 3. ربط القوائم بالسرايا المختارة 🔥
      if (selectedSs.isNotEmpty && !selectedSs.contains(row['soldiers_s'])) {
        return false;
      }

      // 4. ربط القوائم بالفصائل المختارة 🔥
      if (selectedFs.isNotEmpty && !selectedFs.contains(row['soldiers_f'])) {
        return false;
      }

      return true;
    });
  }

  // 2. الكتيبات المتاحة بناءً على الفلاتر الأساسية
  // 1. الكتيبات المتاحة بناءً على فلتر التاريخ فقط
  // 1. الكتيبات المتاحة: تظهر بناءً على (التاريخ + الوحدات + التبعيات) المختارين في تسديد التاريخ
  List<String> get kOptions {
    return _applyBaseFilters()
        .map((e) => e['soldiers_k']?.toString())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // 2. السرايا المتاحة: تظهر بناءً على ما سبق + الكتيبات المختارة (selectedKs)
  List<String> get sOptions {
    final filteredByK = _applyBaseFilters().where((e) {
      return selectedKs.isEmpty || selectedKs.contains(e['soldiers_k']);
    });

    return filteredByK
        .map((e) => e['soldiers_s']?.toString())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // 3. الفصائل المتاحة: تظهر بناءً على ما سبق + الكتيبات والسرايا المختارة
  List<String> get fOptions {
    final filteredByKS = _applyBaseFilters().where((e) {
      bool matchK = selectedKs.isEmpty || selectedKs.contains(e['soldiers_k']);
      bool matchS = selectedSs.isEmpty || selectedSs.contains(e['soldiers_s']);
      return matchK && matchS;
    });

    return filteredByKS
        .map((e) => e['soldiers_f']?.toString())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void setK(String? v) {
    selectedK = v;
    selectedS = null;
    selectedF = null;
    notifyListeners();
  }

  void setS(String? v) {
    selectedS = v;
    selectedF = null;
    notifyListeners();
  }

  void setF(String? v) {
    selectedF = v;
    notifyListeners();
  }

  // ------------------------------------
  // مُحدثات حقول الإضافة
  // ------------------------------------
  void selectSoldier(Map<String, dynamic> soldier) {
    selectedSoldier = soldier;
    notifyListeners();
  }

  void setSendingArea(String? v) {
    sendingArea = v;
    notifyListeners();
  }

  void setSendingFatherArea(String? v) {
    sendingFatherArea = v;
    notifyListeners();
  }

  // ------------------------------------
  // مُحدثات الإجراءات الجماعية (Bulk Operations)
  // ------------------------------------

  void setBulkMode(String mode) {
    bulkMode = mode;
    excludedNames.clear();
    excludedSendingIds.clear();
    rebuildExcludedOptions();
  }

  // ---------- تسديد التاريخ - مُحدثات الاختيار ----------
  void toggleBulkDateUnit(String unit) {
    bulkDateUnits.contains(unit)
        ? bulkDateUnits.remove(unit)
        : bulkDateUnits.add(unit);

    rebuildExcludedOptions();
  }

  void toggleBulkDateFatherArea(String area) {
    bulkDateFatherAreas.contains(area)
        ? bulkDateFatherAreas.remove(area)
        : bulkDateFatherAreas.add(area);

    rebuildExcludedOptions();
  }

  // ---------- تسديد التبعية - مُحدثات الاختيار (تستخدم bulkFatherAreaUnits) ----------
  void toggleBulkFatherAreaUnit(String unit) {
    bulkFatherAreaUnits.contains(unit)
        ? bulkFatherAreaUnits.remove(unit)
        : bulkFatherAreaUnits.add(unit);
    notifyListeners();
  }

  void setBulkSelectedFatherArea(String? val) {
    bulkSelectedFatherArea = val;
    notifyListeners();
  }

  void setPostponed(bool value) {
    isPostponed = value;
    notifyListeners(); // عشان تحدث الواجهة تلقائيًا
  }

  // 💡 تم إزالة toggleBulkUnit و setBulkFatherArea القديمتين
  // 💡 تم إزالة toggleArea, toggleFatherArea, toggleBulkFatherArea القديمة
  void setSendingDate(DateTime? date) {
    sendingDate = date;
    if (date != null) isPostponed = false; // لو اخترت تاريخ، يبطل المؤجل
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // تبديل حالة المؤجل
  // ------------------------------------------------------------------

  // ------------------------------------
  // مُحدثات فلاتر الـ Multi-Select (للعرض)
  // ------------------------------------
  void toggleFilterArea(String area) {
    if (selectedFilterAreas.contains(area)) {
      selectedFilterAreas.remove(area);
    } else {
      selectedFilterAreas.add(area);
    }
    notifyListeners();
  }

  void toggleFilterFatherArea(String area) {
    if (selectedFilterFatherAreas.contains(area)) {
      selectedFilterFatherAreas.remove(area);
    } else {
      selectedFilterFatherAreas.add(area);
    }
    notifyListeners();
  }

  void clearSelectedFilterAreas() {
    selectedFilterAreas.clear();
    notifyListeners();
  }

  void clearSelectedFilterFatherAreas() {
    selectedFilterFatherAreas.clear();
    notifyListeners();
  }

  // ------------------------------------
  // دوال الـ Bulk المساعدة
  // ------------------------------------

  void resetBulkFields() {
    // تسديد التاريخ
    bulkDateUnits.clear();
    bulkDateFatherAreas.clear();
    bulkDateController.clear();

    // تسديد التبعية
    bulkFatherAreaUnits.clear();
    bulkSelectedFatherArea = null;

    excludedSendingIds.clear();
    bulkMode = "التبعيات";
    notifyListeners();
  }

  void resetBulk() {
    // هذه الدالة تم تحديثها لتعكس الحقول الجديدة
    resetBulkFields();
  }

  /// دالة فتح DatePicker وكتابة القيمة في controller
  Future<void> pickBulkDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      bulkDateController.text = format(d);
      notifyListeners();
    }
  }

  /// toggle لاستبعاد الأشخاص
  void toggleExcluded(String name) {
    excludedNames.contains(name)
        ? excludedNames.remove(name)
        : excludedNames.add(name);

    excludedSendingIds = excludedNames
        .map((n) => nameToSendingId[n])
        .whereType<int>()
        .toList();

    notifyListeners();
  }

  Map<String, int> nameToSendingId = {};

  /// أسماء الأفراد المتأثرين عند اختيار وحدات (لتسديد التاريخ)
  List<String> filteredNamesByUnits() {
    nameToSendingId.clear();

    if (bulkDateUnits.isEmpty) return [];

    final names = <String>{};

    for (final row in allSending) {
      if (!_matchSendingDateFilter(row)) continue;
      if (!_matchKSFFilter(row)) continue;

      final area = row['sending_area']?.toString();
      final name = row['soldiers_name']?.toString();
      final sendingId = row['sending_id'];

      if (bulkDateUnits.contains(area) && name != null && sendingId != null) {
        names.add(name);
        nameToSendingId[name] = sendingId as int;
      }
    }

    return names.toList()..sort();
  }

  String? sendingDateFilterValue;
  void setSendingDateFilter(String? v) {
    sendingDateFilterValue = v;
    rebuildExcludedOptions(); // 🔥
  }

  /// أسماء الأفراد المتأثرين عند اختيار تبعيات (لتسديد التاريخ)
  List<String> filteredNamesByFathers() {
    nameToSendingId.clear();

    if (bulkDateFatherAreas.isEmpty) return [];

    final names = <String>{};

    for (final row in allSending) {
      if (!_matchSendingDateFilter(row)) continue;
      if (!_matchKSFFilter(row)) continue;

      final father = row['sending_father_area']?.toString();
      final name = row['soldiers_name']?.toString();
      final sendingId = row['sending_id'];

      if (bulkDateFatherAreas.contains(father) &&
          name != null &&
          sendingId != null) {
        names.add(name);
        nameToSendingId[name] = sendingId as int;
      }
    }

    return names.toList()..sort();
  }

  /// قم بتفريغ الcontroller عند التخلص من الـ VM
  void disposeBulkControllers() {
    bulkDateController.dispose();
  }

  // ============================================
  // 5. الدوال الرئيسية (Load, Filter, CRUD)
  // ============================================

  // ... (دالة load) ...
  Future<void> load() async {
    // 1. يفضل تحميل القوائم دائماً في البداية لتكون جاهزة للـ UI
    await loadUite();

    if (repo.currentBatchId == null) {
      allSoldiers = [];
      allSending = [];
      filtered = [];
      filterAreasOptions = [];
      filterFatherAreasOptions = [];
      selectedFilterAreas = [];
      selectedFilterFatherAreas = [];
      notifyListeners();
      return;
    }

    allSoldiers = await repo.getAllSoldiers();
    allSending = await _tarhilRepo.newgetSoldiersWithSending(
      repo.currentBatchId!,
    );
    filtered = List.from(allSending);

    // تم نقل loadUite للأعلى

    _populateFilterOptions();
    applyFilters();

    notifyListeners();
  }

  // الحالة المختارة للفلتر: "الكل", "تم الترحيل", "لم يرحل", "مؤجل ترحيل"

  // ... (دوال applyFilters, search, resetFilters) ...
  /// تطبيق الفلاتر على allSending وتخزين النتيجة في filtered
  // 1. القائمة الثابتة للخيارات
  final List<String> statusFilterOptions = [
    "تم الترحيل",
    "لم يرحل",
    "مؤجل ترحيل",
  ];

  // 2. المتغير الذي يخزن القيم المختارة
  List<String> selectedStatusFilters = [];

  // 3. دالة التبديل (Toggle)
  void toggleStatusFilter(String value) {
    if (selectedStatusFilters.contains(value)) {
      selectedStatusFilters.remove(value);
    } else {
      selectedStatusFilters.add(value);
    }
    applyFilters(); // تحديث الجدول فوراً
  }

  // 4. تحديث دالة applyFilters لتشمل المنطق الجديد
  void applyFilters() {
    filtered = allSending.where((row) {
      bool ok = true;

      // 1. الفلترة بالاسم أو الرقم العسكري (البحث الذكي 🔥)
      if (filterName.isNotEmpty) {
        // تطبيع نص البحث المدخل
        final searchNorm = normalizeArabic(filterName);

        // تطبيع الاسم من البيانات
        final nameNorm = normalizeArabic(
          row['soldiers_name']?.toString() ?? "",
        );
        final number = row['soldiers_number']?.toString() ?? "";

        // المقارنة بالاسم الموحد أو الرقم العسكري المباشر
        ok &=
            (nameNorm.contains(searchNorm) ||
            number.contains(filterName.trim()));
      }

      // 2. الفلترة بالتاريخ
      if (filterDate != null) {
        ok &= (row['sending_date']?.toString() == format(filterDate!));
      }

      // 3. فلترة الوحدات (Multi-Select)
      if (selectedFilterAreas.isNotEmpty) {
        final area = row['sending_area']?.toString().trim();
        ok &= area != null && selectedFilterAreas.contains(area);
      }

      // 4. فلترة التبعية (Multi-Select)
      if (selectedFilterFatherAreas.isNotEmpty) {
        final father = row['sending_father_area']?.toString().trim();
        ok &= father != null && selectedFilterFatherAreas.contains(father);
      }

      // 5. فلتر حالة الترحيل
      if (selectedStatusFilters.isNotEmpty) {
        final dateValue = row['sending_date']?.toString() ?? "";
        bool matchStatus = false;

        if (selectedStatusFilters.contains("تم الترحيل") &&
            dateValue.isNotEmpty &&
            dateValue != "مؤجل ترحيل") {
          matchStatus = true;
        }

        if (selectedStatusFilters.contains("لم يرحل") && dateValue.isEmpty) {
          matchStatus = true;
        }

        if (selectedStatusFilters.contains("مؤجل ترحيل") &&
            dateValue == "مؤجل ترحيل") {
          matchStatus = true;
        }

        ok &= matchStatus;
      }

      return ok;
    }).toList();
    tableKey = UniqueKey();

    notifyListeners();
  }

  Key tableKey = UniqueKey();

  void search(String query) {
    filterName = query.trim();
    applyFilters();
  }

  void resetFilters() {
    filterName = "";
    filterDate = null;

    selectedFilterAreas.clear();
    selectedFilterFatherAreas.clear();

    applyFilters();
  }

  void SetbulkDateController() {
    bulkDateController.clear();
    notifyListeners();
  }
  // ------------------------------------
  // دوال تنفيذ الـ Bulk
  // ------------------------------------

  /// تنفيذ تحديث التاريخ المجمع
  Future<bool> applyBulkDate() async {
    if (bulkDateController.text.isEmpty) return false;

    final ids = _getFilteredSendingIds();
    if (ids.isEmpty) return false;

    await _tarhilRepo.updateSendingByIds(
      ids: ids,
      data: {"sending_date": bulkDateController.text},
    );

    await load();
    resetBulkFields();
    return true;
  }

  List<int> _getFilteredSendingIds() {
    final ids = <int>[];

    for (final row in allSending) {
      // فلتر التاريخ
      if (!_matchSendingDateFilter(row)) continue;

      // فلتر الكتيبة / السرية / الفصيلة
      if (!_matchKSFFilter(row)) continue;

      final sendingId = row['sending_id'];
      if (sendingId == null) continue;

      if (bulkMode == "الوحدات") {
        final area = row['sending_area'];
        if (bulkDateUnits.contains(area)) {
          ids.add(sendingId as int);
        }
      } else if (bulkMode == "التبعيات") {
        final father = row['sending_father_area'];
        if (bulkDateFatherAreas.contains(father)) {
          ids.add(sendingId as int);
        }
      }
    }

    // استبعاد الأفراد
    ids.removeWhere((id) => excludedSendingIds.contains(id));

    return ids;
  }

  /// تحديث التبعية (Father Area) بشكل جماعي للوحدات المختارة
  Future<bool> applyFatherAreaToUnits() async {
    // استخدام المتغير الجديد bulkFatherAreaUnits
    if (bulkFatherAreaUnits.isEmpty ||
        bulkSelectedFatherArea == null ||
        repo.currentBatchId == null) {
      return false;
    }

    await _tarhilRepo.updateFatherAreaForUnits(
      units: bulkFatherAreaUnits,
      fatherArea: bulkSelectedFatherArea!,
      batchId: repo.currentBatchId!,
    );

    await load();
    applyFilters();

    return true;
  }

  String sendingNote = '';

  void setSendingNote(String n) {
    sendingNote = n;
    notifyListeners();
  }
  // ------------------------------------
  // دوال CRUD
  // ------------------------------------

  /// حفظ سجل ترحيل جديد (INSERT)
  Future<bool> saveSending(BuildContext context) async {
    // التحقق من الحقول المطلوبة
    if (repo.currentBatchId == null ||
        selectedSoldier == null ||
        sendingArea == null ||
        sendingFatherArea == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('جميع الحقول مطلوبة!')));
      return false;
    }

    final soldierNumber = selectedSoldier!['soldiers_number'];
    final rawBatchId =
        selectedSoldier!['soldiers_batch_id'] ?? repo.currentBatchId;

    String batchId = (rawBatchId is num)
        ? rawBatchId.toInt().toString()
        : rawBatchId.toString().trim();

    // إعداد البيانات مع دعم المؤجل
    final data = {
      'sending_soldiers_number': soldierNumber,
      'sending_batch_id': batchId,
      'sending_date': isPostponed
          ? 'مؤجل ترحيل'
          : sendingDate != null
          ? format(sendingDate!)
          : null,
      'sending_area': sendingArea!,
      'sending_father_area': sendingFatherArea!,
      'sending_note': sendingNote,
    };

    try {
      // تحقق لو السجل موجود مسبقًا حسب الرقم العسكري والدفعة
      final existing = await _tarhilRepo.getExistingSending(
        soldierNumber,
        int.parse(batchId),
      );

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ هذا الجندي موجود أو تم ترحيله بالفعل!'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // إدراج جديد باستخدام المتغير data
      await _tarhilRepo.insertSending(data);
      await load();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الترحيل بنجاح ✅'),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ أثناء الحفظ: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// تعديل سجل ترحيل موجود (UPDATE)
  Future<void> updateSending(String id, Map<String, dynamic> data) async {
    await _tarhilRepo.updateSending(id, data);
    await load();
  }

  /// حذف سجل ترحيل (DELETE)
  Future<void> deleteSending(int id) async {
    await _tarhilRepo.deleteSending(id);
    await load();
  }

  // ------------------------------------
  // دوال الإكسل (Import Excel)
  // ------------------------------------

  /// دالة تنظيف النص من علامات الإكسل
  String _cleanString(String? s) {
    if (s == null) return '';
    return s
        .replaceAll(RegExp(r'(_x[0-9A-Fa-f]{4}_)|\p{C}', unicode: true), '')
        .trim();
  }

  /// استيراد بيانات الترحيل من ملف إكسل

  Future<void> importTarhilExcel(BuildContext context) async {
    if (repo.currentBatchId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("حدد دفعة أولًا")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (res == null || res.files.single.path == null) {
        if (context.mounted) Navigator.pop(context);
        return;
      }

      final bytes = await File(res.files.single.path!).readAsBytes();

      final List<List<dynamic>> allRows = await compute(
        _decodeExcelInBg,
        bytes,
      );

      if (allRows.isEmpty || allRows.length < 2) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("الملف فارغ أو غير مدعوم")),
          );
        }
        return;
      }

      final List<Map<String, dynamic>> updatedAllSending = await _tarhilRepo
          .newgetSoldiersWithSending(repo.currentBatchId!);

      // تجهيز الخرائط
      final soldiersByNumMap = {
        for (var s in allSoldiers)
          _cleanString(s['soldiers_number']?.toString()): s,
      };

      final sendingMap = {
        for (var e in updatedAllSending)
          if (e['sending_id'] != null)
            _cleanString(e['sending_soldiers_number']?.toString()): e,
      };

      List<Map<String, String>> failed = [];

      final headers = allRows.first
          .map((v) => _cleanString(v?.toString()))
          .toList();
      final iNumber = headers.indexOf(_cleanString("الرقم العسكرى"));
      final iArea = headers.indexOf(_cleanString("الوحدة"));
      final iFather = headers.indexOf(_cleanString("التبعية"));

      // البدء من الصف الثاني
      for (int i = 1; i < allRows.length; i++) {
        try {
          final row = allRows[i];
          if (row.isEmpty) continue;

          String soldierNumber = (iNumber != -1 && iNumber < row.length)
              ? _cleanString(row[iNumber]?.toString())
              : "";
          if (soldierNumber.isEmpty) continue;

          final soldier = soldiersByNumMap[soldierNumber];
          if (soldier == null) {
            failed.add({"row": "${i + 1}", "reason": "الجندي غير موجود"});
            continue;
          }

          final rawBatchId =
              soldier['soldiers_batch_id'] ?? repo.currentBatchId!;
          final batchId = _cleanString(rawBatchId.toString());

          final areaValue = (iArea != -1 && iArea < row.length)
              ? _cleanString(row[iArea]?.toString())
              : "";
          if (areaValue.isEmpty) {
            failed.add({"row": "${i + 1}", "reason": "حقل الوحدة فارغ"});
            continue;
          }

          final data = {
            "sending_soldiers_number": soldierNumber,
            "sending_batch_id": batchId,
            "sending_area": areaValue,
            "sending_father_area": (iFather != -1 && iFather < row.length)
                ? _cleanString(row[iFather]?.toString())
                : "",
          };

          final existing = sendingMap[soldierNumber];

          if (existing == null) {
            await _tarhilRepo.insertSending(data);
          } else {
            await _tarhilRepo.updateSending(existing["sending_id"].toString(), {
              "sending_area": data["sending_area"],
              "sending_father_area": data["sending_father_area"],
            });
          }
        } catch (e) {
          failed.add({"row": "${i + 1}", "reason": "خطأ: $e"});
        }
      }

      await load();

      if (context.mounted) {
        Navigator.pop(context);
        if (failed.isNotEmpty) {
          _showResultDialog(context, failed);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("تم الاستيراد بنجاح")));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("حدث كراش غير متوقع: $e")));
      }
    }
  }

  void _showResultDialog(
    BuildContext context,
    List<Map<String, String>> failed,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "تقرير الاستيراد",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "تم الاستيراد بنجاح، ولكن تعذر معالجة الصفوف التالية:",
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: failed.length,
                  itemBuilder: (context, index) => Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 12,
                        child: Text(
                          failed[index]['row'] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      title: Text(
                        failed[index]['reason'] ?? "خطأ غير معروف",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }
}

// أضف هذه الدالة في نهاية ملف الـ ViewModel (خارج الكلاس)
List<List<dynamic>> _decodeExcelInBg(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return [];

  // نأخذ أول شيت فقط ونحول صفوفه لبيانات بسيطة
  final sheet = excel.tables[excel.tables.keys.first]!;
  return sheet.rows
      .map((row) => row.map((cell) => cell?.value).toList())
      .toList();
}

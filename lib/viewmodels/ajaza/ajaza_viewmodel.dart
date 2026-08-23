import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/city.dart';
import 'package:flutter_application_1/services/database/ajaza_repo.dart';
import 'package:flutter_application_1/view/ajaza/edit_ajaza_view.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AjazaViewModel extends ChangeNotifier {
  final AjazaRepository repo;

  AjazaViewModel(this.repo) {
    loadAllSoldiers();
  }

  // ==============================
  // Data
  // ==============================

  List<Map<String, dynamic>> allSoldiers = [];
  List<Map<String, dynamic>> soldiersWithLeaves = [];
  List<Map<String, dynamic>> filtered = [];

  Map<String, dynamic>? selectedSoldier;

  // ==============================
  // Table (مطلوب للتصدير)
  // ==============================

  final List<DataColumn> ajazaColumn = const [
    DataColumn(label: Text('الاسم')),
    DataColumn(label: Text('رقم عسكري')),
    DataColumn(label: Text('الكتيبة')),
    DataColumn(label: Text('السرية')),
    DataColumn(label: Text('الفصيل')),
    DataColumn(label: Text('المحافظة')),
    DataColumn(label: Text('تاريخ البدء')),
    DataColumn(label: Text('تاريخ الانتهاء')),
    DataColumn(label: Text('السبب')),
  ];

  final List<String> soldierKeys = [
    'soldiers_name',
    'soldiers_number',
    'soldiers_k',
    'soldiers_s',
    'soldiers_f',
    'soldiers_city',
    'leave_start',
    'leave_end',
    'leave_reason',
  ];

  // ==============================
  // Filters
  // ==============================

  String filterName = "";
  DateTime? filterStart;
  DateTime? filterEnd;
  String? batchId;

  String filterK = "الكل";
  String filterReason = "الكل";

  List<String> selectedKaltibas = [];
  List<String> selectedReasons = [];

  Key tableKey = UniqueKey();

  // ==============================
  // Leave Form
  // ==============================

  DateTime? leaveStart;
  DateTime? leaveEnd;
  String? leaveReason;

  final List<String> ajazaTypes = [
    "مرضى",
    "نفسى",
    "رفد طبى",
    "حالة وفاة",
    "اخرى",
    "مستجدين",
    "سجن",
    "غياب",
    "حجز",
  ];

  // ==============================
  // Batch
  // ==============================

  void updateBatch(String? value) {
    batchId = value;
    loadAllSoldiers();
  }

  // ==============================
  // Load Data
  // ==============================

  Future<void> loadAllSoldiers() async {
    allSoldiers = await repo.getAllSoldiers(batchId: batchId);
    notifyListeners();
    await loadSoldiersWithLeaves();
  }

  Future<void> loadSoldiersWithLeaves() async {
    soldiersWithLeaves = await repo.getSoldiersWithLeaves(batchId: batchId);

    // ملء قائمة المستجدين فقط للاستخدام في التصدير المجمع
    allRecruitmentLeaves = soldiersWithLeaves
        .where((e) => e['leave_reason']?.toString().trim() == 'مستجدين')
        .toList();

    applyFiltersForLeaves(); // الفلترة العادية للجدول اللي قدامك
  }

  // ==============================
  // Toggle Filters
  // ==============================

  void toggleKaltiba(String val) {
    if (selectedKaltibas.contains(val)) {
      selectedKaltibas.remove(val);
    } else {
      selectedKaltibas.add(val);
    }
    applyFiltersForLeaves();
  }

  void toggleReason(String val) {
    if (selectedReasons.contains(val)) {
      selectedReasons.remove(val);
    } else {
      selectedReasons.add(val);
    }
    applyFiltersForLeaves();
  }

  // ==============================
  // Apply Filters
  // ==============================
  // للحفاظ على التوافق مع الـ View القديم
  void setAjazafType(String? type) {
    setLeaveType(type);
  }

  List<Map<String, dynamic>> allRecruitmentLeaves = [];
  void applyFiltersForLeaves() {
    List<Map<String, dynamic>> temp = List.from(soldiersWithLeaves);

    if (filterName.isNotEmpty) {
      final q = normalizeArabic(filterName.trim());
      temp = temp.where((s) {
        final name = normalizeArabic((s["soldiers_name"] ?? "").toString());
        final number = (s["soldiers_number"] ?? "").toString();
        final k = normalizeArabic((s["soldiers_k"] ?? "").toString());
        return name.contains(q) || number.contains(q) || k.contains(q);
      }).toList();
    }

    if (selectedKaltibas.isNotEmpty) {
      temp = temp
          .where((s) => selectedKaltibas.contains(s["soldiers_k"].toString()))
          .toList();
    }

    if (selectedReasons.isNotEmpty) {
      temp = temp
          .where((s) => selectedReasons.contains(s["leave_reason"].toString()))
          .toList();
    }

    if (filterStart != null || filterEnd != null) {
      temp = temp.where((s) {
        final start = s["leave_start"]?.toString();
        final end = s["leave_end"]?.toString();

        if (filterStart != null && filterEnd != null) {
          if (end == null || end == "غياب" || end == "حجز") return false;
          final endDate = DateTime.parse(end.replaceAll('/', '-'));
          return !endDate.isBefore(filterStart!) &&
              !endDate.isAfter(filterEnd!);
        }

        if (filterStart != null) {
          return start == DateFormat("yyyy/MM/dd").format(filterStart!);
        }

        if (filterEnd != null) {
          return end == DateFormat("yyyy/MM/dd").format(filterEnd!);
        }

        return true;
      }).toList();
    }

    filtered = temp;
    tableKey = UniqueKey();
    notifyListeners();
  }

  void resetFilters() {
    filterName = "";
    filterStart = null;
    filterEnd = null;
    selectedKaltibas.clear();
    selectedReasons.clear();
    filterK = "الكل";
    filterReason = "الكل";
    applyFiltersForLeaves();
  }

  // ==============================
  // Form Controls
  // ==============================

  void setLeaveStart(DateTime date) {
    leaveStart = date;
    notifyListeners();
  }

  void setLeaveEnd(DateTime date) {
    leaveEnd = date;
    notifyListeners();
  }

  void setLeaveType(String? type) {
    leaveReason = type;
    if (type == "غياب" || type == "حجز") {
      leaveEnd = null;
    }
    notifyListeners();
  }

  void selectSoldier(Map<String, dynamic> soldier) {
    selectedSoldier = soldier;
    notifyListeners();
  }

  // ==============================
  // Save
  // ==============================

  Future<bool> saveLeave(BuildContext context) async {
    bool isGhayab = leaveReason == "غياب" || leaveReason == "حجز";

    if (selectedSoldier == null ||
        leaveStart == null ||
        leaveReason == null ||
        (!isGhayab && leaveEnd == null)) {
      _showSnack(context, "يرجى إكمال جميع الحقول المطلوبة!");
      return false;
    }

    final soldierNumber = selectedSoldier!["soldiers_number"];
    final bId = batchId ?? selectedSoldier!["soldiers_batch_id"];

    if (!isGhayab) {
      final overlap = await repo.checkOverlap(
        soldierNumber: soldierNumber.toString(),
        batchId: bId.toString(),
        newStart: leaveStart!,
        newEnd: leaveEnd!,
      );

      if (overlap) {
        _showSnack(context, "⚠️ هناك تداخل مع إجازة موجودة بالفعل!");
        return false;
      }
    }

    final endValue = isGhayab
        ? "$leaveReason"
        : DateFormat("yyyy/MM/dd").format(leaveEnd!);

    await repo.insertLeave(
      soldierNumber: soldierNumber.toString(),
      batchId: bId.toString(),
      start: leaveStart!,
      end: endValue,
      reason: leaveReason!,
    );

    await loadSoldiersWithLeaves();
    _showSnack(context, "تم حفظ البيانات بنجاح ✅");
    return true;
  }

  // ==============================
  // Update
  // ==============================

  Future<bool> updateLeave({
    required BuildContext context,
    required int id,
    required String newReason,
    required DateTime newStart,
    required dynamic newEnd,
  }) async {
    final target = soldiersWithLeaves.firstWhere(
      (e) => e["soldiers_leaves_id"] == id,
      orElse: () => {},
    );

    if (target.isEmpty) return false;

    final soldierNumber = target["soldiers_number"];
    final bId = batchId ?? target["soldiers_batch_id"];
    bool isGhayab = newReason == "غياب" || newReason == "حجز";

    if (!isGhayab && newEnd is DateTime) {
      final overlap = await repo.checkOverlap(
        soldierNumber: soldierNumber.toString(),
        batchId: bId.toString(),
        newStart: newStart,
        newEnd: newEnd,
        excludeId: id,
      );

      if (overlap) {
        _showSnack(context, "⚠️ هناك تداخل مع إجازة موجودة بالفعل!");
        return false;
      }
    }

    final endValue = isGhayab
        ? newReason
        : (newEnd is DateTime
              ? DateFormat("yyyy/MM/dd").format(newEnd)
              : newEnd.toString());

    await repo.updateLeave(
      id: id,
      start: newStart,
      end: endValue,
      reason: newReason,
    );

    await loadSoldiersWithLeaves();
    _showSnack(context, "تم التعديل بنجاح ✅");
    return true;
  }

  // ==============================
  // Delete
  // ==============================

  Future<void> deleteLeave(BuildContext context, int id) async {
    await repo.deleteLeave(id);
    await loadSoldiersWithLeaves();
    _showSnack(context, "تم حذف الإجازة بنجاح ✅");
  }

  // ==============================
  // Helpers
  // ==============================

  String fmt(String? date) {
    if (date == null || date.isEmpty) return "—";
    try {
      return DateFormat(
        "yyyy/MM/dd",
      ).format(DateTime.parse(date.replaceAll('/', '-')));
    } catch (_) {
      return date;
    }
  }

  void _showSnack(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  } // أضف هذه المتغيرات والدوال داخل AjazaViewModel

  // خريطة الأقاليم

  Future<String?> saveBulkLeaves({
    required Map<String, DateTimeRange> regionDates,
    required Map<String, int> giftDaysInput,
    required BuildContext context,
  }) async {
    if (batchId == null) return "لم يتم اختيار دفعة";

    try {
      // 1. جلب البيانات الأساسية
      final allSoldiersInBatch = await repo.getAllSoldiers(batchId: batchId);
      if (allSoldiersInBatch.isEmpty) {
        return "لا يوجد جنود مسجلين في هذه الدفعة";
      }

      final extraDaysMap = await repo.getSoldiersGiftsDays(
        batchId!,
        giftDaysInput,
      );
      final excludedList = await repo.getExcludedSoldiers(batchId!);

      final lastLeavesData = await repo.db.readData(
        "SELECT leaves_soldiers_number, MAX(leave_end) as last_end FROM soldiers_leaves WHERE leaves_batch_id = '$batchId' GROUP BY leaves_soldiers_number",
      );

      Map<String, String> lastLeavesMap = {
        for (var item in lastLeavesData)
          item['leaves_soldiers_number'].toString(): item['last_end']
              .toString(),
      };

      List<String> sqlStatements = [];
      int skippedCount = 0;

      // 2. معالجة البيانات في الذاكرة
      for (var soldier in allSoldiersInBatch) {
        String sNumber = soldier['soldiers_number'].toString();

        // شرط الاستبعاد الأول: (ترحيل أو موقف)
        if (excludedList.contains(sNumber)) {
          skippedCount++;
          continue;
        }

        String city = soldier['soldiers_city']?.toString() ?? "";
        String region = 'upper';
        if (regionsMap['cairo']!.contains(city)) {
          region = 'cairo';
        } else if (regionsMap['lower']!.contains(city))
          region = 'lower';

        DateTime startDate = regionDates[region]!.start;
        DateTime endDate = regionDates[region]!.end;
        int extra = extraDaysMap[sNumber] ?? 0;
        endDate = endDate.add(Duration(days: extra));

        // شرط الاستبعاد الثاني: (تداخل أو التحام تواريخ)
        if (lastLeavesMap.containsKey(sNumber)) {
          String lastEnd = lastLeavesMap[sNumber]!;
          if (lastEnd == "غياب" || lastEnd == "حجز") {
            skippedCount++;
            continue;
          }
          try {
            // تحويل تاريخ آخر إجازة لمقارنته
            DateTime lastEndDate = DateTime.parse(lastEnd.replaceAll('/', '-'));

            // التعديل الجوهري هنا:
            // إذا كان تاريخ نهاية الإجازة السابقة ليس قبل تاريخ البداية الجديد
            // (بمعنى لو بيساوي أو أكبر منه) يستبعد
            if (!lastEndDate.isBefore(startDate)) {
              skippedCount++;
              continue;
            }
          } catch (_) {}
        }

        // تجهيز جملة الـ SQL
        String startStr = DateFormat("yyyy/MM/dd").format(startDate);
        String endStr = DateFormat("yyyy/MM/dd").format(endDate);

        sqlStatements.add("""
        INSERT INTO soldiers_leaves (leaves_soldiers_number, leaves_batch_id, leave_start, leave_end, leave_reason)
        VALUES ('$sNumber', '${batchId!}', '$startStr', '$endStr', 'مستجدين')
      """);
      }

      // 3. التنفيذ الجماعي
      if (sqlStatements.isNotEmpty) {
        await repo.db.batchInsert(sqlStatements);
      }

      await loadSoldiersWithLeaves();
      return "SUCCESS: تم حفظ ${sqlStatements.length} فرد واستبعاد $skippedCount";
    } catch (e) {
      debugPrint("Bulk Save Error: $e");
      return "خطأ فني: ${e.toString()}";
    }
  }
}

class AjazaDataSource extends DataTableSource {
  final BuildContext context;
  final List<Map<String, dynamic>> data;

  AjazaDataSource(this.context, this.data);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final s = data[index];

    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () {
              final vm = Provider.of<AjazaViewModel>(context, listen: false);
              vm.selectSoldier(s);
              showDialog(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: EditLeaveDialog(existing: s),
                ),
              );
            },
            child: Text(s["soldiers_name"] ?? ""),
          ),
        ),
        DataCell(Text(s["soldiers_number"].toString())),
        DataCell(Text(s["soldiers_k"] ?? "")),
        DataCell(Text(s["soldiers_s"] ?? "")),
        DataCell(Text(s["soldiers_f"] ?? "")),
        DataCell(Text(s["soldiers_city"] ?? "")),
        DataCell(Text(s["leave_start"] ?? "")),
        DataCell(Text(s["leave_end"] ?? "")),
        DataCell(Text(s["leave_reason"] ?? "—")),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}

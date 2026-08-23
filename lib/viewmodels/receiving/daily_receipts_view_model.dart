// ignore_for_file: unnecessary_type_check

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/batch_plan_columns.dart';
import 'package:flutter_application_1/services/database/batch_repository.dart';
import 'package:flutter_application_1/services/database/batches_plan_repository.dart';
import 'package:flutter_application_1/services/database/daily_receipts_repository.dart';
import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:flutter_application_1/services/database/leaders_repository.dart';
import 'package:flutter_application_1/viewmodels/receiving/daily_receipts_pdf.dart';
import 'package:flutter_application_1/viewmodels/receiving/daliy_weapon_pdf.dart';
import 'package:intl/intl.dart';

class DailyReceiptsViewModel extends ChangeNotifier {
  final DailyReceiptsRepository _repo = DailyReceiptsRepository();
  final BatchesRepository _batchesRepo;
  final BatchPlanRepository _planRepo = BatchPlanRepository(SqlDb());
  final LeadersRepository _leadersRepo = LeadersRepository(SqlDb());

  int? batchId;
  int? currentReceiptId;
  DateTime selectedDate = DateTime.now();
  Map<String, TextEditingController> receiptCtrls = {};
  List<Map<String, dynamic>> historyEntries = [];

  int totalStoredInHistory = 0;
  bool isLoading = false;
  Map<String, int> planData = {};

  DailyReceiptsViewModel(this._batchesRepo) {
    _initControllers();
  }

  int _currentEntryTotal = 0;
  int get currentEntryTotal => _currentEntryTotal;
  Map<String, int> weaponTotals = {};
  Map<String, int> levelTotals = {};

  // --- دالة الحصول على المفتاح (الموحدة مع الـ Repository والـ PDF) ---
  // داخل DailyReceiptsViewModel
  String getDbKey(String level, String weapon, String type) {
    String l = "";
    if (level.contains("عليا")) {
      l = "high";
    } else if (level.contains("فوق متوسط"))
      // ignore: curly_braces_in_flow_control_structures
      l = "above_mid";
    else if (level.contains("عادة")) {
      l = "normal";
    } else if (level.contains("مهن") ||
        weapon.contains("مهني") ||
        level.contains("مهنى")) {
      l = "mid_prof";
    } else {
      l = "mid_skill";
    }

    final wMap = {
      "مهندسين": "eng",
      "مهني مهندسين": "eng",
      "مياه": "water",
      "مياة": "water",
      "مهني مياه": "water",
      "مساحة": "survey",
      "أشغال": "works",
      "مهني أشغال": "works",
    };

    final tMap = {"صف": "base", "جوية": "ground", "بحرية": "naval"};
    return "${l}_${wMap[weapon] ?? weapon}_${tMap[type] ?? type}";
  }

  // --- دالة حساب الإجماليات الخاصة بالـ PDF ---
  Map<String, int> _calculateTotals(
    List<String> levels,
    List<String> weapons,
    List<String> types,
  ) {
    Map<String, int> totals = {};
    for (var level in levels) {
      for (var weapon in weapons) {
        for (var type in types) {
          String key = getDbKey(level, weapon, type);
          int sum = 0;
          for (var record in historyEntries) {
            var val = record[key];
            if (val != null) sum += (val as num).toInt();
          }
          totals[key] = sum;
        }
      }
    }
    return totals;
  }

  // --- دالة جلب بيانات القائد ---
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

  // 1. طباعة التقرير العادي
  Future<void> printDailyReport({
    required List<String> levels,
    required List<String> weapons,
    required List<String> types,
  }) async {
    if (batchId == null) return;
    try {
      isLoading = true;
      notifyListeners();

      Map<String, int> grandTotals = _calculateTotals(levels, weapons, types);
      final batchData = await _batchesRepo.getById(batchId!);
      final leaderInfo = await _getLeaderInfo();
      if (batchData != null) {
        await generateAndPrintPdf(
          batchid: batchData['batch_name'].toString(),
          weapons: weapons,
          levels: levels,
          types: types,
          grandTotals: grandTotals,
          planData: planData,
          leader: leaderInfo,
        );
      }
    } catch (e) {
      debugPrint("Normal PDF Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> printWeaponsDailyReport({
    required List<String> levels,
    required List<String> weapons,
    required List<String> types,
    int manualBalance = 0,
  }) async {
    if (batchId == null) return;
    try {
      isLoading = true;
      notifyListeners();

      // 1. جلب بيانات الدفعة الأساسية
      final batchData = await _batchesRepo.getById(batchId!);
      String batchNameStr = batchData!['batch_name'].toString();

      // 2. جلب البيانات من الـ Repository
      Map<String, int> grandTotals = _calculateTotals(levels, weapons, types);
      Map<String, int> movedData = await _repo.getMovedData(batchId!);
      Map<String, int> moqfData = await _repo.getMoqfData(
        batchId!,
      ); // البيانات القديمة للجداول العلوية
      // جلب إحصائيات المواقف التفصيلية (شطب، رفد، وفاة...) للجدول السفلي
      Map<String, int> moqfStats = await _repo.getMoqfStatsByType(batchId!);
      int totalMoqfData = moqfData.values.fold(0, (sum, value) => sum + value);

      int previousRemaining = await _repo.getPreviousBatchesRemaining(
        batchNameStr,
        batchId!,
      );
      int totalPlan = 0;
      planData.forEach((key, value) {
        if (value is num) totalPlan += value.toInt();
      });

      int totalReceived = grandTotals.values.fold(0, (sum, val) => sum + val);
      int totalMoved = movedData.values.fold(0, (sum, val) => sum + val);

      // 4. تجميع بيانات الجدول السفلي (12 عمود)
      Map<String, int> summaryData = {
        'plan': totalPlan,
        'received': totalReceived,
        'moved': totalMoved,
        'net': totalReceived - totalMoved - totalMoqfData,
        ...moqfStats,
      };

      await generateWeaponsDailyReport(
        batchid: batchNameStr,
        weapons: weapons,
        levels: levels,
        types: types,
        grandTotals: grandTotals,
        planData: planData,
        leader: await _getLeaderInfo(),
        movedData: movedData,
        moqfData: moqfData,
        previousRemaining: previousRemaining,
        manualBalance: manualBalance,
        summaryData: summaryData, // الجدول الجديد المنفصل
      );
    } catch (e) {
      debugPrint("PDF Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- ميثود الحساب اللحظي للواجهة ---
  void calculateAll(
    List<String> weapons,
    List<String> levels,
    List<String> types,
  ) {
    _currentEntryTotal = 0;
    weaponTotals.clear();
    levelTotals.clear();

    for (var w in weapons) {
      int sumW = 0;
      for (var l in levels) {
        for (var t in types) {
          String key = getDbKey(l, w, t);
          sumW += int.tryParse(receiptCtrls[key]?.text ?? '0') ?? 0;
        }
      }
      weaponTotals[w] = sumW;
    }

    for (var l in levels) {
      int sumL = 0;
      for (var w in weapons) {
        for (var t in types) {
          String key = getDbKey(l, w, t);
          sumL += int.tryParse(receiptCtrls[key]?.text ?? '0') ?? 0;
        }
      }
      levelTotals[l] = sumL;
      _currentEntryTotal += sumL;
    }
    notifyListeners();
  }

  // --- تحميل بيانات المخطط ---
  Future<void> loadPlanData() async {
    if (batchId == null) return;
    isLoading = true;
    notifyListeners();
    try {
      final result = await _planRepo.getPlan(batchId!);
      if (result != null) {
        planData = result.map(
          (key, value) => MapEntry(key, value is int ? value : 0),
        );
      } else {
        planData = {};
      }
    } catch (e) {
      planData = {};
    }
    isLoading = false;
    notifyListeners();
  }

  // --- تغيير الدفعة ---
  void updateBatch(String? newBatchId) async {
    if (newBatchId == null) return;
    int? parsedId = int.tryParse(newBatchId);
    if (parsedId != null && batchId != parsedId) {
      batchId = parsedId;
      clearForm();
      await loadPlanData();
      await loadHistory();
    }
  }

  // --- حفظ السجل ---
  Future<bool> saveProcess(BuildContext context) async {
    if (batchId == null) return false;
    if (isDateAlreadyExists(selectedDate, currentReceiptId)) {
      _showError(context, "خطأ: يوجد سجل استلام بالفعل لهذا التاريخ!");
      return false;
    }

    final Map<String, int> dataMap = {};
    for (String col in batchPlanColumns) {
      dataMap[col] = int.tryParse(receiptCtrls[col]?.text ?? '0') ?? 0;
    }

    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      if (currentReceiptId == null) {
        await _repo.insertReceipt(batchId!, dateStr, dataMap);
      } else {
        await _repo.updateReceipt(currentReceiptId!, dateStr, dataMap);
      }
      clearForm();
      await loadHistory();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _initControllers() {
    for (String col in batchPlanColumns) {
      receiptCtrls[col] = TextEditingController();
    }
  }

  void updateSelectedDate(DateTime date) async {
    selectedDate = date;
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    var existingRecord = historyEntries
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (e) => e?['receipt_date'] == formattedDate,
          orElse: () => null,
        );

    if (existingRecord != null) {
      currentReceiptId = existingRecord['receipt_id'];
      for (String col in batchPlanColumns) {
        receiptCtrls[col]!.text = existingRecord[col].toString();
      }
    } else {
      currentReceiptId = null;
      for (var ctrl in receiptCtrls.values) {
        ctrl.clear();
      }
    }
    notifyListeners();
  }

  void selectForEdit(Map<String, dynamic> record) {
    currentReceiptId = record['receipt_id'];
    if (record['receipt_date'] != null) {
      selectedDate = DateTime.parse(record['receipt_date']);
    }
    receiptCtrls.forEach((key, controller) {
      controller.text = record.containsKey(key) ? record[key].toString() : "0";
    });
    onAmountChanged();
    notifyListeners();
  }

  bool isDateAlreadyExists(DateTime date, int? excludeId) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return historyEntries.any(
      (entry) =>
          entry['receipt_date'] == formattedDate &&
          entry['receipt_id'] != excludeId,
    );
  }

  Future<void> loadHistory() async {
    if (batchId == null) return;
    isLoading = true;
    notifyListeners();
    historyEntries = await _repo.getBatchReceipts(batchId.toString());
    int tempTotal = 0;
    for (var entry in historyEntries) {
      for (String col in batchPlanColumns) {
        tempTotal += (entry[col] as int? ?? 0);
      }
    }
    totalStoredInHistory = tempTotal;
    isLoading = false;
    notifyListeners();
  }

  void clearForm() {
    currentReceiptId = null;
    selectedDate = DateTime.now();
    for (var ctrl in receiptCtrls.values) {
      ctrl.clear();
    }
    _currentEntryTotal = 0;
    weaponTotals.clear();
    levelTotals.clear();
    notifyListeners();
  }

  void onAmountChanged() => notifyListeners();

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    for (var ctrl in receiptCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> deleteProcess(int receiptId) async {
    try {
      await _repo.deleteReceipt(receiptId);
      if (currentReceiptId == receiptId) clearForm();
      await loadHistory();
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database/presentations_repo.dart';

class PresentationViewModel extends ChangeNotifier {
  final PresentationRepository repo;

  String? batchId;
  bool isLoading = false;

  // بيانات اللجان والنتائج
  Map<String, dynamic>? committeeFirst;
  Map<String, dynamic>? committeeSecond;
  List<Map<String, dynamic>> firstCommitteeResults = [];
  List<Map<String, dynamic>> secondCommitteeResults = [];

  // بيانات البحث والإدخال
  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic>? selectedSoldier;
  String selectedClinic = 'باطنة';
  String selectedResult = 'لائق';

  Key tableKey = UniqueKey();

  // أعمدة الجدول المحدثة لتشمل خانة السجل
  final List<DataColumn> presentationColumns = const [
    DataColumn(label: Text('الاسم')),
    DataColumn(label: Text('رقم عسكري')),
    DataColumn(label: Text('الكتيبة')),
    DataColumn(label: Text('السرية')),
    DataColumn(label: Text('الفصيل')),
    DataColumn(label: Text('السجل')), // تأكد أن الـ Repository يجلب هذا الحقل
    DataColumn(label: Text('العيادة')),
    DataColumn(label: Text('النتيجة')),
  ];

  PresentationViewModel({required this.repo, this.batchId}) {
    if (batchId != null) {
      init(batchId!);
    }
  }

  // ==========================================
  // 1. إدارة الحالة وجلب البيانات الأساسية
  // ==========================================

  Future<void> init(String bId) async {
    isLoading = true;
    batchId = bId;
    notifyListeners();

    try {
      final committees = await repo.getCommitteesByBatch(bId);

      // البحث عن اللجنة بناءً على الترتيب (1 أو 2) حصراً
      committeeFirst = committees.any((e) => e['committee_order'] == 1)
          ? committees.firstWhere((e) => e['committee_order'] == 1)
          : null;

      committeeSecond = committees.any((e) => e['committee_order'] == 2)
          ? committees.firstWhere((e) => e['committee_order'] == 2)
          : null;

      // جلب النتائج لكل لجنة موجودة
      if (committeeFirst != null) {
        firstCommitteeResults = await repo.getResultsByCommittee(
          committeeFirst!['committee_id'],
        );
      } else {
        firstCommitteeResults = [];
      }

      if (committeeSecond != null) {
        secondCommitteeResults = await repo.getResultsByCommittee(
          committeeSecond!['committee_id'],
        );
      } else {
        secondCommitteeResults = [];
      }

      tableKey = UniqueKey();
    } catch (e) {
      debugPrint("Error in init: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateBatch(String? newBatchId) {
    if (newBatchId == null || newBatchId == batchId) return;
    init(newBatchId);
  }

  // ==========================================
  // 2. عمليات البحث واختيار الجندي
  // ==========================================

  Future<void> searchSoldier(String query) async {
    if (batchId == null) return;
    if (query.isEmpty) {
      searchResults = [];
      selectedSoldier = null;
    } else {
      searchResults = await repo.searchSoldierForCommittee(query, batchId!);
    }
    notifyListeners();
  }

  void selectSoldier(Map<String, dynamic> soldier) {
    selectedSoldier = soldier;
    searchResults = [];
    notifyListeners();
  }

  void updateClinic(String val) {
    selectedClinic = val;
    notifyListeners();
  }

  void updateResult(String val) {
    selectedResult = val;
    notifyListeners();
  }

  // ==========================================
  // 3. العمليات الأساسية (CUD)
  // ==========================================

  // حفظ التاريخ: الآن يعتمد على الـ order لضمان عدم التكرار
  Future<void> saveCommitteeDate(int order, String date) async {
    if (batchId == null) return;
    try {
      await repo.upsertCommittee(batchId: batchId!, date: date, order: order);
      await init(batchId!); // تحديث الحالة لقراءة الـ IDs الجديدة
    } catch (e) {
      debugPrint("Error saving committee date: $e");
    }
  }

  Future<void> addSoldierToCommittee(
    int committeeId,
    List<Map<String, dynamic>> currentResults,
  ) async {
    if (selectedSoldier == null || batchId == null) return;

    // منع إضافة الجندي إذا كان موجوداً مسبقاً في هذه اللجنة
    bool isExist = currentResults.any(
      (e) => e['soldiers_number'] == selectedSoldier!['soldiers_number'],
    );
    if (isExist) {
      debugPrint("Soldier already added to this committee");
      // يمكنك هنا إظهار Snackbar للمستخدم
      return;
    }

    try {
      await repo.insertSoldierResult(
        committeeId: committeeId,
        soldierNumber: selectedSoldier!['soldiers_number'],
        clinicType: selectedClinic,
        result: selectedResult,
      );
      selectedSoldier = null;
      await init(batchId!);
    } catch (e) {
      debugPrint("Error adding soldier: $e");
    }
  }

  Future<void> updateSoldierResult({
    required int presId,
    required String newClinic,
    required String newResult,
  }) async {
    try {
      await repo.updatePresentation(
        presId: presId,
        clinicType: newClinic,
        result: newResult,
      );
      if (batchId != null) await init(batchId!);
    } catch (e) {
      debugPrint("Error updating record: $e");
    }
  }

  Future<void> updatetasfeya() async {
    try {
      await repo.tasfeya();
      if (batchId != null) await init(batchId!);
    } catch (e) {
      debugPrint("Error updating record: $e");
    }
  }

  Future<void> deleteResult(int presId) async {
    if (batchId == null) return;
    try {
      await repo.deleteSoldierResult(presId);
      await init(batchId!);
    } catch (e) {
      debugPrint("Error deleting record: $e");
    }
  }

  final List<String> soldierKeys = [
    'soldiers_name',
    'soldiers_number',
    'soldiers_k',
    'soldiers_s',
    'soldiers_f',
    'soldiers_unit_id',
    'clinic_type',
    'pres_result',
  ];
}

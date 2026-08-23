import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database/medical_visits_repository.dart';

class MedicalVisitsViewModel extends ChangeNotifier {
  final MedicalVisitsRepository repo;
  String? _batchId;
  bool loading = false;
  List<Map<String, Object?>> visits = [];
  List<Map<String, Object?>> soldiers = [];

  MedicalVisitsViewModel(this.repo);

  void updateBatch(String? batchId) {
    if (_batchId == batchId) return;
    _batchId = batchId;
    loadData();
  }

  List<Map<String, dynamic>> getFilteredLatestVisits() {
    if (visits.isEmpty) return [];

    // 1. نسخ القائمة الأصلية
    var allVisits = List<Map<String, dynamic>>.from(visits);

    // تاريخ اليوم (بدون ساعات لضبط المقارنة)
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // 2. عملية الترتيب المتقدمة
    allVisits.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['visit_date'].toString()) ?? today;
      DateTime dateB = DateTime.tryParse(b['visit_date'].toString()) ?? today;

      // حساب الفرق بالأيام
      int diffA = dateA.difference(today).inDays;
      int diffB = dateB.difference(today).inDays;

      // منطق الترتيب:
      // أ- إذا كان التاريخين في المستقبل أو اليوم، نرتب بالأقرب لليوم (الفرق الأصغر أولاً)
      // ب- إذا كان أحدهما قديم والآخر مستقبل، نجعل المستقبل في البداية
      if (diffA >= 0 && diffB >= 0) {
        return diffA.compareTo(diffB); // الأقرب لليوم يظهر أولاً
      } else if (diffA >= 0 && diffB < 0) {
        return -1; // A في المستقبل و B قديم، إذن A يسبق B
      } else if (diffA < 0 && diffB >= 0) {
        return 1; // B في المستقبل و A قديم، إذن B يسبق A
      } else {
        // كلاهما قديم، نرتب بالأحدث تاريخاً
        return diffB.compareTo(diffA);
      }
    });

    // 3. تصفية السجلات لإظهار آخر عرض لكل عسكري فقط (Unique)
    Map<String, Map<String, dynamic>> uniqueSoldiers = {};
    for (var v in allVisits) {
      String sId = v['visit_soldiers_number'].toString();
      if (!uniqueSoldiers.containsKey(sId)) uniqueSoldiers[sId] = v;
    }

    // 4. تطبيق البحث (Search Filter)
    return uniqueSoldiers.values.where((v) {
      final name = v['soldiers_name']?.toString().toLowerCase() ?? "";
      final number = v['visit_soldiers_number']?.toString() ?? "";
      final query = searchQuery.toLowerCase();
      return name.contains(query) || number.contains(query);
    }).toList();
  }

  String searchQuery = "";

  final List<DataColumn> visitColumns = const [
    DataColumn(label: Text('الاسم')),
    DataColumn(label: Text('الكتيبة')),
    DataColumn(label: Text('السرية')),
    DataColumn(label: Text('الفصيلة')),
    DataColumn(label: Text('رقم سجل')),
    DataColumn(label: Text('المستشفى')),
    DataColumn(label: Text('التخصص')),
    DataColumn(label: Text('التاريخ')),
    DataColumn(label: Text('النتيجة')),
    DataColumn(label: Text('ملاحظات')),
  ];
  final List<String> visitKeys = [
    'soldiers_name',
    'soldiers_k',
    'soldiers_s',
    'soldiers_f',
    'soldiers_unit_id',
    'visit_place',
    'visit_type',
    'visit_date',
    'visit_result',
    'visit_notes', // ← ملاحظات (فاضي)
  ];
  String? get batchId => _batchId;

  Future<void> loadData() async {
    if (_batchId == null) return;
    loading = true;
    notifyListeners();
    visits = await repo.getVisits(_batchId!);
    soldiers = await repo.getSoldiers(_batchId!);
    loading = false;
    notifyListeners();
  }

  // دالة الإضافة مع إرجاع رسالة نصية فقط في حالة الخطأ
  Future<String?> addVisit(Map<String, dynamic> data) async {
    try {
      // التحقق من التكرار
      final duplicate = visits.any(
        (v) =>
            v['visit_soldiers_number'].toString() ==
                data['visit_soldiers_number'].toString() &&
            v['visit_date'].toString().split(' ').first ==
                data['visit_date'].toString().split(' ').first,
      );

      if (duplicate) {
        return "هذا الجندي مسجل له عرض بالفعل في هذا التاريخ";
      }

      await repo.insertVisit(data);
      await loadData(); // تحديث القائمة بعد الإضافة
      return null; // نجاح
    } catch (e) {
      return "حدث خطأ أثناء الحفظ: $e";
    }
  }

  Future<String?> editVisit(int id, Map<String, dynamic> data) async {
    try {
      final duplicate = visits.any(
        (v) =>
            v['visit_soldiers_number'].toString() ==
                data['visit_soldiers_number'].toString() &&
            v['visit_date'].toString().split(' ').first ==
                data['visit_date'].toString().split(' ').first &&
            v['visit_id'] != id,
      );

      if (duplicate) {
        return "يوجد سجل آخر بنفس التاريخ لهذا الجندي";
      }

      await repo.updateVisit(id, data);
      await loadData();
      return null;
    } catch (e) {
      return "حدث خطأ أثناء التعديل: $e";
    }
  }

  Future<void> deleteVisit(int id) async {
    await repo.deleteVisit(id);
    await loadData();
  }
}

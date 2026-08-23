import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database/batch_repository.dart';
import 'package:flutter_application_1/services/database/batches_plan_repository.dart';
import 'package:flutter_application_1/models/batch_plan_columns.dart';
import 'package:flutter_application_1/viewmodels/home_viewmodel.dart';
import 'package:provider/provider.dart'; // تأكد من استيراد الملف الذي يحتوي على المصفوفات

class BatchesPageViewModel extends ChangeNotifier {
  final BatchesRepository batchesRepo;
  final BatchPlanRepository planRepo;
  String getBatchMonth(String batchId) {
    if (batchId.endsWith("1")) return "يناير";
    if (batchId.endsWith("2")) return "إبريل";
    if (batchId.endsWith("3")) return "يوليو";
    if (batchId.endsWith("4")) return "أكتوبر";
    return "أكتوبر";
  }

  BatchesPageViewModel(this.batchesRepo, this.planRepo);

  List<Map<String, dynamic>> batches = [];
  bool loading = false;
  int? selectedBatchId;
  bool planExists = false;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();

  // الخريطة التي تحمل المتحكمات - المفاتيح هنا ستكون هي نفسها أسماء الأعمدة في الـ DB (English)
  final Map<String, TextEditingController> planCtrls = {};

  /// تحويل القيم من العربي (الواجهة) إلى الإنجليزي (قاعدة البيانات)
  String getColumnNameFromArabic(String level, String weapon, String type) {
    // هذه الدالة تحول الاختيارات في الـ UI إلى اسم العمود في الـ DB
    // مثال: "عالي", "مهندسين", "صف" -> "high_eng_base"

    String l = _mapLevel(level);
    String w = _mapWeapon(weapon);
    String t = _mapType(type);

    return "${l}_${w}_$t";
  }

  /// تحميل الدفعات
  Future<void> loadBatches() async {
    loading = true;
    notifyListeners();
    batches = await batchesRepo.getAll();
    loading = false;
    notifyListeners();
  }

  /// تهيئة دفعة جديدة
  void newBatch() {
    selectedBatchId = null;
    nameCtrl.clear();
    dateCtrl.clear();
    planExists = false;

    planCtrls.clear();
    for (String col in batchPlanColumns) {
      planCtrls[col] = TextEditingController(text: '0');
    }
    notifyListeners();
  }

  /// اختيار دفعة وتعبئة البيانات
  Future<void> selectBatch(int batchId) async {
    selectedBatchId = batchId;
    final batch = await batchesRepo.getById(batchId);
    if (batch == null) return;

    nameCtrl.text = batch['batch_name'] ?? '';
    dateCtrl.text = batch['batch_start_date'] ?? '';

    final plan = await planRepo.getPlan(batchId);
    planExists = plan != null;

    planCtrls.clear();
    for (String col in batchPlanColumns) {
      // قراءة القيمة من الداتا بيز ووضعها في الـ controller الخاص بها
      planCtrls[col] = TextEditingController(
        text: plan?[col]?.toString() ?? '0',
      );
    }
    notifyListeners();
  }

  /// الحفظ (إدراج أو تعديل)
  Future<void> save(BuildContext context) async {
    if (nameCtrl.text.isEmpty || dateCtrl.text.isEmpty) return;

    // 1. حفظ رأس الدفعة
    if (selectedBatchId == null) {
      selectedBatchId = await batchesRepo.insertBatch(
        nameCtrl.text,
        dateCtrl.text,
      );
    } else {
      await batchesRepo.updateBatch(
        selectedBatchId!,
        nameCtrl.text,
        dateCtrl.text,
      );
    }

    // 2. تحضير بيانات الخطة (Data Mapping)
    final Map<String, int> planData = {};
    for (String col in batchPlanColumns) {
      planData[col] = int.tryParse(planCtrls[col]?.text ?? '0') ?? 0;
    }

    // 3. حفظ الخطة في الـ DB
    if (planExists) {
      await planRepo.updatePlan(selectedBatchId!, planData);
    } else {
      await planRepo.insertPlan(selectedBatchId!, planData);
      planExists = true;
    }

    // 4. إعادة تحميل الدفعات في BatchesPageViewModel
    await loadBatches();

    // 5. تحديث HomeViewmodel حتى تظهر الدفعة الجديدة في القائمة الجانبية
    final homeVM = Provider.of<HomeViewmodel>(context, listen: false);
    await homeVM.refreshBatches(
      batchToSelect: {'batch_id': selectedBatchId, 'batch_name': nameCtrl.text},
    );
  }

  Future<void> delete(BuildContext context, int id) async {
    await batchesRepo.deleteBatch(id);
    newBatch();
    await loadBatches();
    final homeVM = Provider.of<HomeViewmodel>(context, listen: false);
    await homeVM.refreshBatches(
      batchToSelect: {'batch_id': selectedBatchId, 'batch_name': nameCtrl.text},
    );
  }

  // دالة مساعدة للتحويل (Mapping Helpers)
  String _mapLevel(String l) {
    if (l.contains("عالي")) return "high";
    if (l.contains("فوق المتوسط")) return "above_mid";
    if (l.contains("عادة")) return "normal";
    if (l.contains("مهنى")) return "mid_prof";
    if (l.contains("حرفى")) return "mid_skill";
    return "";
  }

  // إجمالي السلاح الواحد (مجموع المؤهلات لنفس السلاح)
  int getWeaponTotal(String weapon) {
    int total = 0;
    for (var lvl in [
      "عالي",
      "فوق المتوسط",
      "عادة",
      "متوسط/حرفى",
      "متوسط/مهنى",
    ]) {
      for (var t in ["صف", "جوية", "بحرية"]) {
        String col = getColumnNameFromArabic(lvl, weapon, t);
        total += int.tryParse(planCtrls[col]?.text ?? '0') ?? 0;
      }
    }
    return total;
  }

  // إجمالي المؤهل الواحد (مجموع الأسلحة لنفس المؤهل)
  int getLevelTotal(String level) {
    int total = 0;
    for (var w in ["مهندسين", "مياه", "مساحة", "أشغال"]) {
      for (var t in ["صف", "جوية", "بحرية"]) {
        String col = getColumnNameFromArabic(level, w, t);
        total += int.tryParse(planCtrls[col]?.text ?? '0') ?? 0;
      }
    }
    return total;
  }

  String _mapWeapon(String w) {
    if (w.contains("مهندسين")) return "eng";
    if (w.contains("مياه") || w.contains("مياة")) return "water";
    if (w.contains("مساحة")) return "survey";
    if (w.contains("أشغال") || w.contains("الأشغال")) return "works";
    return "";
  }

  String _mapType(String t) {
    if (t == "صف") return "base";
    if (t == "جوية") return "ground";
    if (t == "بحرية") return "naval";
    return "";
  }

  bool isLoading = false;
  List<Map<String, String>> failedRows = [];
  Future<void> importExcel(
    BuildContext context,
    Uint8List fileBytes,
    String batchId,
  ) async {
    if (isLoading) return;

    isLoading = true;
    failedRows = [];
    notifyListeners(); // إخطار الواجهة لبدء إظهار "دائرة التحميل"

    try {
      // هنا الـ Repository سيقوم بفتح Isolate (مسار خلفي) للمعالجة
      final failures = await batchesRepo.importExcel(fileBytes, batchId);

      failedRows = failures
          .map((f) => f.map((k, v) => MapEntry(k, v.toString())))
          .toList();

      await loadBatches();
      final homeVM = Provider.of<HomeViewmodel>(context, listen: false);

      // إجبار الهوم على إعادة قراءة الدفعات وتحديد الدفعة الحالية مجدداً
      await homeVM.refreshBatches(
        batchToSelect: {
          'batch_id': int.parse(batchId),
          'batch_name': nameCtrl.text,
        },
      );

      // تحديث القائمة بعد النجاح
    } catch (e) {
      failedRows = [
        {
          'row': 'تنبيه',
          'name': 'النظام',
          'reason': 'حدث خطأ أثناء الرفع: ${e.toString()}',
        },
      ];
    } finally {
      isLoading = false;
      notifyListeners(); // إخطار الواجهة لإخفاء "دائرة التحميل"
    }
  }
}

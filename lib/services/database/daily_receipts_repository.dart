import 'package:flutter_application_1/models/batch_plan_columns.dart';
import 'package:flutter_application_1/services/database/db_helper.dart';

class DailyReceiptsRepository {
  final SqlDb sqlDb = SqlDb();

  // --- إدراج سجل استلام جديد ---
  Future<void> insertReceipt(
    int batchId,
    String date,
    Map<String, int> receiptData,
  ) async {
    final columns = [
      'batch_id',
      'receipt_date',
      ...batchPlanColumns,
    ].join(', ');

    final values = [
      batchId,
      "'$date'",
      ...batchPlanColumns.map((c) => receiptData[c] ?? 0),
    ].join(', ');

    String sql = "INSERT INTO daily_receipts ($columns) VALUES ($values)";
    await sqlDb.insertData(sql);
  }

  // --- جلب مخطط الدفعة ---
  Future<Map<String, dynamic>?> getBatchPlan(int batchId) async {
    List<Map<String, dynamic>> res = await sqlDb.readData(
      "SELECT * FROM batch_plan WHERE batch_id = $batchId",
    );
    return res.isNotEmpty ? res.first : null;
  }

  // --- الدالة المعدلة: جلب بيانات الترحيل مع فصل المهني عن الصف ---
  // داخل DailyReceiptsRepository
  Future<Map<String, int>> getMovedData(int batchId) async {
    // ركز هنا: استخدمنا moqf_soldiers_number من جدول soldiers_moqf
    String sql =
        '''
    SELECT s.soldiers_weapon, s.soldiers_qualification, s.soldiers_management, COUNT(*) as total
    FROM soldiers_t s
    INNER JOIN soldiers_sending send ON s.soldiers_number = send.sending_soldiers_number
    WHERE s.soldiers_batch_id = $batchId 
    AND send.sending_date IS NOT NULL
    -- الاستبعاد: لا تأخذ الجندي إذا كان موجوداً في جدول المواقف
    AND s.soldiers_number NOT IN (
        SELECT moqf_soldiers_number 
        FROM soldiers_moqf 
        WHERE moqf_batch_id = $batchId
    )
    GROUP BY s.soldiers_weapon, s.soldiers_qualification, s.soldiers_management
  ''';

    final List<Map<String, dynamic>> results = await sqlDb.readData(sql);
    Map<String, int> movedMap = {};

    for (var row in results) {
      String sQual = row['soldiers_qualification']?.toString() ?? "";
      String sMgmt = row['soldiers_management']?.toString() ?? "";
      String sWeapon = row['soldiers_weapon']?.toString() ?? "";
      int count = (row['total'] as num).toInt();

      // --- منطق التصنيف (ليظل متوافقاً مع تقريرك) ---
      String l = "unknown";
      if (sQual.contains("عليا")) {
        l = "high";
      } else if (sQual.contains("فوق متوسط"))
        l = "above_mid";
      else if (sQual.contains("عادة") || sWeapon.contains("عادي"))
        l = "normal";
      else if (sQual.contains("مهن") || sWeapon.contains("مهني"))
        l = "mid_prof";
      else
        l = "mid_skill";

      String w = "unknown";
      if (sMgmt.contains("مهندسين")) {
        w = "eng";
      } else if (sMgmt.contains("مياه") || sMgmt.contains("مياة"))
        w = "water";
      else if (sMgmt.contains("مساحة"))
        w = "survey";
      else if (sMgmt.contains("أشغال") || sMgmt.contains("الاشغال"))
        w = "works";

      String t = sWeapon.contains("جوية")
          ? "ground"
          : (sWeapon.contains("بحرية") ? "naval" : "base");

      String key = "${l}_${w}_$t";
      movedMap[key] = (movedMap[key] ?? 0) + count;
    }
    return movedMap;
  }

  Future<Map<String, int>> getMoqfData(int batchId) async {
    // هنا نقوم بالربط مع جدول المواقف soldiers_moqf
    String sql =
        '''
    SELECT s.soldiers_weapon, s.soldiers_qualification, s.soldiers_management, COUNT(*) as total
    FROM soldiers_t s
    INNER JOIN soldiers_moqf m ON s.soldiers_number = m.moqf_soldiers_number
    WHERE s.soldiers_batch_id = $batchId
    GROUP BY s.soldiers_weapon, s.soldiers_qualification, s.soldiers_management
  ''';

    final List<Map<String, dynamic>> results = await sqlDb.readData(sql);
    Map<String, int> moqfMap = {};

    for (var row in results) {
      String sQual = row['soldiers_qualification']?.toString() ?? "";
      String sMgmt = row['soldiers_management']?.toString() ?? "";
      String sWeapon = row['soldiers_weapon']?.toString() ?? "";
      int count = (row['total'] as num).toInt();

      // --- نفس منطق التصنيف الخاص بك لضمان تطابق المفاتيح ---
      String l = "unknown";
      if (sQual.contains("عليا")) {
        l = "high";
      } else if (sQual.contains("فوق متوسط"))
        l = "above_mid";
      else if (sQual.contains("عادة") || sWeapon.contains("عادي"))
        l = "normal";
      else if (sQual.contains("مهن") || sWeapon.contains("مهني"))
        l = "mid_prof";
      else
        l = "mid_skill";

      String w = "unknown";
      if (sMgmt.contains("مهندسين")) {
        w = "eng";
      } else if (sMgmt.contains("مياه") || sMgmt.contains("مياة"))
        w = "water";
      else if (sMgmt.contains("مساحة"))
        w = "survey";
      else if (sMgmt.contains("أشغال") || sMgmt.contains("الاشغال"))
        w = "works";

      String t = sWeapon.contains("جوية")
          ? "ground"
          : (sWeapon.contains("بحرية") ? "naval" : "base");

      // المفتاح الناتج سيكون مثلاً: high_eng_base
      String key = "${l}_${w}_$t";
      moqfMap[key] = (moqfMap[key] ?? 0) + count;
    }
    return moqfMap;
  }

  Future<int> getPreviousBatchesRemaining(
    String currentBatchName,
    int currentBatchId,
  ) async {
    try {
      // 1. استخراج رقم الدفعة الحالية (مثل 20261)
      String cleanName = currentBatchName.trim().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      int? currentVal = int.tryParse(cleanName);

      if (currentVal == null) return 0;

      // 2. الاستعلام:
      // نعد الجنود الذين يتبعون دفعات أقدم من الحالية (بناءً على الاسم)
      // والذين تاريخ ترحيلهم في جدول الترحيل (null) أو نص فارغ
      String sql =
          '''
      SELECT COUNT(*) as total
      FROM soldiers_sending ss
      INNER JOIN soldiers_t s ON ss.sending_soldiers_number = s.soldiers_number
      INNER JOIN batches b ON s.soldiers_batch_id = b.batch_id
      WHERE CAST(b.batch_name AS INTEGER) < $currentVal
      AND (ss.sending_date IS NULL OR ss.sending_date = '')
    ''';

      final List<Map<String, dynamic>> results = await sqlDb.readData(sql);

      if (results.isNotEmpty && results.first['total'] != null) {
        int count = int.parse(results.first['total'].toString());
        print("🔍 إجمالي المتبقي من دفعات سابقة (تاريخ ترحيل فارغ): $count");
        return count;
      }
      return 0;
    } catch (e) {
      print("❌ Error in getPreviousBatchesRemaining: $e");
      return 0;
    }
  } // --- جلب إحصائيات المواقف بالنوع (للجدول السفلي في PDF) ---

  Future<Map<String, int>> getMoqfStatsByType(int batchId) async {
    // الأنواع المطلوبة تماماً كما في جدول الـ PDF
    final List<String> targetTypes = [
      "رفد طبى",
      "رفد امنى",
      "حالة وفاة",
      "اعفاء عائلى",
      "ضم حربية",
      "ضم شرطة",
      "شطب",
      "تعديل سلاح",
    ];

    // استعلام يجلب عدد الجنود لكل نوع مواقف لدفعة محددة
    String sql =
        '''
      SELECT moqf_type, COUNT(*) as total
      FROM soldiers_moqf
      WHERE moqf_batch_id = $batchId
      GROUP BY moqf_type
    ''';

    final List<Map<String, dynamic>> results = await sqlDb.readData(sql);

    // تحويل النتائج إلى Map لسهولة الوصول إليها
    Map<String, int> statsMap = {};

    // نضع قيمة ابتدائية 0 لكل الأنواع المطلوبة لضمان عدم وجود null
    for (var type in targetTypes) {
      statsMap[type] = 0;
    }
    statsMap['أخرى'] = 0;

    for (var row in results) {
      String type = row['moqf_type']?.toString() ?? "";
      int count = (row['total'] as num).toInt();

      if (targetTypes.contains(type)) {
        statsMap[type] = count;
      } else {
        // أي نوع غير موجود في القائمة الأساسية يضاف لخانة "أخرى"
        statsMap['أخرى'] = (statsMap['أخرى'] ?? 0) + count;
      }
    }

    return statsMap;
  }

  // --- تحديث سجل استلام ---
  Future<void> updateReceipt(
    int receiptId,
    String date,
    Map<String, int> receiptData,
  ) async {
    final updates = batchPlanColumns
        .map((c) => "$c = ${receiptData[c] ?? 0}")
        .join(', ');

    String sql =
        "UPDATE daily_receipts SET receipt_date = '$date', $updates WHERE receipt_id = $receiptId";
    await sqlDb.updateData(sql);
  }

  // --- جلب تاريخ الاستلامات لدفعة معينة ---
  Future<List<Map<String, dynamic>>> getBatchReceipts(String batchId) async {
    return await sqlDb.readData(
      "SELECT * FROM daily_receipts WHERE batch_id = $batchId ORDER BY receipt_date DESC",
    );
  }

  // --- حذف سجل ---
  Future<void> deleteReceipt(int receiptId) async {
    await sqlDb.deleteData(
      "DELETE FROM daily_receipts WHERE receipt_id = $receiptId",
    );
  }
}

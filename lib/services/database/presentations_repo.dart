import 'package:flutter_application_1/services/database/db_helper.dart';

class PresentationRepository {
  final SqlDb db;
  PresentationRepository(this.db);

  // ============================================================
  // 1. عمليات لجان العرض (Presentation Committees)
  // ============================================================

  // جلب اللجان (سيجلب لجنتين فقط كحد أقصى لكل دفعة)
  Future<List<Map<String, dynamic>>> getCommitteesByBatch(
    String batchId,
  ) async {
    return await db.readData('''
      SELECT * FROM presentation_committees 
      WHERE committee_batch_id = $batchId 
      ORDER BY committee_order ASC
    ''');
  }

  Future<void> tasfeya() async {
    await db.updateData('''
     UPDATE soldier_presentations 
        SET pres_result = 'لائق'
        WHERE pres_result = 'عرض' 
    ''');
  }

  /// هذه الدالة تضمن منطق "اللجنتين فقط"
  /// تعتمد على committee_order (1 أو 2) للبحث
  Future<void> upsertCommittee({
    required String batchId,
    required String date,
    required int order, // 1 للجنة الأولى، 2 للجنة الثانية
    String? notes,
  }) async {
    // التحقق: هل الدفعة دي عندها لجنة رقم (1 أو 2) فعلاً؟
    final List<Map<String, dynamic>> existing = await db.readData('''
      SELECT committee_id FROM presentation_committees 
      WHERE committee_batch_id = $batchId AND committee_order = $order
      LIMIT 1
    ''');

    if (existing.isNotEmpty) {
      // إذا وجدنا اللجنة بنفس الترتيب، نقوم بتحديث التاريخ فقط
      // هكذا مهما غيرت التاريخ لن تنشأ لجنة جديدة، بل يتعدل تاريخ الحالية
      int id = existing.first['committee_id'];
      await db.updateData('''
        UPDATE presentation_committees 
        SET committee_date = '$date', committee_notes = '${notes ?? ""}'
        WHERE committee_id = $id
      ''');
    } else {
      // إدراج لجنة جديدة فقط إذا كان الترتيب (1 أو 2) غير موجود لهذه الدفعة
      await db.insertData('''
        INSERT INTO presentation_committees 
        (committee_batch_id, committee_date, committee_order, committee_notes)
        VALUES ($batchId, '$date', $order, '${notes ?? ""}')
      ''');
    }
  }

  // حذف لجنة
  Future<void> deleteCommittee(int committeeId) async {
    await db.deleteData('''
      DELETE FROM presentation_committees WHERE committee_id = $committeeId
    ''');
  }

  // ============================================================
  // 2. عمليات نتائج العرض للعساكر (Soldier Presentations)
  // ============================================================

  // جلب النتائج مع بيانات العساكر
  Future<List<Map<String, dynamic>>> getResultsByCommittee(
    int committeeId,
  ) async {
    return await db.readData('''
      SELECT 
        p.pres_id, p.clinic_type, p.pres_result, p.pres_note,
        s.soldiers_name, s.soldiers_number, s.soldiers_k, s.soldiers_s, s.soldiers_f, s.soldiers_unit_id
      FROM soldier_presentations p
      INNER JOIN soldiers_t s ON s.soldiers_number = p.pres_soldier_number
      WHERE p.pres_committee_id = $committeeId
      ORDER BY s.soldiers_name ASC
    ''');
  }

  // إضافة نتيجة عسكري (يُفضل التحقق برمجياً قبل الإضافة لمنع تكرار نفس العسكري في نفس اللجنة)
  Future<void> insertSoldierResult({
    required int committeeId,
    required String soldierNumber,
    required String clinicType,
    required String result,
    String? notes,
  }) async {
    await db.insertData('''
      INSERT INTO soldier_presentations 
      (pres_committee_id, pres_soldier_number, clinic_type, pres_result, pres_note)
      VALUES ($committeeId, '$soldierNumber', '$clinicType', '$result', '${notes ?? ""}')
    ''');
  }

  // تحديث النتيجة
  Future<void> updatePresentation({
    required int presId,
    required String clinicType,
    required String result,
    String? notes,
  }) async {
    await db.updateData('''
      UPDATE soldier_presentations 
      SET clinic_type = '$clinicType', 
          pres_result = '$result', 
          pres_note = '${notes ?? ""}'
      WHERE pres_id = $presId
    ''');
  }

  // حذف جندي
  Future<void> deleteSoldierResult(int presId) async {
    await db.deleteData('''
      DELETE FROM soldier_presentations WHERE pres_id = $presId
    ''');
  }

  // ============================================================
  // 3. البحث والإحصائيات
  // ============================================================

  // البحث عن جندي
  Future<List<Map<String, dynamic>>> searchSoldierForCommittee(
    String value,
    String batchId,
  ) async {
    return await db.readData('''
      SELECT soldiers_name, soldiers_number, soldiers_k 
      FROM soldiers_t
      WHERE soldiers_batch_id = $batchId 
      AND (soldiers_number LIKE '%$value%' OR soldiers_name LIKE '%$value%')
      LIMIT 10
    ''');
  }

  // جلب إحصائيات اللجنة
  Future<Map<String, dynamic>> getCommitteeStats(int committeeId) async {
    final res = await db.readData('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN pres_result = 'لجنة رفد' THEN 1 ELSE 0 END) as unfit,
        SUM(CASE WHEN pres_result = 'لائق' THEN 1 ELSE 0 END) as returned
      FROM soldier_presentations 
      WHERE pres_committee_id = $committeeId
    ''');
    return res.isNotEmpty ? res.first : {'total': 0, 'unfit': 0, 'returned': 0};
  }
}

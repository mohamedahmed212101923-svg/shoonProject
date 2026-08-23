import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:intl/intl.dart';

class AjazaRepository {
  final SqlDb db;

  AjazaRepository(this.db);

  // =========================
  // تحميل الجنود
  // =========================
  Future<List<Map<String, dynamic>>> getAllSoldiers({String? batchId}) async {
    final result = await db.readData("""
      SELECT soldiers_unit_id, soldiers_batch_id,
             soldiers_name, soldiers_number,
             soldiers_k, soldiers_s, soldiers_f,
             soldiers_city
      FROM soldiers_t
      ${batchId != null ? "WHERE soldiers_batch_id = $batchId" : ""}
      ORDER BY soldiers_name ASC;
    """);

    return result;
  }

  // =========================
  // تحميل الجنود بالإجازات
  // =========================
  Future<List<Map<String, dynamic>>> getSoldiersWithLeaves({
    String? batchId,
  }) async {
    final result = await db.readData("""
      SELECT
        l.soldiers_leaves_id,
        s.soldiers_name,
        s.soldiers_number,
        s.soldiers_k,
        s.soldiers_s,
        s.soldiers_f,
        s.soldiers_city,
        l.leave_start,
        l.leave_end,
        l.leave_reason,
        s.soldiers_batch_id
      FROM soldiers_t s
      INNER JOIN soldiers_leaves l
        ON l.leaves_soldiers_number = s.soldiers_number
      ${batchId != null ? "WHERE s.soldiers_batch_id = $batchId" : ""}
      ORDER BY l.leave_end DESC;
    """);

    return result;
  }

  // =========================
  // إضافة إجازة
  // =========================
  Future<int> insertLeave({
    required String soldierNumber,
    required String batchId,
    required DateTime start,
    required String end,
    required String reason,
  }) async {
    final s = DateFormat("yyyy/MM/dd").format(start);

    return await db.insertData("""
      INSERT INTO soldiers_leaves (
        leaves_soldiers_number,
        leaves_batch_id,
        leave_start,
        leave_end,
        leave_reason
      )
      VALUES (
        '$soldierNumber',
        $batchId,
        '$s',
        '$end',
        '$reason'
      );
    """);
  }

  // =========================
  // تعديل إجازة
  // =========================
  Future<int> updateLeave({
    required int id,
    required DateTime start,
    required String end,
    required String reason,
  }) async {
    final s = DateFormat("yyyy/MM/dd").format(start);

    return await db.updateData("""
      UPDATE soldiers_leaves
      SET leave_start = '$s',
          leave_end = '$end',
          leave_reason = '$reason'
      WHERE soldiers_leaves_id = $id;
    """);
  }

  // =========================
  // حذف إجازة
  // =========================
  Future<int> deleteLeave(int id) async {
    return await db.deleteData(
      "DELETE FROM soldiers_leaves WHERE soldiers_leaves_id = $id",
    );
  }

  // =========================
  // فحص التداخل
  // =========================
  Future<bool> checkOverlap({
    required String soldierNumber,
    required String batchId,
    required DateTime newStart,
    required DateTime newEnd,
    int? excludeId,
  }) async {
    final s = DateFormat("yyyy/MM/dd").format(newStart);
    final e = DateFormat("yyyy/MM/dd").format(newEnd);

    String extra = excludeId != null
        ? "AND soldiers_leaves_id != $excludeId"
        : "";

    final result = await db.readData("""
      SELECT * FROM soldiers_leaves
      WHERE leaves_soldiers_number = '$soldierNumber'
        AND leaves_batch_id = $batchId
        AND NOT (leave_end <= '$s' OR leave_start >= '$e')
        $extra;
    """);

    return result.isNotEmpty;
  } // أضف هذه الدوال داخل كلاس AjazaRepository
  // أضف هذه الدالة في AjazaRepository

  Future<List<String>> getExcludedSoldiers(String batchId) async {
    // جلب الأرقام العسكرية من جدول الترحيلات بشرط أن تاريخ الترحيل ليس فارغاً
    // وجلب الأرقام من جدول المواقف (الجزاءات/الموانع)
    final sendingRes = await db.readData(
      "SELECT sending_soldiers_number FROM soldiers_sending WHERE sending_batch_id = $batchId AND sending_date IS NOT NULL",
    );

    final moqfRes = await db.readData(
      "SELECT moqf_soldiers_number FROM soldiers_moqf WHERE moqf_batch_id = $batchId",
    );

    List<String> excluded = [];

    // إضافة العساكر اللي اترحلوا فعلياً
    for (var row in sendingRes) {
      if (row['sending_soldiers_number'] != null) {
        excluded.add(row['sending_soldiers_number'].toString());
      }
    }

    // إضافة العساكر اللي عندهم مواقف (موانع)
    for (var row in moqfRes) {
      if (row['moqf_soldiers_number'] != null) {
        excluded.add(row['moqf_soldiers_number'].toString());
      }
    }

    // استخدام toSet لإزالة التكرار وتحويلها لقائمة
    return excluded.toSet().toList();
  }

  // جلب أنواع المنح الفريدة الموجودة في الدفعة
  Future<List<String>> getUniqueGiftTypes(String batchId) async {
    final res = await db.readData(
      "SELECT DISTINCT gift_type FROM soldiers_gift WHERE gift_batch_id = $batchId",
    );
    return res.map((e) => e['gift_type'].toString()).toList();
  }

  // جلب أيام المنح لكل عسكري
  Future<Map<String, int>> getSoldiersGiftsDays(
    String batchId,
    Map<String, int> giftValues,
  ) async {
    final res = await db.readData(
      "SELECT gift_soldiers_number, gift_type FROM soldiers_gift WHERE gift_batch_id = $batchId",
    );

    Map<String, int> soldierExtraDays = {};
    for (var row in res) {
      // بنحول القيمة لنص بشكل صريح عشان Dart ترتاح
      String num = row['gift_soldiers_number'].toString();
      String type = row['gift_type'].toString();

      int days = giftValues[type] ?? 0;
      soldierExtraDays[num] = (soldierExtraDays[num] ?? 0) + days;
    }
    return soldierExtraDays;
  }
}

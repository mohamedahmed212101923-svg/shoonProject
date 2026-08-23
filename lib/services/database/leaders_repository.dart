import 'package:flutter_application_1/services/database/db_helper.dart';

class LeadersRepository {
  final SqlDb db;
  LeadersRepository(this.db);

  Future<List<Map<String, Object?>>> getLeaders() async {
    return await db.readData('SELECT * FROM leader');
  }

  Future<void> upsertLeader({
    required int fixedId, // تغيير النوع لـ int ليتوافق مع الـ ID
    required String pos,
    required String name,
    required String rank,
  }) async {
    // 1. البحث باستخدام الـ ID الثابت (1 أو 2)
    final existing = await db.readData(
      "SELECT leader_id FROM leader WHERE leader_id = $fixedId",
    );

    if (existing.isEmpty) {
      // 2. إذا لم يكن موجوداً، نقوم بإدخاله مع تحديد الـ ID يدوياً
      await db.insertData("""
      INSERT INTO leader (leader_id, leader_name, leader_rank, leader_posation)
      VALUES ($fixedId, '$name', '$rank', '$pos')
    """);
    } else {
      // 3. إذا كان موجوداً، نقوم بالتحديث بناءً على الـ ID
      await db.updateData("""
      UPDATE leader
      SET leader_name = '$name',
          leader_rank = '$rank',
          leader_posation = '$pos'
      WHERE leader_id = $fixedId
    """);
    }
  }
}

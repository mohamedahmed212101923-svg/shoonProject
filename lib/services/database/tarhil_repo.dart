import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:flutter_application_1/services/database/db_helper.dart';

class TarhilRepo {
  final SqlDb sqlDb;
  TarhilRepo(this.sqlDb);
  Future<int> insertSending(Map<String, dynamic> data) async {
    if (AppMode.isServer) {
      final db = await sqlDb.db;
      return await db.insert('soldiers_sending', data);
    } else {
      final columns = data.keys.join(', ');
      final values = data.values
          .map((v) => v is String ? "'$v'" : v)
          .join(', ');
      final sql = "INSERT INTO soldiers_sending ($columns) VALUES ($values)";
      return await sqlDb.insertData(sql);
    }
  }

  Future<int> updateSending(String id, Map<String, dynamic> data) async {
    if (AppMode.isServer) {
      final db = await sqlDb.db;
      return await db.update(
        'soldiers_sending',
        data,
        where: 'sending_id = ?',
        whereArgs: [id],
      );
    } else {
      final setClause = data.entries
          .map((e) {
            if (e.value.toString().contains("null") == false) {
              return "${e.key} = '${e.value}'";
            } else {
              return "";
            }
          })
          .join(', ');
      final sql =
          "UPDATE soldiers_sending SET ${setClause.replaceAll(", ,", ",")} WHERE sending_id = '$id'";

      return await sqlDb.updateData(sql);
    }
  }

  Future<int> updateSendingBulk({
    required String field,
    required List<String> values,
    required Map<String, dynamic> data,
  }) async {
    if (values.isEmpty) return 0;

    if (AppMode.isServer) {
      final db = await sqlDb.db;
      final placeholders = List.filled(values.length, '?').join(', ');
      return await db.update(
        'soldiers_sending',
        data,
        where: '$field IN ($placeholders)',
        whereArgs: values,
      );
    } else {
      final setClause = data.entries
          .map((e) => "${e.key} = '${e.value}'")
          .join(', ');
      final inValues = values.map((v) => "'$v'").join(', ');
      final sql =
          "UPDATE soldiers_sending SET $setClause WHERE $field IN ($inValues)";
      return await sqlDb.updateData(sql);
    }
  }

  Future<void> updateSendingBulkExcept({
    required String field,
    required List<String> values,
    required List<String> excluded,
    required Map<String, dynamic> data,
  }) async {
    if (values.isEmpty) return;

    if (AppMode.isServer) {
      final db = await sqlDb.db;
      final placeholdersIn = List.filled(values.length, '?').join(', ');
      final placeholdersNotIn = List.filled(excluded.length, '?').join(', ');
      await db.update(
        'soldiers_sending',
        data,
        where:
            "$field IN ($placeholdersIn) AND sending_id NOT IN ($placeholdersNotIn)",
        whereArgs: [...values, ...excluded],
      );
    } else {
      final setClause = data.entries
          .map((e) => "${e.key} = '${e.value}'")
          .join(', ');
      final inValues = values.map((v) => "'$v'").join(', ');
      final notInValues = excluded.map((v) => "'$v'").join(', ');
      final sql =
          "UPDATE soldiers_sending SET $setClause WHERE $field IN ($inValues) AND sending_id NOT IN ($notInValues)";
      await sqlDb.updateData(sql);
    }
  }

  Future<int> updateAllSendingDates(DateTime newDate) async {
    final formatted =
        "${newDate.year}/${newDate.month.toString().padLeft(2, '0')}/${newDate.day.toString().padLeft(2, '0')}";
    if (AppMode.isServer) {
      final db = await sqlDb.db;
      return await db.update('soldiers_sending', {'sending_date': formatted});
    } else {
      final sql = "UPDATE soldiers_sending SET sending_date = '$formatted'";
      return await sqlDb.updateData(sql);
    }
  }

  Future<int> deleteSending(int id) async {
    if (AppMode.isServer) {
      final db = await sqlDb.db;
      return await db.delete(
        'soldiers_sending',
        where: 'sending_id = ?',
        whereArgs: [id],
      );
    } else {
      final sql = "DELETE FROM soldiers_sending WHERE sending_id = $id";
      return await sqlDb.deleteData(sql);
    }
  }

  Future<Map<String, int>> getPreviousBatchNotSentCounts(
    String currentBatchName,
  ) async {
    try {
      String cleanName = currentBatchName.trim().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      int? currentVal = int.tryParse(cleanName);

      if (currentVal == null) return {};

      final String countSql =
          '''
        SELECT 
          CASE 
            WHEN ss.sending_father_area IS NOT NULL AND ss.sending_father_area != '' THEN ss.sending_father_area
            ELSE ss.sending_area 
          END as unit_key,
          COUNT(*) as total_count
        FROM soldiers_sending ss
        INNER JOIN soldiers_t s ON ss.sending_soldiers_number = s.soldiers_number
        INNER JOIN batches b ON s.soldiers_batch_id = b.batch_id
        WHERE CAST(REPLACE(REPLACE(b.batch_name, ' ', ''), 'دفعة', '') AS INTEGER) < $currentVal
          AND (ss.sending_date IS NULL OR ss.sending_date = '')
        GROUP BY unit_key
      ''';

      final List<Map<String, dynamic>> result = await sqlDb.readData(countSql);

      // تحويل النتيجة إلى Map: { "اسم الوحدة": العدد }
      return {
        for (var row in result)
          row['unit_key'].toString(): int.parse(row['total_count'].toString()),
      };
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error in getPreviousBatchNotSentCounts: $e");
      }
      return {};
    }
  }

  Future<Map<String, dynamic>?> getExistingSending(
    String soldiersNumber,
    int batchId,
  ) async {
    final res = await sqlDb.readData(
      "SELECT * FROM soldiers_sending WHERE sending_soldiers_number = '$soldiersNumber' AND sending_batch_id = $batchId LIMIT 1",
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> newgetSoldiersWithSending(
    String batchId,
  ) async {
    return await sqlDb.readData('''
    SELECT s.*, sen.sending_id, sen.sending_date,sen.sending_soldiers_number, sen.sending_area, sen.sending_note,sen.sending_father_area
    FROM soldiers_t AS s
    LEFT JOIN soldiers_sending AS sen 
      ON sen.sending_soldiers_number = s.soldiers_number 
      AND CAST(sen.sending_batch_id AS INTEGER) = s.soldiers_batch_id
    WHERE s.soldiers_batch_id = '$batchId' AND sen.sending_id IS NOT NULL
    ORDER BY sen.sending_father_area, sen.sending_area, s.soldiers_k, s.soldiers_s, s.soldiers_f, s.soldiers_number ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> getTamamSummary(String batchId) async {
    return await sqlDb.readData('''
    SELECT
      COALESCE(NULLIF(send.sending_father_area, ''), send.sending_area) AS tabaeia,
      SUM(CASE WHEN s.soldiers_management = 'إدارة المهندسين' THEN 1 ELSE 0 END) AS engineers,
      SUM(CASE WHEN s.soldiers_management = 'إدارة المياه' THEN 1 ELSE 0 END) AS water,
      SUM(CASE 
            WHEN s.soldiers_management = 'إدارة المساحة'
             AND s.soldiers_weapon NOT IN ('مهنى مساحة', 'مهنى مساحة جوية')
            THEN 1 ELSE 0 
          END) AS masaha,
      SUM(CASE WHEN s.soldiers_management = 'إدارة الأشغال' THEN 1 ELSE 0 END) AS ashghal,
      SUM(CASE 
            WHEN s.soldiers_weapon IN ('مهنى مساحة', 'مهنى مساحة جوية')
            THEN 1 ELSE 0 
          END) AS mahany_masaha,
      COUNT(*) AS total
    FROM soldiers_t s
    LEFT JOIN soldiers_sending send
      ON send.sending_soldiers_number = s.soldiers_number
      AND send.sending_batch_id = s.soldiers_batch_id
    WHERE s.soldiers_batch_id = '$batchId'
      AND send.sending_date IS NULL
    GROUP BY tabaeia
    ORDER BY tabaeia
  ''');
  }

  Future<void> updateSendingByIds({
    required List<int> ids,
    required Map<String, dynamic> data,
  }) async {
    if (ids.isEmpty) return;

    final idsStr = ids.join(',');
    final setClause = data.entries
        .map((e) => "${e.key} = '${e.value}'")
        .join(',');

    await sqlDb.updateData('''
    UPDATE soldiers_sending
    SET $setClause
    WHERE sending_id IN ($idsStr)
  ''');
  }

  Future<void> updateFatherAreaForUnits({
    required List<String> units,
    required String fatherArea,
    required String batchId,
  }) async {
    if (units.isEmpty) return;

    String inClause = units.map((u) => "'$u'").join(',');

    if (AppMode.isServer) {
      final db = await sqlDb.db;
      await db.update(
        "soldiers_sending",
        {"sending_father_area": fatherArea},
        where: "sending_area IN ($inClause) AND sending_batch_id = ?",
        whereArgs: [batchId],
      );
    } else {
      String sql =
          "UPDATE soldiers_sending SET sending_father_area = '$fatherArea' "
          "WHERE sending_area IN ($inClause) AND sending_batch_id = '$batchId'";
      await sqlDb.updateData(sql);
    }
  }
}

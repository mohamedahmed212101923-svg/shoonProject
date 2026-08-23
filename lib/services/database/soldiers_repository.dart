import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db_helper.dart';

class SoldiersRepository {
  final SqlDb dbHelper;
  SoldiersRepository(this.dbHelper);

  Future<Database> getDB() async {
    return await dbHelper.db;
  }

  String? currentBatchId;

  void setBatch(String? batchId) {
    currentBatchId = batchId;
  }

  Future<List<Map<String, dynamic>>> getBatches() async {
    final result = await dbHelper.readData('''
    SELECT batch_id, batch_name
    FROM batches
    WHERE batch_name IS NOT NULL AND batch_name != ''
    ORDER BY batch_name
  ''');
    return result;
  }

  Future<List<String>> getkatiba() async {
    if (currentBatchId == null) return [];
    final result = await dbHelper.readData('''
    SELECT DISTINCT soldiers_k FROM soldiers_t
    WHERE soldiers_k IS NOT NULL AND soldiers_batch_id = '$currentBatchId'
    ORDER BY soldiers_k
  ''');
    return result.map((e) => e['soldiers_k'].toString().trim()).toList();
  }

  Future<List<Map<String, dynamic>>> getAllSoldiers() async {
    if (currentBatchId == null) return [];
    return await dbHelper.readData('''
    SELECT * FROM soldiers_t 
    WHERE soldiers_batch_id = '$currentBatchId'
    ORDER BY soldiers_name
  ''');
  }

  Future<List<String>> getDistinct(String column) async {
    if (currentBatchId == null) return [];
    final result = await dbHelper.readData(
      "SELECT DISTINCT $column FROM soldiers_t WHERE soldiers_batch_id = '$currentBatchId' ORDER BY $column",
    );
    return result
        .map((e) => (e[column] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAllSoldiersForBatch(
    String? batchId,
  ) async {
    if (batchId == null) return [];
    return await dbHelper.readData('''
    SELECT * FROM soldiers_t 
    WHERE soldiers_batch_id = '$batchId' 
    ORDER BY soldiers_k, soldiers_s, soldiers_f ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> getAllTabaeia() async {
    return await dbHelper.readData(
      'SELECT * FROM tabaeia ORDER BY tabaeia_name ASC',
    );
  }

  Future<int> insertTabaeia(String name) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.insert('tabaeia', {'tabaeia_name': name.trim()});
    } else {
      return await dbHelper.insertData(
        "INSERT INTO tabaeia (tabaeia_name) VALUES ('${name.trim()}')",
      );
    }
  }

  Future<int> updateTabaeia(int id, String name) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.update(
        'tabaeia',
        {'tabaeia_name': name.trim()},
        where: 'tabaeia_id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbHelper.updateData(
        "UPDATE tabaeia SET tabaeia_name = '${name.trim()}' WHERE tabaeia_id = $id",
      );
    }
  }

  Future<int> deleteTabaeia(int id) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.delete(
        'tabaeia',
        where: 'tabaeia_id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbHelper.deleteData(
        "DELETE FROM tabaeia WHERE tabaeia_id = $id",
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllUnits() async {
    return await dbHelper.readData(
      'SELECT * FROM units ORDER BY units_name ASC',
    );
  }

  Future<int> insertUnit({
    required int tabaeiaId,
    required String unitName,
  }) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.insert('units', {
        'units_name': unitName.trim(),
        'units_tabaeia_id': tabaeiaId,
      });
    } else {
      return await dbHelper.insertData(
        "INSERT INTO units (units_name, units_tabaeia_id) VALUES ('${unitName.trim()}', $tabaeiaId)",
      );
    }
  }

  Future<int> updateUnit(int id, String name) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.update(
        'units',
        {'units_name': name.trim()},
        where: 'units_id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbHelper.updateData(
        "UPDATE units SET units_name = '${name.trim()}' WHERE units_id = $id",
      );
    }
  }

  Future<int> updateUnitTabaeia(int unitId, int tabaeiaId) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.update(
        'units',
        {'units_tabaeia_id': tabaeiaId},
        where: 'units_id = ?',
        whereArgs: [unitId],
      );
    } else {
      return await dbHelper.updateData(
        "UPDATE units SET units_tabaeia_id = $tabaeiaId WHERE units_id = $unitId",
      );
    }
  }

  Future<int> deleteUnit(int id) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.delete('units', where: 'units_id = ?', whereArgs: [id]);
    } else {
      return await dbHelper.deleteData(
        "DELETE FROM units WHERE units_id = $id",
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMoqfEntries(String? batchId) async {
    String whereClause = batchId == null ? "1=1" : "m.moqf_batch_id = $batchId";

    return await dbHelper.readData('''
    SELECT 
      m.moqf_id, 
      m.moqf_soldiers_number AS soldiers_number, 
      m.moqf_batch_id AS soldiers_batch_id,
      m.moqf_date,
      m.moqf_type,
      m.moqf_note,
      s.soldiers_name,
      s.soldiers_k,
      s.soldiers_s,
      s.soldiers_f,   s.soldiers_unit_id,
      s.soldiers_city
    FROM soldiers_moqf m
    INNER JOIN soldiers_t s 
      ON m.moqf_soldiers_number = s.soldiers_number
      -- يفضل الربط بالدفعة أيضاً لضمان الدقة المطلقة
      AND m.moqf_batch_id = s.soldiers_batch_id
    WHERE $whereClause
    ORDER BY m.moqf_id DESC
  ''');
  }

  Future<int> insertSoliderMoqf(Map<String, dynamic> data) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.insert('soldier_moqf', data);
    } else {
      final columns = data.keys.join(', ');
      final values = data.values.map((v) => v is String ? "'$v'" : v).join(',');
      return await dbHelper.insertData(
        "INSERT INTO soldier_moqf ($columns) VALUES ($values)",
      );
    }
  }

  Future<int> updateSoliderMoqf(int id, Map<String, dynamic> data) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.update(
        'soldier_moqf',
        data,
        where: 'soldier_moqf_id = ?',
        whereArgs: [id],
      );
    } else {
      String setClause = data.entries
          .map((e) => "${e.key} = '${e.value}'")
          .join(',');
      return await dbHelper.updateData(
        "UPDATE soldier_moqf SET $setClause WHERE soldier_moqf_id = $id",
      );
    }
  }

  Future<int> deleteSoliderMoqf(int id) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.delete(
        'soldier_moqf',
        where: 'soldier_moqf_id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbHelper.deleteData(
        "DELETE FROM soldier_moqf WHERE soldier_moqf_id = $id",
      );
    }
  }

  Future<List<Map<String, dynamic>>> getSoliderMoqfEntries(
    String? batchId,
  ) async {
    String whereClause = batchId == null
        ? "1=1"
        : "s.soldiers_batch_id = '$batchId'";

    return await dbHelper.readData('''
    SELECT 
      s.soldiers_name, 
      s.soldiers_number, 
      s.soldiers_k, 
      s.soldiers_s, 
      s.soldiers_f, 
      s.soldiers_city,
      
      GROUP_CONCAT(CASE WHEN m.soldier_moqf_type = 'موقف امنى' THEN m.soldier_moqf_note END, ' | ') AS "موقف امنى",
      GROUP_CONCAT(CASE WHEN m.soldier_moqf_type = 'موقف طبى فرع' THEN m.soldier_moqf_note END, ' | ') AS "موقف طبى فرع",
      GROUP_CONCAT(CASE WHEN m.soldier_moqf_type = 'موقف طبى مركز' THEN m.soldier_moqf_note END, ' | ') AS "موقف طبى مركز",
      GROUP_CONCAT(CASE WHEN m.soldier_moqf_type = 'موقف مهمات' THEN m.soldier_moqf_note END, ' | ') AS "موقف مهمات",
      GROUP_CONCAT(CASE WHEN m.soldier_moqf_type = 'موقف محو الاميه' THEN m.soldier_moqf_note END, ' | ') AS "موقف محو الاميه",
      GROUP_CONCAT(CASE WHEN m.soldier_moqf_type = 'موقف عقوبة' THEN m.soldier_moqf_note END, ' | ') AS "موقف عقوبة"
      
    FROM soldiers_t s
    LEFT JOIN soldier_moqf m 
      ON m.soldier_moqf_soldiers_number = s.soldiers_number 
      AND m.soldier_moqf_batch_id = s.soldiers_batch_id

    WHERE $whereClause

    GROUP BY s.soldiers_number, s.soldiers_name, s.soldiers_k, s.soldiers_s, s.soldiers_f, s.soldiers_city

    HAVING "موقف امنى" IS NOT NULL 
       OR "موقف طبى فرع" IS NOT NULL 
       OR "موقف طبى مركز" IS NOT NULL 
       OR "موقف مهمات" IS NOT NULL 
       OR "موقف محو الاميه" IS NOT NULL 
       OR "موقف عقوبة" IS NOT NULL

    ORDER BY s.soldiers_k, s.soldiers_s, s.soldiers_f ASC
  ''');
  }

  Future<int> insertMoqf(Map<String, dynamic> data) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.insert('soldiers_moqf', data);
    } else {
      final columns = data.keys.join(', ');
      final values = data.values.map((v) => v is String ? "'$v'" : v).join(',');
      return await dbHelper.insertData(
        "INSERT INTO soldiers_moqf ($columns) VALUES ($values)",
      );
    }
  }

  Future<int> updateMoqf(int id, Map<String, dynamic> data) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.update(
        'soldiers_moqf',
        data,
        where: 'moqf_id = ?',
        whereArgs: [id],
      );
    } else {
      String setClause = data.entries
          .map((e) => "${e.key} = '${e.value}'")
          .join(',');
      return await dbHelper.updateData(
        "UPDATE soldiers_moqf SET $setClause WHERE moqf_id = $id",
      );
    }
  }

  Future<int> deleteMoqf(int id) async {
    if (AppMode.isServer) {
      final db = await dbHelper.db;
      return await db.delete(
        'soldiers_moqf',
        where: 'moqf_id = ?',
        whereArgs: [id],
      );
    } else {
      return await dbHelper.deleteData(
        "DELETE FROM soldiers_moqf WHERE moqf_id = $id",
      );
    }
  }

  Future<List<Map<String, dynamic>>> getSoldiersForCards(
    String batchId,
    List<String> katibaList,
  ) async {
    if (katibaList.isEmpty) return [];

    String inClause = katibaList.map((k) => "'$k'").join(',');

    return await dbHelper.readData('''
    SELECT s.*
    FROM soldiers_t AS s
    LEFT JOIN soldiers_moqf AS m
      ON m.moqf_soldiers_number = s.soldiers_number
     AND m.moqf_batch_id = s.soldiers_batch_id
    LEFT JOIN soldiers_sending AS send
      ON send.sending_soldiers_number = s.soldiers_number
     AND send.sending_batch_id = s.soldiers_batch_id
    WHERE s.soldiers_batch_id = '$batchId'
      AND s.soldiers_k IN ($inClause)
      AND m.moqf_id IS NULL 
      AND ( send.sending_id IS NULL
      OR send.sending_date IS NULL)
     
    ORDER BY s.soldiers_k
  ''');
  }

  Future<bool> checkIfMoqfExists(
    String soldierNumber,
    String date,
    String type,
  ) async {
    try {
      final sql =
          "SELECT 1 FROM soldiers_moqf WHERE moqf_number = '${soldierNumber.trim()}' AND moqf_date = '${date.trim()}' AND moqf_type = '${type.trim()}' LIMIT 1";
      final List<Map<String, dynamic>> result = await dbHelper.readData(sql);

      return result.isNotEmpty;
    } catch (e) {
      debugPrint("Error in checkIfMoqfExists: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> multiFilter(
    Map<String, List<String>> filters, {
    String orderBy = 'soldiers_unit_id',
    bool isAscending = true,
  }) async {
    if (currentBatchId == null) return [];

    final whereParts = <String>["s.soldiers_batch_id = '$currentBatchId'"];

    filters.forEach((col, values) {
      if (values.isEmpty) return;

      // ===============================
      // فلتر الحالة الاجتماعية
      // ===============================
      if (col == 'marital_status') {
        final formattedValues = values.map((v) => "'$v'").join(',');

        whereParts.add("""
      (
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM soldiers_wife w
                WHERE w.wife_soldiers_number = s.soldiers_number
                  AND w.wife_batch_id = s.soldiers_batch_id
            ) THEN 'متزوج'
            ELSE 'أعزب'
        END
      ) IN ($formattedValues)
      """);

        return;
      }

      // ===============================
      // فلتر حالة الإجازة
      // ===============================
      if (col == 'leave_status') {
        final formattedValues = values.map((v) => "'$v'").join(',');

        whereParts.add("""
      (
        CASE
            WHEN EXISTS (
                SELECT 1 FROM soldiers_leaves l
                WHERE l.leaves_soldiers_number = s.soldiers_number
                  AND l.leaves_batch_id = s.soldiers_batch_id
                  AND l.leave_end = 'حجز'
            ) THEN 'حجز'

            WHEN EXISTS (
                SELECT 1 FROM soldiers_leaves l
                WHERE l.leaves_soldiers_number = s.soldiers_number
                  AND l.leaves_batch_id = s.soldiers_batch_id
                  AND l.leave_end = 'غياب'
            ) THEN 'غياب'

            WHEN EXISTS (
                SELECT 1 FROM soldiers_leaves l
                WHERE l.leaves_soldiers_number = s.soldiers_number
                  AND l.leaves_batch_id = s.soldiers_batch_id
                  AND l.leave_end LIKE '____/__/__'
                  AND date(REPLACE(l.leave_end,'/','-')) > date('now')
            ) THEN 'إجازة'

            ELSE 'بدون'
        END
      ) IN ($formattedValues)
      """);

        return;
      }

      // ===============================
      // الفلاتر العادية
      // ===============================

      String tableAlias = "s";
      if (col.startsWith("moqf_")) tableAlias = "m";
      if (col.startsWith("sending_")) tableAlias = "send";
      if (col.startsWith("gift_")) tableAlias = "g";

      if (values.contains("بدون")) {
        final realValues = values.where((v) => v != "بدون").toList();
        if (realValues.isEmpty) {
          whereParts.add("$tableAlias.$col IS NULL");
        } else {
          final formattedValues = realValues.map((v) => "'$v'").join(',');
          whereParts.add(
            "($tableAlias.$col IN ($formattedValues) OR $tableAlias.$col IS NULL)",
          );
        }
      } else {
        final formattedValues = values.map((v) => "'$v'").join(',');
        whereParts.add("$tableAlias.$col IN ($formattedValues)");
      }
    });

    String sortDirection = isAscending ? "ASC" : "DESC";

    final fullSql =
        '''
SELECT * FROM (
   SELECT s.*, 
       COALESCE(m.moqf_date, 'بدون') AS moqf_date, 
       COALESCE(m.moqf_type, 'بدون') AS moqf_type, 
       COALESCE(m.moqf_note, 'بدون') AS moqf_note,
       COALESCE(send.sending_date, 'بدون') AS sending_date, 
       COALESCE(send.sending_area, 'بدون') AS sending_area,
       COALESCE(send.sending_note, 'بدون') AS sending_note,
       COALESCE(send.sending_father_area, 'بدون') AS sending_father_area,
       COALESCE(g.gift_type, 'بدون') AS gift_type,

       CASE 
           WHEN w.wife_soldiers_number IS NULL THEN 'أعزب'
           ELSE 'متزوج'
       END AS marital_status,

       CASE
           WHEN EXISTS (
               SELECT 1 FROM soldiers_leaves l
               WHERE l.leaves_soldiers_number = s.soldiers_number
                 AND l.leaves_batch_id = s.soldiers_batch_id
                 AND l.leave_end = 'حجز'
           ) THEN 'حجز'
           WHEN EXISTS (
               SELECT 1 FROM soldiers_leaves l
               WHERE l.leaves_soldiers_number = s.soldiers_number
                 AND l.leaves_batch_id = s.soldiers_batch_id
                 AND l.leave_end = 'غياب'
           ) THEN 'غياب'
           WHEN EXISTS (
               SELECT 1 FROM soldiers_leaves l
               WHERE l.leaves_soldiers_number = s.soldiers_number
                 AND l.leaves_batch_id = s.soldiers_batch_id
                 AND l.leave_end LIKE '____/__/__'
                 AND date(REPLACE(l.leave_end,'/','-')) > date('now')
           ) THEN 'إجازة'
           ELSE 'بدون'
       END AS leave_status

   FROM soldiers_t AS s
   LEFT JOIN soldiers_moqf AS m 
       ON m.moqf_soldiers_number = s.soldiers_number 
      AND m.moqf_batch_id = s.soldiers_batch_id
   LEFT JOIN soldiers_sending AS send 
       ON send.sending_soldiers_number = s.soldiers_number 
      AND send.sending_batch_id = s.soldiers_batch_id
   LEFT JOIN soldiers_gift AS g 
       ON g.gift_soldiers_number = s.soldiers_number 
      AND g.gift_batch_id = s.soldiers_batch_id
   LEFT JOIN soldiers_wife AS w
       ON w.wife_soldiers_number = s.soldiers_number
      AND w.wife_batch_id = s.soldiers_batch_id
   WHERE ${whereParts.join(' AND ')}
)
ORDER BY $orderBy $sortDirection
''';

    return await dbHelper.readData(fullSql);
  }
}

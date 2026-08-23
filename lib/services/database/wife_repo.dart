import 'package:flutter_application_1/services/database/db_helper.dart';

class WifeRepository {
  final SqlDb db;

  WifeRepository(this.db);

  Future<List<Map<String, dynamic>>> getAllSoldiers(String batchId) async {
    return await db.readData('''
      SELECT *
      FROM soldiers_t 
      WHERE soldiers_batch_id = $batchId
      ORDER BY soldiers_name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getWivesWithSoldierDetails(
    String batchId,
  ) async {
    return await db.readData('''
      SELECT 
        w.*, *,
        s.soldiers_name as husband_name, 
        s.soldiers_k as battalion,
        s.soldiers_number as military_number
      FROM soldiers_wife w
      INNER JOIN soldiers_t s ON w.wife_soldiers_number = s.soldiers_number
      WHERE w.wife_batch_id = $batchId
      ORDER BY w.wife_id DESC
    ''');
  }

  Future<List<String>> getUniqueBattalions() async {
    final res = await db.readData('''
    SELECT DISTINCT soldiers_k 
    FROM soldiers_t 
    WHERE soldiers_k IS NOT NULL AND soldiers_k != ''
    ORDER BY soldiers_k ASC
  ''');

    List<String> battalions = res
        .map((e) => e['soldiers_k'].toString())
        .toList();
    battalions.insert(0, "الكل");
    return battalions;
  }

  Future<void> insertWife({
    required String soldierNumber,
    required int batchId,
    required String name,
    required String nationalNumber,
    required String marriedDate,
    required String marriedCardId,
    String? note,
  }) async {
    await db.insertData('''
      INSERT INTO soldiers_wife (
        wife_soldiers_number, 
        wife_batch_id, 
        wife_name, 
        wife_national_number, 
        wife_married_date, 
        wife_married_card_id, 
        wife_married_note
      ) VALUES (
        '$soldierNumber', 
        $batchId, 
        '${name.trim()}', 
        '${nationalNumber.trim()}', 
        '$marriedDate', 
        '$marriedCardId', 
        '${note ?? ""}'
      )
    ''');
  }

  Future<void> updateWife({
    required int wifeId,
    required String soldierNumber,
    required String name,
    required String nationalNumber,
    required String marriedDate,
    required String marriedCardId,
    String? note,
  }) async {
    await db.updateData('''
      UPDATE soldiers_wife
      SET 
        wife_soldiers_number = '$soldierNumber',
        wife_name = '${name.trim()}',
        wife_national_number = '${nationalNumber.trim()}',
        wife_married_date = '$marriedDate',
        wife_married_card_id = '$marriedCardId',
        wife_married_note = '${note ?? ""}'
      WHERE wife_id = $wifeId
    ''');
  }

  Future<void> deleteWife(int wifeId) async {
    await db.deleteData('''
      DELETE FROM soldiers_wife
      WHERE wife_id = $wifeId
    ''');
  }

  Future<bool> wifeExists(String nationalNumber) async {
    final res = await db.readData('''
      SELECT wife_id FROM soldiers_wife
      WHERE wife_national_number = '${nationalNumber.trim()}'
      LIMIT 1
    ''');
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getWivesCountByBattalion(
    String batchId,
  ) async {
    return await db.readData('''
      SELECT s.soldiers_k as battalion, COUNT(w.wife_id) as count
      FROM soldiers_wife w
      INNER JOIN soldiers_t s ON w.wife_soldiers_number = s.soldiers_number
      WHERE w.wife_batch_id = $batchId
      GROUP BY s.soldiers_k
    ''');
  }
}

import 'package:flutter_application_1/services/database/db_helper.dart';
//import 'package:intl/intl.dart';

class GiftRepository {
  final SqlDb db;

  GiftRepository(this.db);

  // ----------------------------
  // Soldiers
  // ----------------------------
  Future<List<Map<String, dynamic>>> getAllSoldiers(String batchId) async {
    return await db.readData('''
      SELECT *
      FROM soldiers_t
      WHERE soldiers_batch_id = $batchId
      ORDER BY soldiers_name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> searchSoldierByNumberOrTriple(
    String value,
    String batchId,
  ) async {
    return await db.readData('''
      SELECT *
      FROM soldiers_t
      WHERE soldiers_batch_id = $batchId
        AND (soldiers_number = '$value'
         OR soldiers_triple_number = '$value')
      LIMIT 1
    ''');
  }

  // ----------------------------
  // Gifts
  // ----------------------------
  // مثال لتعديل الاستعلام ليكون أكثر أماناً ودقة
  Future<List<Map<String, dynamic>>> getGiftsByBatch(String batchId) async {
    return await db.readData('''
    SELECT 
      g.gift_id,
      g.gift_note, 
      g.gift_type,
      s.soldiers_name,
      s.soldiers_number,
      s.soldiers_k,
      s.soldiers_s,
      s.soldiers_f,
      s.soldiers_city,
      g.gift_date
    FROM soldiers_gift g
    INNER JOIN soldiers_t s
      ON s.soldiers_number = g.gift_soldiers_number
      AND s.soldiers_batch_id = g.gift_batch_id
    WHERE g.gift_batch_id = '$batchId' 
    ORDER BY g.gift_id ASC
  ''');
  }

  Future<bool> giftExists(String soldierNumber, String batchId) async {
    final res = await db.readData('''
      SELECT gift_id
      FROM soldiers_gift
      WHERE gift_soldiers_number = '$soldierNumber'
        AND gift_batch_id = $batchId
      LIMIT 1
    ''');
    return res.isNotEmpty;
  }

  Future<void> insertGift({
    required String soldierNumber,
    required String batchId,
    required String giftType,
    required String giftNote,
    required String giftdate,
  }) async {
    await db.insertData('''
      INSERT INTO soldiers_gift
      (gift_soldiers_number, gift_batch_id, gift_type,gift_note,gift_date)
      VALUES ('$soldierNumber', $batchId, '$giftType' , '$giftNote','$giftdate')
    ''');
  }

  // date اختياري: لو null التاريخ القديم يفضل زي ما هو.
  Future<void> updateGift(int giftId, String type, {String? date}) async {
    final dateSet = date == null ? '' : ", gift_date = '$date'";
    await db.updateData('''
      UPDATE soldiers_gift
      SET gift_type = '$type'$dateSet
      WHERE gift_id = $giftId
    ''');
  }

  Future<void> deleteGift(int giftId) async {
    await db.deleteData('''
      DELETE FROM soldiers_gift
      WHERE gift_id = $giftId
    ''');
  }

  // ----------------------------
  // Filters
  // ----------------------------
  Future<List<String>> getGiftTypes(String batchId) async {
    final res = await db.readData('''
      SELECT DISTINCT gift_type
      FROM soldiers_gift
      WHERE gift_batch_id = $batchId
      ORDER BY gift_type
    ''');
    return res.map((e) => e['gift_type'].toString()).toList();
  }

  Future<List<String>> getBattalions(String batchId) async {
    final res = await db.readData('''
      SELECT DISTINCT soldiers_k
      FROM soldiers_t
      WHERE soldiers_batch_id = $batchId
      ORDER BY soldiers_k
    ''');
    return res.map((e) => e['soldiers_k'].toString()).toList();
  }
}

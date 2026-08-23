import 'package:flutter_application_1/services/database/db_helper.dart';

class MedicalVisitsRepository {
  final SqlDb db;
  MedicalVisitsRepository(this.db);

  Future<List<Map<String, Object?>>> getVisits(String batchId) {
    return db.readData('''
      SELECT m.*, s.*
      FROM medical_visits m
      JOIN soldiers_t s 
        ON s.soldiers_number = m.visit_soldiers_number
      WHERE m.visit_batch_id = '$batchId'
      ORDER BY m.visit_date DESC
    ''');
  }

  Future<int> insertVisit(Map<String, dynamic> data) {
    // تم تغيير data['soldierNumber'] إلى data['visit_soldiers_number'] وهكذا للبقية
    return db.insertData('''
      INSERT INTO medical_visits (
        visit_soldiers_number,
        visit_batch_id,
        visit_date,
        visit_place,
        visit_type,
        visit_result,
        visit_complaint,
        visit_diagnosis,
        visit_notes
      ) VALUES (
        '${data['visit_soldiers_number']}',
        '${data['visit_batch_id']}',
        '${data['visit_date']}',
        '${data['visit_place']}',
        '${data['visit_type']}',
        '${data['visit_result']}',
        '${data['visit_complaint']}',
        '${data['visit_diagnosis']}',
        '${data['visit_notes']}'
      )
    ''');
  }

  Future<int> updateVisit(int id, Map<String, dynamic> data) {
    return db.updateData('''
      UPDATE medical_visits SET
        visit_date='${data['visit_date']}',
        visit_place='${data['visit_place']}',
        visit_type='${data['visit_type']}',
        visit_result='${data['visit_result']}',
        visit_complaint='${data[' visit_complaint']}',
        visit_diagnosis='${data['visit_diagnosis']}',
        visit_notes='${data['visit_notes']}'
      WHERE visit_id=$id
    ''');
  }

  Future<int> deleteVisit(int id) {
    return db.deleteData('DELETE FROM medical_visits WHERE visit_id=$id');
  }

  Future<List<Map<String, Object?>>> getSoldiers(String batchId) {
    return db.readData(
      "SELECT soldiers_number, soldiers_name FROM soldiers_t WHERE soldiers_batch_id='$batchId'",
    );
  }
}

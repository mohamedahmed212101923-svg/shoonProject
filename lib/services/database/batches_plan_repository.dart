import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:flutter_application_1/models/batch_plan_columns.dart';

class BatchPlanRepository {
  final SqlDb sqlDb;
  BatchPlanRepository(this.sqlDb);

  Future<Map<String, dynamic>?> getPlan(int batchId) async {
    final result = await sqlDb.readData(
      'SELECT * FROM batch_plan WHERE batch_id = $batchId LIMIT 1',
    );

    if (result.isNotEmpty) {
      Map<String, dynamic> plan = Map<String, dynamic>.from(result.first);

      plan.remove('batch_id');

      return plan;
    }
    return null;
  }

  Future<void> insertPlan(int batchId, Map<String, int> planData) async {
    final columns = batchPlanColumns.join(',');
    final values = batchPlanColumns.map((c) => planData[c] ?? 0).join(',');

    await sqlDb.insertData('''
      INSERT INTO batch_plan (batch_id, $columns)
      VALUES ($batchId, $values)
    ''');
  }

  Future<void> updatePlan(int batchId, Map<String, int> planData) async {
    final updates = batchPlanColumns
        .map((c) => "$c = ${planData[c] ?? 0}")
        .join(', ');

    await sqlDb.updateData('''
      UPDATE batch_plan
      SET $updates
      WHERE batch_id = $batchId
    ''');
  }

  Future<void> deletePlan(int batchId) async {
    await sqlDb.deleteData('DELETE FROM batch_plan WHERE batch_id = $batchId');
  }
}

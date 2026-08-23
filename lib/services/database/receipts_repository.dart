import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:flutter_application_1/models/batch_plan_columns.dart';

class ReceiptsRepository {
  final SqlDb sqlDb;
  ReceiptsRepository(this.sqlDb);

  // جلب كل إيصالات الاستلام لدفعة معينة
  Future<List<Map<String, dynamic>>> getReceiptsByBatch(int batchId) async {
    return await sqlDb.readData(
      'SELECT * FROM daily_receipts WHERE batch_id = $batchId ORDER BY receipt_id DESC',
    );
  }

  // حساب إجمالي ما تم استلامه فعلياً لكل عمود لدفعة معينة (لمقارنته بالمخطط)
  Future<Map<String, int>> getTotalReceivedForBatch(int batchId) async {
    final columnsSum = batchPlanColumns.map((c) => 'SUM($c) as $c').join(', ');
    final result = await sqlDb.readData(
      'SELECT $columnsSum FROM daily_receipts WHERE batch_id = $batchId',
    );

    Map<String, int> totals = {};
    if (result.isNotEmpty && result.first.values.first != null) {
      for (var col in batchPlanColumns) {
        totals[col] = (result.first[col] as num).toInt();
      }
    } else {
      for (var col in batchPlanColumns) {
        totals[col] = 0;
      }
    }
    return totals;
  }

  Future<void> insertReceipt(
    int batchId,
    String date,
    Map<String, int> data,
  ) async {
    final columns = ['batch_id', 'receipt_date', ...batchPlanColumns].join(',');
    final values = [
      batchId,
      "'$date'",
      ...batchPlanColumns.map((c) => data[c] ?? 0),
    ].join(',');

    await sqlDb.insertData(
      'INSERT INTO daily_receipts ($columns) VALUES ($values)',
    );
  }
}

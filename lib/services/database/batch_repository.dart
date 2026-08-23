import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:flutter_application_1/viewmodels/functions/format_date.dart';
import 'package:http/http.dart' as http;

const _dateColumns = [
  'soldiers_military_date',
  'soldiers_income_date',
  'soldiers_end_date',
  'soldiers_birth_date',
];

class BatchesRepository {
  final SqlDb sqlDb;
  BatchesRepository(this.sqlDb);

  /// =============================
  /// جلب كل الدفعات
  /// =============================
  Future<List<Map<String, dynamic>>> getAll() async {
    return await sqlDb.readData('SELECT * FROM batches ORDER BY batch_id DESC');
  }

  /// =============================
  /// جلب دفعة معينة بالـ ID
  /// =============================
  Future<Map<String, dynamic>?> getById(int id) async {
    final result = await sqlDb.readData(
      'SELECT * FROM batches WHERE batch_id = $id LIMIT 1',
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// =============================
  /// إضافة دفعة جديدة
  /// =============================
  Future<int> insertBatch(String name, String date) async {
    return await sqlDb.insertData('''
      INSERT INTO batches (batch_name, batch_start_date)
      VALUES ('$name', '$date')
    ''');
  }

  /// =============================
  /// تحديث دفعة موجودة
  /// =============================
  Future<void> updateBatch(int id, String name, String date) async {
    await sqlDb.updateData('''
      UPDATE batches
      SET batch_name = '$name',
          batch_start_date = '$date'
      WHERE batch_id = $id
    ''');
  }

  /// =============================
  /// حذف دفعة
  /// =============================
  Future<void> deleteBatch(int id) async {
    await sqlDb.deleteData('DELETE FROM batches WHERE batch_id = $id');
  }

  Future<void> _sendBatchImportToRemote(
    List<Map<String, dynamic>> dataList,
  ) async {
    try {
      final url = Uri.parse('http://${AppMode.serverIp}:8080/batch_import');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'data': dataList}),
          )
          .timeout(const Duration(minutes: 2));
      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? "فشل السيرفر في معالجة البيانات");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, String>>> importExcel(
    Uint8List fileBytes,
    String batchId,
  ) async {
    try {
      final result = await compute(_processExcelIsolate, {
        'fileBytes': fileBytes,
        'batchId': batchId,
        'columns': {
          'الرقم العسكرى': 'soldiers_number',
          'الإسـم': 'soldiers_name',
          'الكتيبة': 'soldiers_k',
          'السرية': 'soldiers_s',
          'الفصيلة': 'soldiers_f',
          'رقم السجل': 'soldiers_unit_id',
          'الرقم الثلاثى': 'soldiers_triple_number',
          'الإدارة': 'soldiers_management',
          'السلاح': 'soldiers_weapon',
          'الاتجاه': 'soldiers_direction',
          'المحافظة': 'soldiers_city',
          'العنوان': 'soldiers_address',
          'منطقة التجنيد': 'soldiers_area',
          'المؤهل': 'soldiers_qualification',
          'التخصص': 'soldiers_specialization',
          'سنة زيادة': 'soldiers_plus_year',
          'تاريخ التجنيد': 'soldiers_military_date',
          'تاريخ الضم': 'soldiers_income_date',
          'تاريخ التسريح': 'soldiers_end_date',
          'تاريخ الميلاد': 'soldiers_birth_date',
          'الرقم القومى': 'soldiers_national_number',
          'الديانة': 'soldiers_religion',
          'فصيلة الدم': 'soldiers_blood_type',
          'اقرب الاقارب': 'soldiers_father_name',
          'المهنة': 'soldiers_job',
        },
        'dateColumns': _dateColumns,
      });
      final List<Map<String, dynamic>> rowsToUpload =
          List<Map<String, dynamic>>.from(result['upload']);

      final List<Map<String, String>> failedRows =
          List<Map<String, String>>.from(result['failed']);

      if (rowsToUpload.isNotEmpty) {
        if (AppMode.isServer) {
          await sqlDb.batchImport(rowsToUpload);
          final database = await sqlDb.db;
          await database.execute('PRAGMA wal_checkpoint(FULL);');
        } else {
          await _sendBatchImportToRemote(rowsToUpload);
        }
      }

      return failedRows;
    } catch (e) {
      debugPrint("IMPORT ERROR: $e");
      return [
        {'row': '0', 'name': 'خطأ عام', 'reason': e.toString()},
      ];
    }
  }
}

Future<Map<String, dynamic>> _processExcelIsolate(
  Map<String, dynamic> params,
) async {
  try {
    final Uint8List fileBytes = params['fileBytes'];
    final String batchId = params['batchId'];
    final Map<String, String> excelToDbColumns = params['columns'];
    final List<String> dateColumns = params['dateColumns'];

    // --- Helpers ---
    String cleanText(String? text) => text?.replaceAll('ـ', '').trim() ?? '';

    String localUnifyCode(String value, String prefix) {
      final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
      return numbers.isEmpty ? '' : '$prefix$numbers';
    }

    dynamic normalizeDateValue(dynamic value) {
      if (value is num) {
        // Excel serial date
        return DateTime(1899, 12, 30).add(Duration(days: value.toInt()));
      }
      return value;
    }

    final excel = Excel.decodeBytes(fileBytes);
    if (excel.tables.isEmpty) return {'failed': [], 'upload': []};
    final sheet = excel.tables.values.first;
    final header = sheet.rows.first
        .map((e) => cleanText(e?.value?.toString()))
        .toList();
    final columnIndex = {for (int i = 0; i < header.length; i++) header[i]: i};

    List<Map<String, String>> failedRows = [];
    List<Map<String, dynamic>> rowsToUpload = [];

    // --- Process Rows ---
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final displayRow = (i + 1).toString();

      // تخطي الصفوف الفارغة تماماً
      if (row.isEmpty ||
          row.every((cell) => cell == null || cell.value == null)) {
        continue;
      }

      Map<String, dynamic> rowData = {'soldiers_batch_id': batchId};

      bool skipRow = false;
      String currentName = 'غير معروف';

      for (final entry in excelToDbColumns.entries) {
        final excelColArabic = entry.key;
        final dbColName = entry.value;
        final cleanExcelCol = cleanText(excelColArabic);

        // 1️⃣ التحقق من وجود العمود
        if (!columnIndex.containsKey(cleanExcelCol)) {
          failedRows.add({
            'row': displayRow,
            'name': 'نقص ملف',
            'reason': 'عمود ($excelColArabic) غير موجود في الإكسل',
          });
          skipRow = true;
          break;
        }

        final cellIdx = columnIndex[cleanExcelCol]!;
        final cell = cellIdx < row.length ? row[cellIdx] : null;
        final rawValue = cell?.value?.toString().trim() ?? '';

        if (dbColName == 'soldiers_name' && rawValue.isNotEmpty) {
          currentName = rawValue;
        }

        // 2️⃣ الخلية فاضية
        if (rawValue.isEmpty) {
          failedRows.add({
            'row': displayRow,
            'name': currentName,
            'reason': 'الخلية في عمود ($excelColArabic) فارغة',
          });
          skipRow = true;
          break;
        }

        if (dateColumns.contains(dbColName)) {
          final normalizedValue = normalizeDateValue(cell?.value);
          final formattedDate = formatDate(normalizedValue);

          if (formattedDate == null) {
            failedRows.add({
              'row': displayRow,
              'name': currentName,
              'reason': 'تنسيق التاريخ في ($excelColArabic) غير صحيح',
            });
            skipRow = true;
            break;
          }

          rowData[dbColName] = formattedDate;
        } else if (dbColName == 'soldiers_number') {
          if (!RegExp(r'^\d{5,}$').hasMatch(rawValue)) {
            failedRows.add({
              'row': displayRow,
              'name': currentName,
              'reason': 'الرقم العسكري غير صالح',
            });
            skipRow = true;
            break;
          }
          rowData[dbColName] = rawValue;
        } else if (dbColName == 'soldiers_city') {
          const validQualifications = [
            "القاهرة",
            "الإسكندرية",
            "بورسعيد",
            "السويس",
            "دمياط",
            "الدقهلية",
            "الشرقية",
            "القليوبية",
            "كفر الشيخ",
            "الغربية",
            "المنوفية",
            "البحيرة",
            "الإسماعيلية",
            "الجيزة",
            "بني سويف",
            "الفيوم",
            "المنيا",
            "أسيوط",
            "سوهاج",
            "قنا",
            "أسوان",
            "الأقصر",
            "البحر الأحمر",
            "الوادي الجديد",
            "مرسى مطروح",
            "شمال سيناء",
            "جنوب سيناء",
          ];

          if (!validQualifications.contains(rawValue)) {
            failedRows.add({
              'row': displayRow,
              'name': currentName,
              'reason': 'المحافظة ($rawValue) غير صحيح او ليس كما يجب ان يكون',
            });
            skipRow = true;
            break;
          }

          rowData[dbColName] = rawValue;
        } else if (dbColName == 'soldiers_qualification') {
          const validQualifications = ["عادة", "عليا", "متوسطة", "فوق متوسطة"];

          if (!validQualifications.contains(rawValue)) {
            failedRows.add({
              'row': displayRow,
              'name': currentName,
              'reason': 'المؤهل ($rawValue) غير صحيح او ليس كما يجب ان يكون',
            });
            skipRow = true;
            break;
          }

          rowData[dbColName] = rawValue;
        } else if (dbColName == 'soldiers_management') {
          const validQualifications = [
            "إدارة المهندسين",
            "إدارة الأشغال",
            "إدارة المساحة",
            "إدارة المياه",
          ];

          if (!validQualifications.contains(rawValue)) {
            failedRows.add({
              'row': displayRow,
              'name': currentName,
              'reason': 'الادارة ($rawValue) غير صحيح او ليس كما يجب ان يكون',
            });
            skipRow = true;
            break;
          }

          rowData[dbColName] = rawValue;
        } else if (dbColName == 'soldiers_weapon') {
          const validQualifications = [
            "المهندسون",
            "المهندسون بحرية",
            "المهندسون جوية",
            "حرفي مهندسين",
            "حرفي مهندسين بحرية",
            "حرفي مهندسين جوية",
            "مهني مهندسين",
            "مهني مهندسين بحرية",
            "مهني مهندسين جوية",

            "الأشغال",
            "الأشغال جوية",
            "الأشغال بحرية",
            "حرفي أشغال",
            "حرفي أشغال بحرية",
            "حرفي أشغال جوية",
            "مهني أشغال",
            "مهني أشغال بحرية",
            "مهني أشغال جوية",

            "المياه",
            "المياه بحرية",
            "المياه جوية",
            "مهني مياه",
            "مهني مياه بحرية",
            "مهني مياه جوية",

            "المساحة",
            "المساحة جوية",
            "المساحة بحرية",
            "مهني مساحة",
            "مهني مساحة جوية",
            "مهني مساحة بحرية",
          ];

          if (!validQualifications.contains(rawValue)) {
            failedRows.add({
              'row': displayRow,
              'name': currentName,
              'reason': 'السلاح ($rawValue) غير صحيح او ليس كما يجب ان يكون',
            });
            skipRow = true;
            break;
          }

          rowData[dbColName] = rawValue;
        } else if ([
          'soldiers_k',
          'soldiers_s',
          'soldiers_f',
        ].contains(dbColName)) {
          final prefix = dbColName == 'soldiers_k'
              ? 'ك'
              : (dbColName == 'soldiers_s' ? 'س' : 'ف');
          rowData[dbColName] = localUnifyCode(rawValue, prefix);
        } else {
          rowData[dbColName] = rawValue;
        }
      }

      if (!skipRow) {
        rowsToUpload.add(rowData);
      }
    }

    return {'failed': failedRows, 'upload': rowsToUpload};
  } catch (e) {
    return {
      'failed': [
        {'row': '0', 'name': 'خطأ غير متوقع', 'reason': e.toString()},
      ],
      'upload': [],
    };
  }
}

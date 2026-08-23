import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:http/http.dart' as http;

class SqlDb {
  static SqlDb? _instance;
  static Database? _db;

  // Constructor الخاص
  SqlDb._privateConstructor();

  // Singleton Instance
  factory SqlDb() {
    _instance ??= SqlDb._privateConstructor();
    return _instance!;
  }

  // الحصول على قاعدة البيانات (للسيرفر فقط)
  // الحصول على قاعدة البيانات
  Future<Database> get db async {
    // إذا كانت القاعدة مفتوحة بالفعل
    if (_db != null) return _db!;
    // [تعديل] إذا كان وضع الكلينت، نمنع الوصول للملف المحلي نهائياً
    if (!AppMode.isServer) {
      // بدلاً من رمي خطأ يغلق البرنامج، نطبع تحذير ونرجع Exception مخصص
      // يتم معالجته داخل الـ Repository
      if (kDebugMode) {
        print("🚫 وضع الكلينت: تم حظر محاولة الوصول لملف SQLite المحلي.");
      }
      throw Exception('REMOTE_ACCESS_REQUIRED');
    }

    // --- كود السيرفر فقط يبدأ من هنا ---
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    String databasePath = await getDatabasesPath();
    String path = join(databasePath, "data.db");

    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _db!;
  }

  // أضف هذه الدالة داخل كلاس SqlDb لدعم العمليات الجماعية
  Future<List<dynamic>> batchInsert(List<String> sqlStatements) async {
    if (AppMode.isServer) {
      final dbClient = await db;
      // تنفيذ العمليات كمجموعة واحدة يمنع حدوث Lock متكرر
      return await dbClient.transaction((txn) async {
        var batch = txn.batch();
        for (var sql in sqlStatements) {
          batch.rawInsert(sql);
        }
        return await batch.commit();
      });
    } else {
      // في الكلينت يتم إرسال قائمة الـ SQL للسيرفر (تحتاج لتعديل في API السيرفر لاستقبال List)
      final result = await _sendToRemoteServer(
        jsonEncode(sqlStatements),
        'batch',
      );
      return result as List<dynamic>;
    }
  } // داخل كلاس SqlDb

  Future<void> checkpoint() async {
    // التحقق من أننا في وضع السيرفر وأن قاعدة البيانات مفتوحة
    if (AppMode.isServer) {
      try {
        // نستخدم _db مباشرة إذا كان مفتوحاً لتجنب استدعاء الـ getter الذي قد يحتوي على منطق إضافي
        if (_db != null && _db!.isOpen) {
          await _db!.execute('PRAGMA wal_checkpoint(FULL);');
          if (kDebugMode) {
            print(
              "✅ SQLite Checkpoint: تم دمج ملف الـ WAL في الملف الأصلي بنجاح.",
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ خطأ أثناء تنفيذ Checkpoint: $e");
        }
      }
    } else {
      if (kDebugMode) {
        print("ℹ️ Checkpoint تجاهل: التطبيق يعمل في وضع الكلينت.");
      }
    }
  }

  // تحسين دالة _onConfigure لزيادة الأداء
  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA busy_timeout = 10000'); // زيادة لـ 10 ثواني للأمان
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute(
      'PRAGMA synchronous = NORMAL',
    ); // تحسين سرعة الكتابة مع ضمان الأمان
  }

  // [⭐ تعديل جوهري] دالة جديدة تماماً للحفظ الجماعي السريع
  Future<void> batchImport(List<Map<String, dynamic>> dataList) async {
    final dbClient = await db;

    await dbClient.transaction((txn) async {
      for (final data in dataList) {
        final soldierNumber = data['soldiers_number'];
        final batchId = data['soldiers_batch_id'];

        if (soldierNumber == null || batchId == null) {
          if (kDebugMode) {
            print(
              "⚠️ تجاهل سجل بسبب Missing soldiers_number أو soldiers_batch_id: $data",
            );
          }
          continue; // ننتقل للسطر التالي بدل ما يحصل خطأ
        }

        // ✅ البحث عن المجند بنفس الرقم العسكري داخل نفس الدفعة
        final updated = await txn.update(
          'soldiers_t',
          data,
          where: 'soldiers_number = ? AND soldiers_batch_id = ?',
          whereArgs: [soldierNumber, batchId],
        );

        if (updated == 0) {
          // إذا لم يوجد سجل بنفس الرقم العسكري داخل الدفعة → نضيف سجل جديد
          await txn.insert('soldiers_t', data);
        }
      }
    });
  }

  // ------------------------------------------------------------------
  // دالة الإرسال للسيرفر (تستخدم في وضع الكلينت فقط)
  // ------------------------------------------------------------------
  Future<dynamic> _sendToRemoteServer(String sql, String type) async {
    try {
      final url = Uri.parse('http://${AppMode.serverIp}:8080/raw_query');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sql': sql, 'type': type}),
          )
          .timeout(
            const Duration(seconds: 15),
          ); // 💡 زيادة وقت الانتظار قليلاً للشبكة

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("فشل الاتصال: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> readData(String sql) async {
    if (AppMode.isServer) {
      final dbClient = await db;
      return await dbClient.rawQuery(sql);
    } else {
      final result = await _sendToRemoteServer(sql, 'select');
      // تحويل النتيجة القادمة من JSON إلى التنسيق المطلوب
      return List<Map<String, Object?>>.from(result);
    }
  }

  Future<int> insertData(String sql) async {
    if (AppMode.isServer) {
      final dbClient = await db;
      return await dbClient.transaction((txn) async {
        return await txn.rawInsert(sql);
      });
    } else {
      final result = await _sendToRemoteServer(sql, 'insert');
      return result as int;
    }
  }

  Future<int> updateData(String sql) async {
    if (AppMode.isServer) {
      final dbClient = await db;
      return await dbClient.rawUpdate(sql);
    } else {
      final result = await _sendToRemoteServer(sql, 'update');
      return result as int;
    }
  }

  Future<int> deleteData(String sql) async {
    if (AppMode.isServer) {
      final dbClient = await db;
      await dbClient.execute('PRAGMA foreign_keys = ON');
      return await dbClient.rawDelete(sql);
    } else {
      final result = await _sendToRemoteServer(sql, 'delete');
      return result as int;
    }
  }

  // ------------------------------------------------------------------
  // إعدادات الجداول والتهيئة (تعمل على السيرفر فقط)
  // ------------------------------------------------------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute(''' CREATE TABLE batches (
  batch_id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_name TEXT NOT NULL,
  batch_start_date TEXT NOT NULL,
  batch_status TEXT DEFAULT 'open'
);
 ''');
    await db.execute('''
CREATE TABLE batch_plan (
  batch_id INTEGER PRIMARY KEY,

  -- HIGH
  high_eng_base INTEGER DEFAULT 0,
  high_eng_ground INTEGER DEFAULT 0,
  high_eng_naval INTEGER DEFAULT 0,
  high_water_base INTEGER DEFAULT 0,
  high_water_ground INTEGER DEFAULT 0,
  high_water_naval INTEGER DEFAULT 0,
  high_survey_base INTEGER DEFAULT 0,
  high_survey_ground INTEGER DEFAULT 0,
  high_survey_naval INTEGER DEFAULT 0,
  high_works_base INTEGER DEFAULT 0,
  high_works_ground INTEGER DEFAULT 0,
  high_works_naval INTEGER DEFAULT 0,

  -- ABOVE MID
  above_mid_eng_base INTEGER DEFAULT 0,
  above_mid_eng_ground INTEGER DEFAULT 0,
  above_mid_eng_naval INTEGER DEFAULT 0,
  above_mid_water_base INTEGER DEFAULT 0,
  above_mid_water_ground INTEGER DEFAULT 0,
  above_mid_water_naval INTEGER DEFAULT 0,
  above_mid_survey_base INTEGER DEFAULT 0,
  above_mid_survey_ground INTEGER DEFAULT 0,
  above_mid_survey_naval INTEGER DEFAULT 0,
  above_mid_works_base INTEGER DEFAULT 0,
  above_mid_works_ground INTEGER DEFAULT 0,
  above_mid_works_naval INTEGER DEFAULT 0,

  -- NORMAL
  normal_eng_base INTEGER DEFAULT 0,
  normal_eng_ground INTEGER DEFAULT 0,
  normal_eng_naval INTEGER DEFAULT 0,
  normal_water_base INTEGER DEFAULT 0,
  normal_water_ground INTEGER DEFAULT 0,
  normal_water_naval INTEGER DEFAULT 0,
  normal_survey_base INTEGER DEFAULT 0,
  normal_survey_ground INTEGER DEFAULT 0,
  normal_survey_naval INTEGER DEFAULT 0,
  normal_works_base INTEGER DEFAULT 0,
  normal_works_ground INTEGER DEFAULT 0,
  normal_works_naval INTEGER DEFAULT 0,

  -- MID / PROFESSIONAL
  mid_prof_eng_base INTEGER DEFAULT 0,
  mid_prof_eng_ground INTEGER DEFAULT 0,
  mid_prof_eng_naval INTEGER DEFAULT 0,
  mid_prof_water_base INTEGER DEFAULT 0,
  mid_prof_water_ground INTEGER DEFAULT 0,
  mid_prof_water_naval INTEGER DEFAULT 0,
  mid_prof_survey_base INTEGER DEFAULT 0,
  mid_prof_survey_ground INTEGER DEFAULT 0,
  mid_prof_survey_naval INTEGER DEFAULT 0,
  mid_prof_works_base INTEGER DEFAULT 0,
  mid_prof_works_ground INTEGER DEFAULT 0,
  mid_prof_works_naval INTEGER DEFAULT 0,

  -- MID / SKILLED
  mid_skill_eng_base INTEGER DEFAULT 0,
  mid_skill_eng_ground INTEGER DEFAULT 0,
  mid_skill_eng_naval INTEGER DEFAULT 0,
  mid_skill_water_base INTEGER DEFAULT 0,
  mid_skill_water_ground INTEGER DEFAULT 0,
  mid_skill_water_naval INTEGER DEFAULT 0,
  mid_skill_survey_base INTEGER DEFAULT 0,
  mid_skill_survey_ground INTEGER DEFAULT 0,
  mid_skill_survey_naval INTEGER DEFAULT 0,
  mid_skill_works_base INTEGER DEFAULT 0,
  mid_skill_works_ground INTEGER DEFAULT 0,
  mid_skill_works_naval INTEGER DEFAULT 0,

  FOREIGN KEY (batch_id) REFERENCES batches(batch_id) ON DELETE CASCADE ON UPDATE CASCADE
);


 ''');
    await db.execute('''
CREATE TABLE daily_receipts (
  receipt_id INTEGER PRIMARY KEY AUTOINCREMENT,
  batch_id INTEGER NOT NULL,
  receipt_date TEXT NOT NULL,

  -- نفس الـ 60 عمود
  high_eng_base INTEGER DEFAULT 0,
  high_eng_ground INTEGER DEFAULT 0,
  high_eng_naval INTEGER DEFAULT 0,
  high_water_base INTEGER DEFAULT 0,
  high_water_ground INTEGER DEFAULT 0,
  high_water_naval INTEGER DEFAULT 0,
  high_survey_base INTEGER DEFAULT 0,
  high_survey_ground INTEGER DEFAULT 0,
  high_survey_naval INTEGER DEFAULT 0,
  high_works_base INTEGER DEFAULT 0,
  high_works_ground INTEGER DEFAULT 0,
  high_works_naval INTEGER DEFAULT 0,

  above_mid_eng_base INTEGER DEFAULT 0,
  above_mid_eng_ground INTEGER DEFAULT 0,
  above_mid_eng_naval INTEGER DEFAULT 0,
  above_mid_water_base INTEGER DEFAULT 0,
  above_mid_water_ground INTEGER DEFAULT 0,
  above_mid_water_naval INTEGER DEFAULT 0,
  above_mid_survey_base INTEGER DEFAULT 0,
  above_mid_survey_ground INTEGER DEFAULT 0,
  above_mid_survey_naval INTEGER DEFAULT 0,
  above_mid_works_base INTEGER DEFAULT 0,
  above_mid_works_ground INTEGER DEFAULT 0,
  above_mid_works_naval INTEGER DEFAULT 0,

  normal_eng_base INTEGER DEFAULT 0,
  normal_eng_ground INTEGER DEFAULT 0,
  normal_eng_naval INTEGER DEFAULT 0,
  normal_water_base INTEGER DEFAULT 0,
  normal_water_ground INTEGER DEFAULT 0,
  normal_water_naval INTEGER DEFAULT 0,
  normal_survey_base INTEGER DEFAULT 0,
  normal_survey_ground INTEGER DEFAULT 0,
  normal_survey_naval INTEGER DEFAULT 0,
  normal_works_base INTEGER DEFAULT 0,
  normal_works_ground INTEGER DEFAULT 0,
  normal_works_naval INTEGER DEFAULT 0,

  mid_prof_eng_base INTEGER DEFAULT 0,
  mid_prof_eng_ground INTEGER DEFAULT 0,
  mid_prof_eng_naval INTEGER DEFAULT 0,
  mid_prof_water_base INTEGER DEFAULT 0,
  mid_prof_water_ground INTEGER DEFAULT 0,
  mid_prof_water_naval INTEGER DEFAULT 0,
  mid_prof_survey_base INTEGER DEFAULT 0,
  mid_prof_survey_ground INTEGER DEFAULT 0,
  mid_prof_survey_naval INTEGER DEFAULT 0,
  mid_prof_works_base INTEGER DEFAULT 0,
  mid_prof_works_ground INTEGER DEFAULT 0,
  mid_prof_works_naval INTEGER DEFAULT 0,

  mid_skill_eng_base INTEGER DEFAULT 0,
  mid_skill_eng_ground INTEGER DEFAULT 0,
  mid_skill_eng_naval INTEGER DEFAULT 0,
  mid_skill_water_base INTEGER DEFAULT 0,
  mid_skill_water_ground INTEGER DEFAULT 0,
  mid_skill_water_naval INTEGER DEFAULT 0,
  mid_skill_survey_base INTEGER DEFAULT 0,
  mid_skill_survey_ground INTEGER DEFAULT 0,
  mid_skill_survey_naval INTEGER DEFAULT 0,
  mid_skill_works_base INTEGER DEFAULT 0,
  mid_skill_works_ground INTEGER DEFAULT 0,
  mid_skill_works_naval INTEGER DEFAULT 0,

  FOREIGN KEY (batch_id) REFERENCES batches(batch_id) ON DELETE CASCADE ON UPDATE CASCADE
);


 ''');

    await db.execute('''
      CREATE TABLE soldiers_t(
        soldiers_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        soldiers_unit_id INTEGER NOT NULL,
        soldiers_batch_id INTEGER NOT NULL, 
        soldiers_name TEXT NOT NULL,
        soldiers_father_name TEXT,
        soldiers_number TEXT NOT NULL UNIQUE CHECK(length(soldiers_number) = 13), 
        soldiers_k TEXT NOT NULL, 
        soldiers_s TEXT NOT NULL, 
        soldiers_f TEXT NOT NULL,
        soldiers_triple_number TEXT NOT NULL UNIQUE,
        soldiers_management TEXT NOT NULL, 
        soldiers_weapon TEXT NOT NULL,
        soldiers_direction TEXT NOT NULL,
        soldiers_city TEXT NOT NULL,
        soldiers_address TEXT NOT NULL,
        soldiers_area TEXT NOT NULL,
        soldiers_qualification TEXT NOT NULL,
        soldiers_specialization TEXT NOT NULL,
        soldiers_plus_year TEXT NOT NULL,
        soldiers_military_date TEXT NOT NULL,
        soldiers_income_date TEXT NOT NULL,
        soldiers_end_date TEXT NOT NULL,
        soldiers_birth_date TEXT NOT NULL,
        soldiers_national_number TEXT NOT NULL UNIQUE CHECK(length(soldiers_national_number) = 14), 
        soldiers_religion TEXT NOT NULL,
        soldiers_blood_type TEXT NOT NULL,
        soldiers_job TEXT,
        FOREIGN KEY (soldiers_batch_id) REFERENCES batches(batch_id) ON DELETE CASCADE ON UPDATE CASCADE,
        UNIQUE (soldiers_name, soldiers_number, soldiers_national_number)
      );
    ''');
    await db.execute('''
CREATE TABLE soldiers_leaves (
  soldiers_leaves_id INTEGER PRIMARY KEY AUTOINCREMENT,
  leaves_soldiers_number TEXT NOT NULL,
  leaves_batch_id INTEGER NOT NULL,
  leave_start TEXT NOT NULL,
  leave_end TEXT NOT NULL,
  leave_reason TEXT,
 leave_note TEXT,
  UNIQUE (leaves_soldiers_number, leave_start, leave_end),
  FOREIGN KEY (leaves_soldiers_number)
    REFERENCES soldiers_t (soldiers_number)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (leaves_batch_id)
    REFERENCES batches (batch_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

    ''');

    await db.execute('''
CREATE TABLE soldiers_moqf (
  moqf_id INTEGER PRIMARY KEY AUTOINCREMENT,
  moqf_soldiers_number TEXT NOT NULL UNIQUE,
  moqf_batch_id INTEGER NOT NULL,
  moqf_date TEXT NOT NULL,
  moqf_type TEXT NOT NULL,
  moqf_note TEXT,

  FOREIGN KEY (moqf_soldiers_number)
    REFERENCES soldiers_t (soldiers_number)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (moqf_batch_id)
    REFERENCES batches (batch_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);


    ''');
    await db.execute(''' 
    CREATE TABLE medical_visits (
  visit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  visit_soldiers_number TEXT NOT NULL ,
  visit_batch_id INTEGER NOT NULL,
  visit_date TEXT NOT NULL,
  visit_place TEXT NOT NULL,              
  visit_type TEXT NOT NULL,
  visit_result TEXT NOT NULL,                    
  visit_complaint TEXT,
  visit_diagnosis TEXT,
  visit_notes TEXT,
  next_visit_date TEXT,

  FOREIGN KEY (visit_soldiers_number)
    REFERENCES soldiers_t(soldiers_number)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

  FOREIGN KEY (visit_batch_id)
    REFERENCES batches(batch_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

    ''');

    await db.execute('''
CREATE TABLE soldier_moqf (
  soldier_moqf_id INTEGER PRIMARY KEY AUTOINCREMENT,
  soldier_moqf_soldiers_number TEXT NOT NULL ,
  soldier_moqf_batch_id INTEGER NOT NULL,
  soldier_moqf_date TEXT NOT NULL,
  soldier_moqf_type TEXT NOT NULL,
  soldier_moqf_note TEXT,

  FOREIGN KEY (soldier_moqf_soldiers_number)
    REFERENCES soldiers_t (soldiers_number)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (soldier_moqf_batch_id)
    REFERENCES batches (batch_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);


    ''');

    await db.execute('''
CREATE TABLE soldiers_sending (
  sending_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sending_soldiers_number TEXT NOT NULL UNIQUE,
  sending_batch_id INTEGER NOT NULL,
  sending_date TEXT,
  sending_note TEXT,
  sending_area TEXT NOT NULL,
  sending_father_area TEXT,

  FOREIGN KEY (sending_soldiers_number)
    REFERENCES soldiers_t (soldiers_number)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (sending_batch_id)
    REFERENCES batches (batch_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);


    ''');

    await db.execute('''
CREATE TABLE soldiers_gift (
  gift_id INTEGER PRIMARY KEY AUTOINCREMENT,
  gift_soldiers_number TEXT NOT NULL UNIQUE,
  gift_batch_id INTEGER NOT NULL,
  gift_type TEXT NOT NULL,
  gift_note TEXT,
  gift_date TEXT,
FOREIGN KEY (gift_soldiers_number)
    REFERENCES soldiers_t (soldiers_number)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (gift_batch_id)
    REFERENCES batches (batch_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

    ''');

    await db.execute('''
CREATE TABLE soldiers_wife (
 wife_id INTEGER PRIMARY KEY AUTOINCREMENT,
 wife_soldiers_number TEXT NOT NULL UNIQUE,
 wife_batch_id INTEGER NOT NULL,
 wife_name TEXT NOT NULL,
 wife_national_number TEXT NOT NULL UNIQUE CHECK(length(wife_national_number) = 14), 
 wife_married_date TEXT NOT NULL,
 wife_married_card_id TEXT NOT NULL,
 wife_married_note TEXT,

FOREIGN KEY (wife_soldiers_number)
    REFERENCES soldiers_t (soldiers_number)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (wife_batch_id)
    REFERENCES batches (batch_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

    ''');

    await db.execute(
      'CREATE TABLE tabaeia (tabaeia_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, tabaeia_name TEXT NOT NULL UNIQUE);',
    );
    await db.execute('''CREATE TABLE units (
      units_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      units_tabaeia_id INTEGER NOT NULL,
      units_name TEXT NOT NULL UNIQUE,
      FOREIGN KEY (units_tabaeia_id) REFERENCES tabaeia (tabaeia_id) ON DELETE CASCADE ON UPDATE CASCADE
      );''');

    await db.execute('''
CREATE TABLE soldier_notes (
  note_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  notes_soldiers_number TEXT NOT NULL UNIQUE,
  notes_batch_id INTEGER NOT NULL,
  note_date TEXT,
  note TEXT NOT NULL,

  FOREIGN KEY (notes_soldiers_number)
    REFERENCES soldiers_t (soldiers_number)
    ON DELETE CASCADE ON UPDATE CASCADE,

  FOREIGN KEY (notes_batch_id)
    REFERENCES batches (batch_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

    ''');

    await db.execute('''CREATE TABLE leader  (
     leader_id INTEGER PRIMARY KEY AUTOINCREMENT,
     leader_name TEXT NOT NULL,
     leader_rank TEXT NOT NULL,
     leader_posation TEXT NOT NULL

      );''');

    await db.execute('''
CREATE TABLE presentation_committees (
  committee_id INTEGER PRIMARY KEY AUTOINCREMENT,
  committee_batch_id integer NOT NULL,
  committee_date text NOT NULL,
  committee_order integer,
  committee_notes text,
FOREIGN KEY ( committee_batch_id ) REFERENCES batches ( batch_id ) ON DELETE CASCADE ON UPDATE CASCADE 
);
''');

    await db.execute('''
CREATE TABLE soldier_presentations (
  pres_id INTEGER PRIMARY KEY AUTOINCREMENT,
  pres_committee_id integer NOT NULL,
  pres_soldier_number NOT NULL,
  clinic_type TEXT NOT NULL,
  pres_result TEXT NOT NULL,
  pres_note TEXT NOT NULL,
  FOREIGN KEY ( pres_committee_id ) REFERENCES presentation_committees ( committee_id ) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY ( pres_soldier_number ) REFERENCES soldiers_t ( soldiers_number ) ON DELETE CASCADE ON UPDATE CASCADE 
)

''');

    await _executeSqlFromAssets(db, 'assets/sql/tabaeia.sql');
    await _executeSqlFromAssets(db, 'assets/sql/units.sql');
  }

  Future<void> _executeSqlFromAssets(Database db, String path) async {
    try {
      final sql = await rootBundle.loadString(path);
      final statements = sql.split(';');
      for (final stmt in statements) {
        if (stmt.trim().isNotEmpty) {
          await db.execute(stmt);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ خطأ في تحميل ملف SQL من الأصول: $e");
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> myDeleteDatabase() async {
    if (!AppMode.isServer) return;
    String databasePath = await getDatabasesPath();
    String path = join(databasePath, "data.db");
    await deleteDatabase(path);
    _db = null;
  }

  Future<void> closeData() async {
    if (_db != null && AppMode.isServer) {
      final dbClient = await db;
      await dbClient.close();
      _db = null;
    }
  }
}

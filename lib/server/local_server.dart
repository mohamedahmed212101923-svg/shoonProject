import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path_provider/path_provider.dart';

class LocalServer {
  static RandomAccessFile? _lockFileHandle;

  static Future<bool> start({
    required int port,
    required String lockFileName,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final lockFile = File('${tempDir.path}/$lockFileName.lock');

      _lockFileHandle = await lockFile.open(mode: FileMode.write);

      try {
        await _lockFileHandle!.lock(FileLock.exclusive);
      } catch (e) {
        if (kDebugMode) {
          print("📡 [$lockFileName] سيرفر هذا البرنامج يعمل بالفعل.");
        }
        await _lockFileHandle!.close();
        return false;
      }

      final db = SqlDb();
      final router = Router();

      // مسار استيراد البيانات
      router.post('/batch_import', (Request req) async {
        try {
          final payload = await req.readAsString();
          final body = jsonDecode(payload);
          final List<dynamic> data = body['data'];
          await db.batchImport(List<Map<String, dynamic>>.from(data));
          return Response.ok(
            jsonEncode({'status': 'success'}),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          );
        } catch (e) {
          return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
          );
        }
      });

      // مسار الاستعلامات العامة
      router.post('/raw_query', (Request req) async {
        try {
          final payload = await req.readAsString();
          final body = jsonDecode(payload);
          final dynamic sql = body['sql'];
          final String type = body['type'];
          dynamic result;

          if (type == 'batch' && sql is List) {
            result = await _executeBatch(db, List<String>.from(sql));
          } else {
            switch (type) {
              case 'select':
                result = await db.readData(sql);
                break;
              case 'insert':
                result = await db.insertData(sql);
                break;
              case 'update':
                result = await db.updateData(sql);
                break;
              case 'delete':
                result = await db.deleteData(sql);
                break;
              default:
                throw Exception("نوع العملية غير مدعوم");
            }
          }
          return Response.ok(
            jsonEncode(result),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Access-Control-Allow-Origin': '*',
            },
          );
        } catch (e) {
          return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
          );
        }
      });

      final pipeline = Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      final server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
        shared: false,
      );
      io.serveRequests(server, pipeline);

      if (kDebugMode) {
        print("🚀 سيرفر [$lockFileName] انطلق بنجاح على المنفذ: $port");
      }
      return true;
    } catch (e) {
      if (kDebugMode) print("❌ خطأ غير متوقع في سيرفر $lockFileName: $e");
      return false;
    }
  }

  static Future<List<dynamic>> _executeBatch(
    SqlDb sqlDb,
    List<String> queries,
  ) async {
    final database = await sqlDb.db;
    return await database.transaction((txn) async {
      final batch = txn.batch();
      for (var query in queries) {
        batch.execute(query);
      }
      return await batch.commit();
    });
  }
}

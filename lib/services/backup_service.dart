import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:flutter_application_1/services/database/db_helper.dart'; // تأكد من اسم الملف الصحيح لـ SqlDb
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class BackupService {
  static const _lastBackupKey = 'last_backup_date';
  static const _backupPathKey = 'backup_path';

  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastBackupKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> saveBackupDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, date.toIso8601String());
  }

  Future<String?> getSavedBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupPathKey);
  }

  Future<void> saveBackupPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupPathKey, path);
  }

  Future<bool> _isLastBackupFileExists(
    String folderPath,
    DateTime lastDate,
  ) async {
    final directory = Directory(folderPath);
    if (!await directory.exists()) return false;

    final dateString =
        "${lastDate.year}-${_pad(lastDate.month)}-${_pad(lastDate.day)}";

    try {
      final files = directory.listSync();
      return files.any(
        (file) =>
            file is File && basename(file.path).startsWith('data_$dateString'),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBackupRequired() async {
    final lastDate = await getLastBackupDate();
    final savedPath = await getSavedBackupPath();
    final now = DateTime.now();

    if (lastDate == null || savedPath == null) return true;

    // التحقق من اليوم (هل دخلنا في يوم جديد؟)
    bool isDifferentDay =
        now.year != lastDate.year ||
        now.month != lastDate.month ||
        now.day != lastDate.day;

    if (isDifferentDay) return true;

    // التحقق من وجود الملف في المجلد
    return !await _isLastBackupFileExists(savedPath, lastDate);
  }

  Future<File> createBackup({required String customPath}) async {
    if (AppMode.isServer) {
      try {
        // [هام] دمج بيانات الـ WAL قبل النسخ لضمان الحصول على آخر التعديلات
        await SqlDb().checkpoint();
      } catch (e) {
        if (kDebugMode) {
          print("⚠️ Checkpoint Error: $e");
        }
      }
    }

    final dbPath = join(await getDatabasesPath(), 'data.db');
    if (!File(dbPath).existsSync()) {
      throw Exception("قاعدة البيانات الأصلية مفقودة");
    }

    final backupDir = Directory(customPath);
    if (!await backupDir.exists()) await backupDir.create(recursive: true);

    final now = DateTime.now();
    final fileName =
        'data_${now.year}-${_pad(now.month)}-${_pad(now.day)}_${_pad(now.hour)}-${_pad(now.minute)}.db';
    final targetPath = join(backupDir.path, fileName);

    // عملية النسخ الفيزيائي
    final backupFile = await File(dbPath).copy(targetPath);

    await saveBackupDate(now);
    await saveBackupPath(customPath); // تحديث المسار المختار

    return backupFile;
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}

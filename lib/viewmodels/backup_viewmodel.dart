import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/app_mode.dart';
import '../../services/backup_service.dart';
import 'package:file_picker/file_picker.dart';

class BackupViewModel extends ChangeNotifier {
  final BackupService _service;
  bool backupRequired = false;
  bool isProcessing = false;
  String? backupPath;

  Timer? _autoCheckTimer;

  BackupViewModel(this._service) {
    // تقليل مدة الفحص لـ 15 دقيقة ليكون أكثر استجابة لتغير التاريخ أو حذف المجلد
    _startAutoTimer();
    checkBackupStatus();
  }

  Future<void> setBackupPath(String path) async {
    backupPath = path;
    await _service.saveBackupPath(path);
    notifyListeners();
  }

  /// الدالة الأساسية للفحص - تم تحديثها لتعالج فقدان المسار وتغير التاريخ
  // داخل BackupViewModel
  // داخل ملف BackupViewModel
  void _startAutoTimer() {
    _autoCheckTimer?.cancel();
    // أثناء التجربة اجعلها 10 ثوانٍ، وفي الطبيعي اجعلها دقيقة واحدة مثلاً
    _autoCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      checkBackupStatus();
    });
  }

  Future<void> checkBackupStatus() async {
    if (!AppMode.isServer) return;

    // 1. فحص المسار
    backupPath = await _service.getSavedBackupPath();
    bool isPathMissing = true;
    if (backupPath != null) {
      isPathMissing = !(await Directory(backupPath!).exists());
    }

    // 2. فحص التاريخ (مهم جداً للتعرف على اليوم الجديد)
    bool isDateExpired = await _service.isBackupRequired();

    // الحالة النهائية: لو التاريخ قديم أو المسار ممسوح
    bool finalStatus = isDateExpired || isPathMissing;

    // تحديث الشاشة فقط لو الحالة تغيرت
    if (backupRequired != finalStatus) {
      backupRequired = finalStatus;
      notifyListeners();
      debugPrint("🔔 تغيير الحالة إلى: $backupRequired");
    }
  }

  Future<void> checkBackupOnStartup() async {
    await checkBackupStatus();
  }

  /// دالة تنفيذ النسخ - تمنحك دائماً فرصة اختيار مسار جديد
  Future<void> performBackup() async {
    // 1. التحقق من صحة المسار الابتدائي قبل إرساله للـ Picker
    String? initialPath;
    if (backupPath != null) {
      final dir = Directory(backupPath!);
      if (await dir.exists()) {
        initialPath = backupPath;
      }
    }

    // 2. اختيار المجلد (الآن لن ينهار النظام إذا كان المجلد القديم مفقوداً)
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'تأكيد مسار حفظ النسخة الاحتياطية',
      initialDirectory: initialPath, // نمرر المسار فقط إذا كان موجوداً فعلياً
    );

    if (selectedDirectory == null) return;

    try {
      isProcessing = true;
      notifyListeners();

      // 3. تنفيذ النسخ
      await _service.createBackup(customPath: selectedDirectory);

      // تحديث البيانات المحلية بعد النجاح
      backupPath = selectedDirectory;
      backupRequired = false;

      debugPrint("✅ تم النسخ بنجاح في المسار المحدث: $selectedDirectory");
    } catch (e) {
      debugPrint("❌ خطأ أثناء النسخ: $e");
      // هنا يفضل إظهار رسالة خطأ للمستخدم (SnackBar)
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }
}

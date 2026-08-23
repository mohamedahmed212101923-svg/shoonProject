import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:intl/intl.dart';
import '../../services/database/soldiers_repository.dart';

class MoqfViewModel extends ChangeNotifier {
  final SoldiersRepository repo;

  MoqfViewModel(this.repo) {
    loadAllSoldiers();
  }

  final List<String> moqfTypes = [
    "رفد طبى",
    "رفد امنى",
    "حالة وفاة",
    "اعفاء عائلى",
    "ضم حربية",
    "ضم شرطة",
    "شطب",
    "تعديل سلاح",
  ];
  final List<DataColumn> moqfColumns = const [
    DataColumn(label: Text('الاسم')),
    DataColumn(label: Text('رقم عسكري')),
    DataColumn(label: Text('الكتيبة')),
    DataColumn(label: Text('السرية')),
    DataColumn(label: Text('الفصيلة')),
    DataColumn(label: Text('رقم سجل')),
    DataColumn(label: Text('المحافظة')),
    DataColumn(label: Text('التاريخ')),
    DataColumn(label: Text('النوع')),
    DataColumn(label: Text('ملاحظات')),
  ];

  final List<String> soldierKeys = [
    'soldiers_name',
    'soldiers_number',
    'soldiers_k',
    'soldiers_s',
    'soldiers_f',
    'soldiers_unit_id',
    'soldiers_city',
    'moqf_date',
    'moqf_type',
    'moqf_note',
  ];

  String? batchId;

  void updateBatch(String? value) {
    batchId = value;
    repo.setBatch(value);
    loadAllSoldiers();
  }

  List<Map<String, dynamic>> allSoldiers = [];
  List<Map<String, dynamic>> moqfEntries = [];
  List<Map<String, dynamic>> filtered = [];

  Map<String, dynamic>? selectedSoldier;

  DateTime? moqfDate;
  String? moqfType;
  String moqfNote = '';

  void setMoqfDate(DateTime d) {
    moqfDate = d;
    notifyListeners();
  }

  void setMoqfType(String? t) {
    moqfType = t;
    notifyListeners();
  }

  void setMoqfNote(String n) {
    moqfNote = n;
    notifyListeners();
  }

  Future<void> loadAllSoldiers() async {
    allSoldiers = await repo.getAllSoldiersForBatch(batchId);
    notifyListeners();
    await loadMoqfEntries();
  }

  Future<void> loadMoqfEntries() async {
    moqfEntries = await repo.getMoqfEntries(batchId);
    applyFilters();
  }

  String filterName = "";
  DateTime? filterDate;
  String? filterType;

  // --- دالة تحديث نص البحث المباشر ---
  void setFilterName(String val) {
    filterName = val;
    applyFilters();
  }

  DateTime? fixDate(String? d) {
    if (d == null || d.isEmpty) return null;
    return DateTime.tryParse(d.replaceAll('/', '-'));
  }

  Key tableKey = UniqueKey();

  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(moqfEntries);

    if (filterName.isNotEmpty) {
      String searchNorm = normalizeArabic(filterName);
      temp = temp.where((s) {
        String nameNorm = normalizeArabic(s["soldiers_name"].toString());
        return nameNorm.contains(searchNorm);
      }).toList();
    }

    if (filterDate != null) {
      temp = temp.where((s) {
        final d = fixDate(s["moqf_date"]);
        return d != null &&
            d.year == filterDate!.year &&
            d.month == filterDate!.month &&
            d.day == filterDate!.day;
      }).toList();
    }

    if (filterType != null && filterType!.isNotEmpty) {
      temp = temp.where((s) => s["moqf_type"] == filterType).toList();
    }

    filtered = temp;
    tableKey = UniqueKey();

    notifyListeners();
  }

  void resetFilters() {
    filterName = "";
    filterDate = null;
    filterType = null;
    applyFilters();
  }

  String fmt(String? date) {
    if (date == null || date.isEmpty) return "—";
    try {
      return DateFormat(
        "yyyy/MM/dd",
      ).format(DateTime.parse(date.replaceAll('/', '-')));
    } catch (_) {
      return date;
    }
  }

  Future<bool> saveMoqf(BuildContext context) async {
    // 1️⃣ التحقق من اكتمال البيانات
    if (selectedSoldier == null ||
        moqfDate == null ||
        moqfType == null ||
        moqfType!.isEmpty) {
      _showSnackBar(context, 'يرجى إكمال جميع الحقول المطلوبة!', Colors.orange);
      return false;
    }

    final soldierNumber = selectedSoldier!['soldiers_number'].toString().trim();
    final batchIdVal = (batchId ?? selectedSoldier!['soldiers_batch_id']);
    final dateStr = DateFormat("yyyy/MM/dd").format(moqfDate!);

    final data = {
      'moqf_soldiers_number': soldierNumber,
      'moqf_batch_id': batchIdVal,
      'moqf_date': dateStr,
      'moqf_type': moqfType,
      'moqf_note': moqfNote,
    };

    try {
      final bool exists = await repo.checkIfMoqfExists(
        soldierNumber,
        dateStr,
        moqfType!,
      );

      if (exists) {
        _showSnackBar(
          context,
          '⚠️ هذا الموقف مسجل بالفعل لهذا الجندي في هذا التاريخ!',
          Colors.orange,
        );
        return false;
      }

      await repo.insertMoqf(data);

      await loadMoqfEntries();
      _showSnackBar(context, 'تم حفظ الموقف بنجاح ✅', Colors.green);

      selectedSoldier = null;
      moqfNote = '';
      notifyListeners();

      return true;
    } catch (e) {
      _showSnackBar(context, '❌ خطأ: ${e.toString()}', Colors.red);
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> updateMoqf({
    required int id,
    required String newType,
    required String newNote,
    required DateTime newDate,
  }) async {
    final formatted = DateFormat("yyyy/MM/dd").format(newDate);

    await repo.updateMoqf(id, {
      'moqf_date': formatted,
      'moqf_type': newType,
      'moqf_note': newNote,
    });

    await loadMoqfEntries();
  }

  Future<void> deleteMoqf(int id) async {
    await repo.deleteMoqf(id);
    await loadMoqfEntries();
  }

  void selectSoldier(Map<String, dynamic> soldier) {
    selectedSoldier = soldier;
    notifyListeners();
  }
}

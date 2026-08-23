import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:intl/intl.dart';
import '../../services/database/soldiers_repository.dart';

class SoliderMoqfViewmodel extends ChangeNotifier {
  final SoldiersRepository repo;

  SoliderMoqfViewmodel(this.repo) {
    loadAllSoldiers();
  }

  // --- دالة تطبيع النصوص العربية للبحث الذكي ---

  final List<String> solidersoliderMoqfTypes = [
    "موقف امنى",
    "موقف طبى فرع",
    "موقف طبى مركز",
    "موقف مهمات",
    "موقف محو الاميه",
    "موقف عقوبة",
  ];

  // ======== بيانات الإدخال =========
  Map<String, dynamic>? selectedSoldier;
  DateTime? soliderMoqfDate;
  String? soliderMoqfType;
  String soliderMoqfNote = '';

  void setSoliderMoqfDate(DateTime d) {
    soliderMoqfDate = d;
    notifyListeners();
  }

  void setSoliderMoqfType(String? t) {
    soliderMoqfType = t;
    notifyListeners();
  }

  void setSoliderMoqfNote(String n) {
    soliderMoqfNote = n;
    notifyListeners();
  }

  // ======== batch =========
  String? batchId;

  void updateBatch(String? value) {
    batchId = value;
    repo.setBatch(value);
    loadAllSoldiers();
  }

  // ======== بيانات الجنود والمواقف =========
  List<Map<String, dynamic>> allSoldiers = [];
  List<Map<String, dynamic>> soliderMoqfEntries = [];
  List<Map<String, dynamic>> filtered = [];

  // ======== فلاتر =========
  String filterName = '';
  DateTime? filterDate;
  String? filterType;

  // تحديث نص الفلترة من الواجهة
  void setFilterName(String val) {
    filterName = val;
    applyFilters();
  }

  List<DropdownMenuItem<String>> get dropdownItems {
    return solidersoliderMoqfTypes
        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
        .toList();
  }

  DateTime? fixDate(String? d) {
    if (d == null || d.isEmpty) return null;
    return DateTime.tryParse(d.replaceAll('/', '-'));
  }

  String fmt(String? date) {
    if (date == null || date.isEmpty) return '—';
    try {
      return DateFormat(
        'yyyy/MM/dd',
      ).format(DateTime.parse(date.replaceAll('/', '-')));
    } catch (_) {
      return date;
    }
  }

  // ======== تحميل الجنود =========
  Future<void> loadAllSoldiers() async {
    allSoldiers = await repo.getAllSoldiersForBatch(batchId);
    notifyListeners();
    await loadSoliderMoqfEntries();
  }

  // ======== تحميل المواقف =========
  Future<void> loadSoliderMoqfEntries() async {
    soliderMoqfEntries = await repo.getSoliderMoqfEntries(batchId);
    applyFilters();
  }

  // ======== تطبيق الفلاتر (البحث الذكي) =========
  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(soliderMoqfEntries);

    if (filterName.isNotEmpty) {
      String searchNorm = normalizeArabic(filterName);
      temp = temp.where((s) {
        String nameNorm = normalizeArabic(s['soldiers_name'].toString());
        String docNumber = s['soldiers_number'].toString();

        // البحث بالاسم (ذكي) أو الرقم العسكري (مباشر)
        return nameNorm.contains(searchNorm) ||
            docNumber.contains(filterName.trim());
      }).toList();
    }

    if (filterType != null && filterType!.isNotEmpty) {
      temp = temp
          .where((s) => (s[filterType!]?.toString().isNotEmpty ?? false))
          .toList();
    }

    filtered = temp;
    notifyListeners();
  }

  void resetFilters() {
    filterName = '';
    filterDate = null;
    filterType = null;
    applyFilters();
  }

  // ======== إضافة موقف =========
  Future<bool> saveSoliderMoqf() async {
    if (selectedSoldier == null ||
        soliderMoqfDate == null ||
        soliderMoqfType == null ||
        soliderMoqfType!.isEmpty) {
      return false;
    }

    final s = DateFormat('yyyy/MM/dd').format(soliderMoqfDate!);

    await repo.insertSoliderMoqf({
      'soldier_moqf_soldiers_number': selectedSoldier!['soldiers_number'],
      'soldier_moqf_batch_id': batchId ?? selectedSoldier!['soldiers_batch_id'],
      'soldier_moqf_date': s,
      'soldier_moqf_type': soliderMoqfType,
      'soldier_moqf_note': soliderMoqfNote,
    });

    await loadSoliderMoqfEntries();
    return true;
  }

  // ======== تعديل موقف =========
  Future<void> updateSoliderMoqf({
    required int id,
    required String newType,
    required String newNote,
    required DateTime newDate,
  }) async {
    final formatted = DateFormat('yyyy/MM/dd').format(newDate);

    await repo.updateSoliderMoqf(id, {
      'soldier_moqf_date': formatted,
      'soldier_moqf_type': newType,
      'soldier_moqf_note': newNote,
    });

    await loadSoliderMoqfEntries();
  }

  // ======== حذف موقف =========
  Future<void> deleteSoliderMoqf(int id) async {
    await repo.deleteSoliderMoqf(id);
    await loadSoliderMoqfEntries();
  }

  void selectSoldier(Map<String, dynamic> soldier) {
    selectedSoldier = soldier;
    notifyListeners();
  }

  // ======== الأعمدة للجدول =========
  List<DataColumn> get soliderMoqfColumns {
    List<DataColumn> cols = [
      const DataColumn(label: Text('الاسم')),
      const DataColumn(label: Text('رقم عسكري')),
      const DataColumn(label: Text('كتيبة')),
      const DataColumn(label: Text('سرية')),
      const DataColumn(label: Text('فصلية')),
      const DataColumn(label: Text('رقم السجل')),
    ];
    for (var type in solidersoliderMoqfTypes) {
      cols.add(DataColumn(label: Text(type)));
    }
    return cols;
  }
}

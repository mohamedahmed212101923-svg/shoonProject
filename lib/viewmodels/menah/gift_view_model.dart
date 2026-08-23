import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database/gift_repository.dart';
import 'package:intl/intl.dart';

class GiftViewModel extends ChangeNotifier {
  final GiftRepository repo;

  GiftViewModel(this.repo);
  Key tableKey = UniqueKey(); // المفتاح المسؤول عن إعادة ضبط الجدول

  String? batchId;
  List<Map<String, dynamic>> allGifts = [];
  List<Map<String, dynamic>> filtered = [];
  List<Map<String, dynamic>> allSoldiers = [];
  List<String> allSoldiersNamesAndNumbers = [];

  String giftNote = '';

  void setGigtNote(String n) {
    giftNote = n;
    notifyListeners();
  }

  final List<String> giftTypes = [
    "دم",
    "ضاحية",
    "عرض",
    "يومين",
    "3 ايام",
    "5 ايام",
    "يوم",
  ];
  final List<DataColumn> giftColumns = const [
    DataColumn(label: Text('الاسم')),
    DataColumn(label: Text('رقم عسكري')),
    DataColumn(label: Text('الكتيبة')),
    DataColumn(label: Text('السرية')),
    DataColumn(label: Text('الفصيلة')),
    DataColumn(label: Text('رقم سجل')),
    DataColumn(label: Text('المحافظة')),
    DataColumn(label: Text('النوع')),
    DataColumn(label: Text('ملاحظات')),
    DataColumn(label: Text('التاريخ')),
  ];

  final List<String> soldierKeys = [
    'soldiers_name',
    'soldiers_number',
    'soldiers_k',
    'soldiers_s',
    'soldiers_f',
    'soldiers_city',
    'gift_type',
    'gift_note',
    'gift_date',
  ];
  void toggleGiftType(String value) {
    if (selectedGiftTypes.contains(value)) {
      selectedGiftTypes.remove(value);
    } else {
      selectedGiftTypes.add(value);
    }
    applyFilters();
  }

  void toggleBattalion(String value) {
    if (selectedBattalions.contains(value)) {
      selectedBattalions.remove(value);
    } else {
      selectedBattalions.add(value);
    }
    applyFilters();
  }

  List<String> get allGiftDates {
    final datesSet = <String>{};

    if (kDebugMode) {
      print("allgifts  is $allGifts");
    }
    for (var g in allGifts) {
      final note = g['gift_date'];
      if (kDebugMode) {
        print("the dates is $note");
      }
      // افحص لو gift_note مطابق لتنسيق التاريخ
      if (note != null &&
          (RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(note) ||
              RegExp(r'^\d{2}/\d{1}/\d{4}$').hasMatch(note))) {
        datesSet.add(note);
        if (kDebugMode) {
          print("in the if dataset is $datesSet");
        }
      }
      if (kDebugMode) {
        print("the dates is $datesSet");
      }
    }

    final sorted = datesSet.toList();
    sorted.sort((a, b) => a.compareTo(b)); // ترتيب تصاعدي
    return sorted;
  }

  List<String> giftTypesFromDb = [];
  List<String> battalions = [];
  List<String> selectedGiftTypes = [];
  List<String> selectedBattalions = [];
  List<String> selectedGiftNotes = [];
  List<String> selectedGiftDates = [];

  String searchText = '';
  DateTime? selectedGiftDate;
  String giftnote = '';

  void setGiftDate(DateTime date) {
    selectedGiftDate = date;
    notifyListeners();
  }

  String? _selectedGiftType;
  String? get selectedGiftType => _selectedGiftType;
  String? _selectedGiftNote;
  String? get selectedGiftNote => _selectedGiftNote;

  set selectedGiftType(String? value) {
    _selectedGiftType = value;
    notifyListeners();
  }

  set selectedGiftNote(String? value) {
    _selectedGiftNote = value;
    notifyListeners();
  }

  Future<void> deleteGift(int giftId) async {
    await repo.deleteGift(giftId);
    await loadData(); // لتحديث الجدول فوراً بعد الحذف
  }

  Future<void> updateGift(int giftId, String type, {String? date}) async {
    await repo.updateGift(giftId, type, date: date);
    await loadData(); // لتحديث الجدول فوراً بعد التعديل
  }

  Future<void> loadData() async {
    if (batchId == null) return;
    final rawSoldiers = await repo.getAllSoldiers(batchId!);
    allSoldiers = List<Map<String, dynamic>>.from(rawSoldiers);
    allSoldiersNamesAndNumbers = allSoldiers
        .map((s) => "${s['soldiers_name']} - ${s['soldiers_number']}")
        .toList();
    final rawGifts = await repo.getGiftsByBatch(batchId!);
    allGifts = List<Map<String, dynamic>>.from(rawGifts);
    final rawTypes = await repo.getGiftTypes(batchId!);
    giftTypesFromDb = List<String>.from(rawTypes);
    final rawBattalions = await repo.getBattalions(batchId!);
    battalions = List<String>.from(rawBattalions);

    applyFilters();
  }

  void updateBatch(String? newBatchId) {
    batchId = newBatchId;
    allGifts = [];
    filtered = [];
    selectedGiftType = null;
    selectedGiftNote = null;
    if (newBatchId != null) {
      Future.microtask(() => loadData());
    } else {
      notifyListeners();
    }
  }

  void setSearchText(String v) {
    searchText = v;
    applyFilters();
  }

  void setMolahazatText(String v) {
    giftnote = v;
    notifyListeners();
  }

  void applyFilters() {
    var temp = List<Map<String, dynamic>>.from(allGifts);
    if (searchText.isNotEmpty) {
      final txt = searchText.toLowerCase();
      temp = temp
          .where(
            (e) =>
                e['soldiers_name'].toString().toLowerCase().contains(txt) ||
                e['soldiers_number'].toString().contains(txt),
          )
          .toList();
    }
    if (selectedGiftTypes.isNotEmpty) {
      temp = temp
          .where((e) => selectedGiftTypes.contains(e['gift_type']))
          .toList();
    }
    if (selectedBattalions.isNotEmpty) {
      temp = temp
          .where((e) => selectedBattalions.contains(e['soldiers_k']))
          .toList();
    }
    if (selectedGiftDates.isNotEmpty) {
      temp = temp
          .where((e) => selectedGiftDates.contains(e['gift_date']))
          .toList();
    }

    filtered = temp;
    tableKey = UniqueKey();

    notifyListeners();
  }

  Future<String> insertGiftByScan(String value) async {
    if (batchId == null) return "❌ لم يتم اختيار دفعة";
    if (selectedGiftType == null) return "❌ اختر المنحة اولا  ";
    //if (selectedGiftDate == null) return "❌ اختر تاريخ المنحة أولاً"; // إلزامي

    value = value.trim();
    if (value.isEmpty) return "❌ قيمة فارغة";

    Map<String, dynamic>? targetSoldier;

    // البحث بالرقم العسكري أولاً
    final foundByNumber = allSoldiers
        .where((s) => s['soldiers_number'].toString() == value)
        .toList();
    if (foundByNumber.isNotEmpty) {
      targetSoldier = foundByNumber.first;
    } else {
      // البحث بالاسم
      final foundByName = allSoldiers
          .where((s) => s['soldiers_name'].toString().contains(value))
          .toList();
      if (foundByName.isEmpty) return "❌ الجندي غير موجود";
      if (foundByName.length > 1) return "⚠ يوجد أكثر من جندي بهذا الاسم";
      targetSoldier = foundByName.first;
    }

    final sNum = targetSoldier['soldiers_number'];
    String todayDate = DateFormat('yyyy/MM/dd').format(DateTime.now());

    // التحقق من تكرار التسجيل
    if (await repo.giftExists(sNum, batchId!)) return "⚠ الجندي مسجل مسبقاً";

    try {
      await repo.insertGift(
        soldierNumber: sNum,
        batchId: batchId!,
        giftType: selectedGiftType!,
        // تسجيل التاريخ بشكل إلزامي
        giftNote: giftNote,
        //selectedGiftNote!,
        giftdate: todayDate,
      );

      // إعادة تعيين القيم بعد الإضافة
      selectedGiftDate = null;
      selectedGiftType = null;
      notifyListeners();

      await loadData(); // لتحديث الجدول
      return "✔ تم تسجيل: ${targetSoldier['soldiers_name']}";
    } catch (e) {
      return "❌ خطأ: $e";
    }
  }
}

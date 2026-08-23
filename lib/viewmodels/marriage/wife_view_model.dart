import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/services/database/wife_repo.dart';

class WifeViewModel extends ChangeNotifier {
  final WifeRepository repository;
  WifeViewModel({required this.repository});

  String? batchId;
  List<Map<String, dynamic>> _allWives = [];
  List<Map<String, dynamic>> _filteredWives = [];
  List<String> _battalions = [];
  List<String> _selectedBattalionsList = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _currentSearchQuery = "";
  List<String> get selectedBattalionsList => _selectedBattalionsList;
  List<Map<String, dynamic>> get wives => _filteredWives;
  List<String> get battalions => _battalions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _allWives.length;

  void updateBatch(String? newBatchId) {
    if (newBatchId == null || batchId == newBatchId) return;
    batchId = newBatchId;
    loadWivesData();
  }

  Future<void> loadWivesData() async {
    if (batchId == null) return;
    _setLoading(true);
    try {
      _allWives = await repository.getWivesWithSoldierDetails(batchId!);
      _updateBattalionList();
      _applyFilters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "خطأ في جلب البيانات: $e";
    } finally {
      _setLoading(false);
    }
  }

  void _updateBattalionList() {
    final Set<String> uniqueBattalions = _allWives
        .map((wife) => wife['battalion']?.toString() ?? "غير محدد")
        .where((b) => b.isNotEmpty)
        .toSet();

    _battalions = uniqueBattalions.toList()..sort();
    _selectedBattalionsList.removeWhere((b) => !_battalions.contains(b));
  }

  // --- الفلترة والبحث ---

  void search(String query) {
    _currentSearchQuery = query;
    _applyFilters();
  }

  void filterByMultipleBattalions(List<String> selected) {
    _selectedBattalionsList = List.from(selected);
    _applyFilters();
  }

  void _applyFilters() {
    // نقوم بتوحيد نص البحث مرة واحدة خارج الحلقة لتحسين الأداء
    final String normalizedQuery = normalizeArabic(_currentSearchQuery);

    final List<Map<String, dynamic>> results = _allWives.where((wife) {
      // 1. توحيد نصوص البيانات (اسم الزوجة، اسم الزوج، الرقم العسكري)
      final String wName = normalizeArabic(wife['wife_name']?.toString() ?? "");
      final String hName = normalizeArabic(
        wife['husband_name']?.toString() ?? "",
      );
      final String sNum = wife['wife_soldiers_number']?.toString() ?? "";

      // 2. منطق مطابقة البحث
      // نتحقق من احتواء النصوص الموحدة على نص البحث الموحد
      final bool matchesSearch =
          hName.contains(normalizedQuery) ||
          sNum.contains(normalizedQuery) ||
          wName.contains(normalizedQuery);

      // 3. منطق مطابقة الكتيبة (كما هو في كودك)
      final bool showAll =
          _selectedBattalionsList.isEmpty ||
          _selectedBattalionsList.contains("الكل");

      final bool matchesBattalion =
          showAll ||
          _selectedBattalionsList.contains(wife['battalion']?.toString());

      return matchesSearch && matchesBattalion;
    }).toList();

    _filteredWives = List.from(results);
    notifyListeners();
  }

  Future<bool> addNewWife({
    required String name,
    required String nationalNumber,
    required String soldierNumber,
    required String marriedCardId,
    required String marriageDate,
  }) async {
    try {
      if (batchId == null) return false;
      await repository.insertWife(
        soldierNumber: soldierNumber,
        batchId: int.parse(batchId!),
        name: name,
        nationalNumber: nationalNumber,
        marriedDate: marriageDate,
        marriedCardId: marriedCardId,
      );

      _currentSearchQuery = "";
      _selectedBattalionsList.clear();

      await loadWivesData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editWife({
    required int wifeId,
    required String name,
    required String nationalNumber,
    required String soldierNumber,
    required String marriedCardId,
    required String marriageDate,
  }) async {
    try {
      _setLoading(true);
      await repository.updateWife(
        wifeId: wifeId,
        soldierNumber: soldierNumber,
        name: name,
        nationalNumber: nationalNumber,
        marriedDate: marriageDate,
        marriedCardId: marriedCardId,
      );
      await loadWivesData();
      return true;
    } catch (e) {
      _errorMessage = "فشل تحديث البيانات: ${e.toString()}";
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteWife(int wifeId) async {
    try {
      _setLoading(true);
      await repository.deleteWife(wifeId);
      await loadWivesData();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "حدث خطأ أثناء الحذف: ${e.toString()}";
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getAllSoldiers() async {
    if (batchId == null) return [];
    try {
      return await repository.getAllSoldiers(batchId!);
    } catch (e) {
      debugPrint("Error fetching soldiers: $e");
      return [];
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/database/soldiers_repository.dart';

class UnitsViewModel extends ChangeNotifier {
  final SoldiersRepository repo;

  UnitsViewModel(this.repo) {
    loadData();
  }

  List<Map<String, dynamic>> tabaeia = [];
  List<Map<String, dynamic>> units = [];
  bool isLoading = false;

  // إدارة الوحدات المحددة لتغيير التبعية دفعة
  List<int> selectedUnitIds = [];
  List<String> selectedUnitNames = [];
  int? selectedUnitTabaeiaId;
  String unitsSearch = '';

  // فلترة العرض
  List<int> selectedFilterTabaeiaIds = [];
  List<String> selectedFilterTabaeiaNames = [];

  String? get selectedUnitTabaeiaName {
    if (selectedUnitTabaeiaId == null) return null;
    final t = tabaeia.firstWhere(
      (t) => t['tabaeia_id'] == selectedUnitTabaeiaId,
      orElse: () => {},
    );
    return t.isNotEmpty ? t['tabaeia_name'] : null;
  }

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    tabaeia = await repo.getAllTabaeia();
    units = await repo.getAllUnits();
    isLoading = false;
    notifyListeners();
  }

  // تحديثات الواجهة الفورية
  void setTopSelectedTabaeia(String name) {
    final t = tabaeia.firstWhere((t) => t['tabaeia_name'] == name);
    selectedUnitTabaeiaId = t['tabaeia_id'];
    notifyListeners();
  }

  void toggleUnitSelection(String itemName) {
    final unit = units.firstWhere((u) => u['units_name'] == itemName);
    if (selectedUnitIds.contains(unit['units_id'])) {
      selectedUnitIds.remove(unit['units_id']);
      selectedUnitNames.remove(itemName);
    } else {
      selectedUnitIds.add(unit['units_id']);
      selectedUnitNames.add(itemName);
    }
    notifyListeners();
  }

  void toggleFilterTabaeia(String name) {
    final t = tabaeia.firstWhere((t) => t['tabaeia_name'] == name);
    if (selectedFilterTabaeiaIds.contains(t['tabaeia_id'])) {
      selectedFilterTabaeiaIds.remove(t['tabaeia_id']);
      selectedFilterTabaeiaNames.remove(name);
    } else {
      selectedFilterTabaeiaIds.add(t['tabaeia_id']);
      selectedFilterTabaeiaNames.add(name);
    }
    notifyListeners();
  }

  void resetFilter() {
    selectedFilterTabaeiaIds.clear();
    selectedFilterTabaeiaNames.clear();
    notifyListeners();
  }

  // --- عمليات الـ Database ---
  Future<void> addTabaeia(String name) async {
    await repo.insertTabaeia(name.trim());
    await loadData();
  }

  Future<void> updateTabaeia(int id, String name) async {
    await repo.updateTabaeia(id, name.trim());
    await loadData();
  }

  Future<void> deleteTabaeia(int id) async {
    await repo.deleteTabaeia(id);
    await loadData();
  }

  Future<void> addUnit(int tId, String name) async {
    await repo.insertUnit(tabaeiaId: tId, unitName: name.trim());
    await loadData();
  }

  Future<void> updateUnitFull(
    int unitId,
    String newName,
    int newTabaeiaId,
  ) async {
    await repo.updateUnit(unitId, newName.trim());
    await repo.updateUnitTabaeia(unitId, newTabaeiaId);
    await loadData();
  }

  Future<void> updateSelectedUnitsTabaeia(int tabaeiaId) async {
    for (var id in selectedUnitIds) {
      await repo.updateUnitTabaeia(id, tabaeiaId);
    }
    selectedUnitIds.clear();
    selectedUnitNames.clear();
    selectedUnitTabaeiaId = null;
    await loadData();
  }

  Future<void> deleteUnit(int id) async {
    await repo.deleteUnit(id);
    await loadData();
  }
}

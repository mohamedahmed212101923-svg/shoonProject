import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/services/database/leaders_repository.dart';
import '../../services/database/soldiers_repository.dart';

class JawabatViewModel extends ChangeNotifier {
  final SoldiersRepository repository;
  final LeadersRepository leadersRepo;

  JawabatViewModel(this.repository, this.leadersRepo) {
    loadAllSoldiers();
    loadLeader(); // تحميل القائد مباشرة عند إنشاء ViewModel
  }

  Map<String, String> leader = {'name': 'غير محدد', 'rank': 'جندي'};

  // تحميل القائد من قاعدة البيانات
  Future<void> loadLeader() async {
    final leaders = await leadersRepo.getLeaders();
    if (leaders.isNotEmpty) {
      leader = {
        'name': leaders.first['leader_name'].toString(),
        'rank': leaders.first['leader_rank'].toString(),
        'position': leaders.first['leader_posation'].toString(),
      };
    }
    notifyListeners();
  }

  // لتحديث بيانات القائد

  String? batchId;
  List<Map<String, dynamic>> allSoldiers = [];
  List<Map<String, dynamic>> filteredSoldiers = [];
  Map<String, dynamic>? selectedSoldier;
  bool isLoading = true;

  void updateBatch(String? value) {
    batchId = value;
    repository.setBatch(value);
    loadAllSoldiers();
  }

  Future<void> loadAllSoldiers() async {
    isLoading = true;
    notifyListeners();
    allSoldiers = await repository.getAllSoldiersForBatch(batchId);
    filteredSoldiers = List.from(allSoldiers);
    isLoading = false;
    notifyListeners();
  }

  void selectSoldier(Map<String, dynamic>? soldier) {
    selectedSoldier = soldier;
    notifyListeners();
  }

  void filterSoldiers(String query) {
    if (selectedSoldier != null) selectedSoldier = null;

    // 1. تبسيط كلمة البحث
    final q = normalizeArabic(query);

    if (q.isEmpty) {
      filteredSoldiers = List.from(allSoldiers);
    } else {
      filteredSoldiers = allSoldiers.where((s) {
        // 2. تبسيط بيانات الجندي (الاسم، الرقم العسكري، الرقم الثلاثي)
        final name = normalizeArabic(s['soldiers_name']?.toString() ?? '');
        final number = s['soldiers_number']?.toString() ?? '';
        final triple = s['soldiers_triple_number']?.toString() ?? '';

        // 3. المقارنة
        return name.contains(q) || number.contains(q) || triple.contains(q);
      }).toList();
    }

    notifyListeners();
  }

  Map<String, dynamic> getSelectedSoldierData() {
    if (selectedSoldier == null) throw Exception('No soldier selected');
    return selectedSoldier!;
  }
}

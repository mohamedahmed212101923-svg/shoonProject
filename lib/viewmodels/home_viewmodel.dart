import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/ajaza/ajaza_view.dart';
import 'package:flutter_application_1/view/presentations_view.dart';
import 'package:flutter_application_1/view/new_batches/batch_view.dart';
import 'package:flutter_application_1/view/cards/card_view.dart';
import 'package:flutter_application_1/view/recieving/daily_receipts_view.dart';
import 'package:flutter_application_1/view/menah/gift_view.dart';
import 'package:flutter_application_1/view/leader_view.dart';
import 'package:flutter_application_1/view/medical_view/medical_visits_page.dart';
import 'package:flutter_application_1/view/mawqf/moqf_view.dart';
import 'package:flutter_application_1/view/papers_of_soldiers/jawabat_view.dart';
import 'package:flutter_application_1/view/mawqf/solider_moqf_view.dart';
import 'package:flutter_application_1/view/tarheel/tarhil_view.dart';
import 'package:flutter_application_1/view/taskin_view.dart';
import 'package:flutter_application_1/view/units_view.dart';
import 'package:flutter_application_1/view/marriage/wife_view.dart';
import 'package:flutter_application_1/viewmodels/backup_viewmodel.dart';
import '../services/database/soldiers_repository.dart';

class HomeViewmodel extends ChangeNotifier {
  int selectedIndex = 0;
  late BackupViewModel backupVm;

  Map<String, dynamic>? selectedBatch;

  List<Map<String, dynamic>> batches = [];

  final SoldiersRepository repo;

  HomeViewmodel({required this.repo}) {
    loadBatches();
  }

  final menuItems = [
    {'title': 'الرئيسية', 'icon': Icons.home},
    {'title': 'اضافة دفعات', 'icon': Icons.inventory_2},
    {'title': 'الاستلام', 'icon': Icons.inventory_2},
    {'title': 'اوراق مجندين', 'icon': Icons.person},
    {
      'title': 'الاجازات والسجن والغياب',
      'icon': Icons.holiday_village_outlined,
    },
    {'title': 'المنح', 'icon': Icons.card_giftcard},
    {'title': 'متزوجين', 'icon': Icons.family_restroom},
    {'title': 'مواقف الرفد', 'icon': Icons.work_outline},
    {'title': 'مواقف فرعية', 'icon': Icons.assignment_turned_in},
    {'title': 'التوزيعة', 'icon': Icons.grid_view},
    {'title': 'التبعيات والوحدات', 'icon': Icons.account_tree},
    {'title': 'كروت الدفعة', 'icon': Icons.card_membership},
    {'title': 'القائد', 'icon': Icons.workspace_premium},
    {'title': 'العروض الطبية', 'icon': Icons.health_and_safety},
    {'title': ' دهشور', 'icon': Icons.health_and_safety},
    //{'title': ' طباعة', 'icon': Icons.print},
  ];

  final pages = [
    const TaskinView(),
    BatchesPage(),
    DailyReceiptsView(),
    JawabatView(),
    AjazaView(),
    GiftView(),
    WifeManagementPage(),
    MoqfView(),
    SoliderMoqfView(),
    TarhilView(),
    UnitsView(),
    CardsView(),
    LeadersPage(),
    MedicalVisitsPage(),
    PresentationScreen(),
    //LeadersPage2(),
  ];

  /// دالة تغيير الدفعة مع ضمان التزامن
  void selectBatch(Map<String, dynamic> batch) {
    if (selectedBatch != null &&
        selectedBatch!['batch_id'] == batch['batch_id']) {
      return; // تجنب إعادة التحميل إذا كانت نفس الدفعة
    }

    selectedBatch = batch;

    // إبلاغ الريبوزيتوري بالدفعة الجديدة لاستخدامها في الاستعلامات
    repo.setBatch(selectedBatch!['batch_id'].toString());

    debugPrint("Batch Changed to: ${selectedBatch!['batch_name']}");
    notifyListeners();
  }

  /// جلب الدفعات من قاعدة البيانات (تعمل في وضع السيرفر والكلينت)
  Future<void> loadBatches() async {
    final List<Map<String, dynamic>> result = await repo.getBatches();

    if (result.isNotEmpty) {
      batches = List<Map<String, dynamic>>.from(result);

      batches.sort(
        (a, b) => (a['batch_name'] ?? '').toString().compareTo(
          (b['batch_name'] ?? '').toString(),
        ),
      );

      selectedBatch ??= findClosestBatch(batches);
      repo.setBatch(selectedBatch!['batch_id'].toString());
    } else {
      batches = [];
      selectedBatch = null;
    }

    notifyListeners();
  }

  /// حساب أقرب دفعة بناءً على السنة والربع (تجنيد)
  Map<String, dynamic> findClosestBatch(List<Map<String, dynamic>> batches) {
    if (batches.isEmpty) return {};

    final now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    // تحويل الشهر إلى ربع سنوي (1, 2, 3, 4)
    int currentQuarter = ((currentMonth - 1) ~/ 3) + 1;

    Map<String, dynamic> closest = batches.first;
    int minDiff = 9999;

    for (var batch in batches) {
      String name = batch['batch_name'] ?? '';
      if (name.length < 5) continue;

      int year = int.tryParse(name.substring(0, 4)) ?? 0;
      int quarter = int.tryParse(name.substring(4, 5)) ?? 0;

      int diff = ((year - currentYear) * 4 + (quarter - currentQuarter)).abs();

      if (diff < minDiff) {
        minDiff = diff;
        closest = batch;
      }
    }

    return closest;
  }

  /// تحديث القائمة بعد استيراد بيانات جديدة
  Future<void> refreshBatches({Map<String, dynamic>? batchToSelect}) async {
    await loadBatches();
    if (batchToSelect != null) {
      selectBatch(batchToSelect);
    }
    notifyListeners();
  }

  void selectIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}

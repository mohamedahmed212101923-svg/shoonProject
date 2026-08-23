import 'package:flutter/material.dart';
import '../services/database/leaders_repository.dart';

class LeadersViewModel extends ChangeNotifier {
  final LeadersRepository repo;
  LeadersViewModel(this.repo);

  Map<String, Map<String, dynamic>> leaders = {};
  bool loading = false;

  final List<String> officerRanks = [
    'مشير',
    'فريق أول',
    'فريق',
    'لواء',
    'عميد',
    'عقيد',
    'مقدم',
    'رائد',
    'نقيب',
    'ملازم أول',
    'ملازم',
  ];

  final String arkanHarbSuffix = 'أركان حرب';

  Future<void> loadLeaders() async {
    loading = true;
    notifyListeners();

    final data = await repo.getLeaders();

    if (data.isNotEmpty) {
      // تفريغ البيانات الحالية قبل الملء
      leaders.clear();
      for (var row in data) {
        // نستخدم leader_posation كمفتاح للوصول للبيانات في الـ UI
        final pos = row['leader_posation'] as String;
        final rank = row['leader_rank'] as String;
        final isArkan = rank.contains(arkanHarbSuffix);
        final baseRank = isArkan
            ? rank.replaceAll(' $arkanHarbSuffix', '')
            : rank;

        leaders[pos] = {
          'id': row['id'], // حفظ الـ id القادم من القاعدة
          'name': row['leader_name'],
          'rank': baseRank,
          'arkanHarb': isArkan,
        };
      }
    } else {
      // الحالة الافتراضية
      leaders = {
        'first': {
          'id': 1,
          'name': 'قائد أول',
          'rank': 'لواء',
          'arkanHarb': true,
        },
        'second': {
          'id': 2,
          'name': 'قائد تاني',
          'rank': 'نقيب',
          'arkanHarb': false,
        },
      };
    }

    loading = false;
    notifyListeners();
  }

  Future<void> saveLeader({
    required String pos, // 'first' أو 'second'
    required String name,
    required String rank,
    required bool arkanHarb,
  }) async {
    // تحديد الـ ID بناءً على الكارت
    // إذا كان الكارت الأول (first) يأخذ id 1، غير ذلك يأخذ id 2
    int fixedId = (pos == 'first') ? 1 : 2;

    final finalRank = arkanHarb ? '$rank $arkanHarbSuffix' : rank;

    // إرسال الـ fixedId للمستودع (Repository) لضمان التحديث في مكان محدد
    await repo.upsertLeader(
      fixedId: fixedId,
      pos: pos,
      name: name,
      rank: finalRank,
    );

    // تحديث الحالة المحلية
    leaders[pos] = {
      'id': fixedId,
      'name': name,
      'rank': rank,
      'arkanHarb': arkanHarb,
    };

    notifyListeners();
  }
}

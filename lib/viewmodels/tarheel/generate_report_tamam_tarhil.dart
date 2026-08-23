import 'package:flutter/services.dart';
import 'package:flutter_application_1/viewmodels/new_batches/get_batch_name.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> generateReportTamamTarhil(
  List<Map<String, dynamic>> allSending,
  String? batchid,
  Map<String, String>? leader,
  Map<String, dynamic>? extraData,
) async {
  final pdf = pw.Document();

  // تحميل الخطوط
  final regularFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoNaskhArabic-Regular.ttf"),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoNaskhArabic-Bold.ttf"),
  );

  // --- دالات المساعدة ---
  String normalize(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '');
  }

  String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const hindi = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], hindi[i]);
    }
    return input;
  }

  String getLeaderSignature(Map<String, String>? leader, {int stretch = 3}) {
    if (leader == null || leader['name'] == null || leader['rank'] == null) {
      return '';
    }
    String name = leader['name']!.trim();
    String rank = leader['rank']!.trim();
    if (rank.contains('أركان حرب')) {
      rank = '${rank.replaceAll('أركان حرب', '').trim()} أ ح';
    }

    String applyTatweel(String text, int amount) {
      if (text.isEmpty || amount <= 0) return text;
      final nonJoiners = RegExp(r'[ادذرزوآأإؤء]');
      final tatweel = 'ـ' * amount;
      StringBuffer result = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        result.write(text[i]);
        if (i < text.length - 1 &&
            !nonJoiners.hasMatch(text[i]) &&
            text[i] != ' ' &&
            text[i + 1] != ' ' &&
            text[i + 1] != '/') {
          result.write(tatweel);
        }
      }
      return result.toString();
    }

    return '${applyTatweel(rank, stretch)} / ${applyTatweel(name, stretch)}';
  }

  int getWeight(String rawText) {
    final text = normalize(rawText);
    if (text.contains("قياده الجيش الثاني")) return 1;
    if (text.contains("قياده الجيش الثالث")) return 2;
    if (text.contains("قياده")) return 3;
    if (text.startsWith("اداره")) return 4;
    if (text.contains("لواء")) return 5;
    if (text == "بدون" || text.isEmpty) return 99;
    return 50;
  }

  // استخراج البيانات الإضافية
  final String b1No = toArabicNumbers(extraData?['book1No']?.toString() ?? "");
  final String b1Date = toArabicNumbers(
    extraData?['book1Date']?.toString() ?? "",
  );
  final String b2No = toArabicNumbers(extraData?['book2No']?.toString() ?? "");
  final String b2Date = toArabicNumbers(
    extraData?['book2Date']?.toString() ?? "",
  );
  final List<dynamic> officersList = extraData?['officersDistribution'] ?? [];
  final Map<String, dynamic> prevBatchCounts =
      extraData?['prevBatchCounts'] ?? {};

  final details = getBatchDetails(batchid.toString());
  String batchFullInfo =
      "${details['order']} (${details['month']}) لعام ${toArabicNumbers(details['year'] ?? "")}";

  void buildReportPage(
    List<Map<String, dynamic>> filteredList,
    String statusText, {
    bool simpleTable = false,
  }) {
    // التحقق من وجود بيانات
    if (filteredList.isEmpty &&
        statusText.contains("قامت") &&
        prevBatchCounts.isEmpty) {
      return;
    }

    final Map<String, Map<String, dynamic>> grouped = {};

    // 1. إضافة كل وحدات المراحل السابقة أولاً (لجدول التمام الكبير فقط)
    if (!simpleTable) {
      prevBatchCounts.forEach((unitName, count) {
        if (count > 0) {
          grouped[unitName] = {
            "name": unitName,
            "إدارة المهندسين": 0,
            "إدارة المياه": 0,
            "إدارة المساحة": 0,
            "إدارة الأشغال": 0,
            "مهني مساحة": 0,
            "ضباط احتياط": 0,
            "مراحل سابقة": count,
            "total": count,
            "date": "",
          };
        }
      });
    }

    // 2. تجميع بيانات الترحيل الحالية
    for (final row in filteredList) {
      final father = row['sending_father_area']?.toString().trim();
      final area = row['sending_area']?.toString().trim() ?? 'غير محددة';
      final unitName = (father != null && father.isNotEmpty) ? father : area;
      final dateValue = row['sending_date']?.toString().trim() ?? '';

      // المفتاح يعتمد على نوع الجدول (بناءً على التاريخ أو اسم الوحدة)
      final key = simpleTable ? "${unitName}_$dateValue" : unitName;

      if (!grouped.containsKey(key)) {
        int prevCount = simpleTable ? 0 : (prevBatchCounts[unitName] ?? 0);
        grouped[key] = {
          "name": unitName,
          "إدارة المهندسين": 0,
          "إدارة المياه": 0,
          "إدارة المساحة": 0,
          "إدارة الأشغال": 0,
          "مهني مساحة": 0,
          "ضباط احتياط": 0,
          "مراحل سابقة": prevCount,
          "total": prevCount,
          "date": dateValue,
        };
      }

      final weapon = row['soldiers_weapon']?.toString() ?? '';
      final management = row['soldiers_management']?.toString() ?? '';

      if (weapon.contains("مهني مساحة")) {
        grouped[key]!['مهني مساحة'] = (grouped[key]!['مهني مساحة'] as int) + 1;
      } else if (management.contains("ضباط") || management.contains("احتياط")) {
        grouped[key]!['ضباط احتياط'] =
            (grouped[key]!['ضباط احتياط'] as int) + 1;
      } else if (grouped[key]!.containsKey(management)) {
        grouped[key]![management] = (grouped[key]![management] as int) + 1;
      }
      grouped[key]!['total'] = (grouped[key]!['total'] as int) + 1;
    }

    // 3. دمج توزيع ضباط الاحتياط من الـ Dialog
    if (!simpleTable && officersList.isNotEmpty) {
      for (var offItem in officersList) {
        String offArea = offItem['area']?.toString() ?? "بدون";
        int offCount = offItem['count'] is int
            ? offItem['count']
            : int.tryParse(offItem['count'].toString()) ?? 0;
        if (offCount <= 0) continue;

        String matchedKey = grouped.keys.firstWhere(
          (k) => normalize(grouped[k]!['name']) == normalize(offArea),
          orElse: () => "",
        );

        if (matchedKey.isNotEmpty) {
          grouped[matchedKey]!['ضباط احتياط'] =
              (grouped[matchedKey]!['ضباط احتياط'] as int) + offCount;
          grouped[matchedKey]!['total'] =
              (grouped[matchedKey]!['total'] as int) + offCount;
        } else {
          int prevCount = prevBatchCounts[offArea] ?? 0;
          grouped[offArea] = {
            "name": offArea,
            "إدارة المهندسين": 0,
            "إدارة المياه": 0,
            "إدارة المساحة": 0,
            "إدارة الأشغال": 0,
            "مهني مساحة": 0,
            "ضباط احتياط": offCount,
            "مراحل سابقة": prevCount,
            "total": offCount + prevCount,
            "date": "",
          };
        }
      }
    }

    // فرز البيانات
    final sortedEntries = grouped.entries.toList();
    if (simpleTable) {
      sortedEntries.sort(
        (a, b) =>
            a.value['date'].toString().compareTo(b.value['date'].toString()),
      );
    } else {
      sortedEntries.sort((a, b) {
        int wA = getWeight(a.value['name'].toString());
        int wB = getWeight(b.value['name'].toString());
        if (wA != wB) return wA.compareTo(wB);
        return normalize(a.value['name']).compareTo(normalize(b.value['name']));
      });
    }

    // الإجماليات
    int sumEng = 0,
        sumWater = 0,
        sumMap = 0,
        sumWork = 0,
        sumPro = 0,
        sumOfficers = 0,
        sumPrev = 0,
        sumTotal = 0;
    for (var entry in sortedEntries) {
      var v = entry.value;
      sumEng += v["إدارة المهندسين"] as int;
      sumWater += v["إدارة المياه"] as int;
      sumMap += v["إدارة المساحة"] as int;
      sumWork += v["إدارة الأشغال"] as int;
      sumPro += v["مهني مساحة"] as int;
      sumOfficers += v["ضباط احتياط"] as int;
      sumPrev += v["مراحل سابقة"] as int;
      sumTotal += v["total"] as int;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(14.17),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) => [
          // Header
          pw.Text(
            "الهيئة الهندسية للقوات المسلحة",
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "وحدة تدريب مشترك الهيئة الهندسية",
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "الـــقـــيــد : ش ط /ت / ${toArabicNumbers("1")}/ ${toArabicNumbers(DateTime.now().year.toString())}",
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "التاريـــــــــــــخ:       /       /  ${toArabicNumbers(DateTime.now().year.toString())}",
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              "إلى / الهيئة الهندسية للقوات المسلحة ( فرع التنظيم والإدارة )",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              "إيماءً لكتابكم رقم ($b1No) بتاريخ $b1Date والمشار به لكتاب هيئة التنظيم والإدارة للقوات المسلحة رقم ($b2No) بتاريخ $b2Date",
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Center(
            child: pw.Text(
              "بشأن استقبال وترحيل جنود المرحلة التجنيدية $batchFullInfo والمراحل السابقة.",
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              "يرجى التكرم بالعلم بموقف الوحدات التي $statusText الجنود خاصتها كالآتي :-",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 5),

          // الجدول
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: simpleTable
                ? const {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(3),
                    2: pw.FlexColumnWidth(5),
                    3: pw.FlexColumnWidth(1),
                  }
                : const {
                    0: pw.FlexColumnWidth(0.8),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FlexColumnWidth(0.9),
                    3: pw.FlexColumnWidth(1),
                    4: pw.FlexColumnWidth(1),
                    5: pw.FlexColumnWidth(1),
                    6: pw.FlexColumnWidth(0.8),
                    7: pw.FlexColumnWidth(1.1),
                    8: pw.FlexColumnWidth(3),
                    9: pw.FlexColumnWidth(0.4),
                  },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children:
                    (simpleTable
                            ? ['الإجمالي', 'التاريخ', 'الوحدة / التبعية', 'م']
                            : [
                                'الإجمالي',
                                'ضباط احتياط',
                                'مراحل سابقة',
                                'مهني مساحة',
                                'إدارة الأشغال',
                                'إدارة المساحة',
                                'إدارة المياه',
                                'إدارة المهندسين',
                                'الوحدة / التبعية',
                                'م',
                              ])
                        .map(
                          (e) => pw.Container(
                            alignment: pw.Alignment.center,
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              e,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ...sortedEntries.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value.value;
                final cells = simpleTable
                    ? [
                        v['total'].toString(),
                        v['date'],
                        v['name'],
                        (i + 1).toString(),
                      ]
                    : [
                        v["total"].toString(),
                        v["ضباط احتياط"].toString(),
                        v["مراحل سابقة"].toString(),
                        v["مهني مساحة"].toString(),
                        v["إدارة الأشغال"].toString(),
                        v["إدارة المساحة"].toString(),
                        v["إدارة المياه"].toString(),
                        v["إدارة المهندسين"].toString(),
                        v['name'],
                        (i + 1).toString(),
                      ];

                return pw.TableRow(
                  children: cells.map((text) {
                    bool isNumeric =
                        double.tryParse(text.toString()) != null ||
                        RegExp(
                          r'^[٠١٢٣٤٥٦٧٨٩-]+$',
                        ).hasMatch(toArabicNumbers(text.toString()));
                    return pw.Container(
                      height: 18,
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        toArabicNumbers(text.toString()),
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: isNumeric
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children:
                    (simpleTable
                            ? [sumTotal.toString(), '', 'الإجمالي العام', '']
                            : [
                                sumTotal.toString(),
                                sumOfficers.toString(),
                                sumPrev.toString(),
                                sumPro.toString(),
                                sumWork.toString(),
                                sumMap.toString(),
                                sumWater.toString(),
                                sumEng.toString(),
                                'الإجمالي العام',
                                '',
                              ])
                        .map(
                          (t) => pw.Container(
                            height: 20,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              toArabicNumbers(t),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8.5,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    ' صورة إلى :',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.Text(
                    ' إدارة المهندسين العسكريين',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    ' إدارة الأشغال العسكرية',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    'التوقيع (                                        )',
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    getLeaderSignature(leader, stretch: 3),
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                  pw.Text(
                    'قائد وحدة تدريب مشترك الهيئة الهندسية',
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  final notSent = allSending
      .where(
        (r) =>
            r['sending_date'] == null || r['sending_date'].toString().isEmpty,
      )
      .toList();
  final sent = allSending
      .where(
        (r) =>
            r['sending_date'] != null &&
            r['sending_date'].toString().isNotEmpty,
      )
      .toList();

  buildReportPage(notSent, "لم تقم باستلام", simpleTable: false);
  buildReportPage(sent, "قامت باستلام", simpleTable: true);

  return pdf;
}

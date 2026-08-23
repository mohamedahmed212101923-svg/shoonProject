import 'package:flutter/services.dart';
import 'package:flutter_application_1/viewmodels/new_batches/get_batch_name.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateAndPrintPdf({
  required String batchid,
  required List<String> weapons,
  required List<String> levels,
  required List<String> types,
  required Map<String, int> grandTotals,
  required Map<String, dynamic> planData,
  required Map<String, String>? leader, // تمرير بيانات القائد هنا
}) async {
  final pdf = pw.Document();

  final fontRegular = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoNaskhArabic-Regular.ttf"),
  );
  final fontBold = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoNaskhArabic-Bold.ttf"),
  );

  String toArabic(String s) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < en.length; i++) {
      s = s.replaceAll(en[i], ar[i]);
    }
    return s;
  }

  // دالة توقيع القائد مع التمدد (الكشيدة)
  String getLeaderSignature(Map<String, String>? leader, {int stretch = 3}) {
    if (leader == null || leader['name'] == null || leader['rank'] == null) {
      return 'غير محدد';
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

  final currentDate = DateFormat('yyyy/MM/dd').format(DateTime.now());

  String getDbKey(String level, String weapon, String type) {
    String l = "";
    if (level == "عليا") {
      l = "high";
    } else if (level == "فوق متوسط")
      l = "above_mid";
    else if (level == "عادة")
      l = "normal";
    else if (level.contains("صف"))
      l = "mid_skill";
    else if (level.contains("مهن"))
      l = "mid_prof";

    final wMap = {
      "مهندسين": "eng",
      "مياه": "water",
      "مساحة": "survey",
      "أشغال": "works",
    };
    final tMap = {"صف": "base", "جوية": "ground", "بحرية": "naval"};
    return "${l}_${wMap[weapon] ?? weapon}_${tMap[type] ?? type}";
  }

  int totalPlannedAll = 0;
  planData.forEach((k, v) => totalPlannedAll += (v as num).toInt());
  int totalReceiptAll = grandTotals.values.fold(0, (a, b) => a + b);

  const double margin = 15.0;
  final double pageWidth = PdfPageFormat.a4.width - (margin * 2);
  const double weaponColWidth = 45.0;
  const double statusColWidth = 50.0;
  const double totalColWidth = 40.0;
  final double remainingWidth =
      pageWidth - weaponColWidth - statusColWidth - totalColWidth;
  final double dataCellWidth = remainingWidth / (levels.length * types.length);

  final details = getBatchDetails(batchid);
  String batchFullInfo =
      "${details['order']} (${details['month']}) لعام ${toArabic(details['year']!)}";

  // بناء الخلية بارتفاع أصغر (35 بدل 40) لتوفير مساحة
  pw.Widget buildCell(
    String text,
    double width, {
    bool isBold = false,
    PdfColor? bgColor,
    double height = 35.0,
    double fontSize = 10.0,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(width: 0.5),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: isBold ? fontBold : fontRegular,
          fontSize: fontSize,
        ),
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      pageFormat: PdfPageFormat.a4.portrait,
      margin: const pw.EdgeInsets.all(margin),
      build: (_) => [
        // ترويسة مصغرة
        ...[
          'الهيئة الهندسية للقــوات المسلحــــــة',
          'وحدة تدريب مشترك الهيئة الهندسية',
          'تاريخ: ${toArabic(currentDate)}',
        ].map(
          (text) => pw.Row(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(font: fontBold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            "يومية عددية بما تم استلامه من تجنيد المرحلة التجنيدية $batchFullInfo",
            style: pw.TextStyle(font: fontBold, fontSize: 13),
          ),
        ),
        pw.SizedBox(height: 10),

        // رأس الجدول
        pw.Row(
          children: [
            buildCell(
              "السلاح",
              weaponColWidth,
              isBold: true,
              bgColor: PdfColors.grey300,
            ),
            buildCell(
              "البيان",
              statusColWidth,
              isBold: true,
              bgColor: PdfColors.grey300,
            ),
            ...levels.map(
              (l) => buildCell(
                l,
                dataCellWidth * types.length,
                isBold: true,
                bgColor: PdfColors.grey300,
              ),
            ),
            buildCell(
              "إجمالي",
              totalColWidth,
              isBold: true,
              bgColor: PdfColors.grey300,
            ),
          ],
        ),

        // صف الفئات
        pw.Row(
          children: [
            buildCell(
              "",
              weaponColWidth,
              bgColor: PdfColors.grey100,
              height: 25,
            ),
            buildCell(
              "",
              statusColWidth,
              bgColor: PdfColors.grey100,
              height: 25,
            ),
            ...levels.expand(
              (l) => types.map(
                (t) => buildCell(
                  t,
                  dataCellWidth,
                  isBold: true,
                  bgColor: PdfColors.grey100,
                  height: 25,
                  fontSize: 9,
                ),
              ),
            ),
            buildCell(
              "",
              totalColWidth,
              bgColor: PdfColors.grey100,
              height: 25,
            ),
          ],
        ),

        // بيانات الأسلحة بارتفاع صفوف داخلي أصغر
        ...weapons.map((w) {
          int pRow = 0;
          int rRow = 0;
          const double innerRowHeight = 35.0; // تقليل الارتفاع من 50 إلى 35
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildCell(
                w,
                weaponColWidth,
                isBold: true,
                height: innerRowHeight * 2,
                fontSize: 10,
              ),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        buildCell(
                          "مخطط",
                          statusColWidth,
                          height: innerRowHeight,
                          fontSize: 9,
                        ),
                        ...levels.expand(
                          (l) => types.map((t) {
                            int v = (planData[getDbKey(l, w, t)] ?? 0) as int;
                            pRow += v;
                            return buildCell(
                              toArabic(v.toString()),
                              dataCellWidth,
                              height: innerRowHeight,
                            );
                          }),
                        ),
                        buildCell(
                          toArabic(pRow.toString()),
                          totalColWidth,
                          isBold: true,
                          height: innerRowHeight,
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        buildCell(
                          "استلام",
                          statusColWidth,
                          bgColor: PdfColors.grey50,
                          height: innerRowHeight,
                          fontSize: 9,
                        ),
                        ...levels.expand(
                          (l) => types.map((t) {
                            int v = grandTotals[getDbKey(l, w, t)] ?? 0;
                            rRow += v;
                            return buildCell(
                              toArabic(v.toString()),
                              dataCellWidth,
                              bgColor: PdfColors.grey50,
                              height: innerRowHeight,
                            );
                          }),
                        ),
                        buildCell(
                          toArabic(rRow.toString()),
                          totalColWidth,
                          isBold: true,
                          bgColor: PdfColors.grey50,
                          height: innerRowHeight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),

        // صفوف الإجماليات الرأسية (المخطط والمستلم)
        ...[true, false].map((isPlan) {
          int totalSum = isPlan ? totalPlannedAll : totalReceiptAll;
          return pw.Row(
            children: [
              buildCell(
                isPlan ? "إجمالي المخطط" : "إجمالي المستلم",
                weaponColWidth + statusColWidth,
                isBold: true,
                bgColor: PdfColors.grey200,
                height: 30,
                fontSize: 9,
              ),
              ...levels.expand(
                (l) => types.map((t) {
                  int colSum = 0;
                  for (var w in weapons) {
                    colSum += isPlan
                        ? (planData[getDbKey(l, w, t)] ?? 0) as int
                        : (grandTotals[getDbKey(l, w, t)] ?? 0);
                  }
                  return buildCell(
                    toArabic(colSum.toString()),
                    dataCellWidth,
                    isBold: true,
                    height: 30,
                  );
                }),
              ),
              buildCell(
                toArabic(totalSum.toString()),
                totalColWidth,
                isBold: true,
                bgColor: PdfColors.grey200,
                height: 30,
              ),
            ],
          );
        }),

        // صفوف الإجماليات النهائية المدمجة
        ...["إجمالي المخطط", "إجمالي المستلم"].map((title) {
          bool isPlan = title.contains("المخطط");
          List<int> sums = [];
          for (int i = 0; i < 3; i++) {
            int s = 0;
            for (var w in weapons) {
              for (var t in types) {
                String key = getDbKey(levels[i], w, t);
                s += isPlan
                    ? (planData[key] ?? 0) as int
                    : (grandTotals[key] ?? 0);
              }
            }
            sums.add(s);
          }
          int midTotal = 0;
          for (int i = 3; i < 5; i++) {
            for (var w in weapons) {
              for (var t in types) {
                String key = getDbKey(levels[i], w, t);
                midTotal += isPlan
                    ? (planData[key] ?? 0) as int
                    : (grandTotals[key] ?? 0);
              }
            }
          }

          return pw.Row(
            children: [
              buildCell(
                title,
                weaponColWidth + statusColWidth,
                isBold: true,
                bgColor: PdfColors.grey300,
                height: 35,
                fontSize: 10,
              ),
              buildCell(
                toArabic(sums[0].toString()),
                dataCellWidth * types.length,
                isBold: true,
                height: 35,
              ),
              buildCell(
                toArabic(sums[1].toString()),
                dataCellWidth * types.length,
                isBold: true,
                height: 35,
              ),
              buildCell(
                toArabic(sums[2].toString()),
                dataCellWidth * types.length,
                isBold: true,
                height: 35,
              ),
              buildCell(
                toArabic(midTotal.toString()),
                dataCellWidth * types.length * 2,
                isBold: true,
                height: 35,
              ),
              buildCell(
                toArabic(
                  isPlan
                      ? totalPlannedAll.toString()
                      : totalReceiptAll.toString(),
                ),
                totalColWidth,
                isBold: true,
                bgColor: PdfColors.grey300,
                height: 35,
              ),
            ],
          );
        }),

        // --- قسم التوقيع بالأسفل ---
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'التوقيع (                                                )',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    getLeaderSignature(leader),
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'قائد وحدة تدريب مشترك الهيئة الهندسية',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(width: 30), // إزاحة بسيطة من جهة اليسار
            ],
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => pdf.save());
}

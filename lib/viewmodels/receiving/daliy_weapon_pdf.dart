import 'package:flutter/services.dart';
import 'package:flutter_application_1/viewmodels/new_batches/get_batch_name.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateWeaponsDailyReport({
  required String batchid,
  required List<String> weapons,
  required List<String> levels,
  required List<String> types,
  required Map<String, int> grandTotals,
  required Map<String, dynamic> planData,
  required Map<String, String>? leader,
  required Map<String, int> movedData,
  required Map<String, int> moqfData,
  required int previousRemaining,
  required int manualBalance,
  required Map<String, int> summaryData,
}) async {
  final pdf = pw.Document();
  String getLeaderSignature(Map<String, String>? leader, {stretch = 3}) {
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

  String getDbKey(String level, String weapon, String type) {
    String l = (level.contains("عليا"))
        ? "high"
        : level.contains("فوق متوسط")
        ? "above_mid"
        : (level.contains("عادة") ||
              level.contains("عادي") ||
              level.contains("عادى"))
        ? "normal"
        : level.contains("مهن")
        ? "mid_prof"
        : "mid_skill";
    final wMap = {
      "مهندسين": "eng",
      "مياه": "water",
      "مساحة": "survey",
      "أشغال": "works",
    };
    final tMap = {"صف": "base", "جوية": "ground", "بحرية": "naval"};
    return "${l}_${wMap[weapon] ?? weapon}_${tMap[type] ?? "base"}";
  }

  // استخراج التاريخ فقط (السنة-الشهر-اليوم) وتنسيقه
  DateTime now = DateTime.now();
  String formattedDate = "${now.year}/${now.month}/${now.day}";

  final details = getBatchDetails(batchid);
  // التنسيق النهائي المطلوب
  String batchFullInfo =
      "${details['order']} (${details['month']}) عن يوم   ${toArabic(formattedDate)}";

  const double margin = 25.0; // كانت 10.0

  // pageWidth سيعيد حساب العرض المتاح تلقائياً بناءً على الهامش الجديد
  final double pageWidth = PdfPageFormat.a4.width - (margin * 2);

  const double weaponColWidth = 55.0;
  const double statusColWidth = 45.0;
  const double totalColWidth = 50.0;
  final double remainingWidth =
      pageWidth - weaponColWidth - statusColWidth - totalColWidth;
  final double dataCellWidth = remainingWidth / (levels.length * types.length);

  pw.Widget buildCell(
    String text,
    double width, {
    bool isBold = false,
    PdfColor? bgColor,
    double height = 20.0,
    double fontSize = 9.0,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(width: 0.6),
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

  // ... (بداية الاستيرادات والدوال الفرعية كما هي)

  // 1. زيادة الهوامش هنا

  pdf.addPage(
    pw.MultiPage(
      textDirection: pw.TextDirection.rtl,
      pageFormat: PdfPageFormat.a4.portrait,
      // تطبيق الهامش الجديد على الصفحة
      margin: const pw.EdgeInsets.all(margin),
      build: (_) => [
        // السطر العلوي (الهيئة الهندسية...)
        ...[
          'الهيئة الهندسية للقــوات المسلحــــــة',
          'وحدة تدريب مشترك الهيئة الهندسية',
          'تاريخ: ${toArabic(currentDate)}',
        ].map(
          (text) => pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: -5),

                // تحسين شكل الخط السفلي
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                  ), // تصغير الخط قليلاً ليتناسب مع الهوامش
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 15),
        pw.Center(
          child: pw.Text(
            "يومية تمام إستقبال وترحيل الجنود المرحلة التجنيدية $batchFullInfo",
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: fontBold, fontSize: 13),
          ),
        ),
        pw.SizedBox(height: 15),

        // --- بداية الجدول الرئيسي ---
        pw.Row(
          children: [
            buildCell(
              "السلاح",
              weaponColWidth,
              isBold: true,
              bgColor: PdfColors.grey400,
              height: 35,
            ),
            buildCell(
              "مخـطط الهـــــيئة",
              statusColWidth,
              isBold: true,
              bgColor: PdfColors.grey400,
              height: 35,
            ),
            ...levels.map(
              (l) => buildCell(
                l,
                dataCellWidth * types.length,
                isBold: true,
                bgColor: PdfColors.grey400,
                height: 35,
              ),
            ),
            buildCell(
              "الإجمالي",
              totalColWidth,
              isBold: true,
              bgColor: PdfColors.grey400,
              height: 35,
            ),
          ],
        ),

        ...weapons.map((w) {
          const double rowH = 20.0;
          const double subHeaderH = 18.0;
          const double totalWeaponHeight = subHeaderH + (rowH * 3);

          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildCell(
                w,
                weaponColWidth,
                isBold: true,
                height: totalWeaponHeight,
                fontSize: 10,
              ),
              pw.Column(
                children: [
                  buildCell(
                    "البيان",
                    statusColWidth,
                    isBold: true,
                    bgColor: PdfColors.grey200,
                    height: subHeaderH,
                    fontSize: 8,
                  ),
                  buildCell(
                    "المخطط",
                    statusColWidth,
                    height: rowH,
                    fontSize: 8,
                    isBold: true,
                  ),
                  buildCell(
                    "ما تم استلامه",
                    statusColWidth,
                    height: rowH,
                    fontSize: 8,
                    isBold: true,
                  ),
                  buildCell(
                    "المرحل",
                    statusColWidth,
                    height: rowH,
                    fontSize: 8,
                    isBold: true,
                  ),
                ],
              ),
              ...levels.expand(
                (l) => types.map((t) {
                  String key = getDbKey(l, w, t);

                  // 1. جلب القيم الخام
                  int p = (planData[key] ?? 0) as int; // المخطط
                  int totalInDb =
                      (grandTotals[key] ??
                      0); // الإجمالي الكلي (الموجود في القاعدة)
                  int movedValue = (movedData[key] ?? 0); // قيمة المرحل فقط
                  int moqfValue =
                      (moqfData[key] ?? 0); // قيمة المواقف فقط (شطب/رفد)

                  // 2. الحسبة الصحيحة:
                  // المستلم (الصافي) = الإجمالي الكلي - المرحل - المواقف
                  int netReceived = totalInDb - movedValue - moqfValue;

                  return pw.Column(
                    children: [
                      buildCell(
                        t,
                        dataCellWidth,
                        isBold: true,
                        fontSize: 7,
                        height: subHeaderH,
                        bgColor: PdfColors.grey200,
                      ),
                      // صف المخطط
                      buildCell(
                        toArabic(p.toString()),
                        dataCellWidth,
                        height: rowH,
                      ),
                      // صف ما تم استلامه (الموجود الفعلي حالياً)
                      buildCell(
                        toArabic(netReceived.toString()),
                        dataCellWidth,
                        height: rowH,
                        isBold: true,
                        bgColor: PdfColors.grey100,
                      ),
                      // صف المرحل (تأكد أن المتغير هنا هو movedValue حصراً)
                      buildCell(
                        toArabic(movedValue.toString()),
                        dataCellWidth,
                        height: rowH,
                      ),
                    ],
                  );
                }),
              ),
              pw.Column(
                children: [
                  buildCell(
                    "",
                    totalColWidth,
                    height: subHeaderH,
                    bgColor: PdfColors.grey200,
                  ),
                  buildCell(
                    toArabic(
                      levels
                          .fold<int>(
                            0,
                            (s, l) =>
                                s +
                                types.fold<int>(
                                  0,
                                  (s2, t) =>
                                      s2 + (planData[getDbKey(l, w, t)] ?? 0)
                                          as int,
                                ),
                          )
                          .toString(),
                    ),
                    totalColWidth,
                    height: rowH,
                    isBold: true,
                  ),
                  buildCell(
                    toArabic(
                      levels
                          .fold<int>(
                            0,
                            (s, l) =>
                                s +
                                types.fold<int>(
                                  0,
                                  (s2, t) =>
                                      s2 +
                                      (grandTotals[getDbKey(l, w, t)] ?? 0) -
                                      (movedData[getDbKey(l, w, t)] ?? 0) -
                                      (moqfData[getDbKey(l, w, t)] ?? 0),
                                ),
                          )
                          .toString(),
                    ),
                    totalColWidth,
                    height: rowH,
                    isBold: true,
                    bgColor: PdfColors.grey300,
                  ),
                  buildCell(
                    toArabic(
                      levels
                          .fold<int>(
                            0,
                            (s, l) =>
                                s +
                                types.fold<int>(
                                  0,
                                  (s2, t) =>
                                      s2 + (movedData[getDbKey(l, w, t)] ?? 0),
                                ),
                          )
                          .toString(),
                    ),
                    totalColWidth,
                    height: rowH,
                    isBold: true,
                  ),
                ],
              ),
            ],
          );
        }),

        // صفوف التخصصات الخارجية والمراحل السابقة
        _buildDashRow(
          "تخصصات خارجية",
          toArabic(manualBalance.toString()),
          weaponColWidth + statusColWidth,
          remainingWidth,
          totalColWidth,
          fontBold,
        ),
        _buildDashRow(
          "مراحل سابقة",
          toArabic(previousRemaining.toString()),
          weaponColWidth + statusColWidth,
          remainingWidth,
          totalColWidth,
          fontBold,
        ),

        ...["إجمالي المخطط", "إجمالي المتبقى", "إجمالي المرحل"].map((title) {
          int grandFinal = 0;
          List<pw.Widget> cells = [];
          for (int i = 0; i < levels.length; i++) {
            String l = levels[i];
            int getV(String lvl) {
              int sum = 0;
              for (var w in weapons) {
                for (var t in types) {
                  String k = getDbKey(lvl, w, t);
                  if (title.contains("المخطط")) {
                    sum += (planData[k] ?? 0) as int;
                  } else if (title.contains("المتبقى"))
                    sum +=
                        (grandTotals[k] ?? 0) -
                        (movedData[k] ?? 0) -
                        (moqfData[k] ?? 0);
                  else if (title.contains("المرحل"))
                    sum += (movedData[k] ?? 0);
                }
              }
              return sum;
            }

            bool isMid = l.contains("متوسط") && !l.contains("فوق");
            if (isMid) {
              int comb = getV(l);
              String? prof = levels.firstWhere(
                (e) => e.contains("مهن"),
                orElse: () => "",
              );
              if (prof.isNotEmpty) comb += getV(prof);
              grandFinal += comb;
              cells.add(
                buildCell(
                  toArabic(comb.toString()),
                  dataCellWidth * types.length * 2,
                  isBold: true,
                  height: 25,
                ),
              );
              if (i + 1 < levels.length && levels[i + 1].contains("مهن")) i++;
            } else if (!l.contains("مهن")) {
              int v = getV(l);
              grandFinal += v;
              cells.add(
                buildCell(
                  toArabic(v.toString()),
                  dataCellWidth * types.length,
                  isBold: true,
                  height: 25,
                ),
              );
            }
          }
          return pw.Row(
            children: [
              buildCell(
                title,
                weaponColWidth + statusColWidth,
                isBold: true,
                bgColor: PdfColors.grey300,
                height: 25,
              ),
              ...cells,
              buildCell(
                toArabic(grandFinal.toString()),
                totalColWidth,
                isBold: true,
                bgColor: PdfColors.grey300,
                height: 25,
              ),
            ],
          );
        }),

        pw.SizedBox(height: 20),
        pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
            "يومية عددية بما تم استلامه من المرحلة $batchFullInfo",
            style: pw.TextStyle(font: fontBold, fontSize: 11),
          ),
        ),
        _buildBottomTable(pageWidth, summaryData, toArabic, fontBold),

        pw.SizedBox(height: 30),
        // قسم التوقيعات
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'صورة إلى :',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.Text(
                    'فرع عمليات الهيئة الهندسية',
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                  pw.Text(
                    'فرع تـدريـب الهيئة الهندسية',
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'التوقيع (                                                 )',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    getLeaderSignature(leader),
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.Text(
                    'قـائـد وحدة تدريب مشترك الهيئة الهندسية ',
                    style: pw.TextStyle(font: fontBold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => pdf.save());
}

pw.Widget _buildDashRow(
  String title,
  String value,
  double labelW,
  double dashW,
  double valW,
  pw.Font font,
) {
  return pw.Row(
    children: [
      pw.Container(
        width: labelW,
        height: 22,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.6)),
        alignment: pw.Alignment.center,
        child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10)),
      ),
      pw.Container(
        width: dashW,
        height: 22,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.6)),
        alignment: pw.Alignment.center,
        child: pw.Text("-"),
      ),
      pw.Container(
        width: valW,
        height: 22,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.6),
          color: PdfColors.grey100,
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}

pw.Widget _buildBottomTable(
  double pageWidth,
  Map<String, int> summaryData,
  String Function(String) toArabic,
  pw.Font fontBold,
) {
  final headers = [
    "المخطط",
    "المستلم",
    "المرحل",
    "شطب",
    "ض.شرطة",
    "ض.حربية",
    "رفد طبى",
    "رفد امنى",
    "رفد عائلئ",
    "وفاة",
    "المتبقى",
  ];
  final keys = [
    "plan",
    "received",
    "moved",
    "شطب",
    "ضم شرطة",
    "ضم حربية",
    "رفد طبى",
    "رفد امنى",
    "رفد عائلئ",
    "حالة وفاة",
    "net",
  ];
  return pw.Column(
    children: [
      pw.Row(
        children: headers
            .map(
              (h) => pw.Container(
                width: pageWidth / 11,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  border: pw.Border.all(width: 0.5),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  h,
                  style: pw.TextStyle(fontSize: 10, font: fontBold),
                ),
              ),
            )
            .toList(),
      ),
      pw.Row(
        children: keys
            .map(
              (k) => pw.Container(
                width: pageWidth / 11,
                height: 25,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  toArabic(summaryData[k]?.toString() ?? "0"),
                  style: pw.TextStyle(fontSize: 10, font: fontBold),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

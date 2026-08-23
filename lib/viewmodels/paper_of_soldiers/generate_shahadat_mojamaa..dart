import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> generateShahadatMojamaa(
  Map<String, dynamic> soldier, {
  Map<String, String>? leader,
}) async {
  final pdf = pw.Document();

  final boldFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoNaskhArabic-Bold.ttf"),
  );
  final RegularFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoNaskhArabic-Regular.ttf"),
  );
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
      final tatweel = 'ـ' * amount; // هنا يتم تكرار الكشيدة بناءً على رغبتك
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

    final extendedRank = applyTatweel(rank, stretch);
    final extendedName = applyTatweel(name, stretch);

    return '$extendedRank / $extendedName';
  }

  // دالة تحويل الأرقام (تستخدمها كما هي)
  String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const hindi = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], hindi[i]);
    }
    return input;
  }

  final List<String> footerTexts = [
    "تــشهــــد وحدة تــــدريب مشترك الهيئة الهندسية بأن المذكور بعالية لم يسبق عرضة علي المجلس الطبي العسكري الفرعي من قبل .",
    "تشهــــد وحدة تــــدريب مشترك الهيئة الهندسية بأن المذكور بعالية ما زال يخدم بالوحدة وليس غياب او شطب",
    "تشهــــد وحدة تــــدريب مشترك الهيئة الهندسية بأن المذكور بعالية غير منتظر محاكم عسكرية او مدنية او تم عرضه على النيابة من قبل من طرفنا",
    "تشهــــد وحدة تــــدريب مشترك الهيئة الهندسية بأن المذكور بعالية لم يسبق رفده من الخدمة من قبل ",
  ];

  pw.Widget buildCell(
    String text, {
    bool isHeader = false,
    bool isName = false,
  }) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: isName
          ? pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Text(
                text,
                style: pw.TextStyle(font: boldFont, fontSize: 11),
              ),
            )
          : pw.Text(
              text,
              style: pw.TextStyle(font: boldFont, fontSize: isHeader ? 12 : 11),
            ),
    );
  }

  pw.Widget buildTable() {
    return pw.Table(
      border: pw.TableBorder.all(width: 1, color: PdfColors.black),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(100),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            buildCell('ملاحظات', isHeader: true),
            buildCell('الاســــم', isHeader: true),
            buildCell('درجة', isHeader: true),
            buildCell('رقم عسكري', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            buildCell(''),
            buildCell(soldier['soldiers_name'] ?? '', isName: true),
            buildCell('جندي'),
            // تطبيق دالة تحويل الأرقام هنا
            buildCell(
              toArabicNumbers(soldier['soldiers_number']?.toString() ?? ''),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget buildHalfPage(String customFooter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          children: [
            pw.Text(
              'الهيئة الهندسية للقوات المسلحـــــــة                ',
              style: pw.TextStyle(font: RegularFont, fontSize: 13),
            ),
          ],
        ),
        pw.Row(
          children: [
            pw.Text(
              'وحدة تدريب مشترك الهيئـة الهندسية',
              style: pw.TextStyle(font: RegularFont, fontSize: 13),
            ),
          ],
        ),
        pw.Center(
          child: pw.Text(
            'شهادة',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
        ),
        pw.SizedBox(height: 10),
        buildTable(),
        pw.SizedBox(height: 10),
        pw.Text(
          customFooter,
          style: pw.TextStyle(font: boldFont, fontSize: 13),
        ),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            'و هذه شهادة منا بذلك ،،',
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
        ),

        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              pw.CrossAxisAlignment.start, // لضمان التحكم في الإزاحة من الأعلى
          children: [
            // الجانب الأيمن (توقيع المختص) - سيبقى في مكانه العادي
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'التوقيع (                                                  )',
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'مكت${'ـ' * 8}ب شئ${'ـ' * 15}ون الطلب${'ـ' * 15}ة',
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                ),
              ],
            ),

            // الجانب الأيسر (الاعتماد) - مُزاح للأسفل
            // استبدل الجزء ده داخل buildHalfPage أو داخل الصفحة الأولى عند التوقيع الأيسر
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 25),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'التوقيع (                                                  )',
                    style: pw.TextStyle(font: boldFont, fontSize: 14),
                  ),
                  pw.Text(
                    getLeaderSignature(leader),
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      // يباعد بين الكلمات مع الحفاظ على اتصال حروف الكلمة الواحدة
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.Text(
                    'قائد وحدة تدريب مشترك الهيئة الهندسية',
                    style: pw.TextStyle(font: boldFont, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      textDirection: pw.TextDirection.rtl,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'بيانات المذكور علي نفس الشهادة',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.Center(
              child: pw.Text(
                'شهادات عرض خاصة المذكور بعد',
                style: pw.TextStyle(font: boldFont, fontSize: 20),
              ),
            ),
            pw.SizedBox(height: 10),
            buildTable(), // استخدام نفس الجدول
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 3, color: PdfColors.black), // خط بعد الجدول
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("1")}-	 تشهد الوحدة بان المذكور لم يتم عرضه على المجلس الطبي الفرعي من قبل ",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("2")}-	 تشهد الوحدة بان المذكور لم يحاكم على جريمة مخلة بالشرف.",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("3")}-	 تشهد الوحدة بان المذكور مازال بالخدمة و ليس غياب او هروب ولم يصدر ",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "      في شأنه من قبل (${toArabicNumbers('20')}س) لإنهاء خدمته لأي سبب من الاسباب ",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("4")}-	 تشهد الوحدة بان المذكور غير منتظر اي محاكم عسكرية او مدنية ",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),

            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("5")}-	 تشهد الوحدة بان المذكور ليس مصاب اثناء الخدمة ",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("6")}-	 تشهد الوحدة بان المذكور عنوانه المدني هو  (${soldier['soldiers_address'].toString()} / ${soldier['soldiers_city'].toString()}) ",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("7")}-	 تشهد الوحدة بان جماعة البريد رقم      (    ج${toArabicNumbers('24')}    )",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),

            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("8")}-	 تشهد الوحدة بان النموذج ${toArabicNumbers('1')}س مكرر مطابق للنموذج ${toArabicNumbers('1')}س الاصل للمذكور",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("9")}-	 تشهد الوحدة بان المذكور ليس عليه ديون أميرية او نفقة شرعية ",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("10")}- تشهد الوحدة بان المذكور ليس حادث اثناء الخدمة",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text(
                  "${toArabicNumbers("11")}- تشهد الوحدة بان المذكور تاريخ بدء المرض (قبل الخدمة)",
                  style: pw.TextStyle(font: RegularFont, fontSize: 18),
                ),
              ],
            ),
            pw.SizedBox(height: 5),

            pw.Center(
              child: pw.Text(
                "وهذه شهادة منا بذلك ,,,",
                style: pw.TextStyle(font: boldFont, fontSize: 18),
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw
                  .CrossAxisAlignment
                  .start, // لضمان التحكم في الإزاحة من الأعلى
              children: [
                // الجانب الأيمن (توقيع المختص) - سيبقى في مكانه العادي
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'التوقيع (                                                  )',
                      style: pw.TextStyle(font: boldFont, fontSize: 14),
                    ),
                    pw.Text(
                      'مكت${'ـ' * 8}ب شئ${'ـ' * 15}ون الطلب${'ـ' * 15}ة',
                      style: pw.TextStyle(font: boldFont, fontSize: 14),
                    ),
                  ],
                ),

                // الجانب الأيسر (الاعتماد) - مُزاح للأسفل
                // استبدل الجزء ده داخل buildHalfPage أو داخل الصفحة الأولى عند التوقيع الأيسر
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 25),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'التوقيع (                                                  )',
                        style: pw.TextStyle(font: boldFont, fontSize: 14),
                      ),
                      pw.Text(
                        getLeaderSignature(leader),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          // يباعد بين الكلمات مع الحفاظ على اتصال حروف الكلمة الواحدة
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        'قائد وحدة تدريب مشترك الهيئة الهندسية',
                        style: pw.TextStyle(font: boldFont, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // إضافة 11 سطر ثابت
          ],
        );
      },
    ),
  );

  for (int i = 0; i < 4; i++) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            children: [
              pw.Expanded(
                child: pw.Center(child: buildHalfPage(footerTexts[i])),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 15),
                child: pw.Divider(
                  thickness: 1.5, // سماكة الخط
                  color: PdfColors.black,
                  borderStyle: pw.BorderStyle.solid, // خط متصل تماماً
                ),
              ),
              pw.Expanded(
                child: pw.Center(child: buildHalfPage(footerTexts[i])),
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf;
}

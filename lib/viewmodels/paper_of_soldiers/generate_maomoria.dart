import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> generateMa2moria({Map<String, String>? leader}) async {
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

  //String selectedDate2 = DateFormat('yyyy/MM/dd').format(DateTime.now());

  final List<String> footerTexts = [
    "قادم لكم  اليوم (                 ) الموافق      /      /  ${toArabicNumbers("2026")}   مندوبنا             /                           ",
  ];

  final List<String> footerText2 = [
    "وذلك لتسليم الأوراق المطلوبة خاصة الجنود المقبولين بكلية الشرطة.",
  ];

  pw.Widget buildHalfPage(String customFooter, String customFooter2) {
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
        pw.Row(
          children: [
            pw.Text(
              'التـــاريخ :      /      /  ${toArabicNumbers("2026")}',
              //'التـــاريخ: $selectedDate2',
              style: pw.TextStyle(font: RegularFont, fontSize: 13),
            ),
          ],
        ),
        pw.Center(
          child: pw.Text(
            'إلى /  ',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
        ),
        pw.SizedBox(height: 10),

        pw.SizedBox(height: 10),
        pw.Text(
          customFooter,
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),

        pw.SizedBox(height: 10),
        pw.Text(
          customFooter2,
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),

        pw.SizedBox(height: 15),
        pw.Center(
          child: pw.Text(
            'مع وافر التحية ،،، ',
            style: pw.TextStyle(font: boldFont, fontSize: 18),
          ),
        ),

        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          crossAxisAlignment:
              pw.CrossAxisAlignment.start, // لضمان التحكم في الإزاحة من الأعلى
          children: [
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
      margin: const pw.EdgeInsets.all(35),
      textDirection: pw.TextDirection.rtl,
      build: (context) {
        return pw.Column(
          children: [
            pw.Expanded(
              child: pw.Center(
                child: buildHalfPage(footerTexts[0], footerText2[0]),
              ),
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
              child: pw.Center(
                child: buildHalfPage(footerTexts[0], footerText2[0]),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf;
}

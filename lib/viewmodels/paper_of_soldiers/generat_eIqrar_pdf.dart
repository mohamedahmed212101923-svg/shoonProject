import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> generateIqrarPdf(Map<String, dynamic> soldier) async {
  final pdf = pw.Document();

  // تحميل الخط العربي
  final boldFont = pw.Font.ttf(
    await rootBundle.load("assets/fonts/NotoNaskhArabic-Bold.ttf"),
  );

  // تحويل الأرقام العربية
  String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const hindi = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], hindi[i]);
    }
    return input;
  }

  // دالة بناء محتوى الإقرار
  pw.Widget buildIqrarContent() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Center(
          child: pw.Text(
            'اقـــــــــرار',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 20,
            ), // تكبير الخط قليلاً
          ),
        ),
        pw.SizedBox(height: 15), // زيادة المسافات لتوزيع أفضل
        pw.SizedBox(
          width: double.infinity,
          child: pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw
                .Alignment
                .centerRight, // لضمان بقاء النص جهة اليمين عند التصغير
            child: pw.Text(
              'اقر انا رقم عسكري : ${toArabicNumbers(soldier['soldiers_number'].toString())}    '
              'درجة : جندي    '
              'اســــم : ${soldier['soldiers_name'] ?? ''}',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'بان تاريخ المرض الخاص بى هو : يوم (   -   )  شهر (    -    )   سنه  (    -    )'
          "      قبل الخدمة",
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),

        pw.SizedBox(height: 15),
        pw.Text(
          'الــــمــقــر بــمــا فـــيـــه :',
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        pw.SizedBox(height: 10),
        pw.SizedBox(
          width: double.infinity, // لضمان استخدام كامل عرض الصفحة
          child: pw.FittedBox(
            fit: pw
                .BoxFit
                .scaleDown, // سيقوم بتصغير الخط فقط إذا كان النص طويلاً جداً
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'رقم عسكري / ${toArabicNumbers(soldier['soldiers_number'].toString())}    '
              'درجـــــــــــة / جندي     '
              'اســــــــــــــم / ${soldier['soldiers_name'] ?? ''}',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'الــتــوقـــيــع / ',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.Text(
              'يعتمد ،،،                      ',
              style: pw.TextStyle(font: boldFont, fontSize: 25),
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'الــــبــصـمــة / ',
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
      ],
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      textDirection: pw.TextDirection.rtl,
      build: (context) {
        return pw.Column(
          children: [
            // الإقرار الأول في النصف العلوي
            pw.Expanded(child: pw.Center(child: buildIqrarContent())),

            // فاصل في منتصف الصفحة تماماً
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Divider(thickness: 1.5, color: PdfColors.grey400),
            ),

            // الإقرار الثاني في النصف السفلي
            pw.Expanded(child: pw.Center(child: buildIqrarContent())),
          ],
        );
      },
    ),
  );

  return pdf;
}

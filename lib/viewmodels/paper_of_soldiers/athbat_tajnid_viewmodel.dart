import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

Future<pw.Document> generateAthbatTajnidPdf(
  Map<String, dynamic> soldier,
) async {
  final pdf = pw.Document();

  // تحميل الخط العربي (Bold)
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

  final currentDate = DateFormat('yyyy/MM/dd').format(DateTime.now());

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      textDirection: pw.TextDirection.rtl,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header ثابت
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text('•', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.SizedBox(width: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: -5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 1, color: PdfColors.black),
                    ),
                  ),
                  child: pw.Text(
                    'رقم الوحدة (٢٧٩١) جــ ٢٤',
                    style: pw.TextStyle(font: boldFont, fontSize: 14),
                  ),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text('•', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.SizedBox(width: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: -5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 1, color: PdfColors.black),
                    ),
                  ),
                  child: pw.Text(
                    'تاريخ: ${toArabicNumbers(currentDate)}',
                    style: pw.TextStyle(font: boldFont, fontSize: 14),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 100),

            // عنوان الجواب
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.5),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'إثبــات تجنـيــــد',
                      style: pw.TextStyle(font: boldFont, fontSize: 17),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // جدول بيانات الجندي
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 3),
              headerAlignment: pw.Alignment.center,
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 14),
              cellAlignment: pw.Alignment.center,
              cellStyle: pw.TextStyle(font: boldFont, fontSize: 14),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(1),
              },
              data: [
                [
                  toArabicNumbers(soldier['soldiers_number'].toString()),
                  'الـــــــــــــــــــــــــــرقم العسكــــــــــــــــــــــــــــري',
                ],
                [
                  'جندي مستجد',
                  'الـــــــــــدرجــــــــــــــــــــــــــــــــــــــــــــــــــــــة',
                ],
                [
                  soldier['soldiers_name'] ?? '',
                  'الإســـــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــــم',
                ],
                [
                  'وحدة تدريب مشترك الهيئة الهندسية',
                  'الــــــــــــــــوحــــــــــــــــــــــدة الحــــــــــاليـــــة',
                ],
                [
                  soldier['soldiers_qualification'] ?? '',
                  'مــــــــــــــــدة الخــــــــــــــدمـة المقـــــــــــــررة',
                ],
                [
                  toArabicNumbers(
                    soldier['soldiers_triple_number']?.toString() ?? '',
                  ),
                  'رقـــم بطـــاقة الخـــدمة العسكـــرية والوطنيـــة',
                ],
                [
                  toArabicNumbers(
                    soldier['soldiers_military_date'] is DateTime
                        ? DateFormat(
                            'yyyy/MM/dd',
                          ).format(soldier['soldiers_military_date'])
                        : (soldier['soldiers_military_date']?.toString() ?? ''),
                  ),
                  'تــــاريــــــــــــــــــخ التجنيــــــــــــــــــــــــــــــد',
                ],
              ],
            ),
            pw.SizedBox(height: 90),

            // التوقيع
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'التوقيع (                                                            )',
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'قائـــــد الوحـــــــــدة رقــــــــــم ٢٧٩١ جــــــ٢٤',
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf;
}

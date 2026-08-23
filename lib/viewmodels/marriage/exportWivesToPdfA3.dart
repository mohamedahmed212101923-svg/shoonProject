import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// تحويل الأرقام للعربية
String toArabic(String s) {
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < en.length; i++) {
    s = s.replaceAll(en[i], ar[i]);
  }
  return s;
}

/// الدالة الأساسية ببناء الـ PDF مع هوامش 0.5 من كل جانب وبدون خط العنوان
Future<Uint8List> buildPdfBytes(Map<String, dynamic> data) async {
  final List<Map<String, String>> soldiers = List<Map<String, String>>.from(
    data['soldiers'],
  );
  final Uint8List regularFontData = data['regularFont'];
  final Uint8List boldFontData = data['boldFont'];

  final pdf = pw.Document(compress: true);
  final regular = pw.Font.ttf(ByteData.view(regularFontData.buffer));
  final bold = pw.Font.ttf(ByteData.view(boldFontData.buffer));

  final headers = [
    'م',
    'الاسم',
    'تاريخ التجنيد',
    'تاريخ الضم',
    'منطقة التجنيد',
    'الاتجاه',
    'المؤهل',
    'التخصص',
    'العنوان',
    'السرية',
    'الفصيلة',
    'السجل',
    'ملاحظات',
  ];

  const int rowsPerPage = 31;
  final int totalPages = (soldiers.length / rowsPerPage).ceil();

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final int start = pageIndex * rowsPerPage;
    final int end = (start + rowsPerPage < soldiers.length)
        ? start + rowsPerPage
        : soldiers.length;
    final List<Map<String, String>> chunk = soldiers.sublist(start, end);

    pdf.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a3.landscape,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        margin: const pw.EdgeInsets.all(14.17), // تعادل 0.5 سم
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // العنوان بدون خط سفلي
              pw.Container(
                child: pw.Center(
                  child: pw.Text(
                    'دفتر قيد المستجدين',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 5),

              pw.Expanded(
                child: pw.TableHelper.fromTextArray(
                  headers: headers.reversed.toList(),
                  data: chunk.asMap().entries.map((entry) {
                    final int globalIndex = start + entry.key + 1;
                    final s = entry.value;
                    final row = [
                      toArabic(globalIndex.toString()),
                      s['soldiers_name'] ?? '',
                      toArabic(s['soldiers_military_date'] ?? ''),
                      toArabic(s['soldiers_income_date'] ?? ''),
                      s['soldiers_area'] ?? '',
                      s['soldiers_direction'] ?? '',
                      s['soldiers_qualification'] ?? '',
                      s['soldiers_specialization'] ?? '',
                      s['soldiers_address'] ?? '',
                      s['soldiers_s'] ?? '',
                      s['soldiers_f'] ?? '',
                      toArabic(s['soldiers_unit_id'] ?? ''),
                      '',
                    ];
                    return row.reversed.toList();
                  }).toList(),

                  headerStyle: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                  ),

                  cellStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    vertical: 3.5,
                    horizontal: 4,
                  ),
                  cellAlignment: pw.Alignment.center,

                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                  ),
                  oddRowDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),

                  columnWidths: {
                    12: const pw.FixedColumnWidth(40),
                    11: const pw.FlexColumnWidth(3.5),
                    4: const pw.FlexColumnWidth(2),
                    0: const pw.FlexColumnWidth(1.5),
                  },
                  border: pw.TableBorder.all(width: 0.7),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf.save();
}

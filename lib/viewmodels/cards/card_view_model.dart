import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import '../../services/database/soldiers_repository.dart';

class CardsViewModel extends ChangeNotifier {
  final SoldiersRepository repo;

  CardsViewModel(this.repo);

  String? batchId;

  List<String> katibaOptions = [];
  List<String> selectedKatiba = [];

  bool isLoading = false;

  void updateBatch(String? newBatchId) {
    batchId = newBatchId;
    loadKatiba();
  }

  Future<void> loadKatiba() async {
    if (batchId == null) return;

    isLoading = true;
    notifyListeners();

    katibaOptions = await repo.getkatiba();

    isLoading = false;
    notifyListeners();
  }

  void toggleKatiba(String k) {
    if (selectedKatiba.contains(k)) {
      selectedKatiba.remove(k);
    } else {
      selectedKatiba.add(k);
    }
    notifyListeners();
  }

  bool isKatibaSelected(String k) => selectedKatiba.contains(k);

  Future<File> generateCardsPdf() async {
    if (batchId == null) {
      throw "لم يتم اختيار دفعة";
    }
    if (selectedKatiba.isEmpty) {
      throw "يجب اختيار كتيبة واحدة على الأقل";
    }

    isLoading = true;
    notifyListeners();

    /// تحميل بيانات كل الدفعة
    final data = await repo.getSoldiersForCards(batchId!, selectedKatiba);

    final filtered = data.where((s) {
      final k = s["soldiers_k"]?.toString().trim() ?? "";
      return selectedKatiba.contains(k);
    }).toList();

    /// لو مفيش ولا حد بعد الفلترة
    if (filtered.isEmpty) {
      isLoading = false;
      notifyListeners();
      throw "لا يوجد أفراد في الكتائب المختارة.";
    }

    /// ------------------- نفس الكود القديم للـ PDF -------------------
    final arabicFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoNaskhArabic-Bold.ttf"),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
    );

    const cardsPerRow = 3;
    const rowsPerPage = 6;
    const cardsPerPage = cardsPerRow * rowsPerPage;

    for (int i = 0; i < filtered.length; i += cardsPerPage) {
      final pageItems = filtered.skip(i).take(cardsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Column(
              children: List.generate(rowsPerPage, (row) {
                final start = row * cardsPerRow;
                if (start >= pageItems.length) return pw.SizedBox();

                final rowCards = pageItems
                    .skip(start)
                    .take(cardsPerRow)
                    .toList();

                return pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: rowCards.map((soldier) {
                        final id = soldier["soldiers_number"]?.toString() ?? "";

                        bool hasBarcode = id.isNotEmpty;
                        String? barcodeSvg;

                        if (hasBarcode) {
                          try {
                            final barcode = Barcode.code128();
                            barcodeSvg = barcode.toSvg(id, height: 40);
                          } catch (_) {
                            hasBarcode = false;
                          }
                        }

                        return pw.Container(
                          width: PdfPageFormat.a4.width / 3 - 20,
                          height: 120,
                          padding: const pw.EdgeInsets.all(15),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                          ),
                          child: pw.Directionality(
                            textDirection: pw.TextDirection.rtl,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.FittedBox(
                                  child: pw.Text(
                                    soldier["soldiers_name"] ?? "",
                                    style: pw.TextStyle(
                                      font: arabicFont,
                                      fontSize: 12,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Text(
                                  "${soldier["soldiers_k"]}  "
                                  "${soldier["soldiers_s"]}  "
                                  "${soldier["soldiers_f"]}  ",

                                  style: pw.TextStyle(
                                    font: arabicFont,
                                    fontSize: 11,
                                  ),
                                ),
                                pw.SizedBox(height: 6),

                                if (hasBarcode && barcodeSvg != null)
                                  pw.SvgImage(svg: barcodeSvg)
                                else
                                  pw.Text(
                                    "لا يوجد باركود",
                                    style: pw.TextStyle(
                                      font: arabicFont,
                                      fontSize: 10,
                                    ),
                                  ),

                                pw.SizedBox(height: 4),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    pw.SizedBox(height: 10),
                  ],
                );
              }),
            );
          },
        ),
      );
    }

    /// ------------------- نافذة حفظ Windows -------------------
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف PDF',
      fileName: 'cards_$batchId.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath == null) {
      isLoading = false;
      notifyListeners();
      throw "تم إلغاء حفظ الملف";
    }

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());

    isLoading = false;
    notifyListeners();

    return file;
  }
}

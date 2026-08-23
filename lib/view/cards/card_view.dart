import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cards/card_view_model.dart';

class CardsView extends StatelessWidget {
  const CardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardsViewModel>();

    return Scaffold(
      body: vm.katibaOptions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================
                  // عنوان اختيار الكتيبة
                  // =============================
                  const Text(
                    "اختر الكتيبة (يمكن اختيار أكثر من كتيبة)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // =============================
                  // Multi-Select باستخدام ChoiceChip
                  // =============================
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: vm.katibaOptions.map((k) {
                      final selected = vm.isKatibaSelected(k);
                      return ChoiceChip(
                        label: Text(k),
                        selected: selected,
                        selectedColor: Colors.blue.shade300,
                        onSelected: (_) => vm.toggleKatiba(k),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // =============================
                  // زر استخراج PDF
                  // =============================
                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text(
                              "استخراج كروت",
                              style: TextStyle(fontSize: 18),
                            ),
                            onPressed: vm.selectedKatiba.isEmpty
                                ? null
                                : () async {
                                    try {
                                      final file = await vm.generateCardsPdf();

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "تم حفظ الملف: ${file.path}",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("خطأ: $e"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/paper_of_soldiers/generat_eIqrar_pdf.dart';
import 'package:flutter_application_1/viewmodels/paper_of_soldiers/generate_shahadat_mojamaa..dart';
import 'package:flutter_application_1/viewmodels/paper_of_soldiers/jawabat_view_model.dart';
import 'package:flutter_application_1/viewmodels/paper_of_soldiers/kpeer_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_application_1/viewmodels/paper_of_soldiers/athbat_tajnid_viewmodel.dart';

class JawabatView extends StatefulWidget {
  const JawabatView({super.key});

  @override
  State<JawabatView> createState() => _JawabatViewState();
}

class _JawabatViewState extends State<JawabatView> {
  late TextEditingController _controller;
  bool showList = true; // يتحكم في ظهور القائمة

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<JawabatViewModel>(context, listen: false);
    _controller = TextEditingController(
      text: vm.selectedSoldier?['soldiers_name'] ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<JawabatViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== اختيار الجندي =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'اختر الجندي',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showList = true; // عند الضغط على المربع تظهر القائمة
                      });
                    },
                    child: AbsorbPointer(
                      absorbing: false,
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText:
                              'ابحث باسم الجندي أو الرقم العسكري أو رقم السجل',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () {
                          setState(() {
                            showList = true; // عند الضغط تظهر القائمة
                          });
                        },
                        onChanged: (query) {
                          vm.filterSoldiers(query);
                          setState(() {
                            showList = true; // تظهر القائمة عند الكتابة
                          });
                          // إلغاء أي اختيار سابق
                          if (vm.selectedSoldier != null &&
                              query != vm.selectedSoldier!['soldiers_name']) {
                            vm.selectSoldier(null);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (showList) // ظهور القائمة بناءً على الحالة
                    vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : (vm.filteredSoldiers.isEmpty
                              ? const SizedBox.shrink()
                              : SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    itemCount: vm.filteredSoldiers.length,
                                    itemBuilder: (context, index) {
                                      final s = vm.filteredSoldiers[index];
                                      return ListTile(
                                        leading: const Icon(Icons.person),
                                        title: Text(s['soldiers_name'] ?? ''),
                                        subtitle: Text(
                                          'رقم عسكري: ${s['soldiers_number']} - رقم سجل: ${s['soldiers_triple_number']}',
                                        ),
                                        onTap: () {
                                          vm.selectSoldier(s);
                                          _controller.text =
                                              s['soldiers_name'] ?? '';
                                          setState(() {
                                            showList =
                                                false; // بعد الاختيار تختفي القائمة
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ===== جوابات الجنود =====
            Expanded(
              child: vm.selectedSoldier == null
                  ? const Center(
                      child: Text(
                        'اختر جندي لعرض الجوابات',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: JawabCard(
                                  title: 'إثبات تجنيد',
                                  soldier: vm.selectedSoldier!,
                                  generatePdf: generateAthbatTajnidPdf,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: JawabCard(
                                  title: 'اقرار طبى',
                                  soldier: vm.selectedSoldier!,
                                  generatePdf: generateIqrarPdf,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: JawabCard(
                                  title: 'شهادات مجمعة',
                                  soldier: vm.selectedSoldier!,
                                  generatePdf: (soldier) =>
                                      generateShahadatMojamaa(
                                        soldier,
                                        leader: vm
                                            .leader, // هنا بنمرر الاسم والرتبة
                                      ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: JawabCard(
                                  title: 'شهادات كبير عائلة',
                                  soldier: vm.selectedSoldier!,
                                  generatePdf: (soldier) =>
                                      generateShahadatkpeer(
                                        soldier,
                                        leader: vm
                                            .leader, // هنا بنمرر الاسم والرتبة
                                      ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              /*
                              Expanded(
                                child: JawabCard(
                                  title: 'جواب ماموريه',
                                  soldier: vm.selectedSoldier!,
                                  generatePdf: (soldier) => generateMa2moria(
                                    soldier,
                                    leader:
                                        vm.leader, // هنا بنمرر الاسم والرتبة
                                  ),
                                ),
                              ),*/
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Widget لإعادة استخدامه لكل جواب =====
class JawabCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> soldier;
  final Future<pw.Document> Function(Map<String, dynamic>) generatePdf;

  const JawabCard({
    super.key,
    required this.title,
    required this.soldier,
    required this.generatePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final pdf = await generatePdf(soldier);
              await Printing.layoutPdf(onLayout: (format) => pdf.save());
            },
            child: Text('طباعة $title'),
          ),
        ],
      ),
    );
  }
}

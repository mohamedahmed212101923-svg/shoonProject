import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart'; // تأكد من إضافة الحزمة في pubspec.yaml
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/viewmodels/presentations_viewmodel.dart';

// ملاحظة: دالة buildExcelBytes يجب أن تكون معرفة خارج الكلاس أو في ملف منفصل لتستخدم مع compute
// سنفترض وجودها في الـ ViewModel أو ملف helpers

class PresentationScreen extends StatelessWidget {
  final ScrollController _scroll1 = ScrollController();
  final ScrollController _scroll2 = ScrollController();

  PresentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentBatchId = context.select(
      (PresentationViewModel vm) => vm.batchId,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Colors.white,
          title: const Text(
            "نظام إدارة العروض الطبية",
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2563EB),
            indicatorWeight: 4,
            tabs: [
              Tab(
                child: Text(
                  "اللجنة الأولى",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  "اللجنة الثانية",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        body: currentBatchId == null
            ? _buildNoSelectionPlaceholder(theme)
            : TabBarView(
                children: [
                  CommitteeTabContent(order: 1, scroll: _scroll1),
                  CommitteeTabContent(order: 2, scroll: _scroll2),
                ],
              ),
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 100,
            color: Colors.blue.shade100,
          ),
          const SizedBox(height: 20),
          const Text(
            "لم يتم اختيار دفعة بعد",
            style: TextStyle(
              fontSize: 22,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "اختر الدفعة من القائمة الجانبية لعرض بيانات اللجان",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class CommitteeTabContent extends StatefulWidget {
  final int order;
  final ScrollController scroll;

  const CommitteeTabContent({
    super.key,
    required this.order,
    required this.scroll,
  });

  @override
  State<CommitteeTabContent> createState() => _CommitteeTabContentState();
}

class _CommitteeTabContentState extends State<CommitteeTabContent> {
  String searchQuery = ""; // نص البحث داخل الجدول

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PresentationViewModel>();
    final committee = widget.order == 1
        ? vm.committeeFirst
        : vm.committeeSecond;
    final allResults = widget.order == 1
        ? vm.firstCommitteeResults
        : vm.secondCommitteeResults;

    // تصفية النتائج بناءً على نص البحث (الاسم أو الرقم العسكري)
    final filteredResults = allResults.where((s) {
      final name = (s['soldiers_name'] ?? "").toString();
      final num = (s['soldiers_number'] ?? "").toString();
      return name.contains(searchQuery) || num.contains(searchQuery);
    }).toList();

    int unfitCount = allResults
        .where((e) => e['pres_result'] == 'لجنة فرعية')
        .length;
    int backCount = allResults.where((e) => e['pres_result'] == 'لائق').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dashboard الإحصائيات
          Row(
            children: [
              _buildMiniStatCard(
                "تاريخ اللجنة",
                committee?['committee_date'] ?? 'حدد التاريخ',
                Icons.event,
                Colors.blue,
                isDate: true,
                onEdit: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    vm.saveCommitteeDate(
                      widget.order,
                      picked.toString().split(' ')[0],
                    );
                  }
                },
              ),
              _buildMiniStatCard(
                "إجمالي العرض",
                "${allResults.length}",
                Icons.people,
                Colors.indigo,
              ),
              _buildMiniStatCard(
                "لائق",
                "$backCount",
                Icons.check_circle,
                Colors.green,
              ),
              _buildMiniStatCard(
                "لجنة فرعية",
                "$unfitCount",
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 25),

          // 2. نموذج الإدخال
          if (committee != null)
            _buildEntryPanel(context, vm, committee, allResults),

          const SizedBox(height: 25),

          // 3. كارد البحث والتصدير
          _buildSearchAndExportBar(vm, filteredResults),

          const SizedBox(height: 15),

          // 4. الجدول
          _buildDataTable(context, filteredResults, vm),
        ],
      ),
    );
  }

  Widget _buildSearchAndExportBar(
    PresentationViewModel vm,
    List<Map<String, dynamic>> dataToExport,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                decoration: InputDecoration(
                  hintText:
                      "بحث سريع في الأسماء أو الأرقام العسكرية بالجدول...",
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),

            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.all_inbox, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "تصفية الباقي ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              onPressed: () async {
                await vm.updatetasfeya();
                print("test");
              },
            ),
            const SizedBox(width: 15),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade900,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.file_download_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "تصدير اكسيل",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              onPressed: () async {
                // استخراج العناوين ديناميكياً من الأعمدة المعرفة في الـ ViewModel
                final headersTexts = vm.presentationColumns.map((col) {
                  final w = col.label;
                  if (w is Text) return w.data ?? '';
                  if (w is Center && w.child is Text)
                    return (w.child as Text).data ?? '';
                  if (w is Align && w.child is Text)
                    return (w.child as Text).data ?? '';
                  return '';
                }).toList();

                // تشغيل بناء ملف Excel
                final bytes = await compute(
                  buildExcelBytes, // تأكد أن هذه الدالة موجودة في الـ VM وتستقبل Map
                  {
                    'data': dataToExport,
                    'headersTexts': headersTexts,
                    'headersKeys': vm.soldierKeys,
                  },
                );

                final location = await getSaveLocation(
                  suggestedName: "نتائج_اللجنة_${widget.order}.xlsx",
                  acceptedTypeGroups: [
                    const XTypeGroup(label: "Excel", extensions: ["xlsx"]),
                  ],
                );

                if (location == null) return;
                final file = File(
                  location.path.endsWith(".xlsx")
                      ? location.path
                      : "${location.path}.xlsx",
                );
                await file.writeAsBytes(bytes);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم حفظ ملف الإكسيل بنجاح")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- دوال المساعد (Helper Widgets) ---

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isDate = false,
    VoidCallback? onEdit,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(bottom: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isDate)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryPanel(
    BuildContext context,
    PresentationViewModel vm,
    Map<String, dynamic> committee,
    List<Map<String, dynamic>> results,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person_search, color: Colors.blue),
                const SizedBox(width: 10),
                const Text(
                  "تسجيل عرض طبي جديد",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (vm.selectedSoldier != null)
                  TextButton.icon(
                    onPressed: () => vm.selectSoldier({}),
                    icon: const Icon(Icons.close),
                    label: const Text("إلغاء"),
                  ),
              ],
            ),
            const Divider(height: 30),
            TextField(
              onChanged: vm.searchSoldier,
              decoration: InputDecoration(
                hintText: "بحث عن جندي لإضافته (اسم أو رقم)...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.blueGrey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (vm.searchResults.isNotEmpty) _buildSearchResults(vm),
            if (vm.selectedSoldier != null) ...[
              const SizedBox(height: 20),
              _buildSelectedSoldierInfo(vm),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldLabel(
                      "العيادة المختصة",
                      _buildDropdown(vm.selectedClinic, [
                        'باطنة',
                        'قلب',
                        'رمد',
                        'عظام',
                        'نفسية',
                        'جراحة',
                        'جلدية',
                        'اسنان',
                        'تخاطب',
                        'انف واذن',
                      ], (v) => vm.updateClinic(v!)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildFieldLabel(
                      "قرار اللجنة",
                      _buildDropdown(vm.selectedResult, [
                        'لائق',
                        'لجنة فرعية',
                        'عرض',
                      ], (v) => vm.updateResult(v!)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  _buildSubmitButton(vm, committee, results),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSoldierInfo(PresentationViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.how_to_reg, color: Colors.blue),
          const SizedBox(width: 15),
          Text("تم اختيار: ", style: TextStyle(color: Colors.blue.shade900)),
          Text(
            vm.selectedSoldier!['soldiers_name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    PresentationViewModel vm,
    Map<String, dynamic> committee,
    List<Map<String, dynamic>> results,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () =>
            vm.addSoldierToCommittee(committee['committee_id'], results),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          "إضافة للكشف",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSearchResults(PresentationViewModel vm) {
    return Card(
      margin: const EdgeInsets.only(top: 5),
      elevation: 4,
      child: Column(
        children: vm.searchResults
            .map(
              (s) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(s['soldiers_name']),
                subtitle: Text(
                  "رقم: ${s['soldiers_number']} - كتيبة: ${s['soldiers_k']}",
                ),
                onTap: () => vm.selectSoldier(s),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    List<Map<String, dynamic>> results,
    PresentationViewModel vm,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Scrollbar(
        controller: widget.scroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: widget.scroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1200,
            child: PaginatedDataTable(
              key: vm.tableKey,
              rowsPerPage: results.isEmpty
                  ? 1
                  : (results.length > 10 ? 10 : results.length),
              columns: vm.presentationColumns,
              source: PresentationDataSource(context, results, vm),
              showCheckboxColumn: false,
            ),
          ),
        ),
      ),
    );
  }
}

// PresentationDataSource يبقى كما هو في كودك السابق مع التأكد من استدعاء vm للتعديل والحذف
class PresentationDataSource extends DataTableSource {
  final BuildContext context;
  final List<Map<String, dynamic>> data;
  final PresentationViewModel vm;

  PresentationDataSource(this.context, this.data, this.vm);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final s = data[index];
    final resultText = s["pres_result"] ?? "";
    Color statusColor = resultText == 'لجنة فرعية'
        ? Colors.red
        : (resultText == 'لائق' ? Colors.green : Colors.orange);

    return DataRow(
      cells: [
        DataCell(
          Text(
            s["soldiers_name"] ?? "",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text(s["soldiers_number"] ?? "")),
        DataCell(Text(s["soldiers_k"] ?? "")),
        DataCell(Text(s["soldiers_s"] ?? "")),
        DataCell(Text(s["soldiers_f"] ?? "")),
        DataCell(Text(s["soldiers_unit_id"].toString())),
        DataCell(
          Chip(
            label: Text(s["clinic_type"] ?? ""),
            backgroundColor: Colors.blue.shade50,
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              resultText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onSelectChanged: (_) => _showEditDialog(s),
    );
  }

  // دالة التعديل (كما هي في كودك)
  void _showEditDialog(Map<String, dynamic> soldierData) {
    String tempClinic = soldierData['clinic_type'] ?? 'باطنة';
    String tempResult = soldierData['pres_result'] ?? 'لائق';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("تعديل نتيجة: ${soldierData['soldiers_name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempClinic,
                decoration: const InputDecoration(labelText: "العيادة"),
                items:
                    [
                          'باطنة',
                          'قلب',
                          'رمد',
                          'عظام',
                          'نفسية',
                          'جراحة',
                          'جلدية',
                          'اسنان',
                          'تخاطب',
                          'انف واذن',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => tempClinic = v!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: tempResult,
                decoration: const InputDecoration(labelText: "النتيجة"),
                items: ['لائق', 'لجنة فرعية', 'عرض']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => tempResult = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDelete(soldierData['pres_id']);
              },
              child: const Text(
                "حذف السجل",
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                vm.updateSoldierResult(
                  presId: soldierData['pres_id'],
                  newClinic: tempClinic,
                  newResult: tempResult,
                );
                Navigator.pop(ctx);
              },
              child: const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من مسح هذا الجندي من كشف اللجنة؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              vm.deleteResult(id);
              Navigator.pop(ctx);
            },
            child: const Text(
              "حذف نهائي",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}

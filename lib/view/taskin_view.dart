import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/Multi_select_popup.dart';
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:flutter_application_1/viewmodels/taskin_view_model.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';

/// ================= MultiSelectPopup helper widget =================
/// يستخدم PopupMenuButton ويحتوي داخل القائمة على CheckboxListTile.
/// المهمة هنا ضمان أن التغييرات في القائمة لا تغلقها حتى الضغط على زر "تم".

/// ================= DataSource =================
class SoldiersDataSource extends DataTableSource {
  final List<Map<String, dynamic>> soldiers;

  final List<Map<String, String>> dynamicColumns;
  final List<String> selectedColumnLabels;

  SoldiersDataSource(
    this.soldiers,
    this.dynamicColumns,
    this.selectedColumnLabels,
  );

  String _cleanData(dynamic value) {
    if (value == null) return '';
    final strValue = value.toString().trim().toLowerCase();
    if (strValue == 'null' || strValue.isEmpty || strValue == 'none') {
      return '';
    }
    return value.toString();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= soldiers.length) return null;
    final s = soldiers[index];

    // الأعمدة الثابتة
    List<DataCell> cells = [
      DataCell(SelectableText(_cleanData(s['soldiers_name']))),
      DataCell(SelectableText(_cleanData(s['soldiers_number']))),
      DataCell(SelectableText(_cleanData(s['soldiers_k']))),
      DataCell(SelectableText(_cleanData(s['soldiers_s']))),
      DataCell(SelectableText(_cleanData(s['soldiers_f']))),
    ];

    // الأعمدة الديناميكية — حسب ترتيب selectedColumnLabels
    for (final label in selectedColumnLabels) {
      final col = dynamicColumns.firstWhere((c) => c["label"] == label);
      final key = col["key"]!;

      cells.add(DataCell(SelectableText(_cleanData(s[key]))));
    }

    return DataRow(cells: cells);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => soldiers.length;

  @override
  int get selectedRowCount => 0;
}

/// ================= TaskinView =================
class TaskinView extends StatefulWidget {
  const TaskinView({super.key});

  @override
  State<TaskinView> createState() => _TaskinViewState();
}

class _TaskinViewState extends State<TaskinView> {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    // نستخدم Microtask للتأكد من أن الصفحة بدأت العمل قبل طلب البيانات
    Future.microtask(() {
      final vm = Provider.of<TaskinViewModel>(context, listen: false);
      // إذا كان هناك batchId مختار حالياً، اجبره على إعادة التحميل
      if (vm.batchId != null) {
        vm.updateBatch(vm.batchId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget buildFilterRow(TaskinViewModel vm) {
    return Column(
      children: [
        Row(
          spacing: 15,
          children: [
            Expanded(
              child: MultiSelectPopup(
                label: "الكتيبة",
                options: vm.katibaOptions,
                selectedValues: vm.selectedKatiba,
                onToggle: (v) => vm.toggleKatiba(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "السرية",
                options: vm.sareyaOptions,
                selectedValues: vm.selectedSareya,
                onToggle: (v) => vm.toggleSareya(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "الفصيلة",
                options: vm.fasilaOptions,
                selectedValues: vm.selectedFasila,
                onToggle: (v) => vm.toggleFasila(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "المحافظة",
                options: vm.mohafazaOptions,
                selectedValues: vm.selectedMohafaza,
                onToggle: (v) => vm.toggleMohafaza(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 15,

          children: [
            Expanded(
              child: MultiSelectPopup(
                label: "الإدارة",
                options: vm.idaraOptions,
                selectedValues: vm.selectedIdara,
                onToggle: (v) => vm.toggleIdara(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "السلاح",
                options: vm.silahOptions,
                selectedValues: vm.selectedSilah,
                onToggle: (v) => vm.toggleSilah(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "المؤهل",
                options: vm.moahelOptions,
                selectedValues: vm.selectedMoahel,
                onToggle: (v) => vm.toggleMoahel(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "سنة زيادة",
                options: vm.sanatZiyadaOptions,
                selectedValues: vm.selectedSanatZiyada,
                onToggle: (v) => vm.toggleSanatZiyada(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          spacing: 15,

          children: [
            Expanded(
              child: MultiSelectPopup(
                label: "الموقف",
                options: vm.statusOptions,
                selectedValues: vm.selectedStatus,
                onToggle: (v) => vm.toggleStatus(v),
              ),
            ),

            Expanded(
              child: MultiSelectPopup(
                label: "المنحة",
                options: vm.giftOptions,
                selectedValues: vm.selectedGift,
                onToggle: (v) => vm.toggleGift(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "الحالة الاجتماعية",
                options: vm.maritalStatusOptions,
                selectedValues: vm.selectedMaritalStatus,
                onToggle: (v) => vm.toggleMaritalStatus(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "الحضور",
                options: vm.leaveOptions,
                selectedValues: vm.selectedLeave,
                onToggle: (v) => vm.toggleLeave(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 15,

          children: [
            Expanded(
              child: MultiSelectPopup(
                label: "التخصص",
                options: vm.specializationOptions,
                selectedValues: vm.selectedSpecialization,
                onToggle: (v) => vm.toggleSpecialization(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "تاريخ الضم",
                options: vm.incomeDateOptions,
                selectedValues: vm.selectedIncomeDates,
                onToggle: (v) => vm.toggleIncomeDate(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "تاريخ التجنيد",
                options: vm.militaryDateOptions,
                selectedValues: vm.selectedMilitaryDates,
                onToggle: (v) => vm.toggleMilitaryDate(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "الديانة",
                options: vm.religionOptions,
                selectedValues: vm.selectedReligion,
                onToggle: (v) => vm.toggleReligion(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 15,

          children: [
            Expanded(
              child: MultiSelectPopup(
                label: "الوحدة الموزع عليها",
                options: vm.uniteOptions,
                selectedValues: vm.selectedUnite,
                onToggle: (v) => vm.toggleUnite(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "التبعية",
                options: vm.fatherUniteOptions,
                selectedValues: vm.selectedFatherUnite,
                onToggle: (v) => vm.toggleFatherUnit(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "تاريخ الترحيل ",
                options: vm.sendingDateOptions,
                selectedValues: vm.selectedsendingDate,
                onToggle: (v) => vm.toggleSendingDate(v),
              ),
            ),
            Expanded(
              child: MultiSelectPopup(
                label: "المهنة",
                options: vm.jopOptions,
                selectedValues: vm.selectedJop,
                onToggle: (v) => vm.toggleJop(v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskinViewModel>();
    final double columnWidth = 140; // عرض لكل عمود
    final double extraWidth = 200; // padding + margins
    final double tableWidth =
        (vm.soldierColumns.length * columnWidth) + extraWidth;
    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            buildFilterRow(vm),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: vm.searchController,
                    focusNode: vm.searchFocusNode,
                    decoration: InputDecoration(
                      hintText: "بحث...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    // التعديل هنا:
                    onChanged: (value) {
                      // لا تستدعي applyFilters هنا لأنها تسبب Reload كامل وقاعدة بيانات
                      // بل استدعي دالة البحث المحلي المزودة بمؤقت (Debounce)
                      vm.onSearchChanged(value);
                    },
                  ),
                ),

                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    // 1) العناوين الثابتة
                    final headersTexts = [
                      "الاسم",
                      'الرقم العسكرى',
                      "الكتيبة",
                      "السرية",
                      "الفصيلة",
                      ...vm.selectedColumnLabels, // الأعمدة الديناميكية
                    ];

                    // 2) 💡 التعديل الجوهري هنا: بناء المفاتيح بناءً على ترتيب العناوين المختارة حصراً
                    final headersKeys = [
                      "soldiers_name",
                      "soldiers_number",
                      "soldiers_k",
                      "soldiers_s",
                      "soldiers_f",
                      // هنا نقوم بالبحث عن المفتاح لكل عنوان اختاره المستخدم بالترتيب
                      ...vm.selectedColumnLabels.map((label) {
                        return vm.allColumns.firstWhere(
                          (c) => c["label"] == label,
                        )["key"]!;
                      }),
                    ];

                    // 3) إرسال البيانات للدالة التي تستخدم xlsio
                    final bytes = await compute(buildExcelBytes, {
                      'data': vm.filteredSoldiers,
                      'headersTexts': headersTexts,
                      'headersKeys': headersKeys,
                    });

                    // 4) نافذة الحفظ
                    final location = await getSaveLocation(
                      suggestedName: "اجمالى.xlsx",
                      acceptedTypeGroups: [
                        XTypeGroup(label: "Excel File", extensions: ["xlsx"]),
                      ],
                    );

                    if (location == null) return;

                    String path = location.path;
                    if (!path.endsWith(".xlsx")) path += ".xlsx";

                    final file = File(path);
                    await file.writeAsBytes(bytes, flush: true);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'تصدير',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                ElevatedButton.icon(
                  onPressed: vm.isLoading ? null : () => vm.exportPdfSafe(),
                  icon: vm.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  label: Text(
                    vm.isLoading ? "جاري المعالجة..." : "طباعة الكشف A3",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              spacing: 15,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => vm.resetFilters(),
                  icon: const Icon(Icons.clear, color: Colors.red),
                  label: const Text(
                    'اعادة ضبط',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

                SizedBox(
                  height: 70,
                  width: 200,
                  child: MultiSelectPopup(
                    label: "الأعمدة",
                    options: vm.allColumns.map((e) => e["label"]!).toList(),
                    selectedValues: vm.selectedColumnLabels,
                    onToggle: (v) => vm.toggleColumn(v),
                  ),
                ),
                SizedBox(
                  height: 70,
                  width: 200,
                  child: MultiSelectPopup(
                    label: "أولوية الفرز",
                    // نمرر أسماء خيارات الفرز
                    options: vm.sortOptions.map((e) => e["label"]!).toList(),
                    selectedValues: vm.selectedSortLabels,
                    onToggle: (label) => vm.toggleSortOption(label),
                  ),
                ),
                InkWell(
                  onTap: vm.toggleSortDirection,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: vm.isAscending ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vm.isAscending
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vm.isAscending ? "تصاعدي" : "تنازلي",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ==== calculate table width dynamically based on number of columns ====
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= عدد الصفوف =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          '  العدد ${vm.filteredSoldiers.length}',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= الجدول =================
                Center(
                  child: Scrollbar(
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 12,
                    controller: _scrollController,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      child: SizedBox(
                        width: tableWidth,
                        child: // داخل الـ Build الخاص بالـ View
                        PaginatedDataTable(
                          key: vm.tableKey,
                          showCheckboxColumn: false,

                          // الخصائص الجمالية والوظيفية:
                          headingRowHeight:
                              45, // تقليل ارتفاع الهيدر ليعطي شكل أنيق
                          dataRowMinHeight: 40, // ضبط ارتفاع الصفوف
                          dataRowMaxHeight: 55,
                          horizontalMargin: 15, // هوامش جانبية
                          columnSpacing: 25, // تباعد مريح بين الأعمدة
                          showFirstLastButtons:
                              true, // إضافة أزرار الانتقال لأول/آخر صفحة (مهم جداً للويندوز)
                          // رسالة تظهر عند عدم وجود بيانات (بدل الجدول الفارغ الصامت)
                          rowsPerPage: vm.filteredSoldiers.isEmpty
                              ? 1
                              : vm.filteredSoldiers.length > 10
                              ? 10
                              : vm.filteredSoldiers.length,

                          // المصدر (Data Source)
                          source: SoldiersDataSource(
                            vm.filteredSoldiers
                                .map((m) => m.map((k, v) => MapEntry(k, v)))
                                .toList(),
                            vm.allColumns,
                            vm.selectedColumnLabels,
                          ),

                          columns: vm.soldierColumns,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

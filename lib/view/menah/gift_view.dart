import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_application_1/view/widgets/Multi_select_popup.dart';
import 'package:flutter_application_1/view/menah/edit_gift.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:flutter_application_1/viewmodels/menah/gift_view_model.dart';
import 'package:provider/provider.dart';

// --- دالة توحيد النص العربي للبحث الذكي ---

class GiftView extends StatefulWidget {
  const GiftView({super.key});
  @override
  State<GiftView> createState() => _GiftViewState();
}

class _GiftViewState extends State<GiftView> {
  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();
  final TextEditingController _mainController = TextEditingController();
  final FocusNode _scannerFocus = FocusNode();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _mainController.dispose();
    _scannerFocus.dispose();
    _searchFocus.dispose();
    _horizontalScroll.dispose();
    _verticalScroll.dispose();
    super.dispose();
  }

  void _executeInsert(GiftViewModel vm, String value) async {
    if (value.trim().isEmpty) return;
    final msg = await vm.insertGiftByScan(value.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
          width: 450,
          backgroundColor: msg.contains("✔")
              ? Colors.green.shade700
              : Colors.red.shade700,
        ),
      );
      _mainController.clear();
      _scannerFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GiftViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- 1. قسم الإدخال العلوي (مع البحث الذكي) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, color: Colors.white, size: 35),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: TypeAheadField<String>(
                      controller: _mainController,
                      focusNode: _scannerFocus,
                      builder: (context, controller, focusNode) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "اسم الجندي أو الرقم العسكري...",
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (val) => _executeInsert(vm, val),
                      ),
                      suggestionsCallback: (pattern) {
                        if (pattern.isEmpty) return [];
                        String normalizedPattern = normalizeArabic(pattern);
                        return vm.allSoldiersNamesAndNumbers
                            .where((s) {
                              return normalizeArabic(
                                s,
                              ).contains(normalizedPattern);
                            })
                            .take(10)
                            .toList();
                      },
                      itemBuilder: (context, suggestion) =>
                          ListTile(title: Text(suggestion)),
                      onSelected: (suggestion) =>
                          _executeInsert(vm, suggestion.split('-').last.trim()),
                    ),
                  ),
                  const SizedBox(width: 15),
                  /*change the color  of the box make it transparent*/
                  Expanded(
                    flex: 2,
                    child: SearchableDropdown(
                      //maxHeight: 1,
                      height: 55,

                      label: "نوع المنحة",
                      value: vm.selectedGiftType,
                      items: vm.giftTypes,
                      onChanged: (v) {
                        vm.selectedGiftType = v;
                        _scannerFocus.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(width: 15),

                  Expanded(
                    flex: 2,
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "ملاحظات",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: vm.setGigtNote,
                    ),
                  ),

                  /*Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        // عرض Date Picker
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(
                                    0xFF1E3A8A,
                                  ), // لون الـ AppBar / Action
                                  onPrimary:
                                      Colors.white, // لون النص على Action
                                  surface: Colors.white, // خلفية الكروت
                                  onSurface:
                                      Colors.black, // لون النص داخل التاريخ
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (pickedDate != null) {
                          // حفظ التاريخ في ViewModel أو State
                          vm.setGiftDate(pickedDate);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.selectedGiftDate == null
                                    ? "اختيار تاريخ"
                                    : DateFormat(
                                        "yyyy/MM/dd",
                                      ).format(vm.selectedGiftDate!),
                                style: TextStyle(
                                  color: vm.selectedGiftDate == null
                                      ? Colors.white30
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),*/
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- 2. قسم البحث السريع والفلترة وتصدير الإكسيل ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      focusNode: _searchFocus,
                      onChanged: vm.setSearchText,
                      decoration: const InputDecoration(
                        hintText: "بحث سريع...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: _buildChip(
                      vm.selectedGiftTypes,
                      vm.giftTypesFromDb,
                      "النوع",
                      vm.toggleGiftType,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChip(
                      vm.selectedBattalions,
                      vm.battalions,
                      "الكتيبة",
                      vm.toggleBattalion,
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: _buildChip(
                      vm.selectedGiftDates, // متغير جديد في VM لتخزين التواريخ المختارة
                      vm.allGiftDates, // كل التواريخ المخزنة
                      "التاريخ",
                      (date) {
                        if (vm.selectedGiftDates.contains(date)) {
                          vm.selectedGiftDates.remove(date);
                        } else {
                          vm.selectedGiftDates.add(date);
                        }
                        vm.applyFilters(); // إعادة فلترة الجدول بعد اختيار التاريخ
                      },
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      vm.searchText = '';
                      vm.selectedBattalions.clear();
                      vm.selectedGiftTypes.clear();
                      vm.selectedGiftDates.clear();
                      vm.loadData();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("تصدير اكسيل"),
                    onPressed: () async {
                      final headersTexts = vm.giftColumns.map((col) {
                        final w = col.label;
                        if (w is Text) return w.data ?? '';
                        if (w is Center && w.child is Text) {
                          return (w.child as Text).data ?? '';
                        }
                        if (w is Align && w.child is Text) {
                          return (w.child as Text).data ?? '';
                        }
                        return '';
                      }).toList();

                      final bytes = await compute(buildExcelBytes, {
                        'data': vm.filtered,
                        'headersTexts': headersTexts,
                        'headersKeys': vm.soldierKeys,
                      });

                      final location = await getSaveLocation(
                        suggestedName: "منح.xlsx",
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            Text(
              'العدد ${vm.filtered.length}',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // --- 3. الجدول مع حل التمرير المزدوج ---
            Expanded(
              child: Scrollbar(
                controller: _verticalScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalScroll,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: _horizontalScroll,
                    thumbVisibility: true,
                    notificationPredicate: (notif) => notif.depth == 1,
                    child: SingleChildScrollView(
                      controller: _horizontalScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1400,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            cardTheme: const CardThemeData(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                            ),
                          ),
                          child: PaginatedDataTable(
                            columns: _getColumns(),
                            source: GiftDataSource(context, vm.filtered),
                            key: vm.tableKey,
                            showCheckboxColumn: false,
                            headingRowHeight: 45,
                            dataRowMaxHeight: 55,
                            horizontalMargin: 20,
                            showFirstLastButtons: true,
                            columnSpacing: 30,
                            rowsPerPage: vm.filtered.isEmpty
                                ? 1
                                : (vm.filtered.length > 10
                                      ? 10
                                      : vm.filtered.length),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    List<String> selected,
    List<String> options,
    String label,
    void Function(String) onToggle,
  ) {
    return MultiSelectPopup(
      label: label,
      options: options,
      selectedValues: selected,
      onToggle: onToggle,
    );
  }

  List<DataColumn> _getColumns() => const [
    DataColumn(
      label: Text(
        'الاسم',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    ),
    DataColumn(label: Text('الرقم')),
    DataColumn(label: Text('الكتيبة')),
    DataColumn(label: Text('السرية')),
    DataColumn(label: Text('الفصيلة')),
    DataColumn(label: Text('المحافظة')),
    DataColumn(label: Text('نوع المنحة')),
    DataColumn(label: Text('ملاحظات')),
    DataColumn(label: Text('تاريخ')),
  ];
}

class GiftDataSource extends DataTableSource {
  final BuildContext context;
  final List<Map<String, dynamic>> data;
  GiftDataSource(this.context, this.data);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final row = data[index];
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (_) => EditGiftDialog(existing: row),
            ),
            child: Text(
              row['soldiers_name'] ?? '—',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(Text(row['soldiers_number']?.toString() ?? '—')),
        DataCell(Text(row['soldiers_k'] ?? '—')),
        DataCell(Text(row['soldiers_s'] ?? '—')),
        DataCell(Text(row['soldiers_f'] ?? '—')),
        DataCell(Text(row['soldiers_city'] ?? '—')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              row['gift_type'] ?? '—',
              style: TextStyle(
                color: Colors.green.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(Text(row['gift_note'] ?? '—')),
        DataCell(Text(row['gift_date'] ?? '—')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}

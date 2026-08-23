import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/view/mawqf/edit_moqf_view.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/mawqf/moqf_viewmodel.dart';

class MoqfView extends StatelessWidget {
  MoqfView({super.key});

  final ScrollController _scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MoqfViewModel>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Column(
              children: [
                // ============ إضافة سجل موقف جديد ============
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "إضافة موقف جديد",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // بحث عن الجندي
                          Autocomplete<Map<String, dynamic>>(
                            // 1. البحث الذكي (تجاهل الهمزات، التشكيل، والرقم العسكري)
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<
                                      Map<String, dynamic>
                                    >.empty();
                                  }

                                  // تطبيع نص البحث المدخل
                                  final String searchTerm = normalizeArabic(
                                    textEditingValue.text,
                                  );

                                  return vm.allSoldiers.where((
                                    Map<String, dynamic> soldier,
                                  ) {
                                    final String name = normalizeArabic(
                                      soldier["soldiers_name"].toString(),
                                    );
                                    final String number =
                                        soldier["soldiers_number"].toString();

                                    // البحث بالاسم المطبع أو بالرقم العسكري
                                    return name.contains(searchTerm) ||
                                        number.contains(searchTerm);
                                  });
                                },

                            displayStringForOption: (option) =>
                                option["soldiers_name"],

                            // 2. تصميم الحقل النصي بشكل عصري
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmitted) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      labelText:
                                          "ابحث عن جندي (بالاسم أو الرقم)",
                                      hintText: "اكتب هنا...",
                                      prefixIcon: Icon(
                                        Icons.person_search_rounded,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },

                            // 3. تصميم قائمة الخيارات (Dropdown) بشكل عصري
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4.0,
                                    left: 32,
                                  ), // موازنة مع الحقل
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(15),
                                    clipBehavior: Clip.antiAlias,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 300,
                                      ), // أقصى ارتفاع للقائمة
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.9, // عرض متناسق
                                      color: Colors.white,
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (context, index) =>
                                            Divider(
                                              height: 1,
                                              color: Colors.grey[100],
                                            ),
                                        itemBuilder: (BuildContext context, int index) {
                                          final Map<String, dynamic> option =
                                              options.elementAt(index);
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.blue[50],
                                              child: Text(
                                                option["soldiers_name"][0], // أول حرف من الاسم
                                                style: TextStyle(
                                                  color: Colors.blue[800],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              option["soldiers_name"],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "رقم عسكري: ${option['soldiers_number']}",
                                            ),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },

                            onSelected: (Map<String, dynamic> selection) {
                              vm.selectSoldier(selection);
                              debugPrint(
                                'تم اختيار: ${selection['soldiers_name']}',
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // تاريخ الموقف + النوع
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue.shade100,
                                    foregroundColor: Colors.blue.shade900,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    vm.moqfDate == null
                                        ? "تاريخ الموقف"
                                        : vm.fmt(
                                            vm.moqfDate!.toIso8601String(),
                                          ),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          vm.moqfDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      vm.setMoqfDate(picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),

                              Expanded(
                                child: SearchableDropdown(
                                  label: "نوع الموقف",
                                  value: vm.moqfType,
                                  items: vm.moqfTypes,
                                  onChanged: (v) {
                                    vm.setMoqfType(v);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ملاحظة
                          TextField(
                            decoration: InputDecoration(
                              labelText: "ملاحظات",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.note),
                            ),
                            onChanged: vm.setMoqfNote,
                            maxLines: 2,
                          ),

                          const SizedBox(height: 12),

                          // زر الحفظ
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text("حفظ الموقف"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                // استدعاء الدالة وتمرير الـ context
                                // الدالة الآن هي المسؤولة عن التحقق وعرض الرسائل الملونة (نجاح/فشل/تكرار)
                                final success = await vm.saveMoqf(context);

                                if (success) {
                                  // إذا كنت تريد إغلاق الـ Dialog أو الصفحة بعد النجاح
                                  // Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(),

                // ============ فلاتر البحث ============
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            vm.filterDate == null
                                ? "التاريخ"
                                : vm.fmt(vm.filterDate!.toIso8601String()),
                          ),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              vm.filterDate = d;
                              vm.applyFilters();
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: SearchableDropdown(
                          label: "نوع الموقف",
                          value: vm.moqfTypes.contains(vm.filterType)
                              ? vm.filterType
                              : null,
                          items: vm.moqfTypes,
                          onChanged: (v) {
                            vm.filterType = v;
                            vm.applyFilters();
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: vm.resetFilters,
                          child: const Text("اعادة ضبط"),
                        ),
                      ),
                    ],
                  ),
                ),

                // بحث بالاسم
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "بحث عن الجندي",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (v) {
                            vm.filterName = v;
                            vm.applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          final headersTexts = vm.moqfColumns.map((col) {
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

                          // تشغيل بناء ملف Excel داخل isolate
                          final bytes = await compute(
                            buildExcelBytes, // الدالة
                            {
                              'data': vm.filtered,
                              'headersTexts': headersTexts,
                              'headersKeys': vm.soldierKeys,
                            },
                          );

                          // نافذة حفظ (لازم هنا فقط)
                          final location = await getSaveLocation(
                            suggestedName: "مواقف.xlsx",
                            acceptedTypeGroups: [
                              XTypeGroup(
                                label: "Excel File",
                                extensions: ["xlsx"],
                              ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        '  العدد ${vm.filtered.length}',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // ============ جدول البيانات ============
                Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  trackVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1200,
                      child: PaginatedDataTable(
                        key: vm.tableKey,
                        showCheckboxColumn: false,

                        headingRowHeight: 45,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 55,
                        horizontalMargin: 15,
                        columnSpacing: 25,
                        showFirstLastButtons: true,
                        rowsPerPage: vm.filtered.isEmpty
                            ? 1
                            : vm.filtered.length > 10
                            ? 10
                            : vm.filtered.length,
                        columns: vm.moqfColumns,
                        source: MoqfDataSource(
                          context,
                          vm.filtered,
                          vm.soldierKeys,
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

class MoqfDataSource extends DataTableSource {
  final BuildContext context;
  final List<Map<String, dynamic>> data;
  final List<String> keys;

  MoqfDataSource(this.context, this.data, this.keys);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;

    final row = data[index];

    return DataRow(
      cells: keys.map((key) {
        final value = row[key]?.toString() ?? "—";

        // فتح نافذة التعديل عند الضغط على الاسم / الملاحظة
        if (key == "soldiers_name" || key == "moqf_note") {
          return DataCell(
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: Provider.of<MoqfViewModel>(context, listen: false),
                    child: EditMoqfDialog(existing: row),
                  ),
                );
              },
              child: Text(value),
            ),
          );
        }

        return DataCell(Text(value));
      }).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}

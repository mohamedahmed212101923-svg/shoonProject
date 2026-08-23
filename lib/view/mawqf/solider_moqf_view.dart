import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/view/mawqf/edit_moqf_view.dart';
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:flutter_application_1/viewmodels/mawqf/solider_moqf_viewmodel.dart';
import 'package:provider/provider.dart';

class SoliderMoqfView extends StatelessWidget {
  SoliderMoqfView({super.key});

  final ScrollController _scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoliderMoqfViewmodel>();

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
                            // --- منطق البحث الذكي (كما هو) ---
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable.empty();
                                  }
                                  final String searchTerm = normalizeArabic(
                                    textEditingValue.text,
                                  );
                                  return vm.allSoldiers.where((s) {
                                    final name = normalizeArabic(
                                      s["soldiers_name"].toString(),
                                    );
                                    final num = s["soldiers_number"].toString();
                                    return name.contains(searchTerm) ||
                                        num.contains(searchTerm);
                                  });
                                },

                            displayStringForOption: (option) =>
                                option["soldiers_name"],

                            // 1️⃣ تعديل حقل الإدخال (الظاهر أمامك)
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmitted) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      textAlign: TextAlign.right,
                                      decoration: InputDecoration(
                                        hintText:
                                            "بحث بالاسم أو الرقم العسكري...",
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        // زر المسح (Clear) ليصبح الشكل تفاعلياً
                                        suffixIcon: controller.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear_rounded,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  controller.clear();
                                                  vm.selectSoldier(
                                                    {},
                                                  ); // إعادة تعيين الاختيار
                                                },
                                              )
                                            : null,
                                        border: InputBorder
                                            .none, // إخفاء الحدود التقليدية
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 15,
                                            ),
                                      ),
                                    ),
                                  );
                                },

                            // 2️⃣ تعديل قائمة النتائج (Dropdown) لتظهر بشكل "عائم" وعصري
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment:
                                    Alignment.topRight, // محاذاة لليمين (عربي)
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Material(
                                    elevation: 15,
                                    color: Colors
                                        .transparent, // لجعل الظل يظهر حول الحاوية فقط
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.8, // عرض القائمة
                                      margin: const EdgeInsets.only(
                                        left: 32,
                                      ), // مسافة من حافة الشاشة
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.1),
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        maxHeight: 300,
                                      ),
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (context, index) =>
                                            Divider(
                                              height: 1,
                                              color: Colors.grey[100],
                                            ),
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(
                                            index,
                                          );
                                          return ListTile(
                                            hoverColor: Colors.blue[50],
                                            title: Text(
                                              option["soldiers_name"],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "رقم: ${option['soldiers_number']} | ${option['soldiers_k'] ?? ''}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueGrey[400],
                                              ),
                                            ),
                                            leading: CircleAvatar(
                                              radius: 18,
                                              backgroundColor: Colors.blue[50],
                                              child: const Icon(
                                                Icons.person,
                                                size: 20,
                                                color: Colors.blue,
                                              ),
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

                            onSelected: (selection) =>
                                vm.selectSoldier(selection),
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
                                    vm.soliderMoqfDate == null
                                        ? "تاريخ الموقف"
                                        : vm.fmt(
                                            vm.soliderMoqfDate!
                                                .toIso8601String(),
                                          ),
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          vm.soliderMoqfDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      vm.setSoliderMoqfDate(picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),

                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "نوع الموقف",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.category),
                                  ),
                                  initialValue: vm.soliderMoqfType,
                                  items: vm.dropdownItems,
                                  onChanged: vm.setSoliderMoqfType,
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
                            onChanged: vm.setSoliderMoqfNote,
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
                                final ok = await vm.saveSoliderMoqf();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? "تم حفظ الموقف" : "أكمل البيانات",
                                    ),
                                  ),
                                );
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
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "نوع",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.category),
                          ),
                          initialValue: vm.filterType,
                          items: vm.dropdownItems,
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

                // بحث بالاسم + تصدير اكسيل
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
                          final headersTexts = [
                            'الاسم',
                            'رقم عسكري',
                            'كتيبة',
                            'سرية',
                            'فصلية',
                            ...vm.solidersoliderMoqfTypes,
                          ];

                          final headersKeys = [
                            'soldiers_name',
                            'soldiers_number',
                            'soldiers_k',
                            'soldiers_s',
                            'soldiers_f',
                            ...vm.solidersoliderMoqfTypes,
                          ];

                          final bytes = await compute(buildExcelBytes, {
                            'data': vm.filtered,
                            'headersTexts': headersTexts,
                            'headersKeys': headersKeys,
                          });

                          final location = await getSaveLocation(
                            suggestedName: "مواقف فرعية.xlsx",
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

                // ============ جدول البيانات مع Pagination ============
                Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  trackVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1600,
                      child: PaginatedDataTable(
                        header: const Text("مواقف الجنود"),
                        showCheckboxColumn: false,
                        rowsPerPage: vm.filtered.isEmpty
                            ? 1
                            : (vm.filtered.length > 5
                                  ? 10
                                  : vm.filtered.length),
                        columns: [
                          const DataColumn(label: Text('الاسم')),
                          const DataColumn(label: Text('رقم عسكري')),
                          const DataColumn(label: Text('كتيبة')),
                          const DataColumn(label: Text('سرية')),
                          const DataColumn(label: Text('فصيلة')),
                          const DataColumn(label: Text('رقم السجل')),

                          for (var t in vm.solidersoliderMoqfTypes)
                            DataColumn(label: Text(t)),
                        ],
                        source: SoliderMoqfDataSource(context, vm.filtered, [
                          "soldiers_name",
                          "soldiers_number",
                          'soldiers_k',
                          'soldiers_s',
                          'soldiers_f',
                          'soldiers_unit_id',
                          ...vm.solidersoliderMoqfTypes,
                        ], vm), //
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

class SoliderMoqfDataSource extends DataTableSource {
  final BuildContext context;
  final List<Map<String, dynamic>> data;
  final List<String> keys;
  final SoliderMoqfViewmodel vm; // <-- أضف الـ vm هنا

  SoliderMoqfDataSource(this.context, this.data, this.keys, this.vm);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final row = data[index];

    return DataRow(
      cells: keys.map((key) {
        final value = row[key]?.toString() ?? "—";

        if (key == "soldiers_name" ||
            vm.solidersoliderMoqfTypes.contains(key)) {
          return DataCell(
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: Provider.of<SoliderMoqfViewmodel>(
                      context,
                      listen: false,
                    ),
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

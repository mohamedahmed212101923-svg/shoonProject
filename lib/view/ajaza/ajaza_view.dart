import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/ajaza/ajaza_wedgit.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/view/widgets/Multi_select_popup.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ajaza/ajaza_viewmodel.dart';

class AjazaView extends StatelessWidget {
  AjazaView({super.key});

  final ScrollController _scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AjazaViewModel>();
    Widget dateFilterButton({
      required String title,
      required DateTime? value,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value == null ? title : vm.fmt(value.toIso8601String()),
                  style: TextStyle(
                    color: value == null
                        ? Colors.blueGrey
                        : Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (value != null)
                InkWell(
                  onTap: () {
                    value == vm.filterStart
                        ? vm.filterStart = null
                        : vm.filterEnd = null;
                    vm.applyFiltersForLeaves();
                  },
                  child: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ),
      );
    }

    Widget dateFilterChip(AjazaViewModel vm) {
      // لو مفيش أي فلترة
      if (vm.filterStart == null && vm.filterEnd == null) {
        return const SizedBox.shrink();
      }

      String label;
      Color bgColor;

      // من → إلى (فلترة انتهاء خلال فترة)
      if (vm.filterStart != null && vm.filterEnd != null) {
        label =
            "انتهاء الإجازة من ${vm.fmt(vm.filterStart!.toIso8601String())}"
            " → ${vm.fmt(vm.filterEnd!.toIso8601String())}";
        bgColor = Colors.green.shade100;
      }
      // بداية فقط
      else if (vm.filterStart != null) {
        label = "بداية الإجازة = ${vm.fmt(vm.filterStart!.toIso8601String())}";
        bgColor = Colors.blue.shade100;
      }
      // نهاية فقط
      else {
        label = "نهاية الإجازة = ${vm.fmt(vm.filterEnd!.toIso8601String())}";
        bgColor = Colors.blue.shade100;
      }

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                vm.filterStart = null;
                vm.filterEnd = null;
                vm.applyFiltersForLeaves();
              },
              child: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              Column(
                children: [
                  // =========================
                  // 1) إضافة إجازة جديدة
                  // =========================
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.blue.shade50,
                      child: Container(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "إضافة موقف (اجازة - غياب - سجن) جديد",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // بحث عن الجندي
                              Autocomplete<Map<String, dynamic>>(
                                // 1. البحث الذكي باستخدام الدالة العالمية
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return vm.allSoldiers;
                                      }

                                      // توحيد النص المدخل من المستخدم
                                      final input = normalizeArabic(
                                        textEditingValue.text,
                                      );

                                      return vm.allSoldiers.where((s) {
                                        // توحيد اسم الجندي للمقارنة
                                        final nameInDb = normalizeArabic(
                                          s["soldiers_name"].toString(),
                                        );
                                        // توحيد الرقم العسكري أيضاً للبحث به
                                        final numberInDb = s["soldiers_number"]
                                            .toString();

                                        return nameInDb.contains(input) ||
                                            numberInDb.contains(input);
                                      });
                                    },

                                displayStringForOption: (option) =>
                                    option["soldiers_name"] ?? "",

                                // 2. التصميم العصري لحقل الإدخال
                                fieldViewBuilder:
                                    (
                                      context,
                                      controller,
                                      focusNode,
                                      onSubmitted,
                                    ) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: InputDecoration(
                                            labelText: "اختر الجندي",
                                            labelStyle: TextStyle(
                                              color: Colors.blueGrey.shade700,
                                              fontSize: 14,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.person_search_rounded,
                                              color: Colors.blue.shade700,
                                            ),
                                            // إضافة زر مسح النص
                                            suffixIcon:
                                                controller.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.clear,
                                                      size: 18,
                                                    ),
                                                    onPressed: () {
                                                      controller.clear();
                                                    },
                                                  )
                                                : null,
                                            filled: true,
                                            fillColor: Colors.white,
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.blue.shade50,
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.blue.shade300,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },

                                // 3. التصميم العصري لقائمة النتائج (الاقتراحات)
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment
                                        .topRight, // مناسب للغة العربية
                                    child: Material(
                                      elevation: 10,
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.transparent,
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 5),
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.4, // عرض متناسب
                                        constraints: const BoxConstraints(
                                          maxHeight: 300,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: ListView.separated(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          separatorBuilder: (context, index) =>
                                              Divider(
                                                color: Colors.grey.shade100,
                                                height: 1,
                                              ),
                                          itemBuilder:
                                              (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                final Map<String, dynamic>
                                                option = options.elementAt(
                                                  index,
                                                );
                                                return ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blue.shade50,
                                                    child: Icon(
                                                      Icons.person,
                                                      color:
                                                          Colors.blue.shade700,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    option["soldiers_name"],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    "رقم: ${option["soldiers_number"]}",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    onSelected(option);
                                                  },
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  );
                                },

                                onSelected: (selection) {
                                  vm.selectSoldier(selection);
                                },
                              ),

                              const SizedBox(height: 12),

                              // تواريخ البداية والنهاية
                              // ... (الجزء العلوي من الكود كما هو)

                              // تواريخ البداية والنهاية
                              Row(
                                children: [
                                  // 1. زر تاريخ البداية (يبقى دائماً متاحاً)
                                  Expanded(
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.blue.shade100,
                                        foregroundColor: Colors.blue.shade900,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        vm.leaveStart == null
                                            ? "تاريخ البداية"
                                            : vm.fmt(
                                                vm.leaveStart!
                                                    .toIso8601String(),
                                              ),
                                      ),
                                      onPressed: () async {
                                        final d = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              vm.leaveStart ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (d != null) vm.setLeaveStart(d);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 2. حقل تاريخ النهاية (يتأثر بنوع الموقف)
                                  Expanded(
                                    child:
                                        vm.leaveReason == "غياب" ||
                                            vm.leaveReason == "حجز"
                                        ? Container(
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors
                                                  .orange
                                                  .shade100, // لون مختلف للتمييز
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              "النهاية: ${vm.leaveReason}",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              foregroundColor:
                                                  Colors.blue.shade900,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              vm.leaveEnd == null
                                                  ? "تاريخ النهاية"
                                                  : vm.fmt(
                                                      vm.leaveEnd!
                                                          .toIso8601String(),
                                                    ),
                                            ),
                                            onPressed: () async {
                                              final d = await showDatePicker(
                                                context: context,
                                                initialDate:
                                                    vm.leaveEnd ??
                                                    DateTime.now(),
                                                firstDate: DateTime(2020),
                                                lastDate: DateTime(2030),
                                              );
                                              if (d != null) vm.setLeaveEnd(d);
                                            },
                                          ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 3. قائمة أنواع الموقف
                                  Expanded(
                                    child: SearchableDropdown(
                                      label: "نوع الموقف",
                                      value: vm.leaveReason,
                                      items: vm.ajazaTypes,
                                      onChanged: (val) {
                                        vm.setAjazafType(val);
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // ... (زر الحفظ وبقية الكود)
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
                                    // تمرير context لدالة saveLeave
                                    final ok = await vm.saveLeave(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? "تم حفظ الموقف"
                                              : "أكمل البيانات",
                                        ),
                                      ),
                                    );
                                    // لا تحتاج ScaffoldMessenger هنا لأن الرسائل تُعرض من داخل saveLeave بالفعل
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Divider(),

                  // =========================
                  // 2) فلترة البحث أسفل الصفحة
                  // =========================
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      spacing: 15,
                      children: [
                        Expanded(
                          child: dateFilterButton(
                            title: "تاريخ البداية",
                            value: vm.filterStart,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: vm.filterStart ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) {
                                vm.filterStart = d;
                                vm.applyFiltersForLeaves();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: dateFilterButton(
                            title: "تاريخ النهاية",
                            value: vm.filterEnd,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: vm.filterEnd ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) {
                                vm.filterEnd = d;
                                vm.applyFiltersForLeaves();
                              }
                            },
                          ),
                        ),
                        dateFilterChip(vm),

                        Expanded(
                          child: MultiSelectPopup(
                            label: "تصفية حسب الكتيبة",
                            options: vm.soldiersWithLeaves
                                .map((e) => e["soldiers_k"].toString())
                                .toSet()
                                .toList(),
                            selectedValues: vm.selectedKaltibas,
                            onToggle: (val) => vm.toggleKaltiba(val),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // فلتر نوع الموقف
                        Expanded(
                          child: MultiSelectPopup(
                            label: "نوع الموقف",
                            options: vm
                                .ajazaTypes, // تأكد أن هذه القائمة موجودة في الـ ViewModel
                            selectedValues: vm.selectedReasons,
                            onToggle: (val) => vm.toggleReason(val),
                          ),
                        ),

                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.backspace_outlined,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            vm.filterK = "الكل";
                            vm.filterReason = "الكل";
                            vm.resetFilters();
                          },
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      spacing: 15,
                      children: [
                        // فلتر الاسم
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "بحت عن الجندي",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (v) {
                              vm.filterName = v;
                              vm.applyFiltersForLeaves();
                            },
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text("تصدير اكسيل"),
                          onPressed: () async {
                            // استخراج نصوص الأعمدة فقط
                            final headersTexts = vm.ajazaColumn.map((col) {
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
                              suggestedName: "اجازات.xlsx",
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
                        TextButton(
                          onPressed: () => showBulkInsertDialog(
                            context,
                          ), // استدعاء الدالة اللي كتبتها
                          child: Text("تسجيل اجازة مستجدين"),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("تصدير إكسيل مجمع (مستجدين)"),
                          onPressed: () async {
                            // التحقق من وجود بيانات أولاً
                            if (vm.allRecruitmentLeaves.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "⚠️ لا توجد إجازات مستجدين مسجلة حالياً",
                                  ),
                                ),
                              );
                              return;
                            }

                            // استخراج نصوص الأعمدة (نفس كودك)
                            final headersTexts = vm.ajazaColumn.map((col) {
                              final w = col.label;
                              if (w is Text) return w.data ?? '';
                              // ... باقي حالات استخراج النص من Header ...
                              return '';
                            }).toList();

                            // تشغيل التصدير في Isolate باستخدام القائمة المخصصة
                            final bytes = await compute(
                              buildRecruitmentLeavesExcel,
                              {
                                'data':
                                    vm.allRecruitmentLeaves, // المتغير الجديد
                                'headersTexts': headersTexts,
                                'headersKeys': vm.soldierKeys,
                              },
                            );

                            // اختيار مكان الحفظ (نفس كودك)
                            final location = await getSaveLocation(
                              suggestedName:
                                  "كشوف_المستجدين_الدفعة_${vm.batchId ?? 'عام'}.xlsx",
                              acceptedTypeGroups: [
                                const XTypeGroup(
                                  label: "Excel File",
                                  extensions: ["xlsx"],
                                ),
                              ],
                            );

                            if (location != null) {
                              final file = File(
                                location.path.endsWith(".xlsx")
                                    ? location.path
                                    : "${location.path}.xlsx",
                              );
                              await file.writeAsBytes(bytes, flush: true);
                            }
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
                  // =========================
                  // 3) الجدول المركب مع Scrollbar أفقي
                  // =========================
                  Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    trackVisibility: true,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1300,
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
                          source: AjazaDataSource(context, vm.filtered),
                          columns: vm.ajazaColumn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

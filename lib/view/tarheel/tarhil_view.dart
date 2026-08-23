import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/view/widgets/Multi_select_popup.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:flutter_application_1/viewmodels/tarheel/tarhil_view_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_tarhil_view.dart';

class TarhilView extends StatelessWidget {
  TarhilView({super.key});

  final ScrollController _horizontalScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TarhilViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              // التحقق من وجود الـ context قبل البدء
              if (!context.mounted) return;

              await vm.importTarhilExcel(context);

              // تحديث البيانات في الشاشة بعد العودة
              await vm.load();
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              //=================== إضافة ترحيل ===================
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
                          "إضافة ترحيل جديد",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// البحث عن الجندي
                        Autocomplete<Map<String, dynamic>>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
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
                              option["soldiers_name"] ?? '',

                          // تخصيص شكل قائمة الاقتراحات (النتائج)
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment:
                                  Alignment.topRight, // لتناسب اللغة العربية
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.4, // عرض القائمة
                                    constraints: const BoxConstraints(
                                      maxHeight: 300,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
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
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.blue.shade700,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            option["soldiers_name"] ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "رقم سجل: ${option["soldiers_unit_id"] ?? 'غير معروف'}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
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

                          // تخصيص شكل حقل الإدخال
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
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
                                      labelText: "بحث عن جندي",
                                      labelStyle: TextStyle(
                                        color: Colors.blueGrey.shade700,
                                        fontSize: 13,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: Colors.blue.shade700,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 15,
                                          ),
                                      // شكل الحدود
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.blue.shade50,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.blue.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                          onSelected: vm.selectSoldier,
                        ),

                        const SizedBox(height: 12),

                        /// التاريخ + المنطقة + تبعية المنطقة
                        Row(
                          children: [
                            // زر التاريخ أو مؤجل
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: vm.isPostponed
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                                foregroundColor: vm.isPostponed
                                    ? Colors.orange.shade900
                                    : Colors.blue.shade900,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    vm.isPostponed
                                        ? "مؤجل ترحيل"
                                        : (vm.sendingDate == null
                                              ? "تاريخ الترحيل"
                                              : vm.format(vm.sendingDate!)),
                                  ),
                                  if (vm.sendingDate != null &&
                                      !vm.isPostponed) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        // إزالة التاريخ
                                        vm.setSendingDate(null);
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onPressed: () async {
                                if (!vm.isPostponed) {
                                  // إظهار التاريخ فقط إذا لم يكن مؤجل
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        vm.sendingDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (d != null) vm.setSendingDate(d);
                                }
                              },
                            ),

                            const SizedBox(width: 8),

                            // زر لتفعيل/إلغاء المؤجل
                            IconButton(
                              tooltip: "تأجيل الترحيل",
                              icon: Icon(
                                Icons.schedule,
                                color: vm.isPostponed
                                    ? Colors.orange
                                    : Colors.blueGrey,
                              ),
                              onPressed: () {
                                // التبديل بين مؤجل أو لا
                                vm.setPostponed(!vm.isPostponed);
                              },
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: SearchableDropdown(
                                label: "منطقة الترحيل",
                                value: vm.sendingArea,
                                items: vm.areas, // القائمة التي جلبناها من DB
                                onChanged: (val) => vm.setSendingArea(val),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // التبعية
                            Expanded(
                              child: SearchableDropdown(
                                label: "التبعية",
                                value: vm.sendingFatherArea,
                                items: vm.fatherAreas,
                                onChanged: (val) =>
                                    vm.setSendingFatherArea(val),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
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
                          onChanged: vm.setSendingNote,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 12),
                        Center(
                          child: SizedBox(
                            width: 200,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text(
                                "حفظ الترحيل",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () async {
                                await vm.saveSending(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(),

              //=================== ضبط تبعية الوحدات ===================
              // 🟢 تحديث التبعية (Father Area)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.green.shade50, // لون مختلف للتمييز
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "تحديث التبعية بشكل جماعي للوحدات",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: MultiSelectPopup(
                                label: "فلترة التبعية",
                                options: const ["بدون تبعية", "له تبعية"],
                                selectedValues: vm.dependencyFilter,
                                onToggle: vm.toggleDependencyFilter,
                                maxHeight: 120,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MultiSelectPopup(
                                label: "اختر الوحدات",
                                options: vm.filterAreaItems,
                                // 💡 تم التعديل: استخدام المتغير الخاص بتحديث التبعية
                                selectedValues: vm.bulkFatherAreaUnits,
                                // 💡 تم التعديل: استخدام دالة الـ Toggle الخاصة بتحديث التبعية
                                onToggle: vm.toggleBulkFatherAreaUnit,
                                maxHeight: 300,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SearchableDropdown(
                                label: "اختر التبعية الجديدة",
                                // القيمة المختارة حالياً في الـ ViewModel للعمليات الجماعية
                                value: vm.bulkSelectedFatherArea,
                                // قائمة التبعيات (Strings) التي تم جلبها ديناميكياً
                                items: vm.fatherAreas,
                                // الدالة التي تحدث القيمة عند الاختيار
                                onChanged: (val) {
                                  vm.setBulkSelectedFatherArea(val);
                                },
                                // يمكنك تعديل الارتفاع إذا كانت القائمة طويلة
                                maxHeight: 300,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text(
                              "تطبيق التبعية على الوحدات المختارة",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              final ok = await vm.applyFatherAreaToUnits();
                              if (ok) {
                                vm.resetBulkFields(); // استخدام resetBulkFields الشامل
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? "تم تحديث تبعية الوحدات بنجاح"
                                        : "اختر الوحدات والتبعية أولاً",
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
              //   تسديد التاريخ
              // 🔵 تسديد التاريخ (Bulk Date) - الهيكلية القديمة
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
                        /// العنوان
                        const Text(
                          "تسديد تاريخ (بشكل جماعي)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// طريقة التحديد + فلتر التاريخ
                        Row(
                          children: [
                            Expanded(
                              child: SearchableDropdown(
                                label: "طريقة التحديد",
                                value: vm.bulkMode,
                                items: const ["الوحدات", "التبعيات"],
                                onChanged: (val) => vm.setBulkMode(val!),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: SearchableDropdown(
                                label: "تاريخ التسديد",
                                value: vm.sendingDateFilterValue,
                                items: const ["ليهم تاريخ", "ملهمش تاريخ"],
                                onChanged: vm.setSendingDateFilter,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// 🔥 فلتر الكتيبة / السرية / الفصيلة
                        Row(
                          children: [
                            Expanded(
                              child: MultiSelectPopup(
                                label: "الكتيبة",
                                options: vm.kOptions,
                                selectedValues: vm.selectedKs,
                                onToggle: vm.toggleK,
                                maxHeight: 250,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: MultiSelectPopup(
                                label: "السرية",
                                options: vm.sOptions,
                                selectedValues: vm.selectedSs,
                                onToggle: vm.toggleS,
                                maxHeight: 250,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: MultiSelectPopup(
                                label: "الفصيلة",
                                options: vm.fOptions,
                                selectedValues: vm.selectedFs,
                                onToggle: vm.toggleF,
                                maxHeight: 250,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// اختيار الوحدات / التبعيات + التاريخ
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey(vm.bulkMode),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: MultiSelectPopup(
                                      label: vm.bulkMode == "الوحدات"
                                          ? "اختر الوحدات"
                                          : "اختر التبعيات",
                                      options: vm.bulkMode == "الوحدات"
                                          ? vm
                                                .bulkDateAreaOptions // أصبحت تتبع الفلتر الآن 🔥
                                          : vm.bulkDateFatherAreaOptions, // أصبحت تتبع الفلتر الآن 🔥
                                      selectedValues: vm.bulkMode == "الوحدات"
                                          ? vm.bulkDateUnits
                                          : vm.bulkDateFatherAreas,
                                      onToggle: vm.bulkMode == "الوحدات"
                                          ? vm.toggleBulkDateUnit
                                          : vm.toggleBulkDateFatherArea,
                                      maxHeight: 250,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Container(
                                      // إضافة ظل خفيف ولمسة جمالية للخلفية
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
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
                                      child: TextFormField(
                                        controller: vm.bulkDateController,
                                        readOnly: true,
                                        onTap: () => vm.pickBulkDate(context),
                                        // تغيير اتجاه النص ليناسب العربية
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "تاريخ التسديد",
                                          labelStyle: TextStyle(
                                            color: Colors.blueGrey.shade700,
                                            fontSize: 13,
                                          ),
                                          hintText: "اختر التاريخ...",
                                          // أيقونة التقويم في البداية (Prefix)
                                          prefixIcon: Icon(
                                            Icons.calendar_month_rounded,
                                            color: Colors.blue.shade700,
                                          ),

                                          // زر الحذف (X) يظهر فقط عند وجود نص (Suffix)
                                          suffixIcon:
                                              vm
                                                  .bulkDateController
                                                  .text
                                                  .isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.cancel_rounded,
                                                    color: Colors.redAccent,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    vm.SetbulkDateController();
                                                  },
                                                )
                                              : null,

                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),

                                          // حدود ناعمة ودائرية
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide
                                                .none, // إخفاء الحدود التقليدية
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.blue.shade50,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.blue.shade300,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              /// الاستبعاد + التنفيذ
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: MultiSelectPopup(
                                      label: "استبعاد أفراد",
                                      options: vm.excludedOptions,
                                      selectedValues: vm.excludedNames,
                                      onToggle: vm.toggleExcluded,
                                      maxHeight: 300,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.calendar_month),
                                      label: const Text(
                                        "تطبيق التاريخ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final ok = await vm.applyBulkDate();
                                        if (ok) vm.resetBulkFields();

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? "تم تحديث تاريخ التسديد بنجاح"
                                                  : "اكمل البيانات أولًا",
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              //=================== الفلاتر ===================
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // 1. فلتر التاريخ
                    Expanded(
                      child: InkWell(
                        onTap: () async {
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: vm.filterDate == null
                                ? Colors.white
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: vm.filterDate == null
                                  ? Colors.grey.shade300
                                  : Colors.blue.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: vm.filterDate == null
                                    ? Colors.grey.shade600
                                    : Colors.blue.shade800,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                vm.filterDate == null
                                    ? "التاريخ"
                                    : vm.format(vm.filterDate!),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: vm.filterDate == null
                                      ? Colors.grey.shade700
                                      : Colors.blue.shade900,
                                ),
                              ),
                              // زر صغير لمسح التاريخ إذا كان مختاراً
                              if (vm.filterDate != null) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    vm.filterDate = null;
                                    vm.applyFilters();
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 2. فلتر الوحدات
                    Expanded(
                      child: MultiSelectPopup(
                        label: "الوحدات",
                        options: vm.filterAreasOptions,
                        selectedValues: vm.selectedFilterAreas,
                        onToggle: (item) {
                          vm.toggleFilterArea(item);
                          vm.applyFilters();
                        },
                        maxHeight: 250,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 3. فلتر التبعية
                    Expanded(
                      child: MultiSelectPopup(
                        label: "التبعية",
                        options: vm.filterFatherAreasOptions,
                        selectedValues: vm.selectedFilterFatherAreas,
                        onToggle: (item) {
                          vm.toggleFilterFatherArea(item);
                          vm.applyFilters();
                        },
                        maxHeight: 250,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 🔥 4. فلتر حالة الترحيل (الجديد)
                    Expanded(
                      child: MultiSelectPopup(
                        label: "حالة الترحيل",
                        options: vm
                            .statusFilterOptions, // القائمة: تم الترحيل، لم يرحل، مؤجل
                        selectedValues: vm.selectedStatusFilters,
                        onToggle: (item) {
                          vm.toggleStatusFilter(item);
                        },
                        maxHeight: 200,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 5. زر إعادة الضبط
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Colors.red.shade100, // غيرت اللون لتمييزه كزر مسح
                          foregroundColor: Colors.red.shade900,
                        ),
                        child: const Text("اعادة ضبط"),
                        onPressed: () {
                          vm.selectedStatusFilters
                              .clear(); // تصفية الفلتر الجديد عند الريسيت
                          vm.resetFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              //=================== البحث + التصدير ===================
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "بحث بالاسم / الرقم العسكري / السجل",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: vm.search,
                      ),
                    ),

                    const SizedBox(width: 8),

                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade900,
                      ),
                      child: const Text("تصدير اكسيل"),

                      // ... (الكود داخل دالة onPressed الخاصة بزر التصدير)
                      onPressed: () async {
                        // 1. جمع رؤوس الأعمدة (هذا الجزء صحيح ولا يحتاج تغيير)
                        final headersTexts = vm.columns.map((col) {
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

                        // 2. 💡 استدعاء الدالة الجديدة للتصدير المتعدد
                        final bytes = await compute(buildGroupedExcelBytes, {
                          // ⬅️ تم تغيير اسم الدالة هنا
                          'data': vm.filtered,
                          'headersTexts': headersTexts,
                          'headersKeys': vm.keys,
                        });

                        // 3. تحديد موقع الحفظ
                        final location = await getSaveLocation(
                          suggestedName: "ترحيل.xlsx",
                          acceptedTypeGroups: [
                            XTypeGroup(
                              label: "Excel File",
                              extensions: ["xlsx"],
                            ),
                          ],
                        );

                        if (location == null) return;

                        // 4. حفظ الملف
                        String path = location.path;
                        if (!path.endsWith(".xlsx")) path += ".xlsx";

                        final file = File(path);
                        await file.writeAsBytes(bytes, flush: true);

                        // يمكنك إضافة رسالة نجاح هنا
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم تصدير البيانات إلى ملف Excel بنجاح.',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 8),

                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade900,
                      ),
                      child: const Text("بيان متبقى ترحيل"),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final vm = context.read<TarhilViewModel>();

                        // 1. استعادة البيانات الأساسية (الكتابين والتواريخ)
                        final TextEditingController book1No =
                            TextEditingController(
                              text: prefs.getString('book1No') ?? '',
                            );
                        final TextEditingController book2No =
                            TextEditingController(
                              text: prefs.getString('book2No') ?? '',
                            );
                        String selectedDate1 =
                            prefs.getString('book1Date') ??
                            DateFormat('yyyy/MM/dd').format(DateTime.now());
                        String selectedDate2 =
                            prefs.getString('book2Date') ??
                            DateFormat('yyyy/MM/dd').format(DateTime.now());

                        // 2. استعادة قائمة توزيع الضباط وتحويلها من JSON إلى Controllers
                        List<Map<String, dynamic>> officersDist = [];
                        String? savedDist = prefs.getString(
                          'officersDistribution',
                        );
                        if (savedDist != null) {
                          try {
                            Iterable decoded = jsonDecode(savedDist);
                            officersDist = decoded
                                .map(
                                  (item) => {
                                    'area': item['area'],
                                    'count': TextEditingController(
                                      text: item['count'].toString(),
                                    ),
                                  },
                                )
                                .toList();
                          } catch (e) {
                            debugPrint("Error decoding saved distribution: $e");
                          }
                        }

                        showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text(
                                    "بيانات التقرير وتوزيع الضباط",
                                    textAlign: TextAlign.right,
                                  ),
                                  content: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.95,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // --- القسم الأول: كتاب الهيئة ---
                                          TextField(
                                            controller: book1No,
                                            decoration: const InputDecoration(
                                              labelText: "رقم كتاب الهيئة",
                                              prefixIcon: Icon(
                                                Icons.description,
                                              ),
                                            ),
                                          ),
                                          ListTile(
                                            title: Text(
                                              "تاريخ كتاب الهيئة: $selectedDate1",
                                            ),
                                            trailing: const Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                            ),
                                            onTap: () async {
                                              DateTime? p =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime(2030),
                                                  );
                                              if (p != null) {
                                                setState(
                                                  () => selectedDate1 =
                                                      DateFormat(
                                                        'yyyy/MM/dd',
                                                      ).format(p),
                                                );
                                              }
                                            },
                                          ),
                                          const Divider(),

                                          // --- القسم الثاني: كتاب هيئة التنظيم ---
                                          TextField(
                                            controller: book2No,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  "رقم كتاب هيئة التنظيم",
                                              prefixIcon: Icon(
                                                Icons.edit_document,
                                              ),
                                            ),
                                          ),
                                          ListTile(
                                            title: Text(
                                              "تاريخ كتاب التنظيم: $selectedDate2",
                                            ),
                                            trailing: const Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                            ),
                                            onTap: () async {
                                              DateTime? p =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(2020),
                                                    lastDate: DateTime(2030),
                                                  );
                                              if (p != null) {
                                                setState(
                                                  () => selectedDate2 =
                                                      DateFormat(
                                                        'yyyy/MM/dd',
                                                      ).format(p),
                                                );
                                              }
                                            },
                                          ),
                                          const Divider(
                                            thickness: 2,
                                            color: Colors.blueAccent,
                                          ),

                                          // --- القسم الثالث: توزيع ضباط الاحتياط ---
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "توزيع ضباط الاحتياط:",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      officersDist.add({
                                                        'area':
                                                            vm
                                                                .fatherAreas
                                                                .isNotEmpty
                                                            ? vm
                                                                  .fatherAreas
                                                                  .first
                                                            : null,
                                                        'count':
                                                            TextEditingController(
                                                              text: '0',
                                                            ),
                                                      });
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    "إضافة جهة",
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          if (officersDist.isEmpty)
                                            const Text(
                                              "لم يتم إضافة توزيع للضباط بعد",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),

                                          ...officersDist.asMap().entries.map((
                                            entry,
                                          ) {
                                            int index = entry.key;
                                            Map<String, dynamic> item =
                                                entry.value;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      Colors.blueGrey.shade100,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: SearchableDropdown(
                                                      label: "التبعية المختارة",
                                                      value: item['area'],
                                                      items: vm.fatherAreas,
                                                      onChanged: (val) =>
                                                          setState(
                                                            () => item['area'] =
                                                                val,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    flex: 1,
                                                    child: TextField(
                                                      controller: item['count'],
                                                      keyboardType:
                                                          TextInputType.number,
                                                      textAlign:
                                                          TextAlign.center,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText: "العدد",
                                                          ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_forever,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () => setState(
                                                      () => officersDist
                                                          .removeAt(index),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    // زر مسح الذاكرة (SharedPreferences)
                                    TextButton(
                                      onPressed: () async {
                                        await prefs.remove('book1No');
                                        await prefs.remove('book1Date');
                                        await prefs.remove('book2No');
                                        await prefs.remove('book2Date');
                                        await prefs.remove(
                                          'officersDistribution',
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "مسح البيانات المحفوظة",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // تحضير البيانات النهائية
                                        List<Map<String, dynamic>> finalDist =
                                            officersDist
                                                .where((e) => e['area'] != null)
                                                .map(
                                                  (e) => {
                                                    'area': e['area'],
                                                    'count':
                                                        int.tryParse(
                                                          e['count'].text,
                                                        ) ??
                                                        0,
                                                  },
                                                )
                                                .toList();

                                        // حفظ البيانات في SharedPreferences
                                        await prefs.setString(
                                          'book1No',
                                          book1No.text,
                                        );
                                        await prefs.setString(
                                          'book1Date',
                                          selectedDate1,
                                        );
                                        await prefs.setString(
                                          'book2No',
                                          book2No.text,
                                        );
                                        await prefs.setString(
                                          'book2Date',
                                          selectedDate2,
                                        );
                                        await prefs.setString(
                                          'officersDistribution',
                                          jsonEncode(finalDist),
                                        );

                                        Navigator.pop(context);

                                        // إرسال البيانات للـ PDF
                                        await vm.exportTarhilPdf(
                                          extraData: {
                                            'book1No': book1No.text,
                                            'book1Date': selectedDate1,
                                            'book2No': book2No.text,
                                            'book2Date': selectedDate2,
                                            'officersDistribution': finalDist,
                                          },
                                        );
                                      },
                                      child: Text("بيان متبقى ترحيل"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
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
              //=================== الجدول ===================
              Scrollbar(
                controller: _horizontalScroll,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1600,
                    child: PaginatedDataTable(
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
                      key: vm.tableKey,

                      columns: vm.columns,
                      source: TarhilDataSource(
                        context,
                        vm.filtered,
                        vm.keys,
                        vm,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TarhilDataSource extends DataTableSource {
  final BuildContext context;
  final List<Map<String, dynamic>> data;
  final List<String> keys;
  final TarhilViewModel vm;

  TarhilDataSource(this.context, this.data, this.keys, this.vm);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;

    final row = data[index];

    return DataRow(
      cells: keys.map((k) {
        final value = row[k]?.toString() ?? "";

        if (k == "soldiers_name") {
          return DataCell(
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: vm,
                    child: EditTarhilDialog(existing: row),
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

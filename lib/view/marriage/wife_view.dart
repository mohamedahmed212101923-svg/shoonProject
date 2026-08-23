import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/Multi_select_popup.dart';
import 'package:flutter_application_1/viewmodels/functions/excel.dart';
import 'package:flutter_application_1/viewmodels/functions/format_date.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/viewmodels/functions/normalize_arabic.dart';
import 'package:flutter_application_1/viewmodels/marriage/wife_view_model.dart';

class WifeManagementPage extends StatelessWidget {
  const WifeManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // نستخدم Consumer لتغليف الصفحة بالكامل لضمان استجابتها لأي تغيير في الـ VM
    return Consumer<WifeViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF0F2F5),
          appBar: AppBar(
            title: const Text(
              "منظومة بيانات الزوجات",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.indigo[900],
            foregroundColor: Colors.white,
            elevation: 10,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          body: Column(
            children: [
              _buildTopStats(vm),
              _buildSearchAndFilterSection(context, vm),
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.wives.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: vm.wives.length,
                        itemBuilder: (context, index) =>
                            _buildModernWifeCard(vm.wives[index], vm, context),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showModernForm(context, vm),
            backgroundColor: Colors.indigo[900],
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            label: const Text(
              "إضافة زوجة",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 1. الإحصائيات ---
  // --- 1. الإحصائيات (معدلة لعرض إجمالي الكتيبة المختارة) ---
  Widget _buildTopStats(WifeViewModel vm) {
    // حساب إجمالي الزوجات في الكتائب المختارة حالياً
    // إذا كانت القائمة فارغة، سيعرض 0 أو يمكنك إخفاء العنصر
    final selectedCount = vm.wives.length;
    final isFiltered = vm.selectedBattalionsList.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[900]!, Colors.indigo[700]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("الإجمالي العام", "${vm.totalCount}", Icons.people_alt),

          // إذا تم اختيار كتيبة، نظهر فاصل وإحصائية الكتيبة
          if (isFiltered) ...[
            Container(width: 1, height: 40, color: Colors.white24),
            _statItem(
              "نتائج التصفية",
              "$selectedCount",
              Icons.filter_alt,
              color: Colors.orangeAccent,
            ),
          ],

          Container(width: 1, height: 40, color: Colors.white24),
          _statItem(
            "الكتائب",
            "${vm.battalions.length}",
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  // تعديل بسيط في دالة _statItem لدعم تغيير اللون
  Widget _statItem(
    String label,
    String value,
    IconData icon, {
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color == Colors.white ? Colors.orangeAccent : color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  // --- 2. البحث والفلترة (تم التعديل هنا ليعتمد على الـ ViewModel) ---
  Widget _buildSearchAndFilterSection(BuildContext context, WifeViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        // حولناها لـ Column عشان لو عاوز تضيف صف تاني تحت
        children: [
          Row(
            children: [
              // حقل البحث
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => vm.search(normalizeArabic(v)),
                    decoration: const InputDecoration(
                      hintText: "بحث بالاسم...",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // زر التصفية
              Expanded(
                flex: 1,
                child: MultiSelectPopup(
                  label: "تصفية الكتائب",
                  options: vm.battalions,
                  selectedValues: vm.selectedBattalionsList,
                  onToggle: (val) {
                    List<String> currentSelected = List.from(
                      vm.selectedBattalionsList,
                    );
                    if (currentSelected.contains(val)) {
                      currentSelected.remove(val);
                    } else {
                      currentSelected.add(val);
                    }
                    vm.filterByMultipleBattalions(currentSelected);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // صف أزرار التحكم الإضافية (مثل زر التصدير)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green.shade900,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 20),
                label: const Text(
                  "تصدير إكسيل (النتائج الحالية)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  // 1. تحديد العناوين البرمجية والعناوين الظاهرة
                  final headersTexts = [
                    "الرقم الثلاثى",
                    "الرقم العسكرى",
                    "الكتيبة",
                    "الاسم",
                    "رقم السجل",
                    "المحافظة",
                    "السلاح",
                    "اسم الزوجة",
                    "الرقم القومى للزوجة",
                    "رقم القسيمة",
                    "تاريخ الزواج",
                    "الرقم القومى للزوج",
                  ];

                  final headersKeys = [
                    "soldiers_triple_number",
                    "soldiers_number",
                    "soldiers_k",
                    "soldiers_name",
                    "soldiers_unit_id",
                    "soldiers_city",
                    "soldiers_weapon",
                    "wife_name",
                    "wife_national_number",
                    "wife_married_card_id",
                    "wife_married_date",
                    "soldiers_national_number",
                  ];

                  final bytes = await compute(buildExcelBytes, {
                    'data': vm.wives,
                    'headersTexts': headersTexts,
                    'headersKeys': headersKeys,
                  });

                  // 3. اختيار مكان الحفظ (File Picker)
                  final location = await getSaveLocation(
                    suggestedName: "كشف المتزوجين.xlsx",
                    acceptedTypeGroups: [
                      XTypeGroup(label: "Excel File", extensions: ["xlsx"]),
                    ],
                  );

                  if (location == null) return;

                  // 4. كتابة الملف
                  String path = location.path;
                  if (!path.endsWith(".xlsx")) path += ".xlsx";

                  final file = File(path);
                  await file.writeAsBytes(bytes, flush: true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم تصدير الملف بنجاح")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. الكارت الخاص بالزوجة ---
  Widget _buildModernWifeCard(
    Map<String, dynamic> wife,
    WifeViewModel vm,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: Colors.orangeAccent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              wife['wife_name'] ?? "بدون اسم",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildActionButtons(wife, vm, context),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _infoRow(Icons.person, "الزوج: ${wife['husband_name']}"),
                      _infoRow(
                        Icons.military_tech,
                        "الرقم العسكري: ${wife['wife_soldiers_number']}",
                      ),
                      _infoRow(Icons.flag, "الكتيبة: ${wife['battalion']}"),
                      _infoRow(
                        Icons.calendar_today,
                        "تاريخ الزواج: ${wife['wife_married_date'] ?? 'غير مسجل'}",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.indigo[300]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> wife,
    WifeViewModel vm,
    BuildContext context,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.blue),
          onPressed: () => _showModernForm(context, vm, wife: wife),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_sweep_outlined,
            color: Colors.redAccent,
          ),
          onPressed: () => _confirmDelete(context, wife, vm),
        ),
      ],
    );
  }

  // --- 4. الفورم (تم تعديله لاستقبال vm) ---
  void _showModernForm(
    BuildContext context,
    WifeViewModel vm, {
    Map<String, dynamic>? wife,
  }) async {
    final isEdit = wife != null;
    final formKey = GlobalKey<FormState>();
    List<Map<String, dynamic>> allSoldiers = await vm.getAllSoldiers();
    List<Map<String, dynamic>> filteredSoldiers = [];

    final nameCtrl = TextEditingController(
      text: isEdit ? wife['wife_name'] : "",
    );
    final idCtrl = TextEditingController(
      text: isEdit ? wife['wife_national_number'] : "",
    );
    final cardCtrl = TextEditingController(
      text: isEdit ? wife['wife_married_card_id'] : "",
    );
    final dateCtrl = TextEditingController(
      text: isEdit ? formatDate(wife['wife_married_date']) : "",
    );

    String? selectedSoldierNum = isEdit
        ? wife['wife_soldiers_number'].toString()
        : null;
    String? selectedSoldierName = isEdit ? wife['husband_name'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        // نستخدم StatefulBuilder فقط داخل الـ BottomSheet للبحث المحلي
        builder: (context, setST) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 15,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isEdit ? "تعديل بيانات" : "إضافة زوجة جديدة",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // منطق اختيار العسكري (كما هو في كودك)
                  if (selectedSoldierNum == null) ...[
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: "ابحث عن اسم العسكري أو رقمه...",
                        prefixIcon: const Icon(Icons.person_search),
                        filled: true,
                        fillColor: Colors.blue[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setST(() {
                          final query = normalizeArabic(v);
                          if (query.isEmpty) {
                            filteredSoldiers = [];
                            return;
                          }
                          filteredSoldiers = allSoldiers.where((s) {
                            final name = normalizeArabic(
                              s['soldiers_name'].toString(),
                            );
                            final number = s['soldiers_number'].toString();
                            return name.contains(query) ||
                                number.contains(v.trim());
                          }).toList();
                        });
                      },
                    ),
                    if (filteredSoldiers.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredSoldiers.length,
                          itemBuilder: (c, i) => ListTile(
                            title: Text(filteredSoldiers[i]['soldiers_name']),
                            subtitle: Text(
                              "رقم: ${filteredSoldiers[i]['soldiers_number']}",
                            ),
                            onTap: () => setST(() {
                              selectedSoldierNum =
                                  filteredSoldiers[i]['soldiers_number']
                                      .toString();
                              selectedSoldierName =
                                  filteredSoldiers[i]['soldiers_name'];
                              filteredSoldiers = [];
                            }),
                          ),
                        ),
                      ),
                  ] else
                    ListTile(
                      tileColor: Colors.green[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(
                        selectedSoldierName!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("رقم عسكري: $selectedSoldierNum"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => setST(() => selectedSoldierNum = null),
                      ),
                    ),

                  const SizedBox(height: 15),
                  _modernFormField(
                    controller: nameCtrl,
                    label: "اسم الزوجة",
                    icon: Icons.woman,
                    validator: (v) => v!.isEmpty ? "الاسم مطلوب" : null,
                  ),
                  _modernFormField(
                    controller: idCtrl,
                    label: "الرقم القومي",
                    icon: Icons.badge,
                    isNum: true,
                    validator: (v) => v!.length != 14 ? "14 رقم مطلوب" : null,
                  ),
                  _modernFormField(
                    controller: cardCtrl,
                    label: "رقم القسيمة",
                    icon: Icons.description,
                    isNum: true,
                  ),

                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "تاريخ الزواج",
                      prefixIcon: const Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setST(() => dateCtrl.text = formatDate(picked)!);
                      }
                    },
                  ),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedSoldierNum == null) return;
                        if (formKey.currentState!.validate()) {
                          bool res = isEdit
                              ? await vm.editWife(
                                  wifeId: wife['wife_id'],
                                  name: nameCtrl.text,
                                  nationalNumber: idCtrl.text,
                                  soldierNumber: selectedSoldierNum!,
                                  marriedCardId: cardCtrl.text,
                                  marriageDate: dateCtrl.text,
                                )
                              : await vm.addNewWife(
                                  name: nameCtrl.text,
                                  nationalNumber: idCtrl.text,
                                  soldierNumber: selectedSoldierNum!,
                                  marriedCardId: cardCtrl.text,
                                  marriageDate: dateCtrl.text,
                                );
                          if (res) Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        "حفظ البيانات",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNum = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Map<String, dynamic> wife,
    WifeViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: Text("هل أنت متأكد من حذف بيانات ${wife['wife_name']}؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              vm.deleteWife(wife['wife_id']);
              Navigator.pop(c);
            },
            child: const Text(
              "حذف الآن",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.layers_clear_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          "لا توجد بيانات مسجلة",
          style: TextStyle(color: Colors.grey[400], fontSize: 18),
        ),
      ],
    ),
  );
}

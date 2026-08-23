import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/new_batches/batch_view_model.dart';
import 'package:flutter_application_1/viewmodels/functions/format_date.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:file_picker/file_picker.dart'; // تأكد من إضافة المكتبة

class BatchesPage extends StatefulWidget {
  const BatchesPage({super.key});

  @override
  State<BatchesPage> createState() => _BatchesPageState();
}

class _BatchesPageState extends State<BatchesPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> fieldControllers = {};

  final List<String> weapons = ["مهندسين", "مياه", "مساحة", "أشغال"];
  final List<String> levels = [
    "عالي",
    "فوق المتوسط",
    "عادة",
    "متوسط/حرفى",
    "متوسط/مهنى",
  ];
  final List<String> types = ["صف", "جوية", "بحرية"];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<BatchesPageViewModel>().loadBatches());

    for (var w in weapons) {
      for (var lvl in levels) {
        for (var t in types) {
          String key = "${lvl}_${w}_$t";
          fieldControllers[key] = TextEditingController(text: "0");
        }
      }
    }
  }

  @override
  void dispose() {
    fieldControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // --- دالة استيراد ملف الإكسيل ---
  Future<void> _handleImportExcel(
    BuildContext context,
    BatchesPageViewModel vm,
  ) async {
    // 1. التأكد أن هناك دفعة مختارة قبل البدء
    if (vm.selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار دفعة أولاً من القائمة")),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      // 2. تمرير الـ context والـ ID الحقيقي للدفعة المختارة
      await vm.importExcel(
        context, // مررنا الـ context هنا
        result.files.single.bytes!,
        vm.selectedBatchId.toString(), // مررنا الـ ID الحقيقي بدلاً من "1"
      );

      if (context.mounted) {
        if (vm.failedRows.isNotEmpty) {
          _showErrorsDialog(context, vm.failedRows);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم استيراد الملف بنجاح")),
          );
        }
      }
    }
  }

  void _showErrorsDialog(
    BuildContext context,
    List<Map<String, String>> errors,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تنبيه بخصوص الاستيراد"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(errors[i]['name'] ?? ""),
              subtitle: Text(errors[i]['reason'] ?? ""),
              leading: CircleAvatar(child: Text(errors[i]['row'] ?? "")),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  Future<void> _showBatchDialog(BuildContext context) async {
    final vm = context.read<BatchesPageViewModel>();
    final TextEditingController nameCtrl = TextEditingController(
      text: vm.nameCtrl.text,
    );
    DateTime? selectedDate = DateTime.tryParse(vm.dateCtrl.text);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              vm.selectedBatchId == null ? "إضافة دفعة جديدة" : "تعديل الدفعة",
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "اسم الدفعة",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "ادخل اسم الدفعة" : null,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? "لم يتم اختيار تاريخ"
                                : "التاريخ: ${DateFormat('yyyy/MM/dd').format(selectedDate!)}",
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setStateDialog(() => selectedDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text("اختر التاريخ"),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      const Text(
                        "توزيع الخطة (الأسلحة والمؤهلات)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          defaultColumnWidth: const FixedColumnWidth(100),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                              ),
                              children: [
                                const TableCell(
                                  child: Center(
                                    child: Text(
                                      "السلاح/المؤهل",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                ...levels.map(
                                  (lvl) => TableCell(
                                    child: Center(
                                      child: Text(
                                        lvl,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const TableCell(
                                  child: Center(
                                    child: Text(
                                      "إجمالي السلاح",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...weapons.map(
                              (w) => TableRow(
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        w,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...levels.map(
                                    (lvl) => TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Column(
                                          children: types.map((t) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: TextFormField(
                                                controller:
                                                    vm.planCtrls[vm
                                                        .getColumnNameFromArabic(
                                                          lvl,
                                                          w,
                                                          t,
                                                        )],
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: t,
                                                  border:
                                                      const OutlineInputBorder(),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Center(
                                      child: Text(
                                        vm.getWeaponTotal(w).toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                              ),
                              children: [
                                const TableCell(
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      "إجمالي المؤهل",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                ...levels.map(
                                  (lvl) => TableCell(
                                    child: Center(
                                      child: Text(
                                        vm.getLevelTotal(lvl).toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Center(
                                    child: Text(
                                      weapons
                                          .map((w) => vm.getWeaponTotal(w))
                                          .reduce((a, b) => a + b)
                                          .toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      selectedDate != null) {
                    vm.nameCtrl.text = nameCtrl.text;
                    vm.dateCtrl.text = selectedDate!.toIso8601String();
                    fieldControllers.forEach(
                      (key, controller) =>
                          vm.planCtrls[key]?.text = controller.text,
                    );
                    await vm.save(context);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم الحفظ بنجاح")),
                    );
                  }
                },
                child: const Text("حفظ البيانات"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BatchesPageViewModel>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text("إدارة الدفعات"),
              if (vm.selectedBatchId != null)
                Text(
                  "المحددة حالياً: ${vm.nameCtrl.text}",
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
            ],
          ),
          actions: [
            if (vm.selectedBatchId !=
                null) // لا يظهر الزر إلا إذا تم اختيار دفعة
              TextButton.icon(
                onPressed: vm.isLoading
                    ? null
                    : () => _handleImportExcel(context, vm),
                icon: const Icon(Icons.file_upload, color: Colors.blue),
                label: const Text("استيراد لهذه الدفعة"),
              ),
          ],
        ),
        body: Stack(
          children: [
            // المحتوى الأصلي للصفحة
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "الدفعات المسجلة",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "الإجمالي: ${vm.batches.length}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: vm.batches.isEmpty
                        ? const Center(
                            child: Text("لا توجد دفعات مضافة حالياً"),
                          )
                        : ListView.builder(
                            itemCount: vm.batches.length,
                            itemBuilder: (_, index) {
                              final batch = vm.batches[index];
                              final isSelected =
                                  vm.selectedBatchId == batch['batch_id'];
                              return Card(
                                elevation: isSelected
                                    ? 8
                                    : 2, // ظل أقوى للمختار
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: isSelected
                                      ? const BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ) // إطار أزرق للمختار
                                      : BorderSide.none,
                                ),
                                color: isSelected
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.groups),
                                  ),
                                  title: Text(
                                    "مخطط دفعة: ${vm.getBatchMonth(batch['batch_name'])} ${(batch['batch_name'].toString()).substring(0, batch['batch_name'].length - 1)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "تاريخ البداية: ${formatDate(batch['batch_start_date'])}",
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize
                                        .min, // 👈 هذا السطر ضروري جداً
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_sweep,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () => _confirmDelete(
                                          context,
                                          vm,
                                          batch['batch_id'],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          // 1. تحديث الـ ViewModel بالدفعة التي ضغطت عليها الآن قبل فتح الـ Dialog
                                          await vm.selectBatch(
                                            batch['batch_id'],
                                          );

                                          // 2. تحديث الـ controllers المحلية لضمان ظهور الأرقام الصحيحة في الجدول داخل الـ Dialog
                                          fieldControllers.forEach((key, c) {
                                            c.text =
                                                vm.planCtrls[key]?.text ?? '0';
                                          });

                                          // 3. الآن افتح الـ Dialog وسيظهر ببيانات الدفعة الصحيحة
                                          if (context.mounted) {
                                            await _showBatchDialog(context);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    await vm.selectBatch(batch['batch_id']);
                                    fieldControllers.forEach(
                                      (key, c) => c.text =
                                          vm.planCtrls[key]?.text ?? '0',
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // طبقة التحميل (تظهر فوق كل شيء)
            if (vm.isLoading)
              Container(
                color: Colors.black45, // تعتيم الخلفية
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text(
                            "جاري استيراد البيانات من ملف الإكسيل...",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: vm.isLoading
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  vm.newBatch();
                  fieldControllers.forEach((k, c) => c.text = "0");
                  _showBatchDialog(context);
                },
                label: const Text("إضافة دفعة"),
                icon: const Icon(Icons.add),
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BatchesPageViewModel vm, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد من حذف هذه الدفعة نهائياً؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              await vm.delete(context, id);
              Navigator.pop(ctx);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

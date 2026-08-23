import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/ajaza/ajaza_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// الدالة الرئيسية لاستدعاء الـ Dialog
void showBulkInsertDialog(BuildContext context) async {
  final vm = Provider.of<AjazaViewModel>(context, listen: false);

  // التأكد من اختيار الدفعة أولاً
  if (vm.batchId == null) {
    _showSnackBar(context, "⚠️ برجاء اختيار الدفعة أولاً من القائمة الرئيسية");
    return;
  }

  // 1. إظهار مؤشر تحميل أثناء جلب أنواع المنح
  _showLoading(context, message: "جاري فحص أنواع المنح...");

  List<String> giftTypes = [];
  try {
    giftTypes = await vm.repo.getUniqueGiftTypes(vm.batchId!);
  } catch (e) {
    debugPrint("Error fetching gift types: $e");
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  // تجهيز الـ Controllers والتواريخ الافتراضية
  final Map<String, TextEditingController> giftControllers = {
    for (var type in giftTypes) type: TextEditingController(text: "0"),
  };

  Map<String, DateTimeRange> selectedDates = {
    'cairo': DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 5)),
    ),
    'lower': DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 5)),
    ),
    'upper': DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 5)),
    ),
  };

  if (!context.mounted) return;

  // 2. عرض الـ Dialog الأساسي
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Column(
              children: [
                Icon(Icons.group_sharp, size: 40, color: Colors.green),
                SizedBox(height: 10),
                Text(
                  "تسجيل إجازة مستجدين جماعية",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "📅 حدد تواريخ النزول والعودة لكل إقليم:",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    _buildRegionPicker(
                      "إقليم القاهرة والمركز",
                      selectedDates['cairo']!,
                      (range) => setState(() => selectedDates['cairo'] = range),
                      context,
                    ),
                    _buildRegionPicker(
                      "إقليم وجه بحري",
                      selectedDates['lower']!,
                      (range) => setState(() => selectedDates['lower'] = range),
                      context,
                    ),
                    _buildRegionPicker(
                      "إقليم الصعيد",
                      selectedDates['upper']!,
                      (range) => setState(() => selectedDates['upper'] = range),
                      context,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(thickness: 1.5),
                    ),
                    const Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 18,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "أيام زيادة المنح (إضافي)",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (giftTypes.isEmpty)
                      const Text(
                        "لا توجد أنواع منح مسجلة لهذه الدفعة",
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      )
                    else
                      ...giftTypes.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: giftControllers[type],
                            decoration: InputDecoration(
                              labelText: "أيام منحة ($type)",
                              border: const OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: const Icon(Icons.add_circle_outline),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  "إلغاء",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.save),
                onPressed: () async {
                  final Map<String, int> giftValues = {
                    for (var type in giftTypes)
                      type: int.tryParse(giftControllers[type]!.text) ?? 0,
                  };

                  // إظهار الـ Loading بدون قفل الـ Dialog الأساسي
                  _showLoading(
                    context,
                    message:
                        "جاري معالجة السجلات (قد يستغرق وقتاً للأعداد الكبيرة)...",
                  );

                  try {
                    // استدعاء الدالة وانتظار النتيجة (يجب تعديل الـ ViewModel ليرجع String?)
                    final result = await vm.saveBulkLeaves(
                      regionDates: selectedDates,
                      giftDaysInput: giftValues,
                      context: context,
                    );

                    // 1. إغلاق الـ Loading أولاً
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }

                    // 2. التحقق من النتيجة
                    if (result != null && result.startsWith("SUCCESS")) {
                      // في حالة النجاح فقط نغلق النافذة الأساسية
                      if (context.mounted) Navigator.pop(dialogContext);
                      _showSnackBar(
                        context,
                        result.replaceFirst("SUCCESS: ", ""),
                      );
                    } else {
                      // في حالة وجود خطأ أو رسالة تنبيه، تظل النافذة مفتوحة
                      _showSnackBar(
                        context,
                        "⚠️ ${result ?? 'حدث خطأ غير متوقع'}",
                      );
                    }
                  } catch (e) {
                    // إغلاق الـ Loading في حالة الكراش
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    _showSnackBar(context, "خطأ فني: $e");
                  }
                },
                label: const Text("حفظ وتسجيل الكل"),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Widget مساعد لاختيار التاريخ
Widget _buildRegionPicker(
  String label,
  DateTimeRange currentRange,
  Function(DateTimeRange) onSelect,
  BuildContext context,
) {
  final df = DateFormat("yyyy/MM/dd");
  return Card(
    elevation: 0,
    color: Colors.grey.shade50,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "${df.format(currentRange.start)}  ⬅️  ${df.format(currentRange.end)}",
        style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
      ),
      trailing: const Icon(Icons.calendar_month, color: Colors.blue),
      onTap: () async {
        DateTimeRange? picked = await showDateRangePicker(
          context: context,
          initialDateRange: currentRange,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onSelect(picked);
      },
    ),
  );
}

/// دالة إظهار التحميل (معدلة لضمان الثبات)
void _showLoading(
  BuildContext context, {
  String message = "جاري معالجة البيانات...",
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

void _showSnackBar(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

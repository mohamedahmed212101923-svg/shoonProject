import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/batch_plan_columns.dart';
import 'package:flutter_application_1/viewmodels/receiving/daily_receipts_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

class DailyReceiptsView extends StatelessWidget {
  const DailyReceiptsView({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DailyReceiptsViewModel>();
    final weapons = ["مهندسين", "مياه", "مساحة", "أشغال"];
    final levels = ["عليا", "فوق متوسط", "عادة", "متوسط صف", "متوسط مهنى"];
    final types = ["صف", "جوية", "بحرية"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("استلام اليوميات"),
        actions: [
          // --- إضافة زر التصدير هنا ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // زر التقرير العادي
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("يومية ما تم استلامه"),
                onPressed: () => vm.printDailyReport(
                  levels: levels,
                  weapons: weapons,
                  types: types,
                ),
              ),
              const SizedBox(width: 10),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  "يومية تمام الأسلحة",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  try {
                    // 1. جلب القيمة المخزنة
                    final prefs = await SharedPreferences.getInstance();
                    int lastVal = prefs.getInt('manual_balance') ?? 0;

                    // 2. إعداد المتحكم للقيمة الافتراضية
                    final TextEditingController controller =
                        TextEditingController(text: lastVal.toString());

                    // 3. عرض النافذة (يجب التأكد من وجود context)
                    if (!context.mounted) return;

                    showDialog(
                      context: context,
                      builder: (dialogContext) => Directionality(
                        textDirection:
                            TextDirection.rtl, // لضبط اتجاه اللغة العربية
                        child: AlertDialog(
                          title: const Text(
                            "التخصصات الخارجية",
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("أدخل قيمة التخصصات الخارجية:"),
                              const SizedBox(height: 10),
                              TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "0",
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("إلغاء"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                int inputVal =
                                    int.tryParse(controller.text) ?? 0;

                                // حفظ القيمة الجديدة
                                await prefs.setInt('manual_balance', inputVal);

                                // إغلاق النافذة
                                Navigator.pop(dialogContext);

                                // 4. استدعاء الـ ViewModel بالمعامل الجديد
                                await vm.printWeaponsDailyReport(
                                  levels: levels,
                                  weapons: weapons,
                                  types: types,
                                  manualBalance:
                                      inputVal, // القيمة التي أدخلها المستخدم
                                );
                              },
                              child: const Text("حفظ وطباعة"),
                            ),
                          ],
                        ),
                      ),
                    );
                  } catch (e) {
                    print("Error opening dialog: $e");
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(context, vm, levels, weapons, types),
          _buildHistoryHeader(vm),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildHistoryList(context, vm, weapons, levels, types),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          vm.clearForm();
          _showEntrySheet(context, vm, weapons, levels, types);
        },
        label: const Text(
          "استلام جديد",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_task, color: Colors.amber),
        backgroundColor: Colors.blueAccent[700],
      ),
    );
  }

  // --- جدول الإجماليات التراكمي (ReadOnly) ---
  void _showGrandTotalSheet(
    BuildContext context,
    DailyReceiptsViewModel vm,
    List<String> weapons,
    List<String> levels,
    List<String> types,
  ) {
    final ScrollController horizontalController = ScrollController();
    Map<String, int> grandTotals = {};

    for (var level in levels) {
      for (var weapon in weapons) {
        for (var type in types) {
          String key = getDbKey(level, weapon, type);
          int total = 0;
          for (var record in vm.historyEntries) {
            var val = record[key];
            if (val != null) total += (val as num).toInt();
          }
          grandTotals[key] = total;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSheetHeader(context, "إجمالي السجلات التراكمي", null),
              const Divider(),
              Expanded(
                child: Scrollbar(
                  controller: horizontalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: _buildReadOnlyTable(
                        weapons,
                        levels,
                        types,
                        grandTotals,
                        vm,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إغلاق"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. جدول الإجماليات التراكمي المعدل ليصبح مثل جدول الإدخال تماماً ---
  // --- 1. جدول الإجماليات التراكمي المعدل ليصبح مثل جدول الإدخال تماماً ---
  Widget _buildReadOnlyTable(
    List<String> weapons,
    List<String> levels,
    List<String> types,
    Map<String, int> grandTotals,
    DailyReceiptsViewModel vm,
  ) {
    Map<String, int> columnTotalsReceipt = {}; // إجمالي المستلم
    Map<String, int> columnTotalsPlan = {}; // إجمالي المخطط
    int absoluteGrandTotalReceipt = 0;
    int absoluteGrandTotalPlan = 0;

    // 1. حساب الإجماليات الرأسية لكل من المخطط والمستلم
    for (var l in levels) {
      int sumLevelReceipt = 0;
      int sumLevelPlan = 0;
      for (var w in weapons) {
        for (var t in types) {
          String key = getDbKey(l, w, t);
          sumLevelReceipt += grandTotals[key] ?? 0;
          sumLevelPlan += (vm.planData[key] ?? 0);
        }
      }
      columnTotalsReceipt[l] = sumLevelReceipt;
      columnTotalsPlan[l] = sumLevelPlan;

      absoluteGrandTotalReceipt += sumLevelReceipt;
      absoluteGrandTotalPlan += sumLevelPlan;
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.blueGrey[900]),
      headingRowHeight: 40,
      dataRowMinHeight: 38,
      dataRowMaxHeight: 38,
      columnSpacing: 10,
      horizontalMargin: 10,
      border: TableBorder.all(color: Colors.grey[300]!, width: 0.5),
      columns: [
        const DataColumn(
          label: Expanded(
            child: Center(
              child: Text(
                "السلاح",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const DataColumn(
          label: Expanded(
            child: Center(
              child: Text(
                "البيان",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        ...levels.map(
          (l) => DataColumn(
            label: Expanded(
              child: Center(
                child: Text(
                  l,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const DataColumn(
          label: Text(
            "إجمالي",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      rows: [
        // --- صفوف البيانات لكل سلاح ---
        ...weapons.expand((weapon) {
          int receiptRowTotal = 0;
          int planRowTotal = 0;
          for (var l in levels) {
            for (var t in types) {
              String key = getDbKey(l, weapon, t);
              planRowTotal += (vm.planData[key] ?? 0);
              receiptRowTotal += (grandTotals[key] ?? 0);
            }
          }

          return [
            // (نفس صف الفئة ص ج ب)
            DataRow(
              color: WidgetStateProperty.all(Colors.blueGrey[100]),
              cells: [
                DataCell(Text("")),
                const DataCell(
                  Center(
                    child: Text(
                      "الفئة",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...levels.map(
                  (l) => DataCell(
                    Row(
                      children: types
                          .map(
                            (t) => Expanded(
                              child: Center(
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const DataCell(Text("")),
              ],
            ),
            // (صف المخطط)
            DataRow(
              color: WidgetStateProperty.all(
                Colors.orange[50]!.withOpacity(0.2),
              ),
              cells: [
                DataCell(
                  Center(
                    child: Text(
                      weapon,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      "المخطط",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ...levels.map(
                  (level) => DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: types
                          .map(
                            (type) => _readOnlyBox(
                              vm.planData[getDbKey(level, weapon, type)] ?? 0,
                              type,
                              isPlan: true,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      "$planRowTotal",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // (صف المستلم)
            DataRow(
              cells: [
                const DataCell(Text("")),
                const DataCell(
                  Center(
                    child: Text(
                      "المستلم",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                ...levels.map(
                  (level) => DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: types
                          .map(
                            (t) => _readOnlyBox(
                              grandTotals[getDbKey(level, weapon, t)] ?? 0,
                              t,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      "$receiptRowTotal",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ];
        }),

        // --- صف إجمالي المخطط العام (الجديد) ---
        DataRow(
          color: WidgetStateProperty.all(Colors.orange[100]),
          cells: [
            const DataCell(Text("")),
            const DataCell(
              Center(
                child: Text(
                  "إجمالي مخطط",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.brown,
                  ),
                ),
              ),
            ),
            ...levels.map(
              (l) => DataCell(
                Center(
                  child: Text(
                    "${columnTotalsPlan[l]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              Center(
                child: Text(
                  "$absoluteGrandTotalPlan",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),

        // --- صف إجمالي المستلم العام (إجمالي عام) ---
        DataRow(
          color: WidgetStateProperty.all(Colors.blueGrey[800]),
          cells: [
            const DataCell(Text("")),
            const DataCell(
              Center(
                child: Text(
                  "إجمالي عام",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ...levels.map(
              (l) => DataCell(
                Center(
                  child: Text(
                    "${columnTotalsReceipt[l]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "$absoluteGrandTotalReceipt",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ويدجت لعرض القيمة داخل مربع يشبه حقل الإدخال لكنه للقراءة فقط
  Widget _readOnlyBox(int value, String label, {bool isPlan = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Container(
        width: 42,
        height: 30,
        decoration: BoxDecoration(
          color: isPlan ? Colors.orange[50] : Colors.white,
          border: Border.all(
            color: isPlan ? Colors.orange[200]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            value == 0 ? label[0] : "$value",
            style: TextStyle(
              fontSize: 10,
              color: value == 0
                  ? Colors.grey[400]
                  : (isPlan ? Colors.orange[900] : Colors.black),
              fontWeight: value == 0 ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- واجهة الإدخال (Entry Sheet) مع صف الإجمالي السفلي بالألوان ---
  void _showEntrySheet(
    BuildContext context,
    DailyReceiptsViewModel vm,
    List<String> weapons,
    List<String> levels,
    List<String> types,
  ) {
    // حساب ابتدائي قبل فتح الشاشة لضمان ظهور الأرقام القديمة في العداد
    vm.calculateAll(weapons, levels, types);

    final ScrollController horizontalController = ScrollController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 20,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.98,
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSheetHeader(
                  context,
                  vm.currentReceiptId == null
                      ? "إضافة يوم جديد"
                      : "تعديل البيانات",
                  vm,
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDatePicker(context, vm, setSheetState),
                    ),
                    const SizedBox(width: 15),
                    // هذا العداد سيقرأ الآن vm.currentEntryTotal المحدثة
                    Expanded(flex: 1, child: _buildCurrentCounter(vm)),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Scrollbar(
                      controller: horizontalController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: _buildInputTable(
                            vm,
                            weapons,
                            levels,
                            types,
                            setSheetState,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // زر الحفظ الخاص بك كما كان
                _buildSaveButton(context, vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputTable(
    DailyReceiptsViewModel vm,
    List<String> weapons,
    List<String> levels,
    List<String> types,
    StateSetter setSheetState,
  ) {
    // 1. حساب إجماليات الأعمدة (المستويات) + حساب الإجمالي العام يدوياً لضمان التحديث اللحظي
    Map<String, int> columnTotals = {};
    int grandTotal = 0; // متغير جديد لحساب الإجمالي الكلي

    for (var l in levels) {
      int columnSum = 0;
      for (var w in weapons) {
        for (var t in types) {
          String key = getDbKey(l, w, t);
          int val = int.tryParse(vm.receiptCtrls[key]?.text ?? '0') ?? 0;
          columnSum += val;
        }
      }
      columnTotals[l] = columnSum;
      grandTotal += columnSum; // إضافة إجمالي كل عمود للإجمالي العام
    }

    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.blueGrey[800]),
      columnSpacing: 15,
      border: TableBorder.all(color: Colors.grey[300]!),
      columns: [
        const DataColumn(
          label: Text(
            "السلاح",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        ...levels.map(
          (l) => DataColumn(
            label: Expanded(
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const DataColumn(
          label: Text(
            "إجمالي",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: [
        // 2. بناء صفوف الأسلحة
        ...weapons.map((weapon) {
          int weaponRowTotal = 0;
          for (var l in levels) {
            for (var t in types) {
              weaponRowTotal +=
                  int.tryParse(
                    vm.receiptCtrls[getDbKey(l, weapon, t)]?.text ?? '0',
                  ) ??
                  0;
            }
          }

          return DataRow(
            cells: [
              DataCell(
                Text(
                  weapon,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              ...levels.map(
                (level) => DataCell(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: types
                        .map(
                          (type) => _buildTinyInputField(
                            vm,
                            vm.getDbKey(level, weapon, type),
                            type,
                            setSheetState, // التنبيه المطلوب
                            weapons,
                            levels,
                            types,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "$weaponRowTotal",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),

        // 3. صف الإجمالي النهائي (التعديل هنا)
        DataRow(
          color: WidgetStateProperty.all(Colors.grey[200]),
          cells: [
            const DataCell(
              Text(
                "إجمالي",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            ...levels.map(
              (l) => DataCell(
                Center(
                  child: Text(
                    "${columnTotals[l]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            // الخلية الأخيرة المعدلة
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$grandTotal", // نستخدم grandTotal المحسوب محلياً بدلاً من vm.currentEntryTotal
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- عناصر الواجهة الرئيسية (مع الألوان الأصلية) ---
  Widget _buildSummaryCard(
    BuildContext context,
    DailyReceiptsViewModel vm,
    List<String> levels,
    List<String> weapons,
    List<String> types,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent[700]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            "إجمالي المستلم",
            "${vm.totalStoredInHistory}",
            Icons.people,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          InkWell(
            onTap: () =>
                _showGrandTotalSheet(context, vm, weapons, levels, types),
            child: Column(
              children: [
                const Icon(
                  Icons.table_view_rounded,
                  color: Colors.orangeAccent,
                  size: 28,
                ),
                const Text(
                  "جدول الإجماليات",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "عرض الـ 60 حقل",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem(
            "عدد الأيام",
            "${vm.historyEntries.length}",
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHistoryHeader(DailyReceiptsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            "سجل الحركات السابقة (${vm.historyEntries.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    DailyReceiptsViewModel vm,
    List<String> weapons,
    List<String> levels,
    List<String> types,
  ) {
    if (vm.historyEntries.isEmpty) {
      return const Center(child: Text("لا توجد سجلات حالياً"));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vm.historyEntries.length,
      itemBuilder: (context, index) {
        final record = vm.historyEntries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: () {
              vm.selectForEdit(record);
              _showEntrySheet(context, vm, weapons, levels, types);
            },
            leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
            title: Text(
              "تاريخ: ${record['receipt_date']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () =>
                  _confirmDelete(context, vm, record['receipt_id']),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DailyReceiptsViewModel vm, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              vm.deleteProcess(id);
              Navigator.pop(ctx);
            },
            child: const Text("حذف"),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHeader(
    BuildContext context,
    String title,
    DailyReceiptsViewModel? vm,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    DailyReceiptsViewModel vm,
    StateSetter setSheetState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: Colors.blueAccent),
        title: const Text("التاريخ", style: TextStyle(fontSize: 10)),
        subtitle: Text(
          DateFormat('yyyy-MM-dd').format(vm.selectedDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          DateTime? p = await showDatePicker(
            context: context,
            initialDate: vm.selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (p != null) {
            vm.updateSelectedDate(p);
            setSheetState(() {});
          }
        },
      ),
    );
  }

  Widget _buildCurrentCounter(DailyReceiptsViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "إجمالي اليوم",
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Text(
            "${vm.currentEntryTotal}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyInputField(
    DailyReceiptsViewModel vm,
    String key,
    String type,
    StateSetter setSheetState,
    List<String> weapons, // أضفنا هذه
    List<String> levels, // أضفنا هذه
    List<String> types, // أضفنا هذه
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: SizedBox(
        width: 42,
        height: 32,
        child: TextField(
          controller: vm.receiptCtrls[key],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onChanged: (_) {
            // التغيير الجوهري هنا: استدعاء دالة الحساب الشاملة
            vm.calculateAll(weapons, levels, types);
            // ثم تحديث واجهة الـ Dialog
            setSheetState(() {});
          },
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: type[0],
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, DailyReceiptsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            bool s = await vm.saveProcess(context);
            if (s) Navigator.pop(context);
          },
          child: const Text(
            "حفظ السجل",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

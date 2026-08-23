import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/medical/medical_visits_viewmodel.dart';
import '../../viewmodels/functions/excel.dart';
import '../../viewmodels/functions/format_date.dart';
import 'medical_visit_dialog.dart';
import 'soldier_medical_details_page.dart';

class MedicalVisitsPage extends StatefulWidget {
  const MedicalVisitsPage({super.key});

  @override
  State<MedicalVisitsPage> createState() => _MedicalVisitsPageState();
}

class _MedicalVisitsPageState extends State<MedicalVisitsPage> {
  // ألوان الثيم العصري
  final Color primaryDark = const Color(0xFF1A237E);
  final Color accentColor = const Color(0xFF3949AB);
  final Color bgLight = const Color(0xFFF4F7FA);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MedicalVisitsViewModel>();

    final displayList = vm.getFilteredLatestVisits();

    return Scaffold(
      backgroundColor: bgLight,
      // زر الإضافة العائم بشكل عصري
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(vm),
        label: const Text(
          "إضافة عرض",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        backgroundColor: primaryDark,
        elevation: 4,
      ),
      body: CustomScrollView(
        slivers: [
          // رأس الصفحة بتصميم عصري
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(displayList.length, vm),
            ),
          ),

          // شريط البحث وأدوات التصدير
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                children: [
                  Expanded(child: _buildSearchBar(vm)),
                  const SizedBox(width: 12),
                  _buildExportButton(vm),
                ],
              ),
            ),
          ),

          // قائمة البيانات
          vm.loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : displayList.isEmpty
              ? SliverFillRemaining(
                  child: _buildEmptyState(vm.searchQuery.isNotEmpty),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildMedicalCard(context, vm, displayList[i]),
                      childCount: displayList.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // --- مكونات الواجهة ---

  Widget _buildHeader(int total, MedicalVisitsViewModel vm) {
    // حساب إحصائيات سريعة (مثال: عدد اللائقين اليوم)
    // يمكنك استبدال هذه الأرقام ببيانات حقيقية من الـ ViewModel
    int fitCount = vm.visits.where((v) => v['visit_result'] == "لائق").length;
    int unfitCount = vm.visits
        .where((v) => v['visit_result'] == "غير لائق")
        .length;

    return Stack(
      children: [
        // 1. الخلفية المتدرجة مع تأثير الحواف الناعمة
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark, accentColor.withBlue(250)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
        ),

        // 2. دوائر ديكورية (Glassmorphism Effect)
        Positioned(
          top: -30,
          right: -30,
          child: CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
        ),

        // 3. المحتوى الرئيسي المنظم
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // السطر الأول: العنوان والترحيب
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "المنظومة الطبية",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          "إحصائيات السجلات الحالية",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // السطر الثاني: بطاقات الإحصائيات (توزيع أفقي)
                Row(
                  children: [
                    // بطاقة الإجمالي
                    _buildStatCard(
                      "الإجمالي",
                      total.toString(),
                      Icons.people_alt,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    // بطاقة اللائقين
                    _buildStatCard(
                      "لائق",
                      fitCount.toString(),
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    // بطاقة غير اللائقين
                    _buildStatCard(
                      "غير لائق",
                      unfitCount.toString(),
                      Icons.error_outline,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ويدجت فرعي لبناء بطاقة الإحصائيات الصغيرة
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12), // تأثير الزجاج
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(MedicalVisitsViewModel vm) {
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
        onChanged: (value) => setState(() => vm.searchQuery = value),
        decoration: InputDecoration(
          hintText: "بحث بالاسم أو الرقم العسكري...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: accentColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildExportButton(MedicalVisitsViewModel vm) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: IconButton(
        icon: Icon(Icons.explicit_outlined, color: Colors.green.shade700),
        onPressed: () => _handleExport(vm),
        tooltip: "تصدير Excel",
      ),
    );
  }

  Widget _buildMedicalCard(
    BuildContext context,
    MedicalVisitsViewModel vm,
    Map<String, dynamic> v,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _navigateToDetails(context, v),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: accentColor.withOpacity(0.1),
                      child: Text(
                        v['soldiers_name'].toString()[0],
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v['soldiers_name'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "رقم عسكري: ${v['visit_soldiers_number']}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPopupMenu(context, vm, v),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                      Icons.calendar_today_rounded,
                      formatDate(v['visit_date'].toString())!,
                      Colors.blue,
                    ),
                    _buildResultBadge(v['visit_result'].toString()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildResultBadge(String result) {
    Color bgColor;
    Color textColor;

    // تحديد الألوان بناءً على النص
    switch (result) {
      case "لائق":
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case "غير لائق":
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case "منتظر عرض":
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        break;
      case "استلام نموذج":
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case "عرض جديد":
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      case "ملاحظات":
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        break;
      default:
        bgColor = Colors.blueGrey.shade50;
        textColor = Colors.blueGrey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // نقطة ملونة صغيرة تعطي مظهراً احترافياً
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            result,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo', // تأكد من استخدام خط مناسب إذا كان متوفراً
            ),
          ),
        ],
      ),
    );
  }

  // --- المنطق المساعد ---

  void _openAddDialog(MedicalVisitsViewModel vm) async {
    if (vm.batchId == null) return;
    await vm.loadData();
    if (!mounted) return;
    showDialog(context: context, builder: (_) => const MedicalVisitDialog());
  }

  void _navigateToDetails(BuildContext context, Map<String, dynamic> v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoldierMedicalDetailsPage(
          soldierNumber: v['visit_soldiers_number'].toString(),
          soldierName: v['soldiers_name'].toString(),
        ),
      ),
    );
  }

  Future<void> _handleExport(MedicalVisitsViewModel vm) async {
    final headersTexts = vm.visitColumns.map((col) {
      final w = col.label;
      if (w is Text) return w.data ?? '';
      return '';
    }).toList();

    final bytes = await compute(buildExcelBytes, {
      'data': vm.getFilteredLatestVisits(),
      'headersTexts': headersTexts,
      'headersKeys': vm.visitKeys,
    });

    final location = await getSaveLocation(
      suggestedName: "سجل_العروض.xlsx",
      acceptedTypeGroups: [
        const XTypeGroup(label: "Excel", extensions: ["xlsx"]),
      ],
    );

    if (location != null) {
      final file = File(
        location.path.endsWith(".xlsx")
            ? location.path
            : "${location.path}.xlsx",
      );
      await file.writeAsBytes(bytes);
      if (mounted) _showMessage(context, "تم تصدير الملف بنجاح");
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    MedicalVisitsViewModel vm,
    dynamic v,
  ) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_horiz, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text("تعديل"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text("حذف", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (val) async {
        if (val == 'edit') {
          showDialog(
            context: context,
            builder: (_) => MedicalVisitDialog(existing: v),
          );
        } else {
          bool? confirm = await _showDeleteConfirm(context);
          if (confirm == true) {
            await vm.deleteVisit(v['visit_id'] as int);
          }
        }
      },
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف السجل؟"),
        content: const Text("لا يمكن التراجع عن هذه الخطوة."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "حذف الآن",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.medical_services_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? "لم نجد أي نتائج" : "القائمة فارغة حالياً",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

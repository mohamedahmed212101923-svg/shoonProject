import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/medical/medical_visits_viewmodel.dart';
import '../../viewmodels/functions/format_date.dart';
import 'medical_visit_dialog.dart';

class SoldierMedicalDetailsPage extends StatelessWidget {
  final String soldierNumber;
  final String soldierName;

  const SoldierMedicalDetailsPage({
    super.key,
    required this.soldierNumber,
    required this.soldierName,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MedicalVisitsViewModel>();

    // تصفية السجلات وترتيبها
    final soldierVisits = vm.visits
        .where((v) => v['visit_soldiers_number'].toString() == soldierNumber)
        .toList();

    soldierVisits.sort(
      (a, b) =>
          b['visit_date'].toString().compareTo(a['visit_date'].toString()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("السجل الطبي التفصيلي"),
        backgroundColor: const Color(0xFF1E1E2F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddVisitDialog(context),
        backgroundColor: const Color(0xFF1E1E2F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "إضافة عرض جديد",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildSoldierHeader(),
          Expanded(
            child: soldierVisits.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                    itemCount: soldierVisits.length,
                    itemBuilder: (_, i) {
                      final v = soldierVisits[i];
                      return _buildTimelineItem(
                        context,
                        vm,
                        v,
                        i == soldierVisits.length - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openAddVisitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => MedicalVisitDialog(
        existing: {
          'visit_soldiers_number': soldierNumber,
          'soldiers_name': soldierName,
        },
      ),
    );
  }

  Widget _buildSoldierHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                soldierName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "رقم عسكري: $soldierNumber",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    MedicalVisitsViewModel vm,
    dynamic v,
    bool isLast,
  ) {
    final resultText = v['visit_result'].toString();
    final statusColor = _getResultColor(resultText);

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${v['visit_place']} - ${v['visit_type']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2D2D44),
                        ),
                      ),
                      _buildActionsMenu(context, vm, v),
                    ],
                  ),
                  Text(
                    formatDate(v['visit_date']) ?? '',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    Icons.assignment_turned_in_outlined,
                    "النتيجة",
                    resultText,
                    isBadge: true,
                  ),
                  if (v['visit_complaint']?.toString().isNotEmpty ?? false)
                    _buildDetailRow(
                      Icons.info_outline,
                      "الشكوى",
                      v['visit_complaint'].toString(),
                    ),
                  if (v['visit_diagnosis']?.toString().isNotEmpty ?? false)
                    _buildDetailRow(
                      Icons.medical_services_outlined,
                      "التشخيص",
                      v['visit_diagnosis'].toString(),
                    ),
                  if (v['visit_notes']?.toString().isNotEmpty ?? false)
                    _buildDetailRow(
                      Icons.notes,
                      "ملاحظات",
                      v['visit_notes'].toString(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(
    BuildContext context,
    MedicalVisitsViewModel vm,
    dynamic v,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.grey),
      onSelected: (value) async {
        if (value == 'edit') {
          showDialog(
            context: context,
            builder: (_) => MedicalVisitDialog(existing: v),
          );
        } else if (value == 'delete') {
          final confirm = await _showDeleteConfirm(context);
          if (confirm == true) vm.deleteVisit(v['visit_id'] as int);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text("تعديل"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text("حذف", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف سجل"),
        content: const Text("هل تريد حذف هذا العرض الطبي نهائياً؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    bool isBadge = false,
  }) {
    final statusColor = isBadge ? _getResultColor(value) : Colors.blueGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey.shade400),
          const SizedBox(width: 8),
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getResultColor(String result) {
    String r = result.trim();
    if (r == "لائق") {
      return Colors.green.shade700;
    } else if (r == "غير لائق") {
      return Colors.red.shade700;
    } else if (r == "منتظر عرض") {
      return Colors.amber.shade800;
    } else if (r == "استلام نموذج") {
      return Colors.blue.shade700;
    } else if (r == "عرض جديد") {
      return Colors.purple.shade700;
    } else if (r == "ملاحظات") {
      return Colors.grey.shade700;
    } else {
      return Colors.blueGrey.shade700;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 15),
          const Text(
            "لا توجد سجلات طبية مسجلة",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

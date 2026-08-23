import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/medical/medical_visits_viewmodel.dart';
import '../../viewmodels/functions/format_date.dart';

class MedicalVisitDialog extends StatefulWidget {
  final Map<String, Object?>? existing;
  const MedicalVisitDialog({super.key, this.existing});

  @override
  State<MedicalVisitDialog> createState() => _MedicalVisitDialogState();
}

class _MedicalVisitDialogState extends State<MedicalVisitDialog> {
  String? soldierNumber;
  String? place;
  String? type;
  String? result;
  DateTime visitDate = DateTime.now();

  final complaintController = TextEditingController();
  final diagnosisController = TextEditingController();
  final notesController = TextEditingController();

  // تطبيق الألوان التي أرسلتها أنت حرفياً
  Map<String, Color> _getBadgeColors(String? res) {
    switch (res) {
      case "لائق":
        return {'bg': Colors.green.shade50, 'text': Colors.green.shade700};
      case "غير لائق":
        return {'bg': Colors.red.shade50, 'text': Colors.red.shade700};
      case "منتظر عرض":
        return {'bg': Colors.amber.shade50, 'text': Colors.amber.shade800};
      case "استلام نموذج":
        return {'bg': Colors.blue.shade50, 'text': Colors.blue.shade700};
      case "عرض جديد":
        return {'bg': Colors.purple.shade50, 'text': Colors.purple.shade700};
      case "ملاحظات":
        return {'bg': Colors.grey.shade100, 'text': Colors.grey.shade700};
      default:
        return {
          'bg': Colors.blueGrey.shade50,
          'text': Colors.blueGrey.shade700,
        };
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      soldierNumber = e['visit_soldiers_number']?.toString();
      place = e['visit_place']?.toString();
      type = e['visit_type']?.toString();
      result = e['visit_result']?.toString();

      String rawDate = e['visit_date']?.toString() ?? '';
      visitDate = DateTime.tryParse(rawDate) ?? DateTime.now();

      complaintController.text = e['visit_complaint']?.toString() ?? '';
      diagnosisController.text = e['visit_diagnosis']?.toString() ?? '';
      notesController.text = e['visit_notes']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MedicalVisitsViewModel>();
    final soldierItems = vm.soldiers
        .map((s) => "${s['soldiers_number']} - ${s['soldiers_name']}")
        .toList();

    String? currentSoldierLabel;
    if (soldierNumber != null) {
      try {
        currentSoldierLabel = soldierItems.firstWhere(
          (e) => e.startsWith(soldierNumber!),
        );
      } catch (_) {}
    }

    // استخراج الألوان بناءً على النتيجة الحالية
    final currentColors = _getBadgeColors(result);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            widget.existing == null || !widget.existing!.containsKey('visit_id')
                ? Icons.add_circle_outline
                : Icons.edit_note_rounded,
            color: const Color(0xFF1A237E),
          ),
          const SizedBox(width: 10),
          Text(
            widget.existing == null || !widget.existing!.containsKey('visit_id')
                ? "إضافة عرض طبي"
                : "تعديل بيانات العرض",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchableDropdown(
                label: "بيانات العسكري",
                value: currentSoldierLabel,
                items: soldierItems,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => soldierNumber = v.split(" - ").first);
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SearchableDropdown(
                      label: "مكان العرض",
                      value: place,
                      items: const [
                        "مستشفى احمد جلال",
                        "مستشفى الحلمية",
                        "مستشفى كبرى القبة",
                        "مستشفى المعادى",
                        "المنطقة الطبية",
                      ],
                      onChanged: (v) => setState(() => place = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SearchableDropdown(
                      label: "نوع العرض",
                      value: type,
                      items: const ["كشف", "لجنة رفد", "إعادة كشف"],
                      onChanged: (v) => setState(() => type = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: currentColors['bg'], // الخلفية الفاتحة (shade50)
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentColors['text']!,
                          width: 1.5,
                        ), // الإطار بلون النص الغامق
                      ),
                      child: SearchableDropdown(
                        label: "النتيجة النهائية",
                        value: result,
                        items: const [
                          "لائق",
                          "غير لائق",
                          "منتظر عرض",
                          "استلام نموذج",
                          "عرض جديد",
                          "ملاحظات",
                        ],
                        onChanged: (v) {
                          setState(() => result = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: visitDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => visitDate = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "تاريخ العرض",
                          prefixIcon: const Icon(Icons.calendar_month_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          formatDate(visitDate.toIso8601String()) ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildTextField(
                complaintController,
                "الشكوى المرضية",
                Icons.history_edu,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                diagnosisController,
                "التشخيص الطبي",
                Icons.medical_information_outlined,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                notesController,
                "ملاحظات إضافية / توصيات",
                Icons.event_note,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: soldierNumber == null ? null : () => _handleSave(vm),
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text("حفظ السجل"),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Future<void> _handleSave(MedicalVisitsViewModel vm) async {
    final data = {
      'visit_soldiers_number': soldierNumber,
      'visit_batch_id': vm.batchId,
      'visit_date': visitDate.toIso8601String().split('T').first,
      'visit_place': place,
      'visit_type': type,
      'visit_result': result,
      'visit_complaint': complaintController.text,
      'visit_diagnosis': diagnosisController.text,
      'visit_notes': notesController.text,
    };

    String? errorMessage;
    if (widget.existing == null || !widget.existing!.containsKey('visit_id')) {
      errorMessage = await vm.addVisit(data);
    } else {
      errorMessage = await vm.editVisit(
        widget.existing!['visit_id'] as int,
        data,
      );
    }

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (mounted) {
      Navigator.pop(context);
    }
  }
}

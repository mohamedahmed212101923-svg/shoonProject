import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ajaza/ajaza_viewmodel.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';

class EditLeaveDialog extends StatefulWidget {
  final Map<String, dynamic> existing;

  const EditLeaveDialog({super.key, required this.existing});

  @override
  State<EditLeaveDialog> createState() => _EditLeaveDialogState();
}

class _EditLeaveDialogState extends State<EditLeaveDialog> {
  DateTime? startDate;
  DateTime? endDate;
  String? reason;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    startDate = _parseDate(widget.existing["leave_start"]);
    endDate = _parseDate(widget.existing["leave_end"]);
    reason = widget.existing["leave_reason"];
  }

  DateTime? _parseDate(String? d) {
    if (d == null || d.isEmpty) return null;
    try {
      return DateTime.parse(d.replaceAll('/', '-'));
    } catch (_) {
      return null;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "اختر التاريخ";
    return DateFormat('dd MMMM yyyy', 'ar').format(date);
  }

  Future<void> pickDate(bool isStart) async {
    if (!isStart && reason == "غياب") return;

    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale("ar"),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> onSave(AjazaViewModel vm) async {
    if (startDate == null || reason == null) return;
    if (reason != "غياب" && endDate == null) return;

    setState(() => _busy = true);
    try {
      // قمنا بحذف السطر الذي سبب الخطأ لأن الدالة في الـ ViewModel لا تطلبه
      await vm.updateLeave(
        context: context,
        id: widget.existing["soldiers_leaves_id"],
        newReason: reason!,
        newStart: startDate!,
        newEnd: reason == "غياب" ? "غياب" : endDate!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> onDelete(AjazaViewModel vm) async {
    setState(() => _busy = true);

    await vm.deleteLeave(context, widget.existing["soldiers_leaves_id"]);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AjazaViewModel>(context, listen: false);
    final bool isAbsence = reason == "غياب";

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Text(
          "تعديل الموقف",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      "الاسم الكامل",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      widget.existing["soldiers_name"] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel("نوع الموقف"),
              SearchableDropdown(
                label: "اختر النوع",
                value: reason,
                items: vm.ajazaTypes,
                onChanged: (val) {
                  setState(() {
                    reason = val;
                    if (val == "غياب") endDate = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("تاريخ البداية"),
                        _buildDateTile(
                          formatDate(startDate),
                          Icons.calendar_month,
                          () => pickDate(true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("تاريخ النهاية"),
                        _buildDateTile(
                          isAbsence ? "غير مطلوب" : formatDate(endDate),
                          isAbsence ? Icons.block : Icons.event_available,
                          () => pickDate(false),
                          isDisabled: isAbsence,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      actions: [
        // استخدام Row هنا هو الحل لمشكلة الـ ParentDataWidget في الـ Release
        Row(
          children: [
            TextButton.icon(
              onPressed: _busy ? null : () => onDelete(vm),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              label: const Text(
                "حذف",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _busy ? null : () => onSave(vm),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text("حفظ التغييرات"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildDateTile(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade200 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled ? Colors.grey.shade300 : Colors.blue.shade100,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDisabled ? Colors.grey : Colors.blueAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: isDisabled ? Colors.grey : Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

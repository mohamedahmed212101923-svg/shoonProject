import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:flutter_application_1/viewmodels/tarheel/tarhil_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EditTarhilDialog extends StatefulWidget {
  final Map<String, dynamic> existing;

  const EditTarhilDialog({super.key, required this.existing});

  @override
  State<EditTarhilDialog> createState() => _EditTarhilDialogState();
}

class _EditTarhilDialogState extends State<EditTarhilDialog> {
  DateTime? sendingDate;
  String? sendingArea;
  String? sendingFatherArea;
  bool isPostponed = false; // ✅ متغير مؤجل الترحيل
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    final rawDate = widget.existing["sending_date"];
    sendingDate = _parseNullableDate(rawDate);
    noteController = TextEditingController(
      text: widget.existing["sending_note"] ?? "",
    );
    sendingArea = _sanitizeString(widget.existing["sending_area"]);
    sendingFatherArea = _sanitizeString(widget.existing["sending_father_area"]);

    if (sendingDate == null) isPostponed = false;
    if (rawDate == "مؤجل ترحيل") isPostponed = true;
  }

  String? _sanitizeString(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    return value.toString();
  }

  DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s == "بدون") return null;
    if (value is DateTime) return value;

    final attemptedFormats = [
      'yyyy/MM/dd',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'd/M/yyyy',
      'dd/MM/yy',
      'd/M/yy',
      "yyyyMMdd",
    ];

    for (final fmt in attemptedFormats) {
      try {
        return DateFormat(fmt).parseStrict(s);
      } catch (_) {}
    }
    return DateTime.tryParse(s) ?? DateTime.tryParse(s.replaceAll('-', '/'));
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TarhilViewModel>(context, listen: false);
    final rawId = widget.existing["sending_id"] ?? widget.existing["id"];
    final String? sendingIdStr = rawId?.toString();

    return AlertDialog(
      title: Text(
        "تعديل ترحيل: ${widget.existing["soldiers_name"] ?? ''}",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // ✅ اختيار التاريخ أو مؤجل الترحيل
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      isPostponed
                          ? "مؤجل ترحيل"
                          : (sendingDate != null
                                ? vm.format(sendingDate!)
                                : "اختر تاريخ"),
                    ),
                    onPressed: () async {
                      if (isPostponed) return; // لو مؤجل، لا نفتح التاريخ
                      final d = await showDatePicker(
                        context: context,
                        initialDate: sendingDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => sendingDate = d);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // ✅ زر تبديل مؤجل الترحيل
                IconButton(
                  icon: Icon(
                    isPostponed ? Icons.access_time_filled : Icons.access_time,
                    color: isPostponed ? Colors.orange : Colors.grey,
                  ),
                  tooltip: "تبديل مؤجل الترحيل",
                  onPressed: () => setState(() {
                    isPostponed = !isPostponed;
                    if (isPostponed) sendingDate = null;
                  }),
                ),
                if (!isPostponed && sendingDate != null)
                  IconButton(
                    icon: const Icon(
                      Icons.date_range_outlined,
                      color: Colors.orange,
                    ),
                    tooltip: "إزالة التاريخ",
                    onPressed: () => setState(() => sendingDate = null),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            SearchableDropdown(
              label: "منطقة الترحيل",
              value: sendingArea,
              items: vm.areaItems.map((e) => e.value!).toList(),
              onChanged: (v) => setState(() => sendingArea = v),
            ),

            const SizedBox(height: 12),

            SearchableDropdown(
              label: "منطقة الأب",
              value: sendingFatherArea,
              items: vm.fatherAreaItems.map((e) => e.value!).toList(),
              onChanged: (v) => setState(() => sendingFatherArea = v),
            ),
            const Text(
              "ملاحظة:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            //i want to add enter button here when finish i click enter and it goes
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("حذف", style: TextStyle(color: Colors.red)),
          onPressed: () async {
            if (sendingIdStr == null) return;
            try {
              await vm.deleteSending(int.parse(sendingIdStr));
              if (mounted) Navigator.pop(context, true);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("فشل الحذف: $e")));
              }
            }
          },
        ),
        TextButton(
          child: const Text("إلغاء"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text("حفظ التعديل"), // add entr button here
          onPressed: () async {
            if (sendingIdStr == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("خطأ: ID غير موجود")),
              );
              return;
            }

            try {
              final data = <String, dynamic>{
                "sending_note": noteController.text.toString().trim(),
                "sending_date": isPostponed
                    ? 'مؤجل ترحيل'
                    : (sendingDate != null ? vm.format(sendingDate!) : null),
                "sending_area": sendingArea ?? "بدون",
                "sending_father_area": sendingFatherArea ?? "بدون",
              };

              await vm.updateSending(sendingIdStr, data);

              if (mounted) Navigator.pop(context, true);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("فشل الحفظ: $e")));
              }
            }
          },
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/menah/gift_view_model.dart';

class EditGiftDialog extends StatefulWidget {
  final Map<String, dynamic> existing;

  const EditGiftDialog({super.key, required this.existing});

  @override
  State<EditGiftDialog> createState() => _EditGiftDialogState();
}

class _EditGiftDialogState extends State<EditGiftDialog> {
  late String giftType;
  DateTime? selectedGiftDate;

  @override
  void initState() {
    super.initState();
    giftType = widget.existing["gift_type"]?.toString() ?? "";

    // التاريخ متخزن في عمود gift_date (gift_note للملاحظات).
    final existingDate = widget.existing["gift_date"]?.toString();
    if (existingDate != null && existingDate.contains("/")) {
      selectedGiftDate = _parseDate(existingDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<GiftViewModel>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text("تعديل: ${widget.existing["soldiers_name"]}"),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("اختر نوع المنحة الجديد من القائمة:"),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SearchableDropdown(
                label: "نوع المنحة",
                value: giftType,
                items: vm.giftTypes,
                onChanged: (val) {
                  if (val != null) setState(() => giftType = val);
                },
              ),
            ),

            const SizedBox(height: 15),
            // حقل التاريخ الجديد
            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedGiftDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() => selectedGiftDate = pickedDate);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedGiftDate == null
                            ? "اختر تاريخ المنحة"
                            : DateFormat(
                                "yyyy/MM/dd",
                              ).format(selectedGiftDate!),
                        style: TextStyle(
                          color: selectedGiftDate == null
                              ? Colors.white30
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirm = await _confirmAction(
              context,
              "حذف",
              "هل تريد حذف هذه المنحة نهائياً؟",
            );
            if (confirm == true) {
              await vm.deleteGift(widget.existing["gift_id"]);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text("حذف", style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () async {
            await vm.updateGift(
              widget.existing["gift_id"],
              giftType,
              date: selectedGiftDate == null
                  ? null
                  : DateFormat("yyyy/MM/dd").format(selectedGiftDate!),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text(
            "حفظ التعديل",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // الصفوف القديمة ممكن تكون متخزنة بصيغة dd/M/yyyy بدل yyyy/MM/dd.
  DateTime? _parseDate(String raw) {
    for (final pattern in const ["yyyy/MM/dd", "dd/M/yyyy", "dd/MM/yyyy"]) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<bool?> _confirmAction(
    BuildContext context,
    String title,
    String content,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("تراجع"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }
}

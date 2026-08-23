import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/mawqf/moqf_viewmodel.dart';

class EditMoqfDialog extends StatefulWidget {
  final Map<String, dynamic> existing;
  const EditMoqfDialog({super.key, required this.existing});

  @override
  State<EditMoqfDialog> createState() => _EditMoqfDialogState();
}

class _EditMoqfDialogState extends State<EditMoqfDialog> {
  late TextEditingController noteController;
  DateTime? date;
  String? type;
  bool _busy = false;

  String formatDate(DateTime? d) {
    if (d == null) return "غير محدد";
    return DateFormat('dd MMMM yyyy', 'ar').format(d);
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s.replaceAll('/', '-'));
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(
      text: widget.existing["moqf_note"] ?? "",
    );
    date = _parseDate(widget.existing["moqf_date"]);
    type = widget.existing["moqf_type"];
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> onSave(MoqfViewModel vm) async {
    if (date == null || type == null || type!.isEmpty) return;
    setState(() => _busy = true);

    await vm.updateMoqf(
      id: widget.existing["moqf_id"],
      newType: type!,
      newNote: noteController.text,
      newDate: date!,
    );

    if (mounted) Navigator.pop(context, true);
    setState(() => _busy = false);
  }

  Future<void> onDelete(MoqfViewModel vm) async {
    setState(() => _busy = true);
    await vm.deleteMoqf(widget.existing["moqf_id"]);
    if (mounted) Navigator.pop(context, true);
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MoqfViewModel>(context, listen: false);

    return AlertDialog(
      title: const Text(
        "تعديل الموقف",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing["soldiers_name"] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "تاريخ الموقف:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: pickDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(formatDate(date)),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "نوع الموقف:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SearchableDropdown(
                label: "نوع الموقف",
                value: type,
                items: vm.moqfTypes,
                onChanged: (v) {
                  setState(() {
                    type = v;
                  });
                },
              ),

              const SizedBox(height: 14),

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

              const SizedBox(height: 16),
              if (_busy) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => onDelete(vm),
          child: const Text("حذف", style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: _busy ? null : () => onSave(vm),
          child: const Text(
            "حفظ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text("إغلاق"),
        ),
      ],
    );
  }
}

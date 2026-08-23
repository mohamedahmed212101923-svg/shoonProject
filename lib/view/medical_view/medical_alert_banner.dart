import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/medical_view/soldier_medical_details_page.dart';
import '../../viewmodels/functions/format_date.dart';

class MedicalAlertDialog extends StatelessWidget {
  final List<Map<String, Object?>> alerts;
  const MedicalAlertDialog({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("تنبيهات العروض الطبية"),
      content: SizedBox(
        width: double.maxFinite,
        child: alerts.isEmpty
            ? const Text("لا توجد تنبيهات حالية")
            : ListView.separated(
                shrinkWrap: true,
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final v = alerts[i];
                  return ListTile(
                    leading: const Icon(
                      Icons.medical_services,
                      color: Colors.blue,
                    ),
                    title: Text(v['soldiers_name']?.toString() ?? ''),
                    subtitle: Text("📅 ${formatDate(v['visit_date']) ?? ''}"),
                    onTap: () {
                      Navigator.pop(context); // اغلاق الديالوج
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SoldierMedicalDetailsPage(
                            soldierNumber:
                                v['visit_soldiers_number']?.toString() ?? '',
                            soldierName: v['soldiers_name']?.toString() ?? '',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إغلاق"),
        ),
      ],
    );
  }
}

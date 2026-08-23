import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/leaders_view_model.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';

class LeadersPage extends StatelessWidget {
  const LeadersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeadersViewModel>();

    // استدعاء loadLeaders مرة واحدة بعد البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vmNonListen = Provider.of<LeadersViewModel>(context, listen: false);
      if (!vmNonListen.loading && vmNonListen.leaders.isEmpty) {
        vmNonListen.loadLeaders();
      }
    });

    return Scaffold(
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.leaders.isEmpty
          ? const Center(child: Text('لا يوجد بيانات للقادة'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: vm.leaders.keys.map((pos) {
                final leader = vm.leaders[pos]!;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.military_tech, size: 32),
                    title: Text(leader['name']),
                    subtitle: Text(
                      'الرتبة: ${leader['rank']}${leader['arkanHarb'] ? ' أركان حرب' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditDialog(context, vm, pos);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _showEditDialog(BuildContext context, LeadersViewModel vm, String pos) {
    final leader = vm.leaders[pos]!;

    final nameCtrl = TextEditingController(text: leader['name']);
    String selectedRank = leader['rank'];
    bool arkanHarb = leader['arkanHarb'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                pos == 'first' ? 'تعديل قائد أول' : 'تعديل قائد تاني',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// الرتبة
                    SearchableDropdown(
                      label: 'الرتبة',
                      value: selectedRank,
                      items: vm.officerRanks,
                      onChanged: (value) {
                        setState(() {
                          selectedRank = value!;
                        });
                      },
                      maxHeight: 300,
                    ),

                    const SizedBox(height: 8),

                    /// أركان حرب
                    Row(
                      children: [
                        Checkbox(
                          value: arkanHarb,
                          onChanged: (value) {
                            setState(() {
                              arkanHarb = value!;
                            });
                          },
                        ),
                        const Text('أركان حرب'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    vm.saveLeader(
                      pos: pos,
                      name: nameCtrl.text,
                      rank: selectedRank,
                      arkanHarb: arkanHarb,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ القائد بنجاح')),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/widgets/Multi_select_popup.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:provider/provider.dart';
import '../viewmodels/units_view_model.dart';

class UnitsView extends StatefulWidget {
  const UnitsView({super.key});

  @override
  State<UnitsView> createState() => _UnitsViewState();
}

class _UnitsViewState extends State<UnitsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String tabaeiaSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UnitsViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'التبعيات'),
            Tab(icon: Icon(Icons.corporate_fare), text: 'الوحدات'),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabaeiaSection(context, vm),
                _buildUnitsSection(context, vm),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleAdding(context, vm),
        label: const Text('إضافة جديد'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // قسم التبعيات
  Widget _buildTabaeiaSection(BuildContext context, UnitsViewModel vm) {
    final items = vm.tabaeia
        .where((t) => t['tabaeia_name'].toString().contains(tabaeiaSearch))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => tabaeiaSearch = v),
            decoration: InputDecoration(
              hintText: 'بحث في التبعيات...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'عدد التبعيات: ${items.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(items[index]['tabaeia_name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () =>
                          _showEditTabaeia(context, items[index], vm),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          vm.deleteTabaeia(items[index]['tabaeia_id']),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // قسم الوحدات المطور
  Widget _buildUnitsSection(BuildContext context, UnitsViewModel vm) {
    final filteredUnits = vm.units
        .where(
          (u) =>
              (vm.selectedFilterTabaeiaIds.isEmpty ||
                  vm.selectedFilterTabaeiaIds.contains(
                    u['units_tabaeia_id'],
                  )) &&
              u['units_name'].toString().contains(vm.unitsSearch),
        )
        .toList();

    return Column(
      children: [
        // 1. الجزء العلوي: تعديل تبعية مجموعة
        Card(
          margin: const EdgeInsets.all(12),
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text(
                  "تغيير تبعية الوحدات المختارة",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MultiSelectPopup(
                        label: "الوحدات (${vm.selectedUnitIds.length})",
                        options: vm.units
                            .map((u) => u['units_name'] as String)
                            .toList(),
                        selectedValues: vm.selectedUnitNames,
                        onToggle: (item) => vm.toggleUnitSelection(item),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdown(
                        label: "التبعية الجديدة",
                        value: vm.selectedUnitTabaeiaName,
                        items: vm.tabaeia
                            .map((t) => t['tabaeia_name'] as String)
                            .toList(),
                        onChanged: (name) => vm.setTopSelectedTabaeia(name!),
                      ),
                    ),
                  ],
                ),
                if (vm.selectedUnitIds.isNotEmpty)
                  ElevatedButton(
                    onPressed: vm.selectedUnitTabaeiaId == null
                        ? null
                        : () => vm.updateSelectedUnitsTabaeia(
                            vm.selectedUnitTabaeiaId!,
                          ),
                    child: const Text("تطبيق التغيير"),
                  ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2, // لتحديد نسبة العرض للفلتر
                child: MultiSelectPopup(
                  label: "فلترة حسب التبعية",
                  options: vm.tabaeia
                      .map((t) => t['tabaeia_name'] as String)
                      .toList(),
                  selectedValues: vm.selectedFilterTabaeiaNames,
                  onToggle: (item) => vm.toggleFilterTabaeia(item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1, // نسبة أصغر لشريط البحث
                child: TextField(
                  onChanged: (v) => setState(() => vm.unitsSearch = v),
                  decoration: InputDecoration(
                    hintText: 'بحث في الوحدات...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.layers_clear, color: Colors.redAccent),
                onPressed: () => vm.resetFilter(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'عدد الوحدات: ${filteredUnits.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
          ),
        ),
        // 3. الجزء السفلي: قائمة الوحدات
        Expanded(
          child: ListView.builder(
            itemCount: filteredUnits.length,
            itemBuilder: (context, index) {
              final u = filteredUnits[index];
              final tName = vm.tabaeia.firstWhere(
                (t) => t['tabaeia_id'] == u['units_tabaeia_id'],
                orElse: () => {'tabaeia_name': 'غير محدد'},
              )['tabaeia_name'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(u['units_name']),
                  subtitle: Text("التبعية الحالية: $tName"),
                  trailing: Row(
                    mainAxisSize:
                        MainAxisSize.min, // لضمان أن الصف يأخذ أقل مساحة ممكنة
                    children: [
                      // زر التعديل (القلم) - يفتح نافذة تعديل الاسم والتبعية
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.orange,
                          size: 30,
                        ),
                        onPressed: () => _handleEditUnitDialog(context, u, vm),
                      ),
                      // زر الحذف - يحذف فوراً باستخدام دالتك
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 26,
                        ),
                        onPressed: () => vm.deleteUnit(
                          u['units_id'],
                        ), // استدعاء دالة الحذف مباشرة
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- دالة تعديل "الاسم + التبعية" معاً من أيقونة القلم ---
  Future<void> _handleEditUnitDialog(
    BuildContext context,
    Map<String, dynamic> unit,
    UnitsViewModel vm,
  ) async {
    final nameController = TextEditingController(text: unit['units_name']);
    int? tempTabaeiaId = unit['units_tabaeia_id'];
    String tempTabaeiaName = vm.tabaeia.firstWhere(
      (t) => t['tabaeia_id'] == tempTabaeiaId,
      orElse: () => {'tabaeia_name': 'اختر'},
    )['tabaeia_name'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الوحدة والتبعية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "اسم الوحدة الجديد",
                ),
              ),
              const SizedBox(height: 20),
              SearchableDropdown(
                label: "تعديل التبعية",
                value: tempTabaeiaName,
                items: vm.tabaeia
                    .map((t) => t['tabaeia_name'] as String)
                    .toList(),
                onChanged: (name) {
                  final t = vm.tabaeia.firstWhere(
                    (t) => t['tabaeia_name'] == name,
                  );
                  tempTabaeiaId = t['tabaeia_id'];
                  tempTabaeiaName = name!;
                  setDialogState(
                    () {},
                  ); // تحديث الدروب داون داخل الدايلوج فوراً
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () {
                vm.updateUnitFull(
                  unit['units_id'],
                  nameController.text,
                  tempTabaeiaId!,
                );
                Navigator.pop(ctx);
              },
              child: const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }

  // الدوال المساعدة الأخرى (Add Tabaeia, Unit)
  void _showEditTabaeia(
    BuildContext context,
    Map<String, dynamic> item,
    UnitsViewModel vm,
  ) async {
    final res = await _showStyledDialog(
      context,
      "تعديل التبعية",
      item['tabaeia_name'],
    );
    if (res != null) vm.updateTabaeia(item['tabaeia_id'], res);
  }

  void _handleAdding(BuildContext context, UnitsViewModel vm) async {
    if (_tabController.index == 0) {
      final res = await _showStyledDialog(context, "إضافة تبعية");
      if (res != null) vm.addTabaeia(res);
    } else {
      _showAddUnitDialog(context, vm);
    }
  }

  // إضافة وحدة جديدة
  void _showAddUnitDialog(BuildContext context, UnitsViewModel vm) {
    String name = "";
    int? tId;
    String? selectedTabaeiaName; // متغير لتخزين الاسم المختار للعرض

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // نستخدم StatefulBuilder لتحديث الواجهة داخل الدايلوج
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("إضافة وحدة جديدة"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (v) => name = v,
                decoration: const InputDecoration(hintText: "اسم الوحدة"),
              ),
              const SizedBox(height: 20),

              // استخدام الـ SearchableDropdown الجديد هنا
              SearchableDropdown(
                label: "اختر التبعية",
                value: selectedTabaeiaName, // القيمة النصية المعروضة حالياً
                items: vm.tabaeia
                    .map((t) => t['tabaeia_name'] as String)
                    .toList(),
                onChanged: (name) {
                  // البحث عن الـ ID المقابل للاسم المختار
                  final selectedTabaeia = vm.tabaeia.firstWhere(
                    (t) => t['tabaeia_name'] == name,
                  );

                  // تحديث الحالة داخل الدايلوج
                  setDialogState(() {
                    tId = selectedTabaeia['tabaeia_id'];
                    selectedTabaeiaName = name;
                  });
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty && tId != null) {
                  vm.addUnit(tId!, name);
                  Navigator.pop(ctx);
                }
              },
              child: const Text("إضافة"),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showStyledDialog(
    BuildContext context,
    String title, [
    String init = "",
  ]) async {
    final c = TextEditingController(text: init);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text("تم"),
          ),
        ],
      ),
    );
  }
}

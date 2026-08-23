import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/database/db_helper.dart';
import 'package:flutter_application_1/view/medical_view/medical_alert_banner.dart';
import 'package:flutter_application_1/view/widgets/searchabl_dropdown%20.dart';
import 'package:flutter_application_1/viewmodels/ajaza/ajaza_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/backup_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/cards/card_view_model.dart';
import 'package:flutter_application_1/viewmodels/presentations_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/receiving/daily_receipts_view_model.dart';
import 'package:flutter_application_1/viewmodels/new_batches/get_batch_name.dart';
import 'package:flutter_application_1/viewmodels/menah/gift_view_model.dart';
import 'package:flutter_application_1/viewmodels/home_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/paper_of_soldiers/jawabat_view_model.dart';
import 'package:flutter_application_1/viewmodels/medical/medical_visits_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/mawqf/moqf_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/mawqf/solider_moqf_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/tarheel/tarhil_view_model.dart';
import 'package:flutter_application_1/viewmodels/taskin_view_model.dart';
import 'package:flutter_application_1/viewmodels/marriage/wife_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isSidebarOpen = true;
  bool _backupDialogShown = false; // الآن سنستخدمه فعلياً
  late BackupViewModel _backupVm;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // خزّن نسخة من الـ VM للوصول الآمن في dispose
    _backupVm = context.read<BackupViewModel>();
  }

  @override
  void initState() {
    super.initState();

    // استخدم addPostFrameCallback بدل microtask
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _backupVm.checkBackupOnStartup();
      _backupVm.addListener(_onBackupStateChanged);

      if (_backupVm.backupRequired && AppMode.isServer) {
        _handleInitialBackup();
      }
    });
  }

  void _onBackupStateChanged() {
    if (_backupVm.backupRequired && AppMode.isServer && !_backupDialogShown) {
      if (!mounted) return;
      _handleInitialBackup();
    }
  }

  @override
  void dispose() {
    // استخدم المتغير المخزن بدل context.read()
    _backupVm.removeListener(_onBackupStateChanged);
    super.dispose();
  }

  Future<void> _handleInitialBackup() async {
    _backupDialogShown = true;

    if (!mounted) return;

    if (_backupVm.backupPath == null || _backupVm.backupPath!.isEmpty) {
      _showBackupDialog(context, _backupVm);
    } else {
      await _backupVm.performBackup();

      if (!mounted) return;

      if (!_backupVm.backupRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التحقق من النسخة الاحتياطية بنجاح')),
        );
      } else {
        _showBackupDialog(context, _backupVm);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeViewmodel, BackupViewModel>(
      builder: (context, homeVm, backupVm, child) {
        return Scaffold(
          body: Row(
            children: [
              _buildSidebar(homeVm),
              Expanded(
                child: Column(
                  children: [
                    _buildCustomHeader(homeVm),

                    // --- شريط التنبيه الذكي ---
                    if (backupVm.backupRequired && AppMode.isServer)
                      Container(
                        width: double.infinity,
                        color: Colors.orange.shade100,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "⚠️ تنبيه: لم يتم التأكد من وجود نسخة احتياطية لليوم، أو أن مسار الحفظ غير متاح حالياً.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // زر يفتح الـ FilePicker فوراً لاختيار مسار جديد أو تأكيد الحالي
                            ElevatedButton.icon(
                              onPressed: () => backupVm.performBackup(),
                              icon: const Icon(Icons.backup, size: 18),
                              label: const Text("حفظ نسخة الآن"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: Container(
                        color: const Color(0xFFF5F7FA),
                        child: homeVm.pages[homeVm.selectedIndex],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // دالة الدايلوج تبقى كما هي لضمان وجود خيار يدوي للمستخدم
  void _showBackupDialog(BuildContext context, BackupViewModel vm) {
    _backupDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نسخ احتياطي مطلوب'),
        content: const Text(
          'يجب إنشاء نسخة احتياطية للبيانات قبل استخدام البرنامج.\nسيتم فتح مستعرض الملفات لاختيار المجلد.',
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('اختيار مسار المجلد'),
            onPressed: () async {
              String? path = await FilePicker.platform.getDirectoryPath(
                initialDirectory: vm.backupPath,
              );
              if (path != null) {
                await vm.setBackupPath(path);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تعيين المسار: $path')),
                  );
                }
              }
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.backup),
            label: vm.isProcessing
                ? const Text('جارٍ النسخ...')
                : const Text('تنفيذ النسخ الاحتياطي'),
            onPressed: vm.isProcessing
                ? null
                : () async {
                    try {
                      await vm.performBackup();
                      if (!vm.backupRequired && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ النسخة الاحتياطية بنجاح'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء النسخ: $e')),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(HomeViewmodel vm) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment:
            CrossAxisAlignment.center, // لضمان المحاذاة الرأسية سنتر
        children: [
          _buildNotificationIcon(), // أيقونة الإشعارات

          const SizedBox(width: 12),

          Consumer<BackupViewModel>(
            builder: (context, backupVm, child) {
              return SizedBox(
                height: 40, // تحديد ارتفاع ثابت متناسق مع حجم الـ IconButton
                child: ElevatedButton.icon(
                  icon: backupVm.isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          backupVm.backupRequired
                              ? Icons.priority_high_rounded
                              : Icons.backup_rounded,
                          size: 25,
                        ),
                  label: Text(
                    backupVm.isProcessing ? 'جارٍ...' : 'نسخ احتياطي',
                    style: const TextStyle(
                      fontSize: 15, // تصغير الخط ليناسب حجم الهيدر
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                        elevation:
                            0, // إلغاء الظل ليتماشى مع بساطة الهيدر الأبيض
                        backgroundColor: backupVm.backupRequired
                            ? Colors.redAccent.withOpacity(0.9)
                            : const Color(
                                0xFFF0F4F8,
                              ), // لون هادئ لو الحالة مستقرة
                        foregroundColor: backupVm.backupRequired
                            ? Colors.white
                            : Colors.blueAccent, // النص أزرق لو الحالة مستقرة
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // حواف أنعم وأصغر
                          side: BorderSide(
                            color: backupVm.backupRequired
                                ? Colors.transparent
                                : Colors.blueAccent.withOpacity(0.2),
                          ),
                        ),
                      ).copyWith(
                        mouseCursor: WidgetStateProperty.all(
                          SystemMouseCursors.click,
                        ),
                      ),
                  onPressed: backupVm.isProcessing
                      ? null
                      : () async {
                          // نفس الكود البرمجي السابق بدون تغيير
                          await backupVm.performBackup();
                        },
                ),
              );
            },
          ),
          const SizedBox(width: 10),

          Tooltip(
            message: "إعادة تشغيل البرنامج (Ctrl + R)",
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 22),
                label: const Text(
                  "إعادة تشغيل",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _confirmRestart(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRestart(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("إعادة تشغيل البرنامج"),
        content: const Text(
          "هل أنت متأكد أنك تريد إعادة تشغيل البرنامج؟\n"
          "تأكد من حفظ أي بيانات قبل المتابعة.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              RestartWidget.restartApp(context);
              SqlDb().checkpoint();
            },
            child: const Text("إعادة تشغيل"),
          ),
        ],
      ),
    );
  }

  // ================== أيقونة الإشعارات ==================
  Widget _buildNotificationIcon() {
    return Consumer<MedicalVisitsViewModel>(
      builder: (context, medicalVm, child) {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));

        bool isSameDay(DateTime a, DateTime b) =>
            a.year == b.year && a.month == b.month && a.day == b.day;

        final alerts = medicalVm.visits.where((v) {
          final dateStr = v['visit_date']?.toString();
          if (dateStr == null) return false;
          final visitDate = DateTime.tryParse(dateStr);
          if (visitDate == null) return false;
          return isSameDay(visitDate, now) || isSameDay(visitDate, tomorrow);
        }).toList();

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                size: 35,
                color: Color(0xFF5A5A75),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => MedicalAlertDialog(alerts: alerts),
                );
              },
            ),
            if (alerts.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    alerts.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ================== Sidebar ==================
  Widget _buildSidebar(HomeViewmodel vm) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isSidebarOpen ? 240 : 70,
      color: const Color.fromARGB(255, 30, 30, 47),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildStatusBadge(),
          const SizedBox(height: 15),
          IconButton(
            onPressed: () => setState(() => isSidebarOpen = !isSidebarOpen),
            icon: Icon(
              isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (isSidebarOpen) ...[
            const SizedBox(height: 10),
            const Text(
              'منظومة شئون الطلبة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildBatchDropdown(vm),
          ],
          const SizedBox(height: 20),
          Expanded(child: _buildMenuItems(vm)),
        ],
      ),
    );
  }

  Widget _buildBatchDropdown(HomeViewmodel vm) {
    // 1. تحويل قائمة الخرائط إلى قائمة نصوص (أسماء الدفعات فقط) للعرض
    final List<String> batchNames = vm.batches.map((b) {
      final rawName = b['batch_name']?.toString() ?? '';
      return getBatchDetails(rawName)['full'] ?? rawName;
    }).toList();

    // 2. تحديد النص الحالي المختار
    String? currentSelectedName;
    if (vm.selectedBatch != null) {
      final rawName = vm.selectedBatch!['batch_name']?.toString() ?? '';
      currentSelectedName = getBatchDetails(rawName)['full'] ?? rawName;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SearchableDropdown(
        width: 220, // عرض أصغر ليناسب الـ Sidebar
        height: 55, // ارتفاع نحيف
        maxHeight: 250,
        isDark: true, // ستقوم الودجت بتعديل ألوانها فوراً لتناسب الشريط الجانبي
        label: "الدفعة",
        value: currentSelectedName,
        items: batchNames,
        onChanged: (String? selectedName) {
          if (selectedName != null) {
            // 3. البحث عن الكائن الأصلي (Map) باستخدام الاسم المختار
            final selectedMap = vm.batches.firstWhere((b) {
              final rawName = b['batch_name']?.toString() ?? '';
              final full = getBatchDetails(rawName)['full'] ?? rawName;
              return full == selectedName;
            });

            // 4. تحديث الـ ViewModel والـ UI
            vm.selectBatch(selectedMap);
            _updateAllViewModels(context, selectedMap['batch_id'].toString());
          }
        },
      ),
    );
  }

  Widget _buildMenuItems(HomeViewmodel vm) {
    return ListView.builder(
      itemCount: vm.menuItems.length,

      itemBuilder: (context, index) {
        final item = vm.menuItems[index];
        final isSelected = vm.selectedIndex == index;
        return Tooltip(
          message: (vm.menuItems.map((e) => e["title"]).toList())[index]
              .toString(),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSidebarOpen ? 20 : 23,
            ),
            leading: Icon(
              item['icon'] as IconData,
              color: isSelected ? Colors.amber : Colors.white70,
              size: 22,
            ),
            title: isSidebarOpen
                ? Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  )
                : null,
            selected: isSelected,
            onTap: () => vm.selectIndex(index),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    if (!isSidebarOpen) {
      return Tooltip(
        message: AppMode.isServer ? "وضع السيرفر" : "وضع الكلينت",
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppMode.isServer ? Colors.greenAccent : Colors.blueAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (AppMode.isServer ? Colors.green : Colors.blue)
                    .withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: (AppMode.isServer ? Colors.green : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (AppMode.isServer ? Colors.greenAccent : Colors.blueAccent)
              .withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppMode.isServer ? Icons.dns : Icons.cloud_sync,
            size: 16,
            color: AppMode.isServer ? Colors.greenAccent : Colors.blueAccent,
          ),
          const SizedBox(width: 10),
          Text(
            AppMode.isServer ? "SERVER MODE" : "CLIENT MODE",
            style: TextStyle(
              color: AppMode.isServer ? Colors.greenAccent : Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  void _updateAllViewModels(BuildContext context, dynamic batchId) {
    final String? batchIdStr = batchId?.toString();
    context.read<TaskinViewModel>().updateBatch(batchIdStr);
    context.read<JawabatViewModel>().updateBatch(batchIdStr);
    context.read<AjazaViewModel>().updateBatch(batchIdStr);
    context.read<TarhilViewModel>().updateBatch(batchIdStr);
    context.read<SoliderMoqfViewmodel>().updateBatch(batchIdStr);
    context.read<MoqfViewModel>().updateBatch(batchIdStr);
    context.read<CardsViewModel>().updateBatch(batchIdStr);
    context.read<GiftViewModel>().updateBatch(batchIdStr!);
    context.read<MedicalVisitsViewModel>().updateBatch(batchIdStr);
    context.read<DailyReceiptsViewModel>().updateBatch(batchIdStr);
    context.read<WifeViewModel>().updateBatch(batchIdStr);
    context.read<PresentationViewModel>().updateBatch(batchIdStr);
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_mode.dart';
import 'package:flutter_application_1/server/local_server.dart';
import 'package:flutter_application_1/services/backup_service.dart';
import 'package:flutter_application_1/services/database/ajaza_repo.dart';
import 'package:flutter_application_1/services/database/batch_repository.dart';
import 'package:flutter_application_1/services/database/batches_plan_repository.dart';
import 'package:flutter_application_1/services/database/gift_repository.dart';
import 'package:flutter_application_1/services/database/leaders_repository.dart';
import 'package:flutter_application_1/services/database/medical_visits_repository.dart';
import 'package:flutter_application_1/services/database/presentations_repo.dart';
import 'package:flutter_application_1/services/database/wife_repo.dart';
import 'package:flutter_application_1/view/home_view.dart';
import 'package:flutter_application_1/viewmodels/ajaza/ajaza_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/backup_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/new_batches/batch_view_model.dart';
import 'package:flutter_application_1/viewmodels/cards/card_view_model.dart';
import 'package:flutter_application_1/viewmodels/presentations_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/receiving/daily_receipts_view_model.dart';
import 'package:flutter_application_1/viewmodels/menah/gift_view_model.dart';
import 'package:flutter_application_1/viewmodels/paper_of_soldiers/jawabat_view_model.dart';
import 'package:flutter_application_1/viewmodels/leaders_view_model.dart';
import 'package:flutter_application_1/viewmodels/medical/medical_visits_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/mawqf/moqf_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/mawqf/solider_moqf_viewmodel.dart';
import 'package:flutter_application_1/viewmodels/tarheel/tarhil_view_model.dart';
import 'package:flutter_application_1/viewmodels/units_view_model.dart';
import 'package:flutter_application_1/viewmodels/marriage/wife_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/taskin_view_model.dart';
import 'services/database/soldiers_repository.dart';
import 'services/database/db_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppMode.init();

  // فحص الوحدانية (هل أنا السيرفر الوحيد؟)
  if (AppMode.isServer) {
    try {
      // محاولة تشغيل السيرفر (الدالة الآن داخلها منطق قفل الملف)
      bool started = await LocalServer.start(port: 8080, lockFileName: "main");

      if (!started) {
        // إذا فشل القفل، اجعل هذه النسخة عميل (Client)
        AppMode.isServer = false;
        if (kDebugMode) {
          print("⚠️ تم اكتشاف سيرفر آخر، تحويل النسخة الحالية إلى (عميل).");
        }
      } else {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        if (kDebugMode) {
          print("✅ تم حجز القفل بنجاح: هذه النسخة هي السيرفر الأساسي.");
        }
      }
    } catch (e) {
      AppMode.isServer = false;
    }
  }

  // إعدادات النافذة بناءً على الحالة النهائية
  await windowManager.ensureInitialized();

  // ضبط العنوان ليميز المستخدم نوع النسخة
  String windowTitle = AppMode.isServer
      ? "منظومة شئون الطلبة (السيرفر الرئيسي)"
      : "منظومة شئون الطلبة (نسخة عميل)";

  WindowOptions windowOptions = WindowOptions(
    title: windowTitle,
    size: const Size(1280, 800),
    center: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // تهيئة قاعدة البيانات والمستودعات
  final sqlDb = SqlDb();
  final repository = SoldiersRepository(sqlDb);
  final batchRepo = BatchesRepository(sqlDb);
  final planRepo = BatchPlanRepository(sqlDb);
  final leadersRepo = LeadersRepository(sqlDb);
  final giftRepository = GiftRepository(sqlDb);
  final ajazaRepository = AjazaRepository(sqlDb);
  final presentationRepo = PresentationRepository(sqlDb);

  runApp(
    RestartWidget(
      child: MyApp(
        sqlDb: sqlDb,
        repository: repository,
        batchRepo: batchRepo,
        planRepo: planRepo,
        leadersRepo: leadersRepo,
        giftRepository: giftRepository,
        ajazaRepository: ajazaRepository,
        presentationRepo: presentationRepo,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SqlDb sqlDb;
  final SoldiersRepository repository;
  final BatchesRepository batchRepo;
  final BatchPlanRepository planRepo;
  final LeadersRepository leadersRepo;
  final GiftRepository giftRepository;
  final AjazaRepository ajazaRepository;
  final PresentationRepository presentationRepo;

  const MyApp({
    super.key,
    required this.sqlDb,
    required this.repository,
    required this.batchRepo,
    required this.planRepo,
    required this.leadersRepo,
    required this.giftRepository,
    required this.ajazaRepository,
    required this.presentationRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BackupViewModel(BackupService())),
        ChangeNotifierProvider(create: (_) => LeadersViewModel(leadersRepo)),

        ChangeNotifierProvider(
          create: (_) => BatchesPageViewModel(batchRepo, planRepo),
        ),

        ChangeNotifierProvider(create: (_) => HomeViewmodel(repo: repository)),

        // ================== TASKIN ==================
        ChangeNotifierProxyProvider<HomeViewmodel, TaskinViewModel>(
          create: (_) => TaskinViewModel(repository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),
        // ... داخل مصفوفة providers في MyApp
        ChangeNotifierProxyProvider<HomeViewmodel, DailyReceiptsViewModel>(
          // استخدم batchRepo مباشرة لأنها موجودة داخل الكلاس
          create: (context) => DailyReceiptsViewModel(batchRepo),
          update: (context, homeVm, dailyVm) {
            final selectedId = homeVm.selectedBatch?['batch_id']?.toString();

            if (dailyVm!.batchId.toString() != selectedId) {
              dailyVm.updateBatch(selectedId);
            }
            return dailyVm;
          },
        ),
        // ================== JAWABAT ==================
        ChangeNotifierProxyProvider<HomeViewmodel, JawabatViewModel>(
          create: (_) => JawabatViewModel(repository, leadersRepo),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        ChangeNotifierProxyProvider<HomeViewmodel, AjazaViewModel>(
          create: (_) => AjazaViewModel(ajazaRepository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),
        ChangeNotifierProxyProvider<HomeViewmodel, WifeViewModel>(
          create: (_) => WifeViewModel(repository: WifeRepository(SqlDb())),
          update: (_, homeVm, wifeVm) {
            // الحصول على معرف الدفعة من الـ HomeViewModel
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();

            // إذا تغيرت الدفعة، نقوم بتحديث الـ ViewModel الخاص بالزوجات
            if (wifeVm != null && wifeVm.batchId != batchId) {
              Future.delayed(Duration.zero, () => wifeVm.updateBatch(batchId));
            }
            return wifeVm!;
          },
        ),

        ChangeNotifierProxyProvider<HomeViewmodel, GiftViewModel>(
          create: (_) => GiftViewModel(giftRepository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();

            if (vm != null && vm.batchId != batchId) {
              // استخدام Future.delayed لمنع خطأ "build during build"
              Future.delayed(Duration.zero, () => vm.updateBatch(batchId));
            }
            return vm!;
          },
        ),

        ChangeNotifierProxyProvider<HomeViewmodel, MedicalVisitsViewModel>(
          create: (_) => MedicalVisitsViewModel(MedicalVisitsRepository(sqlDb)),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        ChangeNotifierProvider(create: (_) => UnitsViewModel(repository)),

        ChangeNotifierProxyProvider<HomeViewmodel, MoqfViewModel>(
          create: (_) => MoqfViewModel(repository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        ChangeNotifierProxyProvider<HomeViewmodel, SoliderMoqfViewmodel>(
          create: (_) => SoliderMoqfViewmodel(repository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        ChangeNotifierProxyProvider<HomeViewmodel, TarhilViewModel>(
          create: (_) => TarhilViewModel(repository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        ChangeNotifierProxyProvider<HomeViewmodel, CardsViewModel>(
          create: (_) => CardsViewModel(repository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        ChangeNotifierProxyProvider<HomeViewmodel, CardsViewModel>(
          create: (_) => CardsViewModel(repository),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        /*======================Presentation=================================*/
        ChangeNotifierProxyProvider<HomeViewmodel, PresentationViewModel>(
          create: (_) => PresentationViewModel(repo: presentationRepo),
          update: (_, homeVm, vm) {
            final batchId = homeVm.selectedBatch?['batch_id']?.toString();
            if (vm!.batchId != batchId) {
              vm.updateBatch(batchId);
            }
            return vm;
          },
        ),

        /*********************************************************************/
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "منظومة شئون الطلبة",

        // إعدادات اللغة العربية
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: const Locale('ar'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // --- بداية التصميم العصري ---
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: "Cairo", // استخدام خط Cairo كخط أساسي
          // ألوان التطبيق
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1), // لون أزرق وقور
            primary: const Color(0xFF0D47A1),
            secondary: const Color(0xFF1976D2),
            surface: Colors.white,
          ),

          // تنسيق النصوص لضمان وضوح الأرقام 123
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
            titleLarge: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: Colors.black87,
            ),
            bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),

          // تنسيق الحقول النصية (TextField) بشكل انسيابي
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.blueGrey.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.blueGrey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.blueGrey.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
            ),
            labelStyle: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w500,
            ),
          ),

          // تنسيق الأزرار (ElevatedButton)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              minimumSize: const Size(150, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // تنسيق البطاقات (Cards)
        ),

        // --- نهاية التصميم ---
        home: const HomeView(),
      ),
    );
  }
}

class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: key, child: widget.child);
  }
}

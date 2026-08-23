import 'package:flutter_application_1/models/city.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'dart:async';

// ----------------------------------------------------------------------
// 1. ضبط عرض الأعمدة تلقائياً (منسق لتجاهل العنوان المدمج)
// ----------------------------------------------------------------------
void autoFitColumnsManually(
  xlsio.Worksheet sheet,
  int rowsCount,
  int colsCount, {
  double scaleFactor = 1.15,
}) {
  for (int c = 1; c <= colsCount; c++) {
    int maxLen = 0;

    // نبدأ الفحص من الصف 2 لضمان عدم التأثر بالعنوان الرئيسي المدمج في الصف 1
    int startRow = 2;

    for (int r = startRow; r <= rowsCount; r++) {
      final text = sheet.getRangeByIndex(r, c).displayText;
      if (text.length > maxLen) maxLen = text.length;
    }

    sheet.getRangeByIndex(startRow, c).columnWidth = (maxLen * scaleFactor)
        .clamp(8, 70)
        .toDouble();
  }
}

// ----------------------------------------------------------------------
// 2. ضبط ارتفاع الصفوف بقيم ثابتة (لحل مشكلة التنسيق العشوائي)
// ----------------------------------------------------------------------
void setFixedRowsHeight(xlsio.Worksheet sheet, int totalRows, bool hasTitle) {
  if (hasTitle) {
    // الصف الأول: العنوان الرئيسي الكبير
    sheet.getRangeByIndex(1, 1).rowHeight = 40.0;
    // الصف الثاني: رؤوس الأعمدة (Headers)
    sheet.getRangeByIndex(2, 1).rowHeight = 30.0;
    // من الصف الثالث فصاعداً: قيم البيانات (ارتفاع ثابت)
    if (totalRows >= 3) {
      sheet.getRangeByIndex(3, 1, totalRows, 1).rowHeight = 22.0;
    }
  } else {
    // في حالة عدم وجود عنوان (مثل دالة buildExcelBytes البسيطة)
    sheet.getRangeByIndex(1, 1).rowHeight = 30.0;
    if (totalRows >= 2) {
      sheet.getRangeByIndex(2, 1, totalRows, 1).rowHeight = 22.0;
    }
  }
}

// ----------------------------------------------------------------------
// 3. تجميع البيانات حسب المنطقة أو الوحدة (المنطق الخاص بك)
// ----------------------------------------------------------------------
Map<String, List<Map<String, dynamic>>> _groupDataBySendingFatherOrUnit(
  List<Map<String, dynamic>> data,
) {
  final groupedData = <String, List<Map<String, dynamic>>>{};

  const fatherAreaKey = 'sending_father_area';
  const unitAreaKey = 'sending_area';

  for (final row in data) {
    final fatherArea = row[fatherAreaKey]?.toString().trim() ?? '';
    final unitArea = row[unitAreaKey]?.toString().trim() ?? 'الوحدة غير محددة';

    String sheetKey = fatherArea.isNotEmpty ? fatherArea : 'الوحدة - $unitArea';
    sheetKey = sheetKey.replaceAll(RegExp(r'[\\/?*\[\]:;]'), '_');

    groupedData.putIfAbsent(sheetKey, () => []);
    groupedData[sheetKey]!.add(row);
  }

  return groupedData;
}

// ----------------------------------------------------------------------
// 4. إنشاء وتنسيق الشيت (setupSheet)
// ----------------------------------------------------------------------
void setupSheet(
  xlsio.Worksheet sheet,
  List<Map<String, dynamic>> sheetData,
  List<String> headersTexts,
  List<String> headersKeys,
  String sheetTitle,
) {
  sheet.isRightToLeft = true;
  final workbook = sheet.workbook;

  // تنسيق العنوان (Title)
  final titleStyle =
      workbook.styles.add(
          'TitleStyle-${DateTime.now().microsecondsSinceEpoch}-${sheet.name}',
        )
        ..backColor = '#FFFFFF'
        ..fontColor = '#000000'
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..fontSize = 15
        ..bold = true;

  // تنسيق الـ header (الأزرق)
  final headerStyle =
      workbook.styles.add(
          'HeaderStyle-${DateTime.now().microsecondsSinceEpoch}-${sheet.name}',
        )
        ..bold = true
        ..fontColor = '#FFFFFF'
        ..backColor = '#4472C4'
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..fontSize = 13
        ..borders.all.lineStyle = xlsio.LineStyle.thin;

  // تنسيق البيانات (Data)
  final dataStyle =
      workbook.styles.add(
          'DataStyle-${DateTime.now().microsecondsSinceEpoch}-${sheet.name}',
        )
        ..hAlign = xlsio.HAlignType.center
        ..vAlign = xlsio.VAlignType.center
        ..fontSize = 11
        ..borders.all.lineStyle = xlsio.LineStyle.thin;

  int currentRow = 1;

  // ======== العنوان الرئيسي ========
  if (sheetTitle.isNotEmpty) {
    sheet.getRangeByIndex(currentRow, 1)
      ..setText(sheetTitle)
      ..cellStyle = titleStyle;
    sheet
        .getRangeByIndex(currentRow, 1, currentRow, headersTexts.length + 1)
        .merge();
    currentRow++;
  }

  // ======== الهيدر ========
  sheet.getRangeByIndex(currentRow, 1)
    ..setText('م')
    ..cellStyle = headerStyle;
  for (int i = 0; i < headersTexts.length; i++) {
    sheet.getRangeByIndex(currentRow, i + 2)
      ..setText(headersTexts[i])
      ..cellStyle = headerStyle;
  }
  currentRow++;

  // ======== البيانات ========
  for (int r = 0; r < sheetData.length; r++) {
    sheet.getRangeByIndex(currentRow + r, 1)
      ..setNumber(r + 1)
      ..cellStyle = dataStyle;
    for (int c = 0; c < headersKeys.length; c++) {
      sheet.getRangeByIndex(currentRow + r, c + 2)
        ..setText(sheetData[r][headersKeys[c]]?.toString() ?? '')
        ..cellStyle = dataStyle;
    }
  }

  int totalRows = currentRow + sheetData.length - 1;
  int totalCols = headersTexts.length + 1;

  // الضبط التلقائي للعرض والارتفاع الثابت
  autoFitColumnsManually(sheet, totalRows, totalCols);
  setFixedRowsHeight(sheet, totalRows, sheetTitle.isNotEmpty);

  // إعدادات الطباعة
  sheet.pageSetup
    ..leftMargin = 0.5
    ..rightMargin = 0.5
    ..topMargin = 0.5
    ..bottomMargin = 0.5
    ..fitToPagesWide = 1;
}

// ----------------------------------------------------------------------
// 5. دوال الترتيب والأولوية (المنطق الخاص بك)
// ----------------------------------------------------------------------
String normalize(String text) {
  return text
      .trim()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه');
}

int _getPriority(String key) {
  final n = normalize(key);
  if (n.contains("قياده الجيش الثان")) return 1;
  if (n.contains("قياده الجيش الثالث")) return 2;
  if (n.contains("قياده")) return 3;
  if (n.startsWith("اداره")) return 4;
  if (n.contains("لواء")) return 5;
  if (n == "بدون" || n.isEmpty) return 99;
  return 50;
}

// ----------------------------------------------------------------------
// 6. بناء ملف الإكسيل المجمع (buildGroupedExcelBytes)
// ----------------------------------------------------------------------
Future<List<int>> buildGroupedExcelBytes(Map<String, dynamic> params) async {
  final data = params['data'] as List<Map<String, dynamic>>;
  final headersTexts = params['headersTexts'] as List<String>;
  final headersKeys = params['headersKeys'] as List<String>;

  final workbook = xlsio.Workbook();
  final groupedData = _groupDataBySendingFatherOrUnit(data);

  final sortedEntries = groupedData.entries.toList()
    ..sort((a, b) {
      int pA = _getPriority(a.key);
      int pB = _getPriority(b.key);
      return (pA == pB) ? a.key.compareTo(b.key) : pA.compareTo(pB);
    });

  // شيت جميع الترحيلات
  setupSheet(
    workbook.worksheets[0]..name = 'جميع الترحيلات',
    data,
    headersTexts,
    headersKeys,
    'كشف بأسماء الأفراد الموزعين على قوة / جميع الترحيلات',
  );

  // شيتات المجموعات
  for (final entry in sortedEntries) {
    String sheetName = entry.key.replaceAll(RegExp(r'[\\/*?:\[\]]'), '').trim();
    if (sheetName.length > 31) sheetName = sheetName.substring(0, 31);
    if (sheetName.isEmpty) sheetName = "غير محدد";

    final sheet = workbook.worksheets.addWithName(sheetName);
    setupSheet(
      sheet,
      entry.value,
      headersTexts,
      headersKeys,
      'كشف بأسماء الأفراد الموزعين على قوة / ${entry.key}',
    );
  }

  final bytes = workbook.saveAsStream();
  workbook.dispose();
  return bytes;
}

// ----------------------------------------------------------------------
// 7. بناء ملف إكسيل بسيط (buildExcelBytes)
// ----------------------------------------------------------------------
Future<List<int>> buildExcelBytes(Map<String, dynamic> params) async {
  final data = params['data'] as List<Map<String, dynamic>>;
  final headersTexts = params['headersTexts'] as List<String>;
  final headersKeys = params['headersKeys'] as List<String>;

  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.isRightToLeft = true;

  setupSheet(
    sheet,
    data,
    headersTexts,
    headersKeys,
    "",
  ); // بدون عنوان رئيسي علوي

  final bytes = workbook.saveAsStream();
  workbook.dispose();
  return bytes;
}

/// الدالة الرئيسية لبناء ملف إكسيل إجازات المستجدين المجمع

/// دالة مساعدة لترتيب البيانات جغرافياً (إقليم ثم محافظة)
void _sortSoldiersGeographically(
  List<Map<String, dynamic>> soldiers,
  Map<String, List<String>> regionsMap,
) {
  soldiers.sort((a, b) {
    String cityA = (a['soldiers_city'] ?? '').toString().trim();
    String cityB = (b['soldiers_city'] ?? '').toString().trim();

    int getRegionPriority(String city) {
      if (regionsMap['upper']!.contains(city)) return 1; // صعيد
      if (regionsMap['lower']!.contains(city)) return 2; // بحري
      if (regionsMap['cairo']!.contains(city)) return 3; // قاهرة
      return 4; // غير ذلك
    }

    int priorityA = getRegionPriority(cityA);
    int priorityB = getRegionPriority(cityB);

    if (priorityA != priorityB) {
      return priorityA.compareTo(priorityB); // ترتيب الأقاليم أولاً
    } else {
      return cityA.compareTo(cityB); // ثم ترتيب المحافظات أبجدياً داخل الإقليم
    }
  });
}

/// الدالة الرئيسية لبناء ملف إكسيل إجازات المستجدين المجمع
Future<List<int>> buildRecruitmentLeavesExcel(
  Map<String, dynamic> params,
) async {
  final List<Map<String, dynamic>> allData = List.from(
    params['data'],
  ); // نسخة قابلة للتعديل
  final List<String> headersTexts = params['headersTexts'];
  final List<String> headersKeys = params['headersKeys'];

  final workbook = xlsio.Workbook();

  // 1. ترتيب الإجمالي العام جغرافياً قبل العرض
  _sortSoldiersGeographically(allData, regionsMap);

  setupSheet(
    workbook.worksheets[0]..name = 'إجمالي عام المستجدين',
    allData,
    headersTexts,
    headersKeys,
    'كشف إجمالي إجازات المستجدين - القوة الكاملة (مرتبة جغرافياً)',
  );

  // 2. تقسيم البيانات حسب الكتيبة (soldiers_k)
  final groupedByUnit = <String, List<Map<String, dynamic>>>{};
  for (var row in allData) {
    String unit = row['soldiers_k']?.toString().trim() ?? 'غير محدد';
    groupedByUnit.putIfAbsent(unit, () => []).add(row);
  }

  List<String> sortedUnits = groupedByUnit.keys.toList()..sort();

  for (var unitName in sortedUnits) {
    final unitList = groupedByUnit[unitName]!;

    // ترتيب إجمالي الكتيبة جغرافياً أيضاً
    _sortSoldiersGeographically(unitList, regionsMap);

    // أ- شيت إجمالي الكتيبة
    final summarySheet = workbook.worksheets.addWithName('إجمالي $unitName');
    setupSheet(
      summarySheet,
      unitList,
      headersTexts,
      headersKeys,
      'إجمالي إجازات مستجدين / كتيبة: $unitName (مرتب جغرافياً)',
    );

    // ب- تقسيم الكتيبة حسب تواريخ النزول
    final dailyGroups = <String, List<Map<String, dynamic>>>{};
    for (var row in unitList) {
      String startDate = row['leave_start']?.toString() ?? 'بدون تاريخ';
      dailyGroups.putIfAbsent(startDate, () => []).add(row);
    }

    List<String> sortedDates = dailyGroups.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      String date = sortedDates[i];
      var soldiersInDay = dailyGroups[date]!;

      // ج- ترتيب يوم النزول جغرافياً (تم ترتيبه مسبقاً في خطوة إجمالي الكتيبة ولكن للتأكيد)
      _sortSoldiersGeographically(soldiersInDay, regionsMap);

      String sheetName = 'نزول ${i + 1} $unitName';
      if (sheetName.length > 31) sheetName = sheetName.substring(0, 31);

      final daySheet = workbook.worksheets.addWithName(sheetName);
      setupSheet(
        daySheet,
        soldiersInDay,
        headersTexts,
        headersKeys,
        'كشف نزول اليوم ${i + 1} لكتيبة $unitName بتاريخ $date',
      );
    }
  }

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();
  return bytes;
}

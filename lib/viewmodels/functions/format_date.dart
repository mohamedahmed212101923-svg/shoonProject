import 'package:intl/intl.dart';

String? formatDate(dynamic value) {
  if (value == null) return null;
  DateTime? date;
  try {
    if (value is DateTime) {
      date = value;
    } else {
      String dateString = value.toString().trim();
      if (dateString.isEmpty) return null;
      if (dateString.contains('T')) {
        dateString = dateString.split('T').first;
      }
      dateString = dateString.replaceAll('-', '/');
      List<String> formats = [
        'dd/MM/yyyy',
        'd/M/yyyy',
        'dd/MM/yy',
        'd/M/yy',
        'yyyy/MM/dd',
      ];
      for (var format in formats) {
        try {
          date = DateFormat(format).parseStrict(dateString);
          break;
        } catch (_) {}
      }
      date ??= DateTime.tryParse(dateString);
    }
  } catch (_) {
    date = null;
  }
  if (date == null) return null;
  return '${date.year.toString().padLeft(4, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';
}

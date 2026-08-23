Map<String, String> getBatchDetails(String batchId) {
  if (batchId.length < 5) {
    return {'year': batchId, 'month': '', 'order': '', 'full': batchId};
  }

  String year = batchId.substring(0, 4);
  String lastDigit = batchId.substring(batchId.length - 1);

  String month = "";
  String order = "";

  switch (lastDigit) {
    case "1":
      month = "يناير";
      order = "الأولى";
      break;
    case "2":
      month = "إبريل";
      order = "الثانية";
      break;
    case "3":
      month = "يوليو";
      order = "الثالثة";
      break;
    case "4":
      month = "أكتوبر";
      order = "الرابعة";
      break;
    default:
      month = "أكتوبر";
      order = "الرابعة";
  }

  return {
    'year': year,
    'month': month,
    'order': order,
    // هذا هو السطر الذي سيظهر في القائمة
    'full': "الدفعة $order $month $year",
  };
}

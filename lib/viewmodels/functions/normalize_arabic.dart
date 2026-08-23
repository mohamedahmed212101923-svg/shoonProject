String normalizeArabic(String input) {
  if (input.isEmpty) return "";

  return input
      // 1. توحيد الألفات (أهم خطوة)
      .replaceAll(RegExp(r'[إأآا]'), 'ا')
      // 2. توحيد الياء والألف المقصورة والهمزة على الياء
      .replaceAll(RegExp(r'[ىئِي]'), 'ي')
      // 3. توحيد التاء المربوطة والهاء
      .replaceAll(RegExp(r'[ةه]'), 'ه')
      // 4. توحيد الواو والهمزة على الواو
      .replaceAll(RegExp(r'[ؤو]'), 'و')
      // 5. حذف التشكيل (الفتحة والضمة والكسرة...) لأنه يفسد البحث تماماً
      .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
      // 6. الهمزة المفردة يفضل بقاؤها أو تحويلها لشكل موحد وليس حذفها
      .replaceAll('ء', 'ء')
      .trim()
      .toLowerCase();
}

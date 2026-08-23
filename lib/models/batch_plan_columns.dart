const Map<String, String> levelMap = {
  "عليا": "high",
  "فوق متوسط": "above_mid",
  "عادة": "normal",
  "متوسط صف": "mid_skill",
  "متوسط مهنى": "mid_prof",
};

const Map<String, String> managementMap = {
  "مهندسين": "eng",
  "مياه": "water",
  "مساحة": "survey",
  "أشغال": "works",
};

const Map<String, String> typeMap = {
  "صف": "base",
  "جوية": "ground",
  "بحرية": "naval",
};
String getDbKey(String level, String weapon, String type) {
  final l = levelMap[level] ?? "unknown";
  final w = managementMap[weapon] ?? "unknown";
  final t = typeMap[type] ?? "unknown";
  return "${l}_${w}_$t";
}

const List<String> batchPlanColumns = [
  // ================= HIGH =================
  'high_eng_base', 'high_eng_ground', 'high_eng_naval',
  'high_water_base', 'high_water_ground', 'high_water_naval',
  'high_survey_base', 'high_survey_ground', 'high_survey_naval',
  'high_works_base', 'high_works_ground', 'high_works_naval',

  // ================= ABOVE MID =================
  'above_mid_eng_base', 'above_mid_eng_ground', 'above_mid_eng_naval',
  'above_mid_water_base', 'above_mid_water_ground', 'above_mid_water_naval',
  'above_mid_survey_base', 'above_mid_survey_ground', 'above_mid_survey_naval',
  'above_mid_works_base', 'above_mid_works_ground', 'above_mid_works_naval',

  // ================= NORMAL =================
  'normal_eng_base', 'normal_eng_ground', 'normal_eng_naval',
  'normal_water_base', 'normal_water_ground', 'normal_water_naval',
  'normal_survey_base', 'normal_survey_ground', 'normal_survey_naval',
  'normal_works_base', 'normal_works_ground', 'normal_works_naval',

  // ================= MID / PROFESSIONAL =================
  'mid_prof_eng_base', 'mid_prof_eng_ground', 'mid_prof_eng_naval',
  'mid_prof_water_base', 'mid_prof_water_ground', 'mid_prof_water_naval',
  'mid_prof_survey_base', 'mid_prof_survey_ground', 'mid_prof_survey_naval',
  'mid_prof_works_base', 'mid_prof_works_ground', 'mid_prof_works_naval',

  // ================= MID / SKILLED =================
  'mid_skill_eng_base', 'mid_skill_eng_ground', 'mid_skill_eng_naval',
  'mid_skill_water_base', 'mid_skill_water_ground', 'mid_skill_water_naval',
  'mid_skill_survey_base', 'mid_skill_survey_ground', 'mid_skill_survey_naval',
  'mid_skill_works_base', 'mid_skill_works_ground', 'mid_skill_works_naval',
];

const Map<String, String> batchPlanColumnsArabic = {
  // ================= HIGH =================
  'high_eng_base': 'عاليا مهندسين صف',
  'high_eng_ground': 'عاليا مهندسين جوية',
  'high_eng_naval': 'عاليا مهندسين بحرية',
  'high_water_base': 'عاليا مياة صف',
  'high_water_ground': 'عاليا مياة جوية',
  'high_water_naval': 'عاليا مياة بحرية',
  'high_survey_base': 'عاليا مساحة صف',
  'high_survey_ground': 'عاليا مساحة جوية',
  'high_survey_naval': 'عاليا مساحة بحرية',
  'high_works_base': 'عاليا الأشغال صف',
  'high_works_ground': 'عاليا الأشغال جوية',
  'high_works_naval': 'عاليا الأشغال بحرية',

  // ================= ABOVE MID =================
  'above_mid_eng_base': 'فوق المتوسط مهندسين صف',
  'above_mid_eng_ground': 'فوق المتوسط مهندسين جوية',
  'above_mid_eng_naval': 'فوق المتوسط مهندسين بحرية',
  'above_mid_water_base': 'فوق المتوسط مياة صف',
  'above_mid_water_ground': 'فوق المتوسط مياة جوية',
  'above_mid_water_naval': 'فوق المتوسط مياة بحرية',
  'above_mid_survey_base': 'فوق المتوسط مساحة صف',
  'above_mid_survey_ground': 'فوق المتوسط مساحة جوية',
  'above_mid_survey_naval': 'فوق المتوسط مساحة بحرية',
  'above_mid_works_base': 'فوق المتوسط الأشغال صف',
  'above_mid_works_ground': 'فوق المتوسط الأشغال جوية',
  'above_mid_works_naval': 'فوق المتوسط الأشغال بحرية',

  // ================= NORMAL =================
  'normal_eng_base': 'عادي مهندسين صف',
  'normal_eng_ground': 'عادي مهندسين جوية',
  'normal_eng_naval': 'عادي مهندسين بحرية',
  'normal_water_base': 'عادي مياة صف',
  'normal_water_ground': 'عادي مياة جوية',
  'normal_water_naval': 'عادي مياة بحرية',
  'normal_survey_base': 'عادي مساحة صف',
  'normal_survey_ground': 'عادي مساحة جوية',
  'normal_survey_naval': 'عادي مساحة بحرية',
  'normal_works_base': 'عادي الأشغال صف',
  'normal_works_ground': 'عادي الأشغال جوية',
  'normal_works_naval': 'عادي الأشغال بحرية',

  // ================= MID / PROFESSIONAL =================
  'mid_prof_eng_base': 'متوسط/مهنى مهندسين صف',
  'mid_prof_eng_ground': 'متوسط/مهنى مهندسين جوية',
  'mid_prof_eng_naval': 'متوسط/مهنى مهندسين بحرية',
  'mid_prof_water_base': 'متوسط/مهنى مياة صف',
  'mid_prof_water_ground': 'متوسط/مهنى مياة جوية',
  'mid_prof_water_naval': 'متوسط/مهنى مياة بحرية',
  'mid_prof_survey_base': 'متوسط/مهنى مساحة صف',
  'mid_prof_survey_ground': 'متوسط/مهنى مساحة جوية',
  'mid_prof_survey_naval': 'متوسط/مهنى مساحة بحرية',
  'mid_prof_works_base': 'متوسط/مهنى الأشغال صف',
  'mid_prof_works_ground': 'متوسط/مهنى الأشغال جوية',
  'mid_prof_works_naval': 'متوسط/مهنى الأشغال بحرية',

  // ================= MID / SKILLED =================
  'mid_skill_eng_base': 'متوسط/حرفى مهندسين صف',
  'mid_skill_eng_ground': 'متوسط/حرفى مهندسين جوية',
  'mid_skill_eng_naval': 'متوسط/حرفى مهندسين بحرية',
  'mid_skill_water_base': 'متوسط/حرفى مياة صف',
  'mid_skill_water_ground': 'متوسط/حرفى مياة جوية',
  'mid_skill_water_naval': 'متوسط/حرفى مياة بحرية',
  'mid_skill_survey_base': 'متوسط/حرفى مساحة صف',
  'mid_skill_survey_ground': 'متوسط/حرفى مساحة جوية',
  'mid_skill_survey_naval': 'متوسط/حرفى مساحة بحرية',
  'mid_skill_works_base': 'متوسط/حرفى الأشغال صف',
  'mid_skill_works_ground': 'متوسط/حرفى الأشغال جوية',
  'mid_skill_works_naval': 'متوسط/حرفى الأشغال بحرية',
};

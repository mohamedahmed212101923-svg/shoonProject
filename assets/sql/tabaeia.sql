/*
 Navicat Premium Dump SQL

 Source Server         : flutte_1
 Source Server Type    : SQLite
 Source Server Version : 3045000 (3.45.0)
 Source Schema         : main

 Target Server Type    : SQLite
 Target Server Version : 3045000 (3.45.0)
 File Encoding         : 65001

 Date: 18/01/2026 13:56:11
*/

PRAGMA foreign_keys = false;

-- ----------------------------
-- Table structure for tabaeia
-- ----------------------------
DROP TABLE IF EXISTS "tabaeia";
CREATE TABLE "tabaeia" (
  "tabaeia_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "tabaeia_name" TEXT NOT NULL,
  UNIQUE ("tabaeia_name" ASC)
);

-- ----------------------------
-- Records of tabaeia
-- ----------------------------
INSERT INTO "tabaeia" VALUES (1, 'ادارة الاشغال العسكرية');
INSERT INTO "tabaeia" VALUES (3, 'ادارة المخابرات الحربية والاستطلاع');
INSERT INTO "tabaeia" VALUES (4, 'ادارة المساحة العسكرية');
INSERT INTO "tabaeia" VALUES (5, ' اداره المشاة');
INSERT INTO "tabaeia" VALUES (6, ' اداره الموسيقات العسكريه ');
INSERT INTO "tabaeia" VALUES (7, ' اداره شئون الضباط');
INSERT INTO "tabaeia" VALUES (8, 'الهيئة الهندسية للقوات المسلحة');
INSERT INTO "tabaeia" VALUES (9, ' جهاز العمل النفسى');
INSERT INTO "tabaeia" VALUES (10, ' جهاز مستقبل مصر للتنمية المستدامة');
INSERT INTO "tabaeia" VALUES (11, 'رئاسة جهاز مشروعات الخدمة الوطنية');
INSERT INTO "tabaeia" VALUES (12, 'قيادة قوات الدفاع الجوى');
INSERT INTO "tabaeia" VALUES (13, ' قيادة الجيش الثالث الميداني');
INSERT INTO "tabaeia" VALUES (14, 'قياده المنطقه الجنوبيه');
INSERT INTO "tabaeia" VALUES (16, 'قيادة قوات الحرس جمهورى');
INSERT INTO "tabaeia" VALUES (17, ' هيئة الإمداد والتموين');
INSERT INTO "tabaeia" VALUES (19, ' هيئة القضاء العسكري');
INSERT INTO "tabaeia" VALUES (20, ' هيئه الشئون الماليه');
INSERT INTO "tabaeia" VALUES (21, ' هيئه تسليح القوات المسلحة');
INSERT INTO "tabaeia" VALUES (22, 'إدارة التراخيص والتفتيش والمتابعة');
INSERT INTO "tabaeia" VALUES (23, 'ادارة المدفعية');
INSERT INTO "tabaeia" VALUES (24, 'إدارة النظم والمعلومات ق م');
INSERT INTO "tabaeia" VALUES (25, 'ادارة التجنيد');
INSERT INTO "tabaeia" VALUES (26, 'ادارة التدريب والتعليم المهنى');
INSERT INTO "tabaeia" VALUES (27, 'ادارة الحرب الكترونيه');
INSERT INTO "tabaeia" VALUES (28, 'ادارة الحرب الكيماوية');
INSERT INTO "tabaeia" VALUES (29, 'ادارة الشرطه العسكريه');
INSERT INTO "tabaeia" VALUES (30, 'ادارة المدرعات');
INSERT INTO "tabaeia" VALUES (32, 'ادارة المشروعات الكبرى');
INSERT INTO "tabaeia" VALUES (33, 'ادارة المهمات');
INSERT INTO "tabaeia" VALUES (34, 'ادارة النوادى');
INSERT INTO "tabaeia" VALUES (35, 'ادارة الوقود');
INSERT INTO "tabaeia" VALUES (36, 'اداره التأمين والمعاشات القوات المسلحة');
INSERT INTO "tabaeia" VALUES (37, 'ادارة الخدمات البيطرية');
INSERT INTO "tabaeia" VALUES (38, 'اداره المتاحف العسكريه');
INSERT INTO "tabaeia" VALUES (41, 'ادارة المهندسين العسكريين');
INSERT INTO "tabaeia" VALUES (42, 'الفوج 17 مياه');
INSERT INTO "tabaeia" VALUES (43, 'ادارة النقل');
INSERT INTO "tabaeia" VALUES (44, 'ادارة الأسلحة والذخيرة');
INSERT INTO "tabaeia" VALUES (47, 'ادارة الاشارة');
INSERT INTO "tabaeia" VALUES (50, 'الاكاديمية العسكرية المصرية');
INSERT INTO "tabaeia" VALUES (53, 'السجن العمومي للقوات المسلحة');
INSERT INTO "tabaeia" VALUES (54, 'الشركة الوطنية لإستصلاح وزراعة الأراضي الصحراوية');
INSERT INTO "tabaeia" VALUES (55, 'الشركه الوطنيه لانشاء وتنميه و ادارة الطرق');
INSERT INTO "tabaeia" VALUES (56, 'الشركه الوطنيه للمقاولات العامه');
INSERT INTO "tabaeia" VALUES (68, 'اللواء 23 إنشاءات ');
INSERT INTO "tabaeia" VALUES (69, 'اللواء151 انشاءات اشغال');
INSERT INTO "tabaeia" VALUES (70, 'اللواء152 انشاءات اشغال');
INSERT INTO "tabaeia" VALUES (78, 'المستودع الرئيسي لذخيرة المهندسين العسكريين');
INSERT INTO "tabaeia" VALUES (79, 'المستودع الرئيسي لمعدات المهندسين العسكريين');
INSERT INTO "tabaeia" VALUES (80, 'المعهد الصحي للتمريض إناث بأحمد جلال');
INSERT INTO "tabaeia" VALUES (82, 'المنطقة المركزية');
INSERT INTO "tabaeia" VALUES (92, 'جهاز الاستطلاع');
INSERT INTO "tabaeia" VALUES (93, 'جهاز الرياضة للقوات المسلحة');
INSERT INTO "tabaeia" VALUES (94, 'جهاز مشروعات اراضي القوات المسلحة');
INSERT INTO "tabaeia" VALUES (104, 'دار المهندسين العسكريين');
INSERT INTO "tabaeia" VALUES (105, 'رئاسة اداره المساحه العسكرية');
INSERT INTO "tabaeia" VALUES (133, 'شئون معنوية');
INSERT INTO "tabaeia" VALUES (137, 'صندوق التامين الخاص للقوات المسلحة');
INSERT INTO "tabaeia" VALUES (140, 'فوج 8 إنشاءات أشغال');
INSERT INTO "tabaeia" VALUES (142, 'قطاع أمن مركزي جنوب سيناء / قيادة قوات أمن مركزي المنطقة (ج)');
INSERT INTO "tabaeia" VALUES (143, 'قطاع أمن مركزي شمال سيناء / قيادة قوات أمن مركزي المنطقة (ج)');
INSERT INTO "tabaeia" VALUES (144, 'قطاع أمن مركزي وسط سيناء / قيادة قوات أمن مركزي المنطقة (ج)');
INSERT INTO "tabaeia" VALUES (152, 'قيادة قوات المظلات');
INSERT INTO "tabaeia" VALUES (153, 'قيادة الجيش الثانى الميدانى');
INSERT INTO "tabaeia" VALUES (155, 'قيادة القوات البحرية');
INSERT INTO "tabaeia" VALUES (156, 'قيادة القوات الجوية');
INSERT INTO "tabaeia" VALUES (157, 'اللواء 123 كباري');
INSERT INTO "tabaeia" VALUES (158, 'اللواء 150 إنشاءات أشغال');
INSERT INTO "tabaeia" VALUES (159, 'اللواء 19 طرق');
INSERT INTO "tabaeia" VALUES (160, 'اللواء 22 إنشاءات م ع');
INSERT INTO "tabaeia" VALUES (161, 'اللواء 309 إزالة قنابل');
INSERT INTO "tabaeia" VALUES (162, 'اللواء 9 مهندسين عسكريين');
INSERT INTO "tabaeia" VALUES (163, 'قيادة المقر العام / الامانة العامة');
INSERT INTO "tabaeia" VALUES (164, 'قيادة المنطقة الغربية');
INSERT INTO "tabaeia" VALUES (165, 'قيادة المنطقه الشماليه العسكرية');
INSERT INTO "tabaeia" VALUES (166, 'قيادة فوج تطهير الصحراء الغربية ( من الإمكانيات الداخلية)');
INSERT INTO "tabaeia" VALUES (169, 'قيادة وحدات حوف العسكريه');
INSERT INTO "tabaeia" VALUES (222, 'كلية الطب بالقوات المسلحة');
INSERT INTO "tabaeia" VALUES (226, 'ل199كبارى');
INSERT INTO "tabaeia" VALUES (227, 'اللواء 209 م ع');
INSERT INTO "tabaeia" VALUES (229, 'اللواء 44 كباري');
INSERT INTO "tabaeia" VALUES (230, 'اللواء 509 انشاءات مختلط');
INSERT INTO "tabaeia" VALUES (231, 'ل9 تدخل');
INSERT INTO "tabaeia" VALUES (236, 'مركز التنمية البشرية والعلوم السلوكية للقوات المسلحة');
INSERT INTO "tabaeia" VALUES (237, 'مركز النقليات البحرى');
INSERT INTO "tabaeia" VALUES (238, 'مركز تدريب القوات الجوية');
INSERT INTO "tabaeia" VALUES (239, 'مركز تدريب مهن المهندسين');
INSERT INTO "tabaeia" VALUES (240, 'مركز دراسات نظم الدفاع');
INSERT INTO "tabaeia" VALUES (272, 'اللواء 24 انشاءات');
INSERT INTO "tabaeia" VALUES (273, 'اللواء 29 طرق');
INSERT INTO "tabaeia" VALUES (274, 'اللواء 122 كباري');
INSERT INTO "tabaeia" VALUES (275, 'قيادة قوات الصاعقة');
INSERT INTO "tabaeia" VALUES (276, 'الفوج الأول طرق خدمة وطنية');
INSERT INTO "tabaeia" VALUES (277, 'فر 2 مشا ميكا');
INSERT INTO "tabaeia" VALUES (278, 'فر 9 مشا ميكا');
INSERT INTO "tabaeia" VALUES (279, 'الماسة كابيتال');
INSERT INTO "tabaeia" VALUES (280, 'المجمع الطبي للقوات المسلحة بكوبري القبة');
INSERT INTO "tabaeia" VALUES (281, 'المستشفى العسكري بالعريش 120 سرير');
INSERT INTO "tabaeia" VALUES (282, 'ادارة التعينات');
INSERT INTO "tabaeia" VALUES (283, 'ادارة الخدمات الطبية');
INSERT INTO "tabaeia" VALUES (284, 'الكلية الفنية العسكرية');
INSERT INTO "tabaeia" VALUES (285, 'مست احمد جلال العسكري');
INSERT INTO "tabaeia" VALUES (286, 'ادارة المركبات');
INSERT INTO "tabaeia" VALUES (287, 'هيئة تنظيم وادارة');
INSERT INTO "tabaeia" VALUES (288, 'معامل ق م للبحوث الطبية وبنك الدم');
INSERT INTO "tabaeia" VALUES (289, 'قيادة القطاع الشمالى لمكافحة الإرهاب');
INSERT INTO "tabaeia" VALUES (290, 'مست الحلمية العسكرى');
INSERT INTO "tabaeia" VALUES (291, 'كلية الضباط الاحتياط');
INSERT INTO "tabaeia" VALUES (292, 'المستودع الرئيسى للاشغال 562');
INSERT INTO "tabaeia" VALUES (293, 'مركز الطبى العالمى');
INSERT INTO "tabaeia" VALUES (294, 'مستودع المهندسين الفرعي رقم 10');
INSERT INTO "tabaeia" VALUES (295, 'المستودع الرئسى لمهمات م ع');
INSERT INTO "tabaeia" VALUES (296, 'قيادة قوات حرس الحدود');
INSERT INTO "tabaeia" VALUES (297, 'اللواء 409');
INSERT INTO "tabaeia" VALUES (298, 'هيئة تدريب ق م');
INSERT INTO "tabaeia" VALUES (299, 'ورش المهندسين الرئيسية للانتاج');
INSERT INTO "tabaeia" VALUES (300, 'بدون');
INSERT INTO "tabaeia" VALUES (301, 'وحدة تدريب مشترك هيئة الهندسية');
INSERT INTO "tabaeia" VALUES (303, 'المعهد الصحى للتمريض ذكور حوش عيسى');
INSERT INTO "tabaeia" VALUES (304, 'ك9 اشغال وصيانة');
INSERT INTO "tabaeia" VALUES (306, 'القيادة الاستراتيجية');

-- ----------------------------
-- Auto increment value for tabaeia
-- ----------------------------
UPDATE "sqlite_sequence" SET seq = 307 WHERE name = 'tabaeia';

PRAGMA foreign_keys = true;

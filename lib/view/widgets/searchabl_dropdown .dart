import 'package:flutter/material.dart';

class SearchableDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  // متغيرات التحكم في الأبعاد
  final double maxHeight; // أقصى ارتفاع للقائمة
  final double width; // عرض المربع والقائمة
  final double height; // ارتفاع المربع الخارجي

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.maxHeight = 300,
    this.width = 300, // القيمة الافتراضية للعرض
    this.height = 65, // القيمة الافتراضية للارتفاع
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = value ?? "اختر...";

    final Color bgColor = isDark ? const Color(0xFF1E1E2F) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color labelColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final Color borderColor = isDark ? Colors.white10 : Colors.grey.shade400;
    final Color searchFillColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return PopupMenuButton<String>(
      offset: Offset(0, height + 5), // يظهر تحت المربع بالضبط مهما كان ارتفاعه
      color: bgColor,
      constraints: BoxConstraints(maxWidth: width, minWidth: width),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      itemBuilder: (context) {
        String searchText = "";
        return [
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setState) {
                List<String> filteredItems = items
                    .where(
                      (e) => e.toLowerCase().contains(searchText.toLowerCase()),
                    )
                    .toList();

                return SizedBox(
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          style: TextStyle(color: textColor, fontSize: 14),
                          onChanged: (v) {
                            searchText = v;
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: "بحث...",
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            filled: true,
                            fillColor: searchFillColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade300,
                            indent: 15,
                            endIndent: 15,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelected = value == item;
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              tileColor: isSelected
                                  ? (isDark
                                        ? Colors.white10
                                        : Colors.blue.shade50)
                                  : null,
                              title: Text(
                                item,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark
                                            ? Colors.blueAccent
                                            : Colors.blue.shade900)
                                      : textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () {
                                onChanged(item);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ];
      },
      child: Container(
        width: width, // تطبيق العرض المخصص
        height: height, // تطبيق الارتفاع المخصص
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // توسيط المحتوى رأسياً
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: labelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

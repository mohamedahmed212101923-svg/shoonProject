import 'package:flutter/material.dart';

class MultiSelectPopup extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<String> onToggle;
  final bool isDark;

  // التحكم في الأبعاد
  final double maxHeight;
  final double width;
  final double height;

  const MultiSelectPopup({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    this.maxHeight = 300,
    this.width = 300,
    this.height = 65,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // توحيد الألوان مع الودجت السابقة
    final Color bgColor = isDark ? const Color(0xFF1E1E2F) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color labelColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final Color borderColor = isDark ? Colors.white10 : Colors.grey.shade400;

    final displayText = selectedValues.isEmpty
        ? "اختر..."
        : selectedValues.join(", ");

    return PopupMenuButton(
      offset: Offset(0, height + 5),
      color: bgColor,
      constraints: BoxConstraints(maxWidth: width, minWidth: width),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setState) {
              String searchText = "";
              return StatefulBuilder(
                // للتعامل مع نص البحث والقائمة
                builder: (context, setInnerState) {
                  final filteredItems = options
                      .where(
                        (e) =>
                            e.toLowerCase().contains(searchText.toLowerCase()),
                      )
                      .toList();

                  // ترتيب: المختار يظهر في الأعلى
                  filteredItems.sort((a, b) {
                    bool aSel = selectedValues.contains(a);
                    bool bSel = selectedValues.contains(b);
                    if (aSel && !bSel) return -1;
                    if (!aSel && bSel) return 1;
                    return 0;
                  });

                  return SizedBox(
                    width: width,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // حقل البحث
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: TextField(
                            style: TextStyle(color: textColor, fontSize: 14),
                            onChanged: (v) {
                              setInnerState(() => searchText = v);
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
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100,
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
                        // القائمة
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isSelected = selectedValues.contains(item);

                              return CheckboxListTile(
                                value: isSelected,
                                dense: true,
                                activeColor: isDark
                                    ? Colors.blueAccent
                                    : Colors.blue.shade700,
                                checkColor: Colors.white,
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (val) {
                                  onToggle(item);
                                  setInnerState(
                                    () {},
                                  ); // تحديث شكل الـ Checkbox فوراً
                                },
                              );
                            },
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.grey.shade300,
                        ),
                        // زر الإغلاق
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "تم",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.blueAccent
                                    : Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.filter_list,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';
import 'group_icon_mark.dart';

typedef GroupIconUploadCallback = Future<String?> Function();

/// Picker for built-in geometric marks or host-provided upload.
class GroupIconPickerSheet extends StatelessWidget {
  const GroupIconPickerSheet({
    super.key,
    required this.title,
    this.selectedMarkId,
    this.onMarkSelected,
    this.onUpload,
  });

  final String title;
  final GroupIconMarkId? selectedMarkId;
  final ValueChanged<GroupIconMarkId>? onMarkSelected;
  final GroupIconUploadCallback? onUpload;

  static Future<void> show(
    BuildContext context, {
    required String title,
    GroupIconMarkId? selectedMarkId,
    ValueChanged<GroupIconMarkId>? onMarkSelected,
    GroupIconUploadCallback? onUpload,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: chatThemeOf(context).surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => GroupIconPickerSheet(
        title: title,
        selectedMarkId: selectedMarkId,
        onMarkSelected: onMarkSelected,
        onUpload: onUpload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose group icon',
              style: TextStyle(
                color: theme.inkColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: GroupIconMark.defaults.length,
              itemBuilder: (context, index) {
                final mark = GroupIconMark.defaults[index];
                final isSelected = mark.id == selectedMarkId;
                return InkWell(
                  onTap: () {
                    onMarkSelected?.call(mark.id);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? theme.accentColor
                            : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: GroupAvatar(
                        title: title,
                        markId: mark.id,
                        radius: 22,
                        backgroundColor: theme.surfaceColor,
                        foregroundColor: theme.inkColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (onUpload != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final url = await onUpload!();
                    if (context.mounted && url != null) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Upload'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.inkColor,
                    side: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

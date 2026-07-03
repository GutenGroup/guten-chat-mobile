import 'package:flutter/material.dart';

import '../../../domain/repositories/chat_repository.dart';
import '../../theme/chat_theme.dart';
import 'group_icon_mark.dart';
import 'group_icon_picker.dart';

typedef NewGroupCallback = void Function(String conversationId);

/// New community sheet with slide-down dismiss animation.
class NewGroupSheet extends StatefulWidget {
  const NewGroupSheet({
    super.key,
    required this.repository,
    required this.onCreated,
    this.onUploadIcon,
    this.isPaid = false,
  });

  final ChatRepository repository;
  final NewGroupCallback onCreated;
  final GroupIconUploadCallback? onUploadIcon;
  final bool isPaid;

  static Future<void> show(
    BuildContext context, {
    required ChatRepository repository,
    required NewGroupCallback onCreated,
    GroupIconUploadCallback? onUploadIcon,
    bool isPaid = false,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return NewGroupSheet(
          repository: repository,
          onCreated: onCreated,
          onUploadIcon: onUploadIcon,
          isPaid: isPaid,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  State<NewGroupSheet> createState() => _NewGroupSheetState();
}

class _NewGroupSheetState extends State<NewGroupSheet> {
  final _titleController = TextEditingController();
  GroupIconMarkId _markId = GroupIconMarkId.monogram;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final id = await widget.repository.createGroup(
        title: title,
        memberProfileIds: const [],
        isPaid: widget.isPaid,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated(id);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    final top = MediaQuery.paddingOf(context).top;

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: theme.backgroundColor,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, top + 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isPaid
                            ? 'New paid community'
                            : 'New community',
                        style: TextStyle(
                          color: theme.inkColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.subtleTextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => GroupIconPickerSheet.show(
                        context,
                        title: _titleController.text,
                        selectedMarkId: _markId,
                        onMarkSelected: (mark) =>
                            setState(() => _markId = mark),
                        onUpload: widget.onUploadIcon,
                      ),
                      child: GroupAvatar(
                        title: _titleController.text,
                        markId: _markId,
                        radius: 28,
                        backgroundColor: theme.surfaceColor,
                        foregroundColor: theme.inkColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        autofocus: true,
                        style: TextStyle(color: theme.inkColor),
                        decoration: InputDecoration(
                          hintText: 'Community name',
                          hintStyle:
                              TextStyle(color: theme.subtleTextColor),
                          filled: true,
                          fillColor: theme.searchFieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.inkColor,
                      foregroundColor: theme.backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.backgroundColor,
                            ),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

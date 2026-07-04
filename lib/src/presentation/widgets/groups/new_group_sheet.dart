import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/models/profile.dart';
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
    this.contactsLookup,
    this.isPaid = false,
  });

  final ChatRepository repository;
  final NewGroupCallback onCreated;
  final GroupIconUploadCallback? onUploadIcon;
  final ContactsLookup? contactsLookup;
  final bool isPaid;

  static Future<void> show(
    BuildContext context, {
    required ChatRepository repository,
    required NewGroupCallback onCreated,
    GroupIconUploadCallback? onUploadIcon,
    ContactsLookup? contactsLookup,
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
          contactsLookup: contactsLookup,
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
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _inviteMessageController = TextEditingController();
  final _memberSearchController = TextEditingController();
  GroupIconMarkId _markId = GroupIconMarkId.monogram;
  BillingInterval _billingInterval = BillingInterval.monthly;
  final _selectedMemberIds = <String>{};
  List<ChatContact> _contacts = const [];
  Timer? _memberSearchDebounce;
  PlatformFile? _inviteAttachment;
  bool _isSubmitting = false;
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPaid && widget.contactsLookup != null) {
      _loadContacts('');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _inviteMessageController.dispose();
    _memberSearchController.dispose();
    _memberSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadContacts(String query) async {
    final lookup = widget.contactsLookup;
    if (lookup == null) {
      return;
    }
    setState(() => _isLoadingContacts = true);
    try {
      final contacts = await lookup(query.trim());
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoadingContacts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingContacts = false);
      }
    }
  }

  void _onMemberSearchChanged(String query) {
    _memberSearchDebounce?.cancel();
    _memberSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadContacts(query);
      }
    });
  }

  int? _parsePriceCents() {
    final raw = _priceController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      return null;
    }
    return (value * 100).round();
  }

  Future<void> _pickInviteAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'html', 'htm'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() => _inviteAttachment = result.files.first);
  }

  String _mimeForAttachment(PlatformFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return 'text/html';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSubmitting) {
      return;
    }

    int? priceCents;
    if (widget.isPaid) {
      priceCents = _parsePriceCents();
      if (priceCents == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid price')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final inviteMessage = _inviteMessageController.text.trim();
      final id = await widget.repository.createGroup(
        title: title,
        description: _descriptionController.text.trim(),
        memberProfileIds: _selectedMemberIds.toList(),
        isPaid: widget.isPaid,
        priceCents: priceCents,
        billingInterval: widget.isPaid ? _billingInterval : null,
        inviteMessage: widget.isPaid && inviteMessage.isNotEmpty
            ? inviteMessage
            : null,
      );

      final attachment = _inviteAttachment;
      if (widget.isPaid && attachment?.path != null) {
        try {
          await widget.repository.uploadGroupInviteAttachment(
            conversationId: id,
            localPath: attachment!.path!,
            fileName: attachment.name,
            mime: _mimeForAttachment(attachment),
          );
        } catch (_) {
          // Attachment failure must not fail community creation.
        }
      }

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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: theme.backgroundColor,
        elevation: 8,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 8, 12, 0),
                  child: Row(
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
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 2,
                          style: TextStyle(color: theme.inkColor),
                          decoration: InputDecoration(
                            hintText: 'Description (optional)',
                            hintStyle: TextStyle(color: theme.subtleTextColor),
                            filled: true,
                            fillColor: theme.searchFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (widget.isPaid) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  style: TextStyle(color: theme.inkColor),
                                  decoration: InputDecoration(
                                    hintText: 'Price (USD)',
                                    prefixText: '\$ ',
                                    hintStyle:
                                        TextStyle(color: theme.subtleTextColor),
                                    filled: true,
                                    fillColor: theme.searchFieldColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<BillingInterval>(
                                  initialValue: _billingInterval,
                                  dropdownColor: theme.surfaceColor,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: theme.searchFieldColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: BillingInterval.values
                                      .map(
                                        (interval) => DropdownMenuItem(
                                          value: interval,
                                          child: Text(
                                            switch (interval) {
                                              BillingInterval.oneTime =>
                                                'One-time',
                                              BillingInterval.monthly =>
                                                'Monthly',
                                              BillingInterval.quarterly =>
                                                'Quarterly',
                                              BillingInterval.annual =>
                                                'Annual',
                                            },
                                            style: TextStyle(
                                              color: theme.inkColor,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _billingInterval = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _inviteMessageController,
                            maxLines: 4,
                            style: TextStyle(color: theme.inkColor),
                            decoration: InputDecoration(
                              hintText: 'Personal invite message',
                              alignLabelWithHint: true,
                              hintStyle:
                                  TextStyle(color: theme.subtleTextColor),
                              filled: true,
                              fillColor: theme.searchFieldColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickInviteAttachment,
                            icon: Icon(Icons.attach_file, color: theme.inkColor),
                            label: Text(
                              _inviteAttachment?.name ??
                                  'Add invite attachment (PDF or HTML, optional)',
                              style: TextStyle(color: theme.inkColor),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 44),
                              side: BorderSide(color: theme.dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (widget.contactsLookup != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Invite members',
                              style: TextStyle(
                                color: theme.inkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _memberSearchController,
                              style: TextStyle(color: theme.inkColor),
                              decoration: InputDecoration(
                                hintText: 'Search contacts',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: theme.subtleTextColor,
                                ),
                                filled: true,
                                fillColor: theme.searchFieldColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: _onMemberSearchChanged,
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingContacts)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else
                              ..._contacts.map(
                                (contact) {
                                  final selected = _selectedMemberIds
                                      .contains(contact.profileId);
                                  return CheckboxListTile(
                                    value: selected,
                                    activeColor: theme.paidAccentColor,
                                    checkColor: Colors.black,
                                    title: Text(
                                      contact.name,
                                      style: TextStyle(color: theme.inkColor),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedMemberIds
                                              .add(contact.profileId);
                                        } else {
                                          _selectedMemberIds
                                              .remove(contact.profileId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                          ],
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.inkColor,
                              foregroundColor: theme.backgroundColor,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

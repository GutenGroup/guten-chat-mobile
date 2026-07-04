import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/profile.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../theme/chat_theme.dart';
import '../profile_avatar.dart';

/// "New chat" bottom sheet — search the host-supplied contact directory and
/// tap a contact to start (or reopen) a DM. A "New community" row at the top
/// routes to the existing community creation flow.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({
    super.key,
    required this.repository,
    required this.contactsLookup,
    required this.onCreated,
    required this.onNewCommunity,
  });

  final ChatRepository repository;
  final ContactsLookup contactsLookup;
  final ValueChanged<String> onCreated;
  final VoidCallback onNewCommunity;

  static Future<void> show(
    BuildContext context, {
    required ChatRepository repository,
    required ContactsLookup contactsLookup,
    required ValueChanged<String> onCreated,
    required VoidCallback onNewCommunity,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: chatThemeOf(context).backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final media = MediaQuery.of(context);
        final available = media.size.height -
            media.viewInsets.bottom -
            media.padding.top -
            24;
        final height = math.min(media.size.height * 0.72, available);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: height,
            child: NewChatSheet(
              repository: repository,
              contactsLookup: contactsLookup,
              onCreated: onCreated,
              onNewCommunity: onNewCommunity,
            ),
          ),
        );
      },
    );
  }

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _searchSeq = 0;
  List<ChatContact> _contacts = const [];
  bool _isLoading = true;
  String? _error;
  String? _creatingProfileId;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = true;
        _error = null;
      });
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final seq = ++_searchSeq;
    try {
      final contacts = await widget.contactsLookup(query.trim());
      if (!mounted || seq != _searchSeq) {
        return;
      }
      setState(() {
        _contacts = contacts;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || seq != _searchSeq) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startDm(ChatContact contact) async {
    if (_creatingProfileId != null) {
      return;
    }
    setState(() => _creatingProfileId = contact.profileId);
    try {
      final conversationId =
          await widget.repository.createDm(contact.profileId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onCreated(conversationId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingProfileId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'New chat',
                style: TextStyle(
                  color: theme.inkColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _NewCommunityRow(
            onTap: () {
              Navigator.of(context).pop();
              widget.onNewCommunity();
            },
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: theme.subtleTextColor),
                prefixIcon: Icon(Icons.search, color: theme.subtleTextColor),
                filled: true,
                fillColor: theme.searchFieldColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: TextStyle(color: theme.inkColor),
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(child: _buildResults(theme)),
        ],
      ),
    );
  }

  Widget _buildResults(ChatTheme theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _search(_searchController.text);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_contacts.isEmpty) {
      return Center(
        child: Text(
          'No contacts found',
          style: TextStyle(color: theme.subtleTextColor),
        ),
      );
    }
    return ListView.separated(
      itemCount: _contacts.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _ContactRow(
          contact: contact,
          isCreating: _creatingProfileId == contact.profileId,
          onTap: () => _startDm(contact),
        );
      },
    );
  }
}

class _NewCommunityRow extends StatelessWidget {
  const _NewCommunityRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.surfaceColor,
                child: Icon(
                  Icons.groups_outlined,
                  size: 20,
                  color: theme.inkColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New community',
                  style: TextStyle(
                    color: theme.inkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.subtleTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.isCreating,
    required this.onTap,
  });

  final ChatContact contact;
  final bool isCreating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              ProfileAvatar(profile: contact.profile, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.inkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isCreating)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.inkColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

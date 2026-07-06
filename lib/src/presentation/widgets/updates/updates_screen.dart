import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';
import '../shell/glass_bar.dart';

/// Updates tab — public feed scaffold (Phase 2).
///
/// Planned backend: `chat_updates_feed` table + RPCs for posts with
/// images, links, and HTML-document cards. Not wired yet — UI placeholder
/// shows the intended layout from the design reference.
class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  static const _placeholderPosts = [
    _PlaceholderPost(
      author: 'Techpool Field Ops',
      initials: 'TP',
      timeAgo: '2h',
      body:
          'New torque spec for the RTU-40 install. Full writeup below 👇',
      hasHtmlDoc: true,
      docTitle: 'RTU-40 — Install & Torque Guide',
      docMeta: 'HTML document · 6 sections · 3 min read',
      likes: 24,
      comments: 6,
    ),
    _PlaceholderPost(
      author: 'Daniel Ekström',
      initials: 'DE',
      timeAgo: '5h',
      body: 'Recovery week. Sleep > everything.',
      hasPhoto: true,
      likes: 12,
      comments: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return ColoredBox(
      color: theme.backgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: glassBarFlexibleSpace(theme),
            title: Text(
              'Updates',
              style: TextStyle(
                color: theme.inkColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: theme.subtleTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phase 2: public feed with images, links & HTML-doc '
                        'previews. Backend: `chat_updates_feed` (planned).',
                        style: TextStyle(
                          color: theme.subtleTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _placeholderPosts[index];
                return _UpdatePostCard(post: post);
              },
              childCount: _placeholderPosts.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPost {
  const _PlaceholderPost({
    required this.author,
    required this.initials,
    required this.timeAgo,
    required this.body,
    this.hasHtmlDoc = false,
    this.docTitle,
    this.docMeta,
    this.hasPhoto = false,
    this.likes = 0,
    this.comments = 0,
  });

  final String author;
  final String initials;
  final String timeAgo;
  final String body;
  final bool hasHtmlDoc;
  final String? docTitle;
  final String? docMeta;
  final bool hasPhoto;
  final int likes;
  final int comments;
}

class _UpdatePostCard extends StatelessWidget {
  const _UpdatePostCard({required this.post});

  final _PlaceholderPost post;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.backgroundColor,
                    child: Text(
                      post.initials,
                      style: TextStyle(
                        color: theme.inkColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: TextStyle(
                            color: theme.inkColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Public · ${post.timeAgo}',
                          style: TextStyle(
                            color: theme.subtleTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.body,
                style: TextStyle(color: theme.inkColor, height: 1.4),
              ),
              if (post.hasHtmlDoc) ...[
                const SizedBox(height: 12),
                _HtmlDocPreview(
                  title: post.docTitle!,
                  meta: post.docMeta!,
                ),
              ],
              if (post.hasPhoto) ...[
                const SizedBox(height: 12),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Center(
                    child: Icon(Icons.photo_outlined,
                        color: theme.subtleTextColor, size: 32),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.favorite_border,
                    label: '${post.likes}',
                  ),
                  const SizedBox(width: 16),
                  _ActionChip(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.comments}',
                  ),
                  const Spacer(),
                  Icon(Icons.share_outlined,
                      size: 18, color: theme.subtleTextColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HtmlDocPreview extends StatelessWidget {
  const _HtmlDocPreview({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HTML doc',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Open',
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: theme.inkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: TextStyle(color: theme.subtleTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = chatThemeOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.subtleTextColor),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: theme.subtleTextColor, fontSize: 13)),
      ],
    );
  }
}

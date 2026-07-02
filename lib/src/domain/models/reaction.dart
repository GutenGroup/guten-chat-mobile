import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

enum ReactionKind {
  emoji,
  brand;

  static ReactionKind fromJson(String? value) {
    switch (value) {
      case 'brand':
        return ReactionKind.brand;
      case 'emoji':
      default:
        return ReactionKind.emoji;
    }
  }

  String toJson() => name;
}

/// Mirrors `chat_message_reactions`.
class Reaction extends Equatable {
  const Reaction({
    required this.messageId,
    required this.profileId,
    required this.value,
    required this.kind,
    required this.createdAt,
    this.isOptimistic = false,
  });

  final String messageId;
  final String profileId;
  final String value;
  final ReactionKind kind;
  final DateTime createdAt;
  final bool isOptimistic;

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      messageId: requireString(json, 'message_id', 'messageId'),
      profileId: requireString(json, 'profile_id', 'profileId'),
      value: requireString(json, 'value', 'value'),
      kind: ReactionKind.fromJson(
        readJson<String>(json, 'kind', 'kind') ??
            readJson<String>(json, 'reaction_kind', 'reactionKind'),
      ),
      createdAt: parseTimestamp(
        readJson<dynamic>(json, 'created_at', 'createdAt'),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'profile_id': profileId,
        'value': value,
        'kind': kind.toJson(),
        'created_at': createdAt.toIso8601String(),
      };

  Reaction copyWith({
    String? messageId,
    String? profileId,
    String? value,
    ReactionKind? kind,
    DateTime? createdAt,
    bool? isOptimistic,
  }) {
    return Reaction(
      messageId: messageId ?? this.messageId,
      profileId: profileId ?? this.profileId,
      value: value ?? this.value,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  @override
  List<Object?> get props =>
      [messageId, profileId, value, kind, createdAt, isOptimistic];
}

/// Aggregated reaction chip for UI display.
class ReactionSummary extends Equatable {
  const ReactionSummary({
    required this.value,
    required this.kind,
    required this.count,
    required this.profileIds,
    required this.includesMe,
  });

  final String value;
  final ReactionKind kind;
  final int count;
  final List<String> profileIds;
  final bool includesMe;

  @override
  List<Object?> get props =>
      [value, kind, count, profileIds, includesMe];
}

List<ReactionSummary> summarizeReactions(
  List<Reaction> reactions,
  String currentProfileId,
) {
  final grouped = <String, List<Reaction>>{};
  for (final reaction in reactions) {
    final key = '${reaction.kind.name}:${reaction.value}';
    grouped.putIfAbsent(key, () => []).add(reaction);
  }

  return grouped.entries.map((entry) {
    final list = entry.value;
    final first = list.first;
    final profileIds = list.map((r) => r.profileId).toList();
    return ReactionSummary(
      value: first.value,
      kind: first.kind,
      count: list.length,
      profileIds: profileIds,
      includesMe: profileIds.contains(currentProfileId),
    );
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}

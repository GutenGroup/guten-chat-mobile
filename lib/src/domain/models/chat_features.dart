import 'package:equatable/equatable.dart';

/// Per-app feature flags mirroring web `@gutengroup/chat-core` ChatFeatures.
class ChatFeatures extends Equatable {
  const ChatFeatures({
    this.reactions = true,
    this.brandReactions = true,
    this.tipping = false,
    this.paymentRequests = false,
    this.paidGroups = false,
    this.groupProvisioning = false,
    this.moderatorRole = true,
    this.teamAddon = false,
    this.readReceipts = true,
    this.typingIndicators = true,
    this.presence = true,
    this.replies = true,
  });

  final bool reactions;
  final bool brandReactions;
  final bool tipping;
  final bool paymentRequests;
  final bool paidGroups;
  final bool groupProvisioning;
  final bool moderatorRole;
  final bool teamAddon;
  final bool readReceipts;
  final bool typingIndicators;
  final bool presence;
  final bool replies;

  /// Merges host overrides with platform defaults (same semantics as web
  /// `resolveFeatures`).
  factory ChatFeatures.resolve({
    bool? reactions,
    bool? brandReactions,
    bool? tipping,
    bool? paymentRequests,
    bool? paidGroups,
    bool? groupProvisioning,
    bool? moderatorRole,
    bool? teamAddon,
    bool? readReceipts,
    bool? typingIndicators,
    bool? presence,
    bool? replies,
  }) {
    return resolveFeatures(
      ChatFeatures(
        reactions: reactions ?? true,
        brandReactions: brandReactions ?? true,
        tipping: tipping ?? false,
        paymentRequests: paymentRequests ?? false,
        paidGroups: paidGroups ?? false,
        groupProvisioning: groupProvisioning ?? false,
        moderatorRole: moderatorRole ?? true,
        teamAddon: teamAddon ?? false,
        readReceipts: readReceipts ?? true,
        typingIndicators: typingIndicators ?? true,
        presence: presence ?? true,
        replies: replies ?? true,
      ),
    );
  }

  ChatFeatures copyWith({
    bool? reactions,
    bool? brandReactions,
    bool? tipping,
    bool? paymentRequests,
    bool? paidGroups,
    bool? groupProvisioning,
    bool? moderatorRole,
    bool? teamAddon,
    bool? readReceipts,
    bool? typingIndicators,
    bool? presence,
    bool? replies,
  }) {
    return ChatFeatures(
      reactions: reactions ?? this.reactions,
      brandReactions: brandReactions ?? this.brandReactions,
      tipping: tipping ?? this.tipping,
      paymentRequests: paymentRequests ?? this.paymentRequests,
      paidGroups: paidGroups ?? this.paidGroups,
      groupProvisioning: groupProvisioning ?? this.groupProvisioning,
      moderatorRole: moderatorRole ?? this.moderatorRole,
      teamAddon: teamAddon ?? this.teamAddon,
      readReceipts: readReceipts ?? this.readReceipts,
      typingIndicators: typingIndicators ?? this.typingIndicators,
      presence: presence ?? this.presence,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [
        reactions,
        brandReactions,
        tipping,
        paymentRequests,
        paidGroups,
        groupProvisioning,
        moderatorRole,
        teamAddon,
        readReceipts,
        typingIndicators,
        presence,
        replies,
      ];
}

/// Applies dependency rules between flags (mirrors web `resolveFeatures`).
ChatFeatures resolveFeatures(ChatFeatures input) {
  var features = input;

  if (!features.reactions) {
    features = features.copyWith(brandReactions: false);
  }

  if (!features.brandReactions && features.reactions) {
    // brand reactions require base reactions — already satisfied.
  } else if (features.brandReactions && !features.reactions) {
    features = features.copyWith(brandReactions: false);
  }

  if (!features.moderatorRole) {
    // Moderator role is only meaningful for groups; no further cascade.
  }

  if (!features.paidGroups) {
    // Paid group join checkout disabled; group provisioning may still apply.
  }

  if (!features.tipping) {
    // Tips hidden in UI when disabled.
  }

  if (!features.paymentRequests) {
    // Payment request UI hidden when disabled.
  }

  return features;
}

/// Brand reaction marks supplied by the host app (e.g. Cowbolt bolt icon).
class BrandReactionMark extends Equatable {
  const BrandReactionMark({
    required this.id,
    required this.label,
    required this.emojiFallback,
  });

  final String id;
  final String label;
  final String emojiFallback;

  @override
  List<Object?> get props => [id, label, emojiFallback];
}

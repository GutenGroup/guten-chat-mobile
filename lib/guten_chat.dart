/// Guten Chat Mobile — public API barrel.
///
/// SCAFFOLD ONLY. The implementation is built on a Flutter-capable environment
/// per BUILD_SPEC.md (this machine has no Flutter toolchain). The intended
/// public surface is a single entrypoint the host app drops in:
///
///   GutenChat(
///     supabase: Supabase.instance.client, // same chat_* backend as web
///     profileLookup: (id) async => Profile(name: ..., avatarUrl: ...),
///     features: ChatFeatures(tipping: true, paymentRequests: true, ...),
///   )
///
/// Mirrors Guten Chat Web (@gutengroup/chat-*): ChatFeatures/resolveFeatures,
/// a pluggable ProfileLookup, and a realtime ConversationChannel over Supabase
/// postgres_changes + presence + typing.
///
/// TODO(build): implement lib/src/{domain,data,presentation} per BUILD_SPEC.md,
/// seeding UI from cowbolt-mobile group_chat, data layer on supabase_flutter.
library guten_chat;

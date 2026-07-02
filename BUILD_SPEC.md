# Guten Chat Mobile — Build Spec (the contract)

This is the single source of truth for building `guten_chat` (Flutter). It
guarantees **feature parity** with Guten Chat Web so the two stay identical.
Both skins target the **same Supabase `chat_*` schema** — that shared backend is
what makes Web and Mobile the same conversations.

## 0. Environment (why this wasn't built inline)
Building/verifying Flutter needs the Flutter SDK; an iOS/TestFlight build needs
Xcode + Apple signing + an App Store Connect API key. Execute this on a
Flutter-capable environment (a Cursor cloud agent, or a Flutter dev machine).
**TestFlight upload is credential-gated on Daniel's Apple Developer account.**

## 1. Shared backend — DO NOT invent a new one
Same Supabase project + schema as Guten Chat Web. Tables (all `chat_`-prefixed):
`chat_conversations`, `chat_conversation_participants`, `chat_messages`,
`chat_message_attachments`, `chat_message_reactions`, `chat_payment_requests`,
`chat_tips`, `chat_group_provisioning_rules`. Writes go through the SECURITY
DEFINER RPCs (e.g. `chat_create_dm`, send-message, `toggle_reaction`,
group create/add/remove/leave/`set_group_role`/`join_group`, mark-read,
tips/payment-request RPCs). Realtime = Supabase `postgres_changes` on
`chat_messages` + `chat_message_reactions`, plus presence + typing broadcast —
mirror the web `ConversationChannel` in `@gutengroup/chat-core`.

Canonical schema lives in `github.com/GutenGroup/guten-chat` →
`packages/schema/migrations`. Read it; do not redefine it.

## 2. Feature parity with Guten Chat Web (must match)
- DMs + group conversations; roles **owner / admin / moderator / member** (co-ownership allowed).
- Optimistic send (temp bubble → reconcile to real id → rollback on failure).
- Realtime delivery with optimistic-echo de-dupe (no double bubbles).
- Message reactions: emoji **and** host brand-marks; optimistic with rollback.
- Typing indicators (throttled, ~4s TTL), presence/online, read receipts (double-tick DM, "seen by N" group).
- Replies with quoted preview; day dividers; consecutive-sender grouping.
- **Mobile-feel**: composer pinned above the keyboard; own-sent message snaps to bottom (instant); "N new" jump-to-latest pill when scrolled up; safe-area aware.
- Paid groups + join checkout; in-chat payment requests; per-conversation tipping. (Payments are host-configurable per app via a feature-flags object mirroring web `ChatFeatures` / `resolveFeatures`.)
- Per-app feature flags: reactions, brandReactions, tipping, paymentRequests, paidGroups, groupProvisioning, moderator role, team add-on — each toggleable by the host app.
- Pluggable profile lookup: the package NEVER reads a host's profile columns directly — the host passes a `ProfileLookup` callback (profileId → {name, avatar}), mirroring web.

## 3. Architecture
Clean architecture, mirroring the Cowbolt app's structure: `lib/src/{data,domain,presentation}`.
- `domain`: models mirroring the schema (camelCase), repository interfaces.
- `data`: `supabase_flutter` datasource + repositories over the RPCs/tables + realtime.
- `presentation`: the chat UI (inbox, thread, composer, bubble, reactions, typing, jump-to-latest), state via cubit/bloc or Riverpod — match the consuming apps' state lib.
- Public API: a single `GutenChat` entrypoint widget/config taking `SupabaseClient`, `ProfileLookup`, and `ChatFeatures`.

## 4. Seed — reuse Cowbolt's chat UI, NOT its backend
Cowbolt already has a native Flutter chat at
`~/repos/cowbolt-mobile/lib/modules/groups/group_expenses_and_chat_features/group_chat`
(presentation/ui, cubit, widgets, emojis). **Reuse the UI patterns + widgets.**
⚠️ Cowbolt's chat data layer is **Firebase/Firestore** — do **not** port it.
Replace the data/datasource/repository layer with `supabase_flutter` against the
`chat_*` schema above.

## 5. Consumers (each app installs this one package)
- **Instant Capture / Techpool** (`techpool-mobile`, native Flutter) — clean install; no existing chat.
- **Cowbolt** (`cowbolt-mobile`, native Flutter, being rewritten to match Techpool) — replace its Firebase chat with this package.
- **Fysigo-mobile** — add a native `GutenChat` screen (Fysigo mobile is a Flutter shell today; this is the first native screen, or lands as the app moves fully native).
Consume via a git dependency: `guten_chat: { git: https://github.com/GutenGroup/guten-chat-mobile }`.

## 6. Native touches (for the "slick native" bar)
- Haptic feedback on send (each app's haptics bridge / `HapticFeedback`).
- Push notifications for new messages: a Supabase trigger on `chat_messages` insert → APNs/FCM via each app's existing push bridge.

## 7. Verify
`flutter pub get` → `flutter analyze` (0 issues) → `flutter test`. Prove a message
sent from Guten Chat Web appears here and vice-versa (same DB). Then wire into one
consumer app and run on a simulator.

## 8. Parity rule
Any chat feature change must land in **both** Guten Chat Web and Guten Chat
Mobile, validated against the same `chat_*` schema. The schema is the contract.

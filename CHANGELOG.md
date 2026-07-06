# Changelog

## 0.9.0

### Changed
- **Shell DLS round (Daniel's on-device feedback, 2026-07-06).** The chat
  shell now carries the host accent the way the web module does — not just
  the bubbles:
  - Active bottom-bar tab (icon + label + profile avatar) = accent
    (web `.gc-tab[aria-selected]` parity).
  - Unread-count pill = accent with accent-contrast ink (web unread badge
    parity).
  - Primary bar affordances (new chat pencil, new community +) = accent
    (web `.gc-btn--primary` parity).
  - **Translucent glass headers**: the conversation header and every tab's
    app bar are now blurred translucent chrome (`glassBarFlexibleSpace`,
    the top-side twin of the bottom bar) — the thread/list scrolls visibly
    under the bar. The thread Scaffold extends behind its header; the
    message list pads itself past it.
  - **Composer fills to the physical bottom edge** — SafeArea moved inside
    the composer's Material, so its surface paints through the
    home-indicator zone (no more bare gap under the input).
  - **Host-pinned appearance removes the in-chat light/dark toggle** — a
    host passing `appearance != system` owns light/dark (Fysigo is
    black-only); the Profile appearance tile only renders when the host
    follows the system.

## 0.8.1

### Fixed
- **Live-schema column names in the money/reaction parsers — conversations no
  longer crash.** The 0.6.0 reconciliation missed three tables, so any
  conversation containing a reaction (or payment request) failed to load with
  `FormatException: Missing required field` (hit on-device in Fysigo b30,
  4 prod conversations). Verified against the live schema + prod DB:
  - `Reaction`: reads `reaction` (was `value`-only).
  - `PaymentRequest`: reads `requested_by_profile_id` (was
    `requester_profile_id`-only), `paid_by_profile_id` (was
    `payer_profile_id`-only), and accepts the schema's `canceled` spelling.
  - `Tip`: reads `from_profile_id`/`to_profile_id` (was
    `sender_profile_id`/`recipient_profile_id`-only) — tip sends parse the
    RPC's returned row again.
  Legacy key names still parse (fallback), and each `toJson` emits both
  spellings for lossless round-trips.
- **Decoration rows can no longer take down a thread.** Embedded reactions,
  attachments, and payment cards now parse leniently (`parseRowsLenient`): a
  malformed row is dropped with a debug log instead of throwing through the
  whole conversation load. Schema-shaped fixtures pin all of the above in
  `test/schema_row_parsing_test.dart`.

## 0.8.0

### Added
- **Theme contract — a host app can no longer ship the unthemed gray default
  silently.** `GutenChatTheme` grows the full host-DLS token set:
  `backgroundColor`, `surfaceColor`, `sentBubbleColor`, `receivedBubbleColor`,
  `sentTextColor`, `receivedTextColor`, `fontFamily`, `borderRadius` — all
  optional, deriving the existing v0.5.0 defaults from `accentColor` + the
  shared foundation tokens when null, so existing callers are value-identical.
  `fontFamily` flows through the resolved `ChatTheme` into the chat
  `ThemeData`. Derived neighbours (composer ground, translucent bottom bar,
  search field) follow the host `backgroundColor`/`surfaceColor` overrides.
- **Loud unthemed default (debug).** Mounting `GutenChat` (or
  `GutenChatConversationRoute`) with no theme prints a prominent once-per-run
  console banner telling the host to pass `GutenChatTheme(...)` from its
  design system. Compiles away in release. New: `GutenChatTheme.isUnthemed`,
  `debugCheckGutenChatHostTheme`, `debugResetGutenChatThemeWarning` (test
  hook). README gains "Theming — bring your host DLS" with Fysigo as the
  reference integration.

## 0.7.0

### Changed
- **v0.5.0 web design parity — the accent finally does the talking.** Outgoing
  bubbles now carry the host `accentColor` with `accentContrastColor` ink
  (new host token, default white); incoming bubbles sit on the token neutral
  (`#1F1F22` dark / `#ECEEF1` light). Values come from guten-chat
  `foundation/design/tokens.json` — the ONE design source web already
  generates from; this hand-port keeps the two skins value-identical until
  the Flutter generator lands. Kills the old white-on-black max-contrast
  outgoing bubble (same change the web module shipped in its v0.5.0).
- Brand-reaction emphasized bubbles use the accent-contrast ink instead of
  hardcoded black/white.
- **Full v0.5.0 component parity** (matching web guten-chat #14):
  - **Voice recording is inline** — the composer input row swaps to a
    recording bar (discard · pulsing red dot · tabular timer · accent
    waveform · accent send). The modal recorder sheet is gone.
  - **Voice player**: the web module's 32-bar waveform (same deterministic
    heights), inked from the bubble it sits in (legible on accent AND
    neutral bubbles), tap/drag to scrub, play button on a 16%-ink disc,
    inline elapsed/total time. No more surface box inside the bubble.
  - **Media bubbles**: an image-only message renders as a thin raised tile
    (3px pad, hairline border) so transparent logos/stickers read as sent,
    with the timestamp overlaid as a pill on the image (below-bubble time
    row suppressed). Image caps 320×420.
  - **Payment cards hug their content** (min 240 / max 320) on an
    accent-tinted surface (7% accent over raised) with a 32% accent
    hairline — no more full-width stretch.
  - **HTML document cards**: 280px cap, neutral chrome, 180px preview with
    a 14px-padding white-ground reset injected (arbitrary shared HTML no
    longer sits edge-to-edge). Fullscreen still renders the document raw.
  - **Composer send button carries the accent** (was ink-on-ink).

## 0.6.0

### Added
- **Paid communities (schema + UX parity with web v0.4.0).** Reconciled to the
  live `@gutengroup/chat-schema` contract: `chat_create_group_conversation`
  (with `price_cents`, `billing_interval`, `invite_message`), invite attachment
  upload via `chat_set_group_invite_attachment`, and all RPC params use the live
  `p_`-prefixed names. Sends, deletes, and mark-read use direct table ops
  (`body_md`, soft `deleted_at`, participant `last_read_message_id`) — no
  `chat_send_message` / `chat_delete_message` / `chat_mark_read` RPCs.
  Communities inbox shows **Invitation · tap to join** for pending paid members; a
  **PaidGate** join screen renders title, description, personal invite message,
  optional PDF/HTML attachment, and a **Join** button wired to the new host
  callback `GutenChat.onJoinPaidCommunity` (no Stripe in the module).

## 0.5.0

### Added
- **"New chat" DM compose.** New optional `GutenChat.contactsLookup` host callback
  (`ContactsLookup` — `Future<List<ChatContact>> Function(String query)`; the
  `ChatContact` model carries `profileId` / `name` / `avatarUrl` and is exported
  from the package barrel). When provided, the Chats tab pencil opens a
  **New chat** bottom sheet: contact search (300 ms debounce; empty query loads
  the initial directory), tapping a contact calls the existing `chat_create_dm`
  RPC and opens the conversation. A **New community** row at the top routes to
  the existing community flow. When `contactsLookup` is null the pencil keeps
  today's behavior (straight to New community) — existing hosts unaffected.

## 0.4.4

### Added
- Composer **+ attach menu** is the single money action hub: **Request payment** and
  **Send tip** entries (feature-gated via `paymentRequests` / `tipping`), separated
  from attachments by a visual divider. No standalone composer money buttons.
- **`PaymentRequestSheet`** — amount (USD, decimal keypad), optional note, Send request.
- **`ConversationCubit.createPaymentRequest`** — calls existing repository RPC; request
  lands in the thread as a message.
- **Send tip from composer** — DM opens preset amounts (`$1` / `$3` / `$5` / `$10`);
  group shows a member picker first (exclude self), then presets. Uses existing
  `sendTip` path (no message anchor).
- **`PaymentRequestCard`** inline bubble — bank icon, amount, requested-by, status
  (Open / Paid / Canceled / Expired). Display + status only; paying stays on web.
- Shared **`TipPresetsSheet`** / **`TipPresetAmountRow`** extracted for composer and
  context-menu tip UI.

### Unchanged
- Message-context-menu **Tip** on received messages (unchanged).
- Keyboard / scaffold discipline from 0.4.3 (`resizeToAvoidBottomInset`, composer
  `Padding(viewInsets)`, `buildLabel`).

## 0.4.3

### Fixed
- **Keyboard discipline (WhatsApp standard).** The bottom tab bar is locked to
  the physical screen bottom — the keyboard slides over it, it never floats up
  (home Scaffold `resizeToAvoidBottomInset: false`; the body pads itself by the
  keyboard inset so the Chats search stays visible). The thread screen makes
  the composer the single, explicit owner of the keyboard inset
  (`resizeToAvoidBottomInset: false` + plain `Padding(viewInsets)` — the old
  150 ms `AnimatedPadding` tween lagged the iOS keyboard curve and could go
  double under a resizing host ancestor). Closing a thread unfocuses first so
  the inbox never mounts mid-keyboard-dismiss.

### Added
- `GutenChat.buildLabel` — optional build stamp (e.g. `b16 · chat 0.4.3`)
  rendered as a tiny caption under the Chats list, mirroring the web app's
  version footer, so testers can tell exactly which build feedback refers to.

## 0.4.2

### Added
- Voice note recording and playback via `flutter_sound` (replaces `record` + `just_audio` removed in 0.4.1).
- Composer attach menu: Voice note restored as first item (Voice note · Photo · Camera · HTML file · File).
- `path_provider` for temp recording paths; microphone permission via `permission_handler`.

### iOS (host app)
Consuming apps must declare in `Info.plist`:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMicrophoneUsageDescription`

## 0.4.1

### Added
- iMessage-class message context menu on tap/long-press: lifted bubble, blurred backdrop, quick reactions (❤️ 😂 👍 ‼️ 🙏 + full emoji picker), and action sheet (Reply, Copy, Tip, Forward, Delete).
- Composer bottom-left `+` attach menu with labeled speed-dial pills: Photo, Camera, HTML file, File.
- Message forward and delete actions.
- Dev build-stamp messages (commit hash banners) hidden in release builds.
- CI compile gates: `flutter build apk --debug` (Ubuntu) and `flutter build ios --no-codesign` (macOS) on the example app.

### Changed
- Tipping moved from composer/per-bubble affordance to message context menu only.
- Attach menu uses Techpool-style labeled pills for all attachment types.

### Removed
- Inline `MessageTipAffordance` beside received bubbles.
- Voice note recording from this release (deferred to a follow-up with `flutter_sound`).

### iOS (host app)
Consuming apps must declare in `Info.plist`:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## 0.4.0

(Superseded by 0.4.1 — voice notes removed before ship.)

## 0.3.0

### Added
- Composer bottom-left attach button with hand-rolled expanding menu (camera, gallery, file).
- Attachment send pipeline: upload to `chat-attachments`, insert message + attachment rows, optimistic UI with upload progress.
- Message rendering for images (inline thumbnail + fullscreen viewer), HTML files (`HtmlDocumentCard` with sandboxed WebView preview), PDF files (`PdfDocumentCard` with first-page preview via `pdfx`), and generic file chips.
- Per-message tip affordance with expanding preset amounts ($1, $3, $5, $10) via existing `chat_send_tip` RPC (gated by `ChatFeatures.tipping`).
- Dependencies: `image_picker`, `file_picker`, `webview_flutter`, `pdfx`.

### iOS (host app)
Consuming apps must declare in `Info.plist`:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## 0.2.0

- Black-first redesign with theme-agnostic accent injection.

# Guten Chat Mobile

The **Flutter** chat package for Guten Group's mobile apps — the sibling of
**Guten Chat Web** (`@gutengroup/chat-*`). One package, installed by every
native Flutter app: **Instant Capture / Techpool**, **Cowbolt**, and
**Fysigo-mobile** (once it's on Flutter).

It renders chat natively in Flutter but talks to the **exact same Supabase
database** as Guten Chat Web — the `chat_*` tables and RPCs. A message sent on
the web shows up in the app and vice-versa. Web and Mobile are two skins over
**one shared contract** (the database + the feature spec).

- **Web (desktop):** `github.com/GutenGroup/guten-chat` → `@gutengroup/chat-*` (React/TS) — done, unchanged.
- **Mobile (this repo):** `guten_chat` (Flutter/Dart) — seeded from Cowbolt's native chat UI, rebuilt on the shared Supabase backend.

**To build/verify you need a Flutter toolchain** (`flutter pub get`, `flutter
analyze`, `flutter test`). See [`BUILD_SPEC.md`](./BUILD_SPEC.md) — the single
source of truth for what to build, the feature parity with the web version, the
Supabase schema it targets, the Cowbolt UI seed, and how each app consumes it.

## Theming — bring your host DLS (required)

Guten Chat ships **no design system of its own** — every host app passes a
`GutenChatTheme` built from its **real DLS tokens**. If you mount `GutenChat`
without one, you get a placeholder gray accent and a **prominent debug-console
warning** (debug builds only): the unthemed default must never ship.

```dart
GutenChat(
  theme: const GutenChatTheme(
    accentColor: Color(0xFF04AA72),          // your DLS accent (required in practice)
    appearance: GutenChatAppearance.dark,
    // Optional host tokens — anything omitted derives a sane default
    // from the accent + the shared foundation tokens:
    // backgroundColor, surfaceColor,
    // sentBubbleColor, receivedBubbleColor, sentTextColor, receivedTextColor,
    // fontFamily, borderRadius
  ),
  ...
)
```

- **Minimum viable theme:** `accentColor` (+ `appearance`). Outgoing bubbles,
  send affordances, and active states derive from it; everything else uses the
  shared `foundation/design/tokens.json` neutrals, value-identical to the web
  module.
- **Full DLS adoption:** override surfaces, bubbles, `fontFamily`, and
  `borderRadius` when your design system diverges from the shipped neutrals.
- **Reference integration:** Fysigo passes
  `GutenChatTheme(accentColor: Color(0xFF04AA72), appearance: GutenChatAppearance.dark)`
  here and the matching `accent="#04AA72" theme="dark"` to web
  `<GutenChat/>` — it pins `guten_chat` **v0.7.0+** (design parity with web
  v0.5.0). Same rule on both SDKs: the host DLS is applied from day one.

## iOS permissions (host app)

When using camera/gallery attachments, the consuming app must add to `Info.plist`:

- `NSCameraUsageDescription` — in-app photo capture
- `NSPhotoLibraryUsageDescription` — gallery picks

The package handles permission-denied errors gracefully (SnackBar, no crash).

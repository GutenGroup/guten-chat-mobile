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

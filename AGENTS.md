# AGENTS.md: guten-chat-mobile

Read this before editing. **This repo is PUBLIC.** The Flutter chat package
(`guten_chat`) for Guten Group mobile apps — the sibling of Guten Chat Web
(`GutenGroup/guten-chat`, the `@gutengroup/chat-*` packages). Both skins target
the same Supabase `chat_*` schema, so a message is one conversation on web and
mobile. `BUILD_SPEC.md` is the contract: feature parity with web, the schema it
targets, and how each app consumes the package.

## Stack + run/verify

Flutter >=3.24 / Dart >=3.4 (`pubspec.yaml`; supabase_flutter, flutter_bloc).

- `flutter pub get` — at repo root AND in `example/`.
- `flutter analyze` — root and `example/` (CI runs both).
- `flutter test` — the verify gate (bloc_test + mocktail).
- `cd example && flutter build apk --debug` — the compile gate CI runs.
- CI (`.github/workflows/ci.yml`) = analyze + test + example Android/iOS builds
  on every push/PR. Green CI = done.

## Conventions (hard)

- PUBLIC repo: never commit secrets, Supabase keys or project URLs, internal
  hostnames, or private product context. Credentials live in host apps and CI
  secrets, never here.
- The backend is the shared `chat_*` Supabase schema. The canonical DDL lives
  in guten-chat (`packages/schema`) — never invent or alter schema from this
  side; writes go through the SECURITY DEFINER RPCs listed in `BUILD_SPEC.md`.
- Theming: this package ships NO design system. Hosts pass a `GutenChatTheme`
  built from their own DLS tokens; the gray unthemed placeholder warns loudly
  in debug builds by design — don't silence it, and never ship it.
- Keep feature parity with the web package per `BUILD_SPEC.md`. Land matching
  changes in both repos or record the gap in the spec.

## Gotchas

- Live-schema column-name drift has crashed conversations before (0.8.1 fix) —
  parse rows defensively against the real schema, not assumptions.
- Camera/gallery attachments require host-app `Info.plist` permission strings
  (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) — package-side
  code cannot fix a missing one; the README documents them.
- `example/` has its own pubspec and analysis — a green root build can still
  break the example; CI checks both, so should you.

## Git

Confirm before commit/push. Daniel handles git.

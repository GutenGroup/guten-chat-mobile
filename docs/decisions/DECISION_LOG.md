# Guten Chat — Decision Log

System of record for architecture, UX, and release decisions across the Guten Chat module (this repo + its sibling — `guten-chat` web and `guten-chat-mobile`). Newest at top. Companion to Daniel's brain Decision Journal (the "why"). **Append an entry whenever a non-trivial decision is made — what, why, and the alternatives rejected.** Update the Version History on every release.

---

## Architecture & ownership
- **Agnostic module, repos-first — HARD DECK (2026-07-03).** All chat functionality is built HERE (in the module repos) and *consumed* by the host app — NEVER edited directly in the host (Fysigo). Rationale: this proves and exercises the module→host route so the identical chat drops into any product (Fysigo, Techpool, Cowbolt); building in the host forks the code and the route rots. Web UI lives in `@gutengroup/chat-react` (headless hooks **and** exported components, incl. a top-level `<GutenChat>`); mobile in the `guten_chat` Flutter package. Hosts pass adapters (Supabase client, feature flags, accent token, profileLookup).
- **Two repos, not one:** `guten-chat` (React/TS monorepo: `core` logic, `react` UI, `schema` SQL) + `guten-chat-mobile` (Flutter). Chosen over a monorepo because the toolchains differ.
- **Full relocation first:** the entire web chat UI was moved OUT of Fysigo INTO the module before any new features were added — so the agnostic route is real, not half-wired.
- **Base is black & white; the accent is the ONLY brand colour**, injected by the host (`--accent` on web, `GutenChatTheme.accentColor` on mobile). System light/dark, scoped to a `[data-guten-chat]` wrapper on web so it never flips the host app.

## UX decisions (2026-07-03, from live TestFlight feedback)
- **Message tap = iMessage/WhatsApp context menu** — the tapped message lifts + backdrop blurs, a reactions row floats above, an action list below (Reply · Copy · Tip · Forward · Delete). Replaced an earlier broken floating bar ("looks like shit").
- **Composer leading control = `+` (attach), NOT a tip button.** `+` opens an Instant-Capture-style multi-choice menu: **Voice note · Photo · Camera · HTML file · File**.
- **Tipping lives in the message context menu** (received messages only, feature-gated), not the composer. Preset amounts **$1 / $3 / $5 / $10** (chosen over $2/5/10/25 and $5/10/20/50 — the low ladder maximises tap-rate).
- **Attachment rendering:** image inline; **HTML file → its own sandboxed rendered card**; **PDF → its own rendered card** (like HTML, not a plain chip); other files → file chip; voice note → audio-player bubble.
- **Naming / nav:** bottom bar Updates · Chats · Communities · Profile; "Messages" → "Chats" (bubble icon); "paid groups" → "Communities" (free or paid).

## Sequencing decisions
- **Voice notes deferred on mobile (2026-07-03):** the `record` package's `record_linux` transitive is incompatible with its platform interface and breaks the iOS compile. Decision: ship every other fix first (build 15), add voice notes as a follow-on using `flutter_sound`. Web voice uses the browser's `MediaRecorder` — no dependency conflict, so web keeps it.

## Backend
- Attachments use the existing `chat_message_attachments` table (kind ∈ image | voice_note | file; storage_path, duration_ms, width_px, height_px) + private Storage bucket `chat-attachments` (participant-gated RLS). A non-text message = a `chat_messages` row (+ optional caption) plus attachment child rows; there is **no** kind column on `chat_messages` itself.

## Release / CI operational rules (learned the hard way, 2026-07-03)
- **CI MUST actually compile the target.** The mobile CI ran only `flutter analyze`, which passed while `flutter build ios` FAILED — a broken build reached a TestFlight attempt. Every mobile PR must run `flutter build ios --no-codesign` (or equivalent) as a **required** check. `analyze` alone is theater.
- **Web publish (`publish.yml`, GitHub Packages, tag-triggered)** publishes core+react+schema and:
  - **409s if ANY package version already exists** → bump all three to the same new version each release.
  - **401s if a package's intra-repo dependency version ≠ the local workspace version** (e.g. `react` depending on `@gutengroup/chat-core: "0.1.1"` while core is `0.2.0`): npm then fetches that dep from the registry and the read auth fails. Keep intra-repo deps pinned to the current lockstep version.
- **Version lockstep:** core, react, schema share one version; bump together.

## Version history
| Version | Repo | What |
|---|---|---|
| 0.1.0–0.1.1 | guten-chat | initial module; web UI still in-Fysigo |
| **0.2.0** | guten-chat | web chat UI **relocated into the module** (agnostic, no behavior change) |
| 0.3.0 *(in progress)* | guten-chat | attachments + iMessage context menu + `+` attach menu (web) |
| 0.2.0 | guten-chat-mobile | black-first redesign, theme-agnostic accent, liquid-glass bottom bar |
| **0.3.0** | guten-chat-mobile | attach menu (camera/photo/file), HTML + PDF cards, tip picker $1/3/5/10 → **TestFlight build 14** |
| 0.4.0 | guten-chat-mobile | iMessage context menu + `+` attach + tip-in-menu + voice notes; **BROKEN iOS compile** (record pkg) — not shipped |
| 0.4.1 *(in progress)* | guten-chat-mobile | 0.4.0 minus voice notes; iOS-compile-gated → **TestFlight build 15** |
| 0.4.2 *(planned)* | guten-chat-mobile | voice notes via `flutter_sound` |

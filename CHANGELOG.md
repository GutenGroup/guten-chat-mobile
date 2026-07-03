# Changelog

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

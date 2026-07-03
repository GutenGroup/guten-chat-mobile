# Changelog

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

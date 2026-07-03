# Changelog

## 0.4.0

### Added
- iMessage-class message context menu on tap/long-press: lifted bubble, blurred backdrop, quick reactions (❤️ 😂 👍 ‼️ 🙏 + full emoji picker), and action sheet (Reply, Copy, Tip, Forward, Delete).
- Composer bottom-left `+` attach menu with labeled speed-dial pills: Voice note, Photo, Camera, HTML file, File.
- Voice note recording (`record`) and playback bubble with waveform (`just_audio`).
- Message forward and delete actions.
- Dev build-stamp messages (commit hash banners) hidden in release builds.

### Changed
- Tipping moved from composer/per-bubble affordance to message context menu only.
- Attach menu uses Techpool-style labeled pills for all attachment types.

### Removed
- Inline `MessageTipAffordance` beside received bubbles.

### iOS (host app)
Consuming apps must declare in `Info.plist`:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMicrophoneUsageDescription` (for voice notes)

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

# Changelog

## 0.3.0

### Added
- Composer bottom-left attach button with hand-rolled expanding menu (camera, gallery, file).
- Attachment send pipeline: upload to `chat-attachments`, insert message + attachment rows, optimistic UI with upload progress.
- Message rendering for images (inline thumbnail + fullscreen viewer), HTML files (`HtmlDocumentCard` with sandboxed WebView preview), and generic file chips.
- Per-message tip affordance with expanding preset amounts via existing `chat_send_tip` RPC (gated by `ChatFeatures.tipping`).
- Dependencies: `image_picker`, `file_picker`, `webview_flutter`.

### iOS (host app)
Consuming apps must declare in `Info.plist`:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## 0.2.0

- Black-first redesign with theme-agnostic accent injection.

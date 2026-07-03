import 'dart:io';

import 'package:flutter/foundation.dart';

String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String inferExtension(String fileName, {String? mimeType}) {
  final dot = fileName.lastIndexOf('.');
  if (dot > 0 && dot < fileName.length - 1) {
    return fileName.substring(dot + 1).toLowerCase();
  }
  if (mimeType == null) {
    return 'bin';
  }
  return switch (mimeType) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/gif' => 'gif',
    'image/webp' => 'webp',
    'text/html' => 'html',
    'application/pdf' => 'pdf',
    _ => 'bin',
  };
}

String inferMimeType(String fileName) {
  final ext = inferExtension(fileName);
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'html' || 'htm' => 'text/html',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}

Future<(int width, int height)?> readImageDimensions(Uint8List bytes) async {
  try {
    return await compute(_decodeImageDimensions, bytes);
  } catch (_) {
    return null;
  }
}

(int width, int height)? _decodeImageDimensions(Uint8List bytes) {
  if (bytes.length < 24) {
    return null;
  }

  // PNG
  if (bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    return (width, height);
  }

  // JPEG — scan for SOF marker
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
    var offset = 2;
    while (offset + 9 < bytes.length) {
      if (bytes[offset] != 0xFF) {
        break;
      }
      final marker = bytes[offset + 1];
      if (marker == 0xC0 || marker == 0xC2) {
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return (width, height);
      }
      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (length < 2) {
        break;
      }
      offset += length + 2;
    }
  }

  return null;
}

bool isLocalAttachmentPath(String path) {
  return path.startsWith('/') || path.contains(Platform.pathSeparator);
}

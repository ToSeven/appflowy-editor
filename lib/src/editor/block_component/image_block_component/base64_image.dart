import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

Image imageFromBase64String(String base64String, {double? width}) {
  return Image.memory(
    base64Decode(base64String),
    width: width,
  );
}

Uint8List dataFromBase64String(String base64String) {
  return base64Decode(base64String);
}

String base64String(Uint8List data) {
  return base64Encode(data);
}

Future<String> base64StringFromImage(String imagePath) async {
  final file = File(imagePath); //convert Path to File
  final imageBytes = await file.readAsBytes(); //convert to bytes

  return base64.encode(imageBytes);
}

/// Safely decodes a base64 string, returning `null` on failure instead of
/// throwing [FormatException].
///
/// Use this anywhere user-provided / untrusted base64 data is decoded so a
/// malformed string never crashes the editor.
Uint8List? tryDecodeBase64(String base64String) {
  try {
    return base64Decode(base64String);
  } catch (_) {
    return null;
  }
}

/// Returns true if [src] is a base64 data-URL image.
///
/// Examples that return true:
///   `data:image/png;base64,iVBOR...`
///   `data:image/jpeg;base64,/9j/...`
bool isDataUrl(String src) => src.startsWith('data:image/');

/// Extracts the raw base64 payload from a `data:image/...;base64,` URL.
/// Returns `null` if the prefix is missing or the payload is empty.
String? extractBase64FromDataUrl(String src) {
  final commaIndex = src.indexOf(',');
  if (commaIndex < 0 || commaIndex == src.length - 1) {
    return null;
  }
  final payload = src.substring(commaIndex + 1);
  return payload.isEmpty ? null : payload;
}

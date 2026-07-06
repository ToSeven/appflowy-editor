import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/block_component/image_block_component/base64_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('imageNode / ImageBlockKeys', () {
    test('default node has center align, null dimensions, no alt', () {
      final node = imageNode(url: 'https://example.com/a.png');
      expect(node.type, ImageBlockKeys.type);
      expect(node.type, 'image');
      expect(node.attributes[ImageBlockKeys.url], 'https://example.com/a.png');
      expect(node.attributes[ImageBlockKeys.align], 'center');
      expect(node.attributes[ImageBlockKeys.width], isNull);
      expect(node.attributes[ImageBlockKeys.height], isNull);
      expect(node.attributes.containsKey(ImageBlockKeys.alt), isFalse);
    });

    test('node preserves alt, align, and dimensions', () {
      final node = imageNode(
        url: 'https://example.com/a.png',
        align: 'left',
        alt: 'A diagram',
        width: 200.0,
        height: 100.0,
      );
      expect(node.attributes[ImageBlockKeys.align], 'left');
      expect(node.attributes[ImageBlockKeys.alt], 'A diagram');
      expect(node.attributes[ImageBlockKeys.width], 200.0);
      expect(node.attributes[ImageBlockKeys.height], 100.0);
    });

    test('alt is omitted from attributes when null', () {
      final node = imageNode(url: 'x');
      expect(node.attributes.containsKey(ImageBlockKeys.alt), isFalse);
    });
  });

  group('image markdown round-trip', () {
    test('document -> markdown preserves url + alt', () {
      final doc = Document.blank()
        ..insert([0], [
          imageNode(
            url: 'https://example.com/a.png',
            alt: 'Caption',
          ),
        ]);

      final md = documentToMarkdown(doc);
      expect(md, contains('![Caption]'));
      expect(md, contains('(https://example.com/a.png)'));
    });

    test('document -> markdown preserves dimensions', () {
      final doc = Document.blank()
        ..insert([0], [
          imageNode(
            url: 'https://example.com/a.png',
            width: 300.0,
            height: 150.0,
          ),
        ]);

      final md = documentToMarkdown(doc);
      expect(md, contains('=300x150'));
    });

    test('document -> markdown preserves width only', () {
      final doc = Document.blank()
        ..insert([0], [
          imageNode(
            url: 'https://example.com/a.png',
            width: 200.0,
          ),
        ]);

      final md = documentToMarkdown(doc);
      // Width-only produces "=200" suffix (no "xNNN" height component).
      expect(md, contains('=200'));
      expect(md, isNot(contains('=200x')));
    });
  });

  group('base64 safe decode helpers', () {
    test('tryDecodeBase64 returns bytes for valid input', () {
      // "hi" in base64
      const valid = 'aGk=';
      final result = tryDecodeBase64(valid);
      expect(result, isNotNull);
      expect(result!.length, 2);
    });

    test('tryDecodeBase64 returns null for invalid input', () {
      const invalid = '!!!not-base64!!!';
      final result = tryDecodeBase64(invalid);
      expect(result, isNull);
    });

    test('isDataUrl detects data image URLs', () {
      expect(isDataUrl('data:image/png;base64,iVBOR'), isTrue);
      expect(isDataUrl('data:image/jpeg;base64,/9j/'), isTrue);
      expect(isDataUrl('https://example.com/a.png'), isFalse);
      expect(isDataUrl(''), isFalse);
    });

    test('extractBase64FromDataUrl returns payload', () {
      const src = 'data:image/png;base64,iVBORw0KGgo=';
      expect(extractBase64FromDataUrl(src), 'iVBORw0KGgo=');
    });

    test('extractBase64FromDataUrl returns null for malformed', () {
      expect(extractBase64FromDataUrl('data:image/png;base64,'), isNull);
      expect(extractBase64FromDataUrl('not-a-data-url'), isNull);
    });
  });
}

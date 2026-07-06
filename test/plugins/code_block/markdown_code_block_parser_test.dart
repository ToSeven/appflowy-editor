import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the fenced-code-block Markdown decoder parser and the
/// markdown <-> document round-trip.
void main() {
  group('MarkdownCodeBlockParserV2', () {
    final parser = DocumentMarkdownDecoder(
      markdownElementParsers: const [
        MarkdownCodeBlockParserV2(),
      ],
    );

    test('fenced code with language becomes a code node', () {
      const md = '```python\nprint("hello")\nprint("world")\n```';
      final doc = parser.convert(md);
      final node = doc.nodeAtPath([0]);
      expect(node, isNotNull);
      expect(node!.type, CodeBlockKeys.type);
      expect(node.attributes[CodeBlockKeys.language], 'python');
      expect(node.delta!.toPlainText(), 'print("hello")\nprint("world")');
    });

    test('fenced code without language leaves language null', () {
      const md = '```\nplain code\n```';
      final doc = parser.convert(md);
      final node = doc.nodeAtPath([0]);
      expect(node, isNotNull);
      expect(node!.type, CodeBlockKeys.type);
      expect(node.attributes[CodeBlockKeys.language], isNull);
      expect(node.delta!.toPlainText(), 'plain code');
    });

    test('non-pre elements are ignored by the parser', () {
      final doc = parser.convert('# A heading');
      // The parser list only contains the code parser, so a heading is not
      // converted to any known node.
      expect(doc.root.children, isEmpty);
    });

    test('trailing newline in fenced content is trimmed', () {
      const md = '```js\nconst x = 1;\n\n\n```';
      final doc = parser.convert(md);
      final node = doc.nodeAtPath([0]);
      expect(node, isNotNull);
      // trimRight strips the trailing blank lines / newline.
      expect(node!.delta!.toPlainText(), 'const x = 1;');
    });
  });

  group('code block markdown round-trip', () {
    test('document -> markdown -> document preserves code + language', () {
      final original = Document.blank()
        ..insert([0], [
          codeBlockNode(
            language: 'dart',
            delta: Delta()..insert('void main() {}'),
          ),
        ]);

      final markdown = documentToMarkdown(original);
      // The encoder emits ```dart\nvoid main() {}\n```.
      expect(markdown, contains('```dart'));
      expect(markdown, contains('void main() {}'));

      final decoded = markdownToDocument(markdown);
      final node = decoded.nodeAtPath([0]);
      expect(node, isNotNull);
      expect(node!.type, CodeBlockKeys.type);
      expect(node.attributes[CodeBlockKeys.language], 'dart');
      expect(node.delta!.toPlainText(), 'void main() {}');
    });

    test('round-trip preserves multi-line content', () {
      const content = 'line one\nline two\nline three';
      final original = Document.blank()
        ..insert([0], [
          codeBlockNode(
            language: 'python',
            delta: Delta()..insert(content),
          ),
        ]);

      final markdown = documentToMarkdown(original);
      final decoded = markdownToDocument(markdown);
      final node = decoded.nodeAtPath([0]);
      expect(node, isNotNull);
      expect(node!.delta!.toPlainText(), content);
    });
  });
}

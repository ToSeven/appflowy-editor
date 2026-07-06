import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('codeBlockNode / CodeBlockKeys', () {
    test('default node has empty delta and null language', () {
      final node = codeBlockNode();
      expect(node.type, CodeBlockKeys.type);
      expect(node.type, 'code');
      expect(node.attributes[CodeBlockKeys.language], isNull);
      expect(node.delta, isNotNull);
      expect(node.delta!.toPlainText(), isEmpty);
      expect(node.attributes.containsKey(CodeBlockKeys.indentSize), isFalse);
    });

    test('node preserves delta and language', () {
      final node = codeBlockNode(
        delta: Delta()..insert('print("hi")'),
        language: 'python',
      );
      expect(node.attributes[CodeBlockKeys.language], 'python');
      expect(node.delta!.toPlainText(), 'print("hi")');
    });

    test('indentSize is only set when explicitly provided', () {
      // omitted -> attribute absent (handlers default to 2)
      final withoutIndent = codeBlockNode();
      expect(
        withoutIndent.attributes.containsKey(CodeBlockKeys.indentSize),
        isFalse,
      );

      // provided -> attribute present
      final withIndent = codeBlockNode(indentSize: 4);
      expect(withIndent.attributes[CodeBlockKeys.indentSize], 4);
    });

    test('CodeBlockKeys constants are stable string values', () {
      // These values are part of the serialization format and must not drift.
      expect(CodeBlockKeys.type, 'code');
      expect(CodeBlockKeys.delta, 'delta');
      expect(CodeBlockKeys.language, 'language');
      expect(CodeBlockKeys.indentSize, 'indent_size');
    });
  });
}

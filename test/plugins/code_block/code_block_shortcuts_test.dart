import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an [EditorState] containing a single code block node at path [0]
/// with the given [text], [language] and optional [indentSize].
EditorState _codeBlockEditorState(
  String text, {
  String? language,
  int? indentSize,
}) {
  final document = Document.blank()
    ..insert([0], [
      codeBlockNode(
        language: language,
        indentSize: indentSize,
        delta: Delta()..insert(text),
      ),
    ]);
  return EditorState(document: document);
}

void _select(EditorState editorState, String text) {
  editorState.selection = Selection(
    start: Position(path: [0], offset: 0),
    end: Position(path: [0], offset: text.length),
  );
}

void main() {
  group('indent / outdent in code block', () {
    test('tab indents every selected line by 2 spaces by default', () {
      const text = 'line1\nline2\nline3';
      final editorState = _codeBlockEditorState(text);
      _select(editorState, text);

      final result =
          tabToInsertSpacesInCodeBlockCommand('').execute(editorState);

      expect(result, KeyEventResult.handled);
      final after = editorState.getNodeAtPath([0])!;
      expect(after.delta!.toPlainText(), '  line1\n  line2\n  line3');
    });

    test('shift+tab removes 2 spaces from every selected indented line', () {
      const text = '  line1\n  line2';
      final editorState = _codeBlockEditorState(text);
      _select(editorState, text);

      final result =
          tabToDeleteSpacesInCodeBlockCommand('').execute(editorState);

      expect(result, KeyEventResult.handled);
      final after = editorState.getNodeAtPath([0])!;
      expect(after.delta!.toPlainText(), 'line1\nline2');
    });

    test('indent respects CodeBlockKeys.indentSize when set', () {
      const text = 'line1\nline2';
      final editorState = _codeBlockEditorState(text, indentSize: 4);
      _select(editorState, text);

      tabToInsertSpacesInCodeBlockCommand('').execute(editorState);

      final after = editorState.getNodeAtPath([0])!;
      expect(after.delta!.toPlainText(), '    line1\n    line2');
    });

    test('indent is ignored when selection is collapsed', () {
      const text = 'line1\nline2';
      final editorState = _codeBlockEditorState(text);
      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 2),
      );

      final result =
          tabToInsertSpacesInCodeBlockCommand('').execute(editorState);

      // Collapsed selection must fall through (handled by the other tab event).
      expect(result, KeyEventResult.ignored);
      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        text,
      );
    });

    test('indent is ignored outside a code block', () {
      final document = Document.blank()
        ..insert([0], [paragraphNode(delta: Delta()..insert('hello'))]);
      final editorState = EditorState(document: document);
      editorState.selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [0], offset: 5),
      );

      final result =
          tabToInsertSpacesInCodeBlockCommand('').execute(editorState);
      expect(result, KeyEventResult.ignored);
    });
  });

  group('toggle line comment (ctrl+/)', () {
    test('adds // prefix to selected lines for C-like languages', () {
      const text = 'line1\nline2';
      final editorState = _codeBlockEditorState(text, language: 'dart');
      _select(editorState, text);

      final result =
          toggleCommentInCodeBlockCommand('').execute(editorState);

      expect(result, KeyEventResult.handled);
      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        '// line1\n// line2',
      );
    });

    test('uses # for hash-comment languages (python)', () {
      const text = 'line1\nline2';
      final editorState = _codeBlockEditorState(text, language: 'python');
      _select(editorState, text);

      toggleCommentInCodeBlockCommand('').execute(editorState);

      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        '# line1\n# line2',
      );
    });

    test('toggling twice restores the original content', () {
      const text = 'line1\nline2';
      final editorState = _codeBlockEditorState(text, language: 'javascript');
      _select(editorState, text);

      toggleCommentInCodeBlockCommand('').execute(editorState);
      // re-select the full (now longer) range before toggling back
      final commented = editorState.getNodeAtPath([0])!.delta!.toPlainText();
      _select(editorState, commented);
      toggleCommentInCodeBlockCommand('').execute(editorState);

      expect(
        editorState.getNodeAtPath([0])!.delta!.toPlainText(),
        text,
      );
    });
  });
}

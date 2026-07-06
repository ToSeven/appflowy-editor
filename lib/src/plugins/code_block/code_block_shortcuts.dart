import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'code_block_component.dart';
import 'code_block_localization.dart';

final List<CharacterShortcutEvent> codeBlockCharacterEvents = [
  enterInCodeBlock,
  ...ignoreKeysInCodeBlock,
];

List<CommandShortcutEvent> codeBlockCommands({
  CodeBlockLocalizations localizations = const CodeBlockLocalizations(),
}) =>
    [
      insertNewParagraphNextToCodeBlockCommand(
        localizations.codeBlockNewParagraph,
      ),
      pasteInCodeblock(localizations.codeBlockPasteText),
      selectAllInCodeBlockCommand(localizations.codeBlockSelectAll),
      tabToInsertSpacesInCodeBlockCommand(localizations.codeBlockIndentLines),
      tabToDeleteSpacesInCodeBlockCommand(localizations.codeBlockOutdentLines),
      tabSpacesAtCurosrInCodeBlockCommand(localizations.codeBlockAddTwoSpaces),
      toggleCommentInCodeBlockCommand(localizations.codeBlockToggleComment),
    ];

/// Press the enter key in code block to insert a new line in it.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CharacterShortcutEvent enterInCodeBlock = CharacterShortcutEvent(
  key: 'press enter in code block',
  character: '\n',
  handler: _enterInCodeBlockCommandHandler,
);

/// Ignore ' ', '/', '_', '*' in code block.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final List<CharacterShortcutEvent> ignoreKeysInCodeBlock =
    [' ', '/', '_', '*', '~', '-']
        .map(
          (e) => CharacterShortcutEvent(
            key: 'ignore keys in code block',
            character: e,
            handler: (editorState) =>
                _ignoreKeysInCodeBlockCommandHandler(editorState, e),
          ),
        )
        .toList();

/// Shift+enter to insert a new node next to the code block.
///
/// - support
///   - desktop
///   - web
///
CommandShortcutEvent insertNewParagraphNextToCodeBlockCommand(
  String description,
) =>
    CommandShortcutEvent(
      key: 'insert a new paragraph next to the code block',
      command: 'shift+enter',
      getDescription: () => description,
      handler: _insertNewParagraphNextToCodeBlockCommandHandler,
    );

/// Tab to insert two spaces at the cursor if selection is collapsed.
///
/// - support
///   - desktop
///   - web
CommandShortcutEvent tabSpacesAtCurosrInCodeBlockCommand(String description) =>
    CommandShortcutEvent(
      key: 'tab to insert two spaces at the cursor in code block',
      command: 'tab',
      getDescription: () => description,
      handler: (editorState) =>
          _addTwoSpacesInCodeBlockCommandHandler(editorState),
    );

/// Tab to insert two spaces at the line start in code block,
/// if there is more than one line selected.
///
/// - support
///   - desktop
///   - web
CommandShortcutEvent tabToInsertSpacesInCodeBlockCommand(String description) =>
    CommandShortcutEvent(
      key: 'tab to insert two spaces at the line start in code block',
      command: 'tab',
      getDescription: () => description,
      handler: (editorState) => _indentationInCodeBlockCommandHandler(
        editorState,
        true,
      ),
    );

/// Shift+tab to delete two spaces at the line start in code block if needed.
///
/// - support
///   - desktop
///   - web
CommandShortcutEvent tabToDeleteSpacesInCodeBlockCommand(
  String description,
) =>
    CommandShortcutEvent(
      key: 'shift + tab to delete two spaces at the line start in code block',
      command: 'shift+tab',
      getDescription: () => description,
      handler: (editorState) => _indentationInCodeBlockCommandHandler(
        editorState,
        false,
      ),
    );

/// CTRL+A to select all content inside a Code Block, if cursor is inside one.
///
/// - support
///   - desktop
///   - web
CommandShortcutEvent selectAllInCodeBlockCommand(
  String description,
) =>
    CommandShortcutEvent(
      key: 'ctrl + a to select all content inside a code block',
      command: 'ctrl+a',
      macOSCommand: 'meta+a',
      getDescription: () => description,
      handler: _selectAllInCodeBlockCommandHandler,
    );

/// ctrl + v to paste text in code block.
///
/// - support
///   - desktop
///   - web
CommandShortcutEvent pasteInCodeblock(
  String description,
) =>
    CommandShortcutEvent(
      key: 'paste in codeblock',
      command: 'ctrl+v',
      macOSCommand: 'cmd+v',
      getDescription: () => description,
      handler: _pasteInCodeBlock,
    );

/// ctrl + / (cmd + / on macOS) to toggle line comments in a code block.
///
/// The comment syntax is chosen based on the block's language (`#` for
/// python/bash/ruby/etc., `//` for the rest as a sane default).
///
/// - support
///   - desktop
///   - web
CommandShortcutEvent toggleCommentInCodeBlockCommand(String description) =>
    CommandShortcutEvent(
      key: 'toggle line comment in code block',
      command: 'ctrl+/',
      macOSCommand: 'cmd+/',
      getDescription: () => description,
      handler: _toggleCommentInCodeBlockCommandHandler,
    );

CharacterShortcutEventHandler _enterInCodeBlockCommandHandler =
    (editorState) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != CodeBlockKeys.type) {
    return false;
  }

  final lines = node.delta?.toPlainText().split('\n');
  int spaces = 0;
  if (lines?.isNotEmpty == true) {
    int index = 0;
    for (final line in lines!) {
      if (index <= selection.endIndex &&
          selection.endIndex <= index + line.length) {
        final lineSpaces = line.length - line.trimLeft().length;
        spaces = lineSpaces;
        break;
      }
      index += line.length + 1;
    }
  }

  final transaction = editorState.transaction
    ..insertText(
      node,
      selection.end.offset,
      '\n${' ' * spaces}',
    );
  await editorState.apply(transaction);
  return true;
};

Future<bool> _ignoreKeysInCodeBlockCommandHandler(
  EditorState editorState,
  String key,
) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null || node.type != CodeBlockKeys.type) {
    return false;
  }
  await editorState.insertTextAtCurrentSelection(key);
  return true;
}

CommandShortcutEventHandler _insertNewParagraphNextToCodeBlockCommandHandler =
    (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }
  final sliced = delta.slice(selection.startIndex);
  final transaction = editorState.transaction
    ..deleteText(
      // delete the text after the cursor in the code block
      node,
      selection.startIndex,
      delta.length - selection.startIndex,
    )
    ..insertNode(
      // insert a new paragraph node with the sliced delta after the code block
      selection.end.path.next,
      paragraphNode(attributes: {'delta': sliced.toJson()}),
    )
    ..afterSelection = Selection.collapsed(
      Position(path: selection.end.path.next),
    );
  editorState.apply(transaction);
  return KeyEventResult.handled;
};

KeyEventResult _addTwoSpacesInCodeBlockCommandHandler(
  EditorState editorState,
) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  final indentSize = node.attributes[CodeBlockKeys.indentSize] as int? ?? 2;
  final spaces = ' ' * indentSize;

  final transaction = editorState.transaction
    ..insertText(node, selection.end.offset, spaces);

  editorState.apply(transaction);

  return KeyEventResult.handled;
}

KeyEventResult _indentationInCodeBlockCommandHandler(
  EditorState editorState,
  bool shouldIndent,
) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  final indentSize = node.attributes[CodeBlockKeys.indentSize] as int? ?? 2;
  final spaces = ' ' * indentSize;
  final lines = delta.toPlainText().split('\n');
  int index = 0;

  // We store indexes to be indented in a list, because we should
  // indent it in a reverse order to not mess up the offsets.
  final List<int> transactions = [];
  bool selectionStartsAtLineStart = false;

  for (final line in lines) {
    // When indenting, every line qualifies; when outdenting, only lines that
    // already start with the indent unit do. (Previously this condition relied
    // on && / || precedence and was unreadable; behavior is unchanged.)
    final qualifies = shouldIndent || line.startsWith(spaces);
    if (qualifies) {
      var shouldTransform = index + line.length >= selection.startIndex &&
          selection.endIndex >= index;

      if (shouldIndent && line.trim().isEmpty) {
        shouldTransform = false;
      }

      if (shouldTransform) {
        transactions.add(index);
      }
    }

    if ([index, index + 1].contains(selection.startIndex)) {
      selectionStartsAtLineStart = true;
    }

    index += line.length + 1;
  }

  if (transactions.isEmpty) {
    return KeyEventResult.ignored;
  }

  final transaction = editorState.transaction;

  for (final index in transactions.reversed) {
    shouldIndent
        ? transaction.insertText(node, index, spaces)
        : transaction.deleteText(node, index, spaces.length);
  }

  // In case the selection is made backwards, we store the start
  // and end here, we will adjust the order later
  final start = !selection.isBackward ? selection.end : selection.start;
  final end = !selection.isBackward ? selection.start : selection.end;

  final endOffset = shouldIndent
      ? end.offset + (spaces.length * transactions.length)
      : end.offset - (spaces.length * transactions.length);

  final endSelection = end.copyWith(offset: endOffset);

  final startOffset = shouldIndent
      ? start.offset + spaces.length
      : start.offset - (selectionStartsAtLineStart ? 0 : spaces.length);

  final startSelection = selection.isCollapsed
      ? endSelection
      : start.copyWith(offset: startOffset);

  transaction.afterSelection = selection.copyWith(
    start: selection.isBackward ? startSelection : endSelection,
    end: selection.isBackward ? endSelection : startSelection,
  );

  editorState.apply(transaction);

  return KeyEventResult.handled;
}

CommandShortcutEventHandler _selectAllInCodeBlockCommandHandler =
    (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isSingle) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  editorState.service.selectionService.updateSelection(
    Selection.single(
      path: node.path,
      startOffset: 0,
      endOffset: delta.length,
    ),
  );

  return KeyEventResult.handled;
};

CommandShortcutEventHandler _pasteInCodeBlock = (editorState) {
  final initialSelection = editorState.selection;
  if (initialSelection == null) {
    return KeyEventResult.ignored;
  }

  if (editorState.getNodesInSelection(initialSelection).length != 1) {
    return KeyEventResult.ignored;
  }

  final node = editorState.getNodeAtPath(initialSelection.end.path);
  if (node == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  // Perform the (possibly async) delete + insert off the synchronous handler
  // path. The handler must return KeyEventResult synchronously, so we fire the
  // future deliberately — but wrap it so exceptions are never swallowed.
  unawaited(
    _performCodeBlockPaste(editorState, node, initialSelection),
  );

  return KeyEventResult.handled;
};

Future<void> _performCodeBlockPaste(
  EditorState editorState,
  Node node,
  Selection initialSelection,
) async {
  try {
    // delete the existing selection first, if any.
    if (!initialSelection.isCollapsed) {
      await editorState.deleteSelection(initialSelection);
    }

    // re-fetch selection after the potential delete.
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final data = await AppFlowyClipboard.getData();
    final text = data.text;
    if (text == null || text.isEmpty) {
      return;
    }

    final transaction = editorState.transaction
      ..insertText(node, selection.end.offset, text);

    await editorState.apply(transaction);
  } catch (e, stackTrace) {
    AppFlowyEditorLog.editor.error(
      'paste in code block failed: $e\n$stackTrace',
    );
  }
}

// Languages whose line-comment token is `#`. Everything else defaults to `//`.
const _hashCommentLanguages = <String>{
  'python',
  'bash',
  'shell',
  'sh',
  'ruby',
  'perl',
  'r',
  'yaml',
  'dockerfile',
  'powershell',
  'toml',
  'makefile',
  'gnuplot',
};

KeyEventResult _toggleCommentInCodeBlockCommandHandler(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || node.type != CodeBlockKeys.type) {
    return KeyEventResult.ignored;
  }

  final language = (node.attributes[CodeBlockKeys.language] as String?)
          ?.toLowerCase() ??
      '';
  final commentToken =
      _hashCommentLanguages.contains(language) ? '#' : '//';
  final commentPrefix = '$commentToken ';

  final text = delta.toPlainText();
  final lines = text.split('\n');

  // Collect (lineIndex, absoluteOffset) for each line that overlaps the
  // selection. We mutate in reverse so earlier offsets stay valid.
  final List<int> lineStartOffsets = [];
  int index = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineEnd = index + line.length;
    final overlaps = lineEnd >= selection.startIndex &&
        selection.endIndex > index &&
        line.trim().isNotEmpty;
    if (overlaps) {
      lineStartOffsets.add(index);
    }
    index = lineEnd + 1; // +1 for the '\n'
  }

  if (lineStartOffsets.isEmpty) {
    return KeyEventResult.ignored;
  }

  // Decide whether to comment or uncomment by inspecting the first touched
  // line: if its trimmed content starts with the token, we uncomment;
  // otherwise we comment.
  final firstLine = lines[_lineIndexForOffset(text, lineStartOffsets.first)];
  final alreadyCommented = firstLine.trimLeft().startsWith(commentToken);

  final transaction = editorState.transaction;
  // net change in length, used to fix up the selection afterwards.
  var deltaLen = 0;

  for (final offset in lineStartOffsets.reversed) {
    final lineIndex = _lineIndexForOffset(text, offset);
    final line = lines[lineIndex];
    final leadingWhitespaceLen = line.length - line.trimLeft().length;
    final contentStart = offset + leadingWhitespaceLen;

    if (alreadyCommented) {
      // Remove one occurrence of commentPrefix (token + single trailing
      // space if present) from the start of the line's content.
      final tail = line.substring(leadingWhitespaceLen);
      var removeLen = commentToken.length;
      if (tail.length >= commentPrefix.length &&
          tail.startsWith(commentPrefix)) {
        removeLen = commentPrefix.length;
      }
      transaction.deleteText(node, contentStart, removeLen);
      deltaLen -= removeLen;
    } else {
      transaction.insertText(node, contentStart, commentPrefix);
      deltaLen += commentPrefix.length;
    }
  }

  // Adjust the selection to account for the inserted/removed prefixes.
  final touchedCount = lineStartOffsets.length;
  final start = !selection.isBackward ? selection.end : selection.start;
  final end = !selection.isBackward ? selection.start : selection.end;

  final endOffset = alreadyCommented
      ? end.offset - (commentPrefix.length * touchedCount)
      : end.offset + (commentPrefix.length * touchedCount);
  final startOffset = alreadyCommented
      ? start.offset - commentPrefix.length
      : start.offset + commentPrefix.length;

  transaction.afterSelection = selection.copyWith(
    start: start.copyWith(offset: startOffset.clamp(0, text.length + deltaLen)),
    end: end.copyWith(offset: endOffset.clamp(0, text.length + deltaLen)),
  );

  editorState.apply(transaction);

  return KeyEventResult.handled;
}

/// Returns the index of the line (0-based) that contains the given absolute
/// [offset] within [text].
int _lineIndexForOffset(String text, int offset) {
  var lineIndex = 0;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text[i] == '\n') lineIndex++;
  }
  return lineIndex;
}

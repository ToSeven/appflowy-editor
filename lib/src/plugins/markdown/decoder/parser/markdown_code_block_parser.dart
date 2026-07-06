import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;

/// Converts a Markdown fenced code block into an AppFlowy code node.
///
/// Markdown fenced code blocks (`` ```lang ... ``` ``) are parsed by the
/// `markdown` package into a `<pre><code class="language-<lang>">` element.
/// This parser turns that element into a [codeBlockNode], preserving the
/// language when one is declared.
///
/// It must run BEFORE [MarkdownParagraphParserV2] in the parser list so that
/// `<pre>` elements are claimed here rather than falling through.
///
class MarkdownCodeBlockParserV2 extends CustomMarkdownParser {
  const MarkdownCodeBlockParserV2();

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    if (element is! md.Element || element.tag != 'pre') {
      return [];
    }

    final children = element.children;
    if (children == null || children.isEmpty) {
      return [];
    }

    final code = children.first;
    if (code is! md.Element || code.tag != 'code') {
      return [];
    }

    // The language (if any) is encoded as a class like `language-python`.
    String? language;
    final cls = code.attributes['class'];
    if (cls != null) {
      for (final token in cls.split(' ')) {
        if (token.startsWith('language-')) {
          language = token.substring('language-'.length);
          break;
        }
      }
    }

    return [
      codeBlockNode(
        language: (language == null || language.isEmpty) ? null : language,
        delta: Delta()..insert(code.textContent.trimRight()),
      ),
    ];
  }
}

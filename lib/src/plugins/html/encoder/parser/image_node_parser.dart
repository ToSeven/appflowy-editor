import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:html/dom.dart' as dom;

class HTMLImageNodeParser extends HTMLNodeParser {
  const HTMLImageNodeParser();

  @override
  String get id => ImageBlockKeys.type;

  @override
  String transformNodeToHTMLString(
    Node node, {
    required List<HTMLNodeParser> encodeParsers,
  }) {
    return toHTMLString(
      transformNodeToDomNodes(node, encodeParsers: encodeParsers),
    );
  }

  @override
  List<dom.Node> transformNodeToDomNodes(
    Node node, {
    required List<HTMLNodeParser> encodeParsers,
  }) {
    final url = node.attributes[ImageBlockKeys.url] ?? '';
    final alt = node.attributes[ImageBlockKeys.alt] ?? '';
    final height = node.attributes[ImageBlockKeys.height];
    final width = node.attributes[ImageBlockKeys.width];
    final align = node.attributes[ImageBlockKeys.align] as String?;

    final img = dom.Element.tag(HTMLTags.image)
      ..attributes['src'] = url
      ..attributes['alt'] = alt;

    if (height != null) {
      img.attributes['height'] = height.toString();
    }
    if (width != null) {
      img.attributes['width'] = width.toString();
    }

    // Wrap in a <div> with CSS text-align instead of the deprecated
    // <img align="..."> attribute (removed in HTML5).
    if (align == 'left' || align == 'right') {
      final wrapper = dom.Element.tag('div')
        ..attributes['style'] = 'text-align:$align';
      wrapper.append(img);
      return [
        wrapper,
        ...processChildrenNodes(
          node.children.toList(),
          encodeParsers: encodeParsers,
        ),
      ];
    }

    // center or null — center is the default for <div>, so we don't need
    // an explicit wrapper.
    return [
      img,
      ...processChildrenNodes(
        node.children.toList(),
        encodeParsers: encodeParsers,
      ),
    ];
  }
}

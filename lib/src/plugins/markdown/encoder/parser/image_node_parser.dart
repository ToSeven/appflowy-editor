import 'package:appflowy_editor/appflowy_editor.dart';

class ImageNodeParser extends NodeParser {
  const ImageNodeParser();

  @override
  String get id => ImageBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final url = node.attributes[ImageBlockKeys.url] ?? '';
    final alt = node.attributes[ImageBlockKeys.alt] ?? '';
    final width = node.attributes[ImageBlockKeys.width]?.toDouble();
    final height = node.attributes[ImageBlockKeys.height]?.toDouble();

    // Preserve alt text and optional dimensions using the CommonMark image
    // size extension: ![alt](url =widthxheight). Without this, round-tripping
    // through markdown would silently discard alt and resize info.
    String suffix = '';
    if (width != null && height != null) {
      suffix = ' =${width.toInt()}x${height.toInt()}';
    } else if (width != null) {
      suffix = ' =${width.toInt()}';
    }

    return '![$alt]($url$suffix)';
  }
}

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

import 'base64_image.dart';

/// The kind of image source, resolved once from [src] to avoid re-parsing on
/// every build.
enum _ImageSourceKind { network, dataUrl, base64, file, invalid }

class ResizableImage extends StatefulWidget {
  const ResizableImage({
    super.key,
    required this.alignment,
    required this.editable,
    required this.onResize,
    required this.width,
    required this.src,
    this.height,
  });

  final String src;
  final double width;
  final double? height;
  final Alignment alignment;
  final bool editable;

  final void Function(double width) onResize;

  @override
  State<ResizableImage> createState() => _ResizableImageState();
}

const _kImageBlockComponentMinWidth = 30.0;

class _ResizableImageState extends State<ResizableImage> {
  late double imageWidth;

  double initialOffset = 0;
  double moveDistance = 0;

  // Hover state isolated into a ValueNotifier so enter/exit don't rebuild the
  // whole image widget — only the resize handles listen to it.
  final _hoverNotifier = ValueNotifier<bool>(false);

  // The resolved source kind, recomputed when [src] changes.
  _ImageSourceKind _kind = _ImageSourceKind.invalid;

  // Cached decoded bytes for base64 sources. Invalidated when src changes.
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    imageWidth = widget.width;
    _resolveSource();
  }

  @override
  void didUpdateWidget(covariant ResizableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate cache + re-resolve when the source changes (e.g. replacing an
    // image). Previously the cached Image widget survived src changes.
    if (oldWidget.src != widget.src) {
      _decodedBytes = null;
      _resolveSource();
    }
    if (oldWidget.width != widget.width) {
      imageWidth = widget.width;
    }
  }

  @override
  void dispose() {
    _hoverNotifier.dispose();
    super.dispose();
  }

  void _resolveSource() {
    final src = widget.src;
    if (isDataUrl(src)) {
      _kind = _ImageSourceKind.dataUrl;
      final payload = extractBase64FromDataUrl(src);
      _decodedBytes = payload != null ? tryDecodeBase64(payload) : null;
      if (_decodedBytes == null) {
        _kind = _ImageSourceKind.invalid;
      }
    } else if (isBase64(src)) {
      _kind = _ImageSourceKind.base64;
      _decodedBytes = tryDecodeBase64(src);
      if (_decodedBytes == null) {
        _kind = _ImageSourceKind.invalid;
      }
    } else if (isURL(src)) {
      _kind = _ImageSourceKind.network;
    } else if (src.isNotEmpty) {
      _kind = _ImageSourceKind.file;
    } else {
      _kind = _ImageSourceKind.invalid;
    }
  }

  /// The effective display width clamped to [min, max] so the image can't be
  /// dragged wider than the viewport.
  double get _clampedWidth {
    final maxW = MediaQuery.of(context).size.width;
    return min(maxW, max(_kImageBlockComponentMinWidth, imageWidth - moveDistance));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Align(
        alignment: widget.alignment,
        child: SizedBox(
          width: _clampedWidth,
          height: widget.height,
          child: MouseRegion(
            onEnter: (_) => _hoverNotifier.value = true,
            onExit: (_) => _hoverNotifier.value = false,
            child: _buildResizableImage(context),
          ),
        ),
      ),
    );
  }

  Widget _buildResizableImage(BuildContext context) {
    return Stack(
      children: [
        _buildImage(context),
        if (widget.editable) ...[
          _buildEdgeGesture(
            context,
            top: 0,
            left: 5,
            bottom: 0,
            width: 5,
            onUpdate: (distance) {
              setState(() {
                moveDistance = distance;
              });
            },
          ),
          _buildEdgeGesture(
            context,
            top: 0,
            right: 5,
            bottom: 0,
            width: 5,
            onUpdate: (distance) {
              setState(() {
                moveDistance = -distance;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Builds the [Image] widget for the current source kind.
  ///
  /// All three sources (network / data-url / local file) share the same
  /// loading + error treatment, and none of them hard-code a fixed [width] —
  /// the parent [SizedBox] controls the render size via [BoxFit.contain].
  Widget _buildImage(BuildContext context) {
    switch (_kind) {
      case _ImageSourceKind.dataUrl:
      case _ImageSourceKind.base64:
        if (_decodedBytes == null) {
          return _buildError(context);
        }
        return Image.memory(
          _decodedBytes!,
          gaplessPlayback: true,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildError(context),
        );

      case _ImageSourceKind.network:
        return Image.network(
          widget.src,
          gaplessPlayback: true,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null ||
                loadingProgress.cumulativeBytesLoaded ==
                    loadingProgress.expectedTotalBytes) {
              return child;
            }
            return _buildLoading(context);
          },
          errorBuilder: (context, error, stackTrace) => _buildError(context),
        );

      case _ImageSourceKind.file:
        return Image.file(
          File(widget.src),
          gaplessPlayback: true,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildError(context),
        );

      case _ImageSourceKind.invalid:
        return _buildError(context);
    }
  }

  Widget _buildLoading(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.fromSize(
            size: const Size(18, 18),
            child: const CircularProgressIndicator(),
          ),
          SizedBox.fromSize(
            size: const Size(10, 10),
          ),
          Text(AppFlowyEditorL10n.current.loading),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      width: _clampedWidth,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
        border: Border.all(
          width: 1,
          color: colorScheme.outline.withAlpha(0x55),
        ),
        color: colorScheme.errorContainer.withAlpha(0x44),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 18, color: colorScheme.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              AppFlowyEditorL10n.current.imageLoadFailed,
              style: TextStyle(color: colorScheme.onErrorContainer),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdgeGesture(
    BuildContext context, {
    double? top,
    double? left,
    double? right,
    double? bottom,
    double? width,
    void Function(double distance)? onUpdate,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      width: width,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          initialOffset = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          if (onUpdate != null) {
            var offset = (details.globalPosition.dx - initialOffset);
            // When centered, a single edge drag should resize symmetrically
            // (both sides move), so the distance is doubled.
            if (widget.alignment.x == 0.0) {
              offset *= 2.0;
            }
            onUpdate(offset);
          }
        },
        onHorizontalDragEnd: (details) {
          imageWidth = _clampedWidth;
          initialOffset = 0;
          moveDistance = 0;

          widget.onResize(imageWidth);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          // Only the handle listens to hover, not the whole image — avoids
          // rebuilding Image on every mouse enter/exit.
          child: ValueListenableBuilder<bool>(
            valueListenable: _hoverNotifier,
            builder: (context, hovered, _) {
              if (!hovered) return const SizedBox.shrink();
              return Center(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                    border: Border.all(width: 1, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

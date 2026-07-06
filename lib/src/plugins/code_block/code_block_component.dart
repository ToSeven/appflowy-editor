import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'code_block_actions.dart';
import 'code_block_languages.dart';
import 'code_block_localization.dart';
import 'code_block_style.dart';
import '../utils/string_ext.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'code_block_themes.dart';

class CodeBlockKeys {
  const CodeBlockKeys._();

  static const String type = 'code';

  /// The content of a code block.
  ///
  /// The value is a String.
  static const String delta = 'delta';

  /// The language of a code block.
  ///
  /// The value is a String.
  static const String language = 'language';

  /// Optional indent size (int) for the code block.
  ///
  /// When absent, shortcut handlers default to 2 spaces.
  static const String indentSize = 'indent_size';
}

Node codeBlockNode({
  Delta? delta,
  String? language,
  int? indentSize,
}) {
  final attributes = {
    CodeBlockKeys.delta: (delta ?? Delta()).toJson(),
    CodeBlockKeys.language: language,
    if (indentSize != null) CodeBlockKeys.indentSize: indentSize,
  };
  return Node(
    type: CodeBlockKeys.type,
    attributes: attributes,
  );
}

// Code block menu item for selection
SelectionMenuItem codeBlockItem(
  String name, [
  IconData icon = Icons.abc,
  List<String> keywords = const ['code', 'codeblock'],
  String? language,
]) =>
    SelectionMenuItem.node(
      getName: () => name,
      iconData: icon,
      keywords: keywords,
      nodeBuilder: (_, __) => codeBlockNode(language: language),
      replace: (_, node) => node.delta?.isEmpty ?? false,
    );

const _interceptorKey = 'code-block-interceptor';

/// Used to provide a custom Language picker widget for the [CodeBlockComponentWidget].
///
typedef CodeBlockLanguagePickerBuilder = Widget Function(
  EditorState editorState,
  List<String> supportedLanguages,
  void Function(String language) onLanguageSelected, {
  String? selectedLanguage,

  /// Used to manage the visibility of the language picker, to ensure
  /// it is visible while the user is currently interacting with it.
  VoidCallback? onMenuOpen,
  VoidCallback? onMenuClose,
});

/// Used to provide a custom copy button for the [CodeBlockComponentWidget].
///
typedef CodeBlockCopyBuilder = Widget Function(EditorState, Node);

class CodeBlockComponentBuilder extends BlockComponentBuilder {
  CodeBlockComponentBuilder({
    super.configuration,
    this.padding = const EdgeInsets.only(
      top: 20,
      left: 20,
      right: 20,
      bottom: 34,
    ),
    this.styleBuilder,
    this.actions = const CodeBlockActions(),
    this.actionWrapperBuilder,
    this.languagePickerBuilder,
    this.copyButtonBuilder,
    this.localizations = const CodeBlockLocalizations(),
    this.showLineNumbers = false,
  });

  final EdgeInsets padding;
  final CodeBlockStyle Function()? styleBuilder;
  final CodeBlockActions actions;
  final Widget Function(
    Node node,
    EditorState editorState,
    Widget child,
  )? actionWrapperBuilder;
  final CodeBlockLanguagePickerBuilder? languagePickerBuilder;
  final CodeBlockCopyBuilder? copyButtonBuilder;
  final CodeBlockLocalizations localizations;
  final bool showLineNumbers;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CodeBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      padding: padding,
      showActions: showActions(node),
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
      actionWrapperBuilder: actionWrapperBuilder,
      style: styleBuilder?.call(),
      languagePickerBuilder: languagePickerBuilder,
      actions: actions,
      copyButtonBuilder: copyButtonBuilder,
      localizations: localizations,
      showLineNumbers: showLineNumbers,
    );
  }

  @override
  bool Function(Node) get validate => (node) => node.delta != null;
}

/// A widget representing a code block component.
///
/// It is highly recommended to use a monospace font for the code block,
/// as otherwise the alignment of line numbers and lines won't match up.
///
class CodeBlockComponentWidget extends BlockComponentStatefulWidget {
  const CodeBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.padding = const EdgeInsets.all(20),
    this.style,
    this.actions = const CodeBlockActions(),
    this.actionWrapperBuilder,
    this.languagePickerBuilder,
    this.copyButtonBuilder,
    this.localizations = const CodeBlockLocalizations(),
    this.showLineNumbers = true,
  });

  final EdgeInsets padding;

  /// The style of the code block.
  ///
  /// If null, theme defaults will be used.
  ///
  final CodeBlockStyle? style;

  /// The actions available for the code block.
  ///
  final CodeBlockActions actions;

  /// The builder for the action widgets.
  ///
  /// Used to override the default action wrapper,
  /// especially useful for mobile adaptation.
  ///
  /// _Note: This renders the [actionBuilder] obsolete!_
  ///
  final Widget Function(
    Node node,
    EditorState editorState,
    Widget child,
  )? actionWrapperBuilder;

  /// Provide a custom Widget for the language picker.
  ///
  /// It is highly recommended to replace the default language picker that
  /// consists of a [DropdownMenu], with a custom picker that fits the
  /// design of your app.
  ///
  final CodeBlockLanguagePickerBuilder? languagePickerBuilder;

  /// Provide a custom Widget for the copy button.
  ///
  /// It is highly recommended to replace the default copy button that
  /// consists of a simple [IconButton], with a custom button that fits the
  /// design of your app.
  ///
  final CodeBlockCopyBuilder? copyButtonBuilder;

  final CodeBlockLocalizations localizations;

  final bool showLineNumbers;

  @override
  State<CodeBlockComponentWidget> createState() =>
      _CodeBlockComponentWidgetState();
}

class _CodeBlockComponentWidgetState extends State<CodeBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin {
  // The key used to forward focus to the richtext child
  @override
  final forwardKey = GlobalKey(debugLabel: 'code_flowy_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey =
      GlobalKey(debugLabel: CodeBlockKeys.type);

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => node.key;

  @override
  Node get node => widget.node;

  @override
  late EditorState editorState;

  final scrollController = ScrollController();

  // We use this to calculate the position of the cursor in the code block
  // for automatic scrolling.
  final codeBlockKey = GlobalKey();

  String? get language => node.attributes[CodeBlockKeys.language] as String?;

  bool isSelected = false;
  bool isHovering = false;
  bool canPanStart = true;

  late final interceptor = SelectionGestureInterceptor(
    key: _interceptorKey,
    canTap: (_) => canPanStart && !isSelected,
    canPanStart: (_) => canPanStart && !isSelected,
  );

  late final StreamSubscription<dynamic> transactionSubscription;

  // --- Highlight memoization ------------------------------------------------
  // Parsing the syntax tree and converting it to TextSpans runs on the UI
  // thread and is expensive. We cache the result keyed by (content, language,
  // brightness) so that rebuilds triggered by unrelated state (hover, selection
  // changes, foreign transactions) do not re-parse.
  String? _highlightedContent;
  String? _highlightedLanguage;
  bool? _highlightedIsLight;
  List<TextSpan> _highlightedSpans = const [];

  // Last observed content/language, used to filter the global transaction
  // stream so only transactions that actually touched THIS node trigger a
  // rebuild. Without this, every code block in the document rebuilds on each
  // keystroke typed anywhere.
  String? _lastContent;
  String? _lastLanguage;

  @override
  void initState() {
    super.initState();
    editorState = context.read<EditorState>();

    editorState.selectionService.registerGestureInterceptor(interceptor);
    editorState.selectionNotifier.addListener(calculateScrollPosition);
    _lastContent = node.delta?.toPlainText();
    _lastLanguage = language;
    transactionSubscription = editorState.transactionStream.listen((_) {
      // The selection-based scroll handling is cheap (it self-no-ops via
      // addPostFrameCallback + path checks), but we must avoid the expensive
      // setState -> rebuild -> re-parse path unless THIS node actually changed.
      calculateScrollPosition();
      final content = node.delta?.toPlainText();
      final lang = language;
      if (content != _lastContent || lang != _lastLanguage) {
        _lastContent = content;
        _lastLanguage = lang;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    editorState.selectionService.currentSelection
        .removeListener(calculateScrollPosition);
    editorState.selectionService.unregisterGestureInterceptor(_interceptorKey);

    editorState = context.read<EditorState>();
  }

  @override
  void dispose() {
    scrollController.dispose();
    editorState.selectionService.currentSelection
        .removeListener(calculateScrollPosition);
    editorState.selectionService.unregisterGestureInterceptor(_interceptorKey);
    transactionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = calculateTextDirection(
      layoutDirection: Directionality.maybeOf(context),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // --- Resolved surface colors ------------------------------------------------
    // The code block uses a layered surface: a body background and a slightly
    // differentiated header band so the controls read as chrome, not content.
    final bgColor = widget.style?.backgroundColor ??
        (isLight
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerLow);
    final headerBg = widget.style?.headerBackgroundColor ??
        (isLight
            ? _CodeBlockColorUtils.darken(bgColor, 0.018)
            : _CodeBlockColorUtils.lighten(bgColor, 0.04));
    final borderColor = widget.style?.borderColor ??
        colorScheme.outline.withAlpha(isLight ? 0x33 : 0x55); // ~0.2 / ~0.33
    final radius = widget.style?.radius ?? 10.0;
    final border = BorderSide(color: borderColor, width: 1.0);

    Widget child = MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          color: bgColor,
          border: Border.fromBorderSide(border),
          // Subtle elevation on desktop/web only — skipped on mobile to keep
          // repaint cost low.
          boxShadow: UniversalPlatform.isDesktopOrWeb
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(isLight ? 0x08 : 0x18),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          // Clip children so the header band + scroll area honor the radius.
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            textDirection: textDirection,
            children: [
              // --- Header band ---------------------------------------------------
              MouseRegion(
                onEnter: (_) => setState(() => canPanStart = false),
                onExit: (_) => setState(() => canPanStart = true),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: headerBg,
                    border: Border(
                      bottom: BorderSide(
                        color: borderColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Flexible lets the selector shrink when the selected
                      // language label is long, so it never overflows the
                      // header row. Inner Text uses ellipsis as a fallback.
                      Flexible(
                        child: _LanguageSelector(
                          editorState: editorState,
                          language: language,
                          isSelected: isSelected,
                          onLanguageSelected: (language) {
                            updateLanguage(language);
                            widget.actions.onLanguageChanged?.call(language);
                          },
                          onMenuOpen: () => isSelected = true,
                          onMenuClose: () => setState(() => isSelected = false),
                          languagePickerBuilder: widget.languagePickerBuilder,
                          localizations: widget.localizations,
                        ),
                      ),
                      const Spacer(),
                      if (widget.actions.onCopy != null &&
                          widget.copyButtonBuilder == null) ...[
                        _CopyButton(
                          node: node,
                          onCopy: widget.actions.onCopy!,
                          localizations: widget.localizations,
                          foregroundColor: widget.style?.foregroundColor,
                        ),
                      ] else if (widget.copyButtonBuilder != null) ...[
                        widget.copyButtonBuilder!(editorState, node),
                      ],
                    ],
                  ),
                ),
              ),
              // Isolate repaints (hover/selection/highlight) from the rest of
              // the document so a single code block does not trigger a full
              // editor repaint.
              RepaintBoundary(
                child: _buildCodeBlock(context, textDirection),
              ),
            ],
          ),
        ),
      ),
    );

    child = Padding(key: blockComponentKey, padding: padding, child: child);

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );

    if (widget.actionWrapperBuilder != null) {
      child = widget.actionWrapperBuilder!(node, editorState, child);
    } else if (UniversalPlatform.isDesktopOrWeb) {
      if (widget.showActions && widget.actionBuilder != null) {
        child = BlockComponentActionWrapper(
          node: widget.node,
          actionBuilder: widget.actionBuilder!,
          child: child,
        );
      }
    }

    return child;
  }

  Widget _buildCodeBlock(BuildContext context, TextDirection textDirection) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final colorScheme = Theme.of(context).colorScheme;
    final delta = node.delta ?? Delta();
    final content = delta.toPlainText();

    final codeTextSpans = _resolveHighlightedSpans(content, isLightMode);

    // Calculate lines of code dynamically
    final linesOfCode = content.isEmpty ? 1 : content.split('\n').length;

    // Define textStyle based on editor style configuration.
    // Flutter's [TextStyle.fontFamily] does NOT accept a CSS-style fallback
    // list ("A, B, C"); it must be a single name with [fontFamilyFallback].
    final textStyle =
        editorState.editorStyle.textStyleConfiguration.text.copyWith(
      fontSize: 13.5,
      height: 1.55,
      fontFamily: 'Monaco',
      fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier New', 'monospace'],
    );

    // Intentional, tighter body padding: horizontal 14, top 14, bottom 18.
    final innerPadding = widget.style?.padding ??
        const EdgeInsets.fromLTRB(14, 14, 14, 18);

    // Gutter separator + muted digits. ~35% onSurface reads as chrome.
    final gutterColor = widget.style?.gutterColor ??
        colorScheme.onSurface.withAlpha(isLightMode ? 0x59 : 0x66);
    final separatorColor =
        colorScheme.outline.withAlpha(isLightMode ? 0x26 : 0x40);

    return Padding(
      padding: innerPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLineNumbers) ...[
            _LinesOfCodeNumbers(
              key: ValueKey('lines-$linesOfCode'),
              linesOfCode: linesOfCode,
              textStyle: textStyle.copyWith(
                color: gutterColor,
                // Tabular figures keep digits column-aligned.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              separatorColor: separatorColor,
            ),
          ],
          Flexible(
            child: Scrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                key: codeBlockKey,
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 4),
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: AppFlowyRichText(
                  key: forwardKey,
                  delegate: this,
                  node: widget.node,
                  editorState: editorState,
                  placeholderText: placeholderText,
                  lineHeight: 1.55,
                  textSpanDecorator: (_) =>
                      TextSpan(style: textStyle, children: codeTextSpans),
                  placeholderTextSpanDecorator: (textSpan) => textSpan,
                  textDirection: textDirection,
                  cursorColor: editorState.editorStyle.cursorColor,
                  selectionColor: editorState.editorStyle.selectionColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the syntax-highlighted [TextSpan] children for [content],
  /// memoized on the tuple (content, language, isLightMode) so that rebuilds
  /// not caused by an actual content/language change skip re-parsing.
  ///
  /// Parsing failures (unknown language, parser exceptions) never crash the
  /// build: they fall back to a single plain [TextSpan] wrapping the content.
  List<TextSpan> _resolveHighlightedSpans(String content, bool isLightMode) {
    if (content == _highlightedContent &&
        language == _highlightedLanguage &&
        isLightMode == _highlightedIsLight) {
      return _highlightedSpans;
    }

    List<TextSpan> spans;
    try {
      final result = highlight.highlight.parse(
        content,
        language: language,
        autoDetection: language == null,
      );
      final codeNodes = result.nodes;
      if (codeNodes == null || codeNodes.isEmpty) {
        spans = [TextSpan(text: content)];
      } else {
        spans = _convert(codeNodes, isLightMode: isLightMode);
      }
    } catch (_) {
      // Never let a highlighter failure red-screen the editor.
      spans = [TextSpan(text: content)];
    }

    _highlightedContent = content;
    _highlightedLanguage = language;
    _highlightedIsLight = isLightMode;
    _highlightedSpans = spans;
    return spans;
  }

  Future<void> updateLanguage(String language) async {
    final transaction = editorState.transaction
      ..updateNode(
        node,
        {CodeBlockKeys.language: language == 'auto' ? null : language},
      );
    await editorState.apply(transaction);
  }

  void calculateScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selection = editorState.selection;
      if (!mounted || selection == null || !selection.isCollapsed) {
        return;
      }

      final nodes = editorState.getNodesInSelection(selection);
      if (nodes.isEmpty || nodes.length > 1) {
        return;
      }

      final selectedNode = nodes.first;
      if (selectedNode.path.equals(widget.node.path)) {
        final renderBox =
            codeBlockKey.currentContext?.findRenderObject() as RenderBox?;
        final rects = editorState.selectionRects();
        if (renderBox == null || rects.isEmpty) {
          return;
        }

        final codeBlockOffset = renderBox.localToGlobal(Offset.zero);
        final codeBlockSize = renderBox.size;

        final cursorRect = rects.first;
        final cursorRelativeOffset = cursorRect.center - codeBlockOffset;

        // If the relative position of the cursor is less than 1, and the scrollController
        // is not at offset 0, then we need to scroll to the left to make cursor visible.
        if (cursorRelativeOffset.dx < 1 && scrollController.offset > 0) {
          scrollController
              .jumpTo(scrollController.offset + cursorRelativeOffset.dx - 1);

          // If the relative position of the cursor is greater than the width of the code block,
          // then we need to scroll to the right to make cursor visible.
        } else if (cursorRelativeOffset.dx > codeBlockSize.width - 1) {
          scrollController.jumpTo(
            scrollController.offset +
                cursorRelativeOffset.dx -
                codeBlockSize.width +
                1,
          );
        }
      }
    });
  }

  // Copy from flutter.highlight package.
  // https://github.com/git-touch/highlight.dart/blob/master/flutter_highlight/lib/flutter_highlight.dart
  List<TextSpan> _convert(
    List<highlight.Node> nodes, {
    bool isLightMode = true,
  }) {
    final List<TextSpan> spans = [];
    List<TextSpan> currentSpans = spans;
    final List<List<TextSpan>> stack = [];

    // Resolve the highlight theme, honoring an optional override supplied via
    // CodeBlockStyle so the code block can follow the host app's dynamic theme.
    final cbTheme = isLightMode
        ? (widget.style?.lightTheme ?? lightThemeInCodeblock)
        : (widget.style?.darkTheme ?? darkThemeInCodeBlock);

    void traverse(highlight.Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(text: node.value, style: cbTheme[node.className!]),
        );
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(children: tmp, style: cbTheme[node.className!]),
        );
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (final node in nodes) {
      traverse(node);
    }

    return spans;
  }
}

class _LinesOfCodeNumbers extends StatelessWidget {
  const _LinesOfCodeNumbers({
    super.key,
    required this.linesOfCode,
    required this.textStyle,
    required this.separatorColor,
  });

  final int linesOfCode;
  final TextStyle textStyle;
  final Color separatorColor;

  @override
  Widget build(BuildContext context) {
    // Render all line numbers as a single Text instead of one Text widget per
    // line. For large code blocks this collapses thousands of child elements
    // into one, dramatically shrinking the element tree.
    final buffer = StringBuffer();
    for (int i = 1; i <= linesOfCode; i++) {
      if (i > 1) buffer.write('\n');
      buffer.write(i);
    }
    return Container(
      padding: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: separatorColor, width: 1.0),
        ),
      ),
      margin: const EdgeInsets.only(right: 12),
      child: Text(
        buffer.toString(),
        style: textStyle,
        textAlign: TextAlign.right,
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({
    required this.node,
    required this.onCopy,
    required this.localizations,
    this.foregroundColor,
  });

  final Node node;
  final void Function(String) onCopy;
  final CodeBlockLocalizations localizations;
  final Color? foregroundColor;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _hovered = false;
  bool _justCopied = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor =
        widget.foregroundColor ?? colorScheme.onSurface.withAlpha(0xCC);
    final iconColor = _hovered ? colorScheme.onSurface : baseColor;
    final bgColor = _hovered
        ? colorScheme.onSurface.withAlpha(0x0F)
        : Colors.transparent;

    return Tooltip(
      message: widget.localizations.copyTooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            final delta = widget.node.delta?.toPlainText();
            if (delta != null) {
              widget.onCopy(delta);
              setState(() => _justCopied = true);
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (mounted) setState(() => _justCopied = false);
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              _justCopied ? Icons.check_rounded : Icons.copy_rounded,
              size: 15,
              color: _justCopied
                  ? colorScheme.primary
                  : iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatefulWidget {
  const _LanguageSelector({
    required this.editorState,
    this.language,
    required this.isSelected,
    required this.onLanguageSelected,
    this.onMenuOpen,
    this.onMenuClose,
    this.languagePickerBuilder,
    required this.localizations,
  });

  final EditorState editorState;
  final String? language;
  final bool isSelected;
  final void Function(String) onLanguageSelected;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  final CodeBlockLanguagePickerBuilder? languagePickerBuilder;
  final CodeBlockLocalizations localizations;

  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.languagePickerBuilder != null) {
      return widget.languagePickerBuilder!(
        widget.editorState,
        defaultCodeBlockSupportedLanguages,
        widget.onLanguageSelected,
        selectedLanguage: widget.language,
        onMenuOpen: widget.onMenuOpen,
        onMenuClose: widget.onMenuClose,
      );
    }

    return _LanguageSelectionDropdown(
      editorState: widget.editorState,
      language: widget.language,
      onLanguageSelected: (lang) => widget.onLanguageSelected(lang),
      supportedLanguages: defaultCodeBlockSupportedLanguages,
      localizations: widget.localizations,
      onMenuOpen: widget.onMenuOpen,
      onMenuClose: widget.onMenuClose,
    );
  }
}

class _LanguageSelectionDropdown extends StatefulWidget {
  const _LanguageSelectionDropdown({
    required this.editorState,
    required this.language,
    required this.onLanguageSelected,
    required this.supportedLanguages,
    required this.localizations,
    this.onMenuOpen,
    this.onMenuClose,
  });

  final EditorState editorState;
  final String? language;
  final void Function(String) onLanguageSelected;
  final List<String> supportedLanguages;
  final CodeBlockLocalizations localizations;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  @override
  State<_LanguageSelectionDropdown> createState() =>
      _LanguageSelectionDropdownState();
}

class _LanguageSelectionDropdownState
    extends State<_LanguageSelectionDropdown> {
  bool _isHovered = false;
  final MenuController _menuController = MenuController();

  // Cache of MenuItemButton widgets keyed on (language, brightness).
  String? _cachedLang;
  bool? _cachedIsDark;
  late List<MenuItemButton> _menuChildren;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureItemCache(Theme.of(context).brightness == Brightness.dark);
  }

  @override
  void didUpdateWidget(covariant _LanguageSelectionDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language ||
        oldWidget.supportedLanguages != widget.supportedLanguages ||
        oldWidget.localizations != widget.localizations) {
      _rebuildItemCache(Theme.of(context).brightness == Brightness.dark);
    }
  }

  void _ensureItemCache(bool isDarkMode) {
    final currentLanguage = widget.language ?? 'auto';
    if (currentLanguage != _cachedLang || isDarkMode != _cachedIsDark) {
      _rebuildItemCache(isDarkMode);
    }
  }

  void _rebuildItemCache(bool isDarkMode) {
    final currentLanguage = widget.language ?? 'auto';
    final labelOf = (String lang) => lang == 'auto'
        ? widget.localizations.autoLanguage
        : lang.capitalize();

    _menuChildren = widget.supportedLanguages.map((lang) {
      final isSelected = lang == currentLanguage;
      return MenuItemButton(
        onPressed: () {
          widget.onLanguageSelected(lang);
          widget.onMenuClose?.call();
        },
        trailingIcon: isSelected
            ? Icon(
                Icons.check,
                size: 14,
                color: isDarkMode
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1D4ED8),
              )
            : null,
        child: Text(
          labelOf(lang),
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Monaco',
            fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
            color: isDarkMode
                ? const Color(0xFFD4D4D4)
                : const Color(0xFF333333),
          ),
        ),
      );
    }).toList();

    _cachedLang = currentLanguage;
    _cachedIsDark = isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    _ensureItemCache(isDarkMode);
    final currentLanguage = widget.language ?? 'auto';
    final label = currentLanguage == 'auto'
        ? widget.localizations.autoLanguage
        : currentLanguage.capitalize();

    // Resting pill is a soft ghost; on hover it lifts to a clearer surface.
    final pillBg = _isHovered
        ? colorScheme.onSurface.withAlpha(0x10)
        : colorScheme.onSurface.withAlpha(0x07);
    final labelColor = colorScheme.onSurface.withAlpha(isDarkMode ? 0xB3 : 0x99);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      // MenuAnchor (Material 3) replaces DropdownButton. The trigger widget is
      // 100% custom — it does NOT depend on DropdownButton's internal
      // `mainAxisSize.min` Row + `isExpanded` flex algorithm, which is
      // notoriously hard to constrain. Here the trigger width is deterministic:
      //   ConstrainedBox(maxWidth: 104) on the Text directly → short labels
      //   render at natural width (compact pill), long labels ellipsize.
      // The popup menu width is independent (sized by its own menuChildren).
      child: MenuAnchor(
        controller: _menuController,
        menuChildren: _menuChildren,
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          elevation: const WidgetStatePropertyAll(6),
        ),
        builder: (context, controller, child) {
          return GestureDetector(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
                widget.onMenuClose?.call();
              } else {
                widget.onMenuOpen?.call();
                controller.open();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              constraints: const BoxConstraints(maxWidth: 150),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 104),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Monaco',
                        fontFamilyFallback: const [
                          'Menlo',
                          'Consolas',
                          'monospace',
                        ],
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: labelColor,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tiny HSL-based color helpers for deriving layered surface tints.
///
/// We avoid pulling in extra packages; this is the minimal math needed to
/// darken/lighten a color for the header band.
class _CodeBlockColorUtils {
  const _CodeBlockColorUtils._();

  /// Returns [color] mixed with black by [amount] (0.0..1.0).
  static Color darken(Color color, double amount) {
    final f = amount.clamp(0.0, 1.0);
    return Color.alphaBlend(
      Colors.black.withValues(alpha: f),
      color,
    );
  }

  /// Returns [color] mixed with white by [amount] (0.0..1.0).
  static Color lighten(Color color, double amount) {
    final f = amount.clamp(0.0, 1.0);
    return Color.alphaBlend(
      Colors.white.withValues(alpha: f),
      color,
    );
  }
}

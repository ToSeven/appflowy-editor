import 'package:flutter/material.dart';

/// Style configuration for a code block.
///
/// [backgroundColor] and [foregroundColor] are always required. The optional
/// fields let the host app override specific visual aspects so the code block
/// can follow a dynamic theme or a custom design system.
///
class CodeBlockStyle {
  const CodeBlockStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    this.padding,
    this.lightTheme,
    this.darkTheme,
    this.borderColor,
    this.headerBackgroundColor,
    this.gutterColor,
    this.radius,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  /// Optional padding override for the code block body.
  final EdgeInsets? padding;

  /// Override for the light-mode syntax-highlight theme.
  ///
  /// When null, the component falls back to the built-in
  /// [lightThemeInCodeblock].
  final Map<String, TextStyle>? lightTheme;

  /// Override for the dark-mode syntax-highlight theme.
  ///
  /// When null, the component falls back to the built-in
  /// [darkThemeInCodeBlock].
  final Map<String, TextStyle>? darkTheme;

  /// Override for the 1px container border color.
  ///
  /// When null, a low-alpha [ColorScheme.outline] is used.
  final Color? borderColor;

  /// Override for the header band background tint.
  ///
  /// When null, a slightly darkened/lightened version of [backgroundColor]
  /// is derived automatically.
  final Color? headerBackgroundColor;

  /// Override for the line-number gutter color (the separator + the digits).
  ///
  /// When null, [ColorScheme.onSurface] at ~35% alpha is used.
  final Color? gutterColor;

  /// Override for the container's border radius.
  ///
  /// When null, a default of 10.0 is used.
  final double? radius;
}

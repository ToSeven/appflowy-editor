import 'package:flutter/painting.dart';

/// Light syntax-highlight theme for the code block.
///
/// Inspired by GitHub's light code theme: neutral background, soft grays, and
/// restrained accent colors that stay readable on a light surface.
const lightThemeInCodeblock = <String, TextStyle>{
  'root': TextStyle(
    backgroundColor: Color(0xfffafafa),
    color: Color(0xff24292f),
  ),
  'subst': TextStyle(color: Color(0xff24292f)),
  'comment': TextStyle(
    color: Color(0xff6e7781),
    fontStyle: FontStyle.italic,
  ),
  'quote': TextStyle(
    color: Color(0xff6e7781),
    fontStyle: FontStyle.italic,
  ),
  'keyword': TextStyle(color: Color(0xffcf222e), fontWeight: FontWeight.w600),
  'selector-tag': TextStyle(color: Color(0xffcf222e), fontWeight: FontWeight.w600),
  'literal': TextStyle(color: Color(0xff0550ae)),
  'number': TextStyle(color: Color(0xff0550ae)),
  'bullet': TextStyle(color: Color(0xff0550ae)),
  'symbol': TextStyle(color: Color(0xff0550ae)),
  'meta': TextStyle(color: Color(0xff0550ae)),
  'regexp': TextStyle(color: Color(0xff0a3069)),
  'link': TextStyle(color: Color(0xff0969da), decoration: TextDecoration.underline),
  'title': TextStyle(color: Color(0xff6639ba), fontWeight: FontWeight.w600),
  'section': TextStyle(color: Color(0xff6639ba), fontWeight: FontWeight.w600),
  'name': TextStyle(color: Color(0xff6639ba)),
  'selector-id': TextStyle(color: Color(0xff6639ba)),
  'selector-class': TextStyle(color: Color(0xff6639ba)),
  'selector-attr': TextStyle(color: Color(0xff6639ba)),
  'selector-pseudo': TextStyle(color: Color(0xff6639ba)),
  'type': TextStyle(color: Color(0xff953800), fontWeight: FontWeight.w600),
  'built_in': TextStyle(color: Color(0xff953800)),
  'builtin-name': TextStyle(color: Color(0xff953800)),
  'class': TextStyle(color: Color(0xff953800)),
  'params': TextStyle(color: Color(0xff24292f)),
  'attr': TextStyle(color: Color(0xff0550ae)),
  'attribute': TextStyle(color: Color(0xff116329)),
  'template-tag': TextStyle(color: Color(0xff24292f)),
  'template-variable': TextStyle(color: Color(0xff24292f)),
  'variable': TextStyle(color: Color(0xff24292f)),
  'string': TextStyle(color: Color(0xff0a3069)),
  'doctag': TextStyle(color: Color(0xff0a3069)),
  'meta-string': TextStyle(color: Color(0xff0a3069)),
  'addition': TextStyle(
    color: Color(0xff116329),
    backgroundColor: Color(0xffdafbe1),
  ),
  'deletion': TextStyle(
    color: Color(0xff82071e),
    backgroundColor: Color(0xffffdce0),
  ),
  'formula': TextStyle(
    color: Color(0xff24292f),
    fontStyle: FontStyle.italic,
  ),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.w700),
  'tag': TextStyle(color: Color(0xff116329), fontWeight: FontWeight.w600),
  'meta-keyword': TextStyle(color: Color(0xffcf222e)),
  'code': TextStyle(color: Color(0xff0a3069)),
};

/// Dark syntax-highlight theme for the code block.
///
/// Inspired by Atom One Dark: a balanced, slightly desaturated palette on a
/// deep neutral background. Reads cleanly in low-light conditions.
const darkThemeInCodeBlock = <String, TextStyle>{
  'root': TextStyle(
    backgroundColor: Color(0xff282c34),
    color: Color(0xffabb2bf),
  ),
  'subst': TextStyle(color: Color(0xffabb2bf)),
  'comment': TextStyle(
    color: Color(0xff5c6370),
    fontStyle: FontStyle.italic,
  ),
  'quote': TextStyle(
    color: Color(0xff5c6370),
    fontStyle: FontStyle.italic,
  ),
  'keyword': TextStyle(color: Color(0xffc678dd), fontWeight: FontWeight.w500),
  'selector-tag': TextStyle(color: Color(0xffc678dd), fontWeight: FontWeight.w500),
  'literal': TextStyle(color: Color(0xffd19a66)),
  'number': TextStyle(color: Color(0xffd19a66)),
  'bullet': TextStyle(color: Color(0xffd19a66)),
  'symbol': TextStyle(color: Color(0xff56b6c2)),
  'meta': TextStyle(color: Color(0xffd19a66)),
  'regexp': TextStyle(color: Color(0xff98c379)),
  'link': TextStyle(color: Color(0xff61afef), decoration: TextDecoration.underline),
  'title': TextStyle(color: Color(0xff61afef), fontWeight: FontWeight.w500),
  'section': TextStyle(color: Color(0xff61afef), fontWeight: FontWeight.w500),
  'name': TextStyle(color: Color(0xffe06c75)),
  'selector-id': TextStyle(color: Color(0xffe06c75)),
  'selector-class': TextStyle(color: Color(0xffe06c75)),
  'selector-attr': TextStyle(color: Color(0xffe06c75)),
  'selector-pseudo': TextStyle(color: Color(0xffe06c75)),
  'type': TextStyle(color: Color(0xffe6c07b), fontWeight: FontWeight.w500),
  'built_in': TextStyle(color: Color(0xffe6c07b)),
  'builtin-name': TextStyle(color: Color(0xffe6c07b)),
  'class': TextStyle(color: Color(0xffe6c07b)),
  'params': TextStyle(color: Color(0xffabb2bf)),
  'attr': TextStyle(color: Color(0xffd19a66)),
  'attribute': TextStyle(color: Color(0xff98c379)),
  'template-tag': TextStyle(color: Color(0xffabb2bf)),
  'template-variable': TextStyle(color: Color(0xffabb2bf)),
  'variable': TextStyle(color: Color(0xffe06c75)),
  'string': TextStyle(color: Color(0xff98c379)),
  'doctag': TextStyle(color: Color(0xff98c379)),
  'meta-string': TextStyle(color: Color(0xff98c379)),
  'addition': TextStyle(
    color: Color(0xff98c379),
    backgroundColor: Color(0xff1e222a),
  ),
  'deletion': TextStyle(
    color: Color(0xffe06c75),
    backgroundColor: Color(0xff1e222a),
  ),
  'formula': TextStyle(
    color: Color(0xffabb2bf),
    fontStyle: FontStyle.italic,
  ),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.w700),
  'tag': TextStyle(color: Color(0xffe06c75), fontWeight: FontWeight.w500),
  'meta-keyword': TextStyle(color: Color(0xffc678dd)),
  'code': TextStyle(color: Color(0xff98c379)),
};

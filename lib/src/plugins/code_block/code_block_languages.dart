import 'package:highlight/languages/all.dart';

/// Curated set of language labels offered in the code-block language picker.
///
/// Each label is lower-cased and intersected with the languages actually
/// registered in the `highlight` package (see [allLanguages]), so unsupported
/// labels are filtered out automatically. The resulting list is sorted and
/// augmented with an `'auto'` entry (auto-detection).
const allCodeBlockLanguages = [
  'Assembly',
  'Bash',
  'BASIC',
  'C',
  'C#',
  'CPP',
  'Clojure',
  'CS',
  'CSS',
  'Dart',
  'Delphi',
  'DockerFile',
  'Elixir',
  'Elm',
  'Erlang',
  'Fortran',
  'Go',
  'GraphQL',
  'Haskell',
  'HTML',
  'Java',
  'JavaScript',
  'JSON',
  'Kotlin',
  'LaTeX',
  'Lisp',
  'Lua',
  'Markdown',
  'MATLAB',
  'Objective-C',
  'OCaml',
  'Perl',
  'PHP',
  'PowerShell',
  'Python',
  'R',
  'Ruby',
  'Rust',
  'Scala',
  'Shell',
  'SQL',
  'Swift',
  'TypeScript',
  'Visual Basic',
  'XML',
  'YAML',
];

/// Languages supported by the code block, derived from
/// [allCodeBlockLanguages] filtered by what the `highlight` package actually
/// knows about, plus `'auto'` for auto-detection.
final defaultCodeBlockSupportedLanguages = allCodeBlockLanguages
    .map((e) => e.toLowerCase())
    .toSet()
    .intersection(allLanguages.keys.toSet())
    .toList()
  ..add('auto')
  ..add('c')
  ..sort();

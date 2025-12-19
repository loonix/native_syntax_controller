import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// SYNTAX HIGHLIGHTING CONTROLLER
// ---------------------------------------------------------------------------

/// A TextEditingController that provides syntax highlighting for formula expressions.
///
/// This controller automatically highlights different syntax elements in formula text:
/// - Functions (like SUM, AVERAGE, IF) - highlighted in blue by default
/// - Operators (+, -, *, /, =, >, <, etc.) - highlighted in red by default
/// - Numbers - highlighted in green by default
/// - Strings - highlighted in purple by default
///
/// You can customize the colors by providing a [customStyles] map in the constructor.
/// Only provide the styles you want to override; defaults will be used for others.
///
/// Example:
/// ```dart
/// final controller = SyntaxHighlightingController(
///   customStyles: {
///     'function': TextStyle(color: Colors.red),
///     'operator': TextStyle(color: Colors.blue),
///   },
/// );
/// ```
class SyntaxHighlightingController extends TextEditingController {
  // Cores padrão
  static const Map<String, TextStyle> _defaultStyles = {
    'function': TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold), // Azul
    'operator': TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.bold), // Vermelho
    'number': TextStyle(color: Color(0xFF81C784)), // Verde
    'string': TextStyle(color: Color(0xFFCE93D8)), // Roxo
  };

  // Estilos personalizáveis
  final Map<String, TextStyle> styles;

  SyntaxHighlightingController({super.text, Map<String, TextStyle>? customStyles}) : styles = {..._defaultStyles, ...?customStyles};

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    List<TextSpan> children = [];
    String text = this.text;

    if (text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    // REGEX OTIMIZADA
    // Grupo 1: Strings
    // Grupo 2: Funções
    // Grupo 3: Números
    // Grupo 4: Operadores
    final RegExp syntaxRegex = RegExp(r'''('[^']*'|"[^"]*")|(\b[A-Z_]+\b(?=\())|(\b\d+(?:\.\d+)?\b)|([+\-*/=<>!&|]{1,2})''', multiLine: true);

    int currentIndex = 0;

    for (final Match match in syntaxRegex.allMatches(text)) {
      // Texto normal antes do match
      if (currentIndex < match.start) {
        children.add(TextSpan(text: text.substring(currentIndex, match.start), style: style));
      }

      // Aplica cor baseada no grupo
      TextStyle? matchStyle;
      if (match.group(1) != null) {
        matchStyle = styles['string'];
      } else if (match.group(2) != null) {
        matchStyle = styles['function'];
      } else if (match.group(3) != null) {
        matchStyle = styles['number'];
      } else if (match.group(4) != null) {
        matchStyle = styles['operator'];
      }

      children.add(TextSpan(text: match.group(0), style: style?.merge(matchStyle) ?? matchStyle));

      currentIndex = match.end;
    }

    // Texto restante
    if (currentIndex < text.length) {
      children.add(TextSpan(text: text.substring(currentIndex), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}

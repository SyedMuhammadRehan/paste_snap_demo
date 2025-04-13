import 'package:flutter/material.dart';
import 'package:paste_snap_demo/model/formatting_range.dart';

class StyleableTextFieldController extends TextEditingController {
  StyleableTextFieldController({
    required this.formattingRanges,
  });

  List<FormattingRange> formattingRanges;

  @override
  set text(String newText) {
    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
      composing: TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final textSpanChildren = <InlineSpan>[];
    var lastEnd = 0;

    final sortedRanges = List<FormattingRange>.from(formattingRanges)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final range in sortedRanges) {
      if (range.start < 0 || range.end > text.length || range.start >= range.end) {
        continue;
      }

      if (range.start > lastEnd) {
        final unstyledText = text.substring(lastEnd, range.start);
        textSpanChildren.add(TextSpan(
          text: unstyledText,
          style: style ?? const TextStyle(color: Colors.black), // Match TextField style
        ));
      }

      final rangeStyle = TextStyle(
        fontWeight: range.isBold ? FontWeight.bold : null,
        fontStyle: range.isItalic ? FontStyle.italic : null,
        decoration: range.isStrikethrough ? TextDecoration.lineThrough : null,
        color: Colors.black, // Match TextField style
      );

      final styledText = text.substring(range.start, range.end);
      textSpanChildren.add(TextSpan(
        text: styledText,
        style: rangeStyle,
      ));

      lastEnd = range.end;
    }

    if (lastEnd < text.length) {
      final remainingText = text.substring(lastEnd);
      textSpanChildren.add(TextSpan(
        text: remainingText,
        style: style ?? const TextStyle(color: Colors.black),
      ));
    }

    return TextSpan(children: textSpanChildren);
  }

  void updateFormatting(List<FormattingRange> newRanges) {
    formattingRanges = newRanges;
    notifyListeners();
  }
}
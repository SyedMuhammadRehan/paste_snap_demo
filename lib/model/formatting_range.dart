class FormattingRange {
  FormattingRange({
    required this.start,
    required this.end,
    this.isBold = false,
    this.isItalic = false,
    this.isStrikethrough = false,
  });

  int start;
  int end;
  bool isBold;
  bool isItalic;
  bool isStrikethrough;

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'isBold': isBold,
        'isItalic': isItalic,
        'isStrikethrough': isStrikethrough,
      };

  @override
  String toString() {
    return 'FormattingRange(start: $start, end: $end, isBold: $isBold, isItalic: $isItalic, isStrikethrough: $isStrikethrough)';
  }
}
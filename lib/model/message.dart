import 'dart:typed_data';
import 'package:paste_snap_demo/model/formatting_range.dart';

class Message {
  final String id;
  final String? text;
  final Uint8List? imageData;
  final String timestamp;
  final List<FormattingRange> formattingRanges;

  Message(
    this.text, {
    this.imageData,
    this.formattingRanges = const [],
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = DateTime.now().toIso8601String();
}
import 'dart:typed_data';

class Message {
  final Uint8List? imageData;
  final String timestamp;
  final String? text;

  Message(this.text, {this.imageData}) : timestamp = DateTime.now().toIso8601String();
}

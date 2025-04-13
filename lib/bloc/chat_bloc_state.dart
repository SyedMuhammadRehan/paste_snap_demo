part of 'chat_bloc_bloc.dart';
class ChatState extends Equatable {
  final String text;
  final Uint8List? previewImage;
  final List<Message> messages;
  final List<FormattingRange> formattingRanges;

  const ChatState({
    required this.text,
    this.previewImage,
    this.messages = const [],
    this.formattingRanges = const []
  });

  ChatState copyWith({
    String? text,
    Uint8List? previewImage,
    List<Message>? messages,
    List<FormattingRange>? formattingRanges,
  }) {
    return ChatState(
      text: text ?? this.text,
      previewImage: previewImage ?? this.previewImage,
      messages: messages ?? this.messages,
      formattingRanges: formattingRanges ?? this.formattingRanges,
    );
  }

  @override
  List<Object?> get props => [text, previewImage, messages,formattingRanges];
}

part of 'chat_bloc_bloc.dart';
class ChatState extends Equatable {
  final String text;
  final Uint8List? previewImage;
  final List<Message> messages;

  const ChatState({
    required this.text,
    this.previewImage,
    this.messages = const [],
  });

  ChatState copyWith({
    String? text,
    Uint8List? previewImage,
    List<Message>? messages,
  }) {
    return ChatState(
      text: text ?? this.text,
      previewImage: previewImage ?? this.previewImage,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [text, previewImage, messages];
}

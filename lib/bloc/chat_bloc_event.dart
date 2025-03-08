part of 'chat_bloc_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class PasteImageEvent extends ChatEvent {}

class UpdateTextEvent extends ChatEvent {
  final String text;
  const UpdateTextEvent(this.text);
  @override
  List<Object?> get props => [text];
}

class SendMessageEvent extends ChatEvent {
  final String text;
  final Uint8List? imageData;
  const SendMessageEvent({required this.text, this.imageData});
  @override
  List<Object?> get props => [text, imageData];
}
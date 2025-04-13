part of 'chat_bloc_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class PasteImageEvent extends ChatEvent {}

class UpdateTextEvent extends ChatEvent {
  final String text;
  final TextSelection selection; 

  const UpdateTextEvent(this.text, this.selection);

  @override
  List<Object?> get props => [text, selection];
}

class SendMessageEvent extends ChatEvent {
  final String text;
  final Uint8List? imageData;
  final List<FormattingRange> formattingRanges; 

  const SendMessageEvent({
    required this.text,
    this.imageData,
    required this.formattingRanges,
  });

  @override
  List<Object?> get props => [text, imageData, formattingRanges];
}

class ToggleBoldEvent extends ChatEvent {
  final TextSelection selection;

  const ToggleBoldEvent(this.selection);

  @override
  List<Object?> get props => [selection];
}

class ToggleItalicEvent extends ChatEvent {
  final TextSelection selection;

  const ToggleItalicEvent(this.selection);

  @override
  List<Object?> get props => [selection];
}

class ToggleStrikethroughEvent extends ChatEvent {
  final TextSelection selection;

  const ToggleStrikethroughEvent(this.selection);

  @override
  List<Object?> get props => [selection];
}
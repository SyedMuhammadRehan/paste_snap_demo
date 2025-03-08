import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:paste_snap_demo/model/message.dart';

part 'chat_bloc_event.dart';
part 'chat_bloc_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  static const _imageChannel = MethodChannel('clipboard/image');

  ChatBloc() : super(const ChatState(text: '')) {
    on<PasteImageEvent>(_onPasteImage);
    on<UpdateTextEvent>(_onUpdateText);
    on<SendMessageEvent>(_onSendMessage);
  }

  Future<void> _onPasteImage(PasteImageEvent event, Emitter<ChatState> emit) async {
    try {
      final imageData = await _imageChannel.invokeMethod('getClipboardImage');
      if (imageData != null && imageData is Uint8List) {
        emit(ChatState(
         text: state.text,
          previewImage: imageData,
          messages: state.messages,
        ));
      } else {
        print('No image data found in clipboard');
      }
    } catch (e) {
      print('Error pasting image: $e');
    }
  }

  void _onUpdateText(UpdateTextEvent event, Emitter<ChatState> emit) {
    emit(ChatState(
     text: event.text,
      previewImage: state.previewImage,
      messages: state.messages,
    ));
  }

  void _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) {
    final text = event.text.trim();
    if (text.isNotEmpty || event.imageData != null) {
      final newMessage = Message(text, imageData: event.imageData);
      emit(ChatState(
       text: '', // Clear text after sending
        messages: [...state.messages, newMessage],
        previewImage: null, // Clear preview image after sending
      ));
    } else {
      print('No content to send');
    }
  }
}
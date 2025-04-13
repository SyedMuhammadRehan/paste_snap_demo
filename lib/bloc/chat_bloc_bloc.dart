import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:paste_snap_demo/model/formatting_range.dart';
import 'package:paste_snap_demo/model/message.dart';

part 'chat_bloc_event.dart';
part 'chat_bloc_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  static const _imageChannel = MethodChannel('clipboard/image');

  ChatBloc() : super(const ChatState(text: '')) {
    on<PasteImageEvent>(_onPasteImage);
    on<UpdateTextEvent>(_onUpdateText);
    on<SendMessageEvent>(_onSendMessage);
    on<ToggleBoldEvent>(_onToggleBold);
    on<ToggleItalicEvent>(_onToggleItalic);
    on<ToggleStrikethroughEvent>(_onToggleStrikethrough);
  }

  Future<void> _onPasteImage(PasteImageEvent event, Emitter<ChatState> emit) async {
    try {
      final imageData = await _imageChannel.invokeMethod('getClipboardImage');
      if (imageData != null && imageData is Uint8List) {
        emit(state.copyWith(
          previewImage: imageData,
        ));
      } else {
        print('No image data found in clipboard');
      }
    } catch (e) {
      print('Error pasting image: $e');
    }
  }

  void _onUpdateText(UpdateTextEvent event, Emitter<ChatState> emit) {
    final updatedRanges = _updateFormattingRanges(
      state.formattingRanges,
      state.text,
      event.text,
      event.selection,
    );

    emit(state.copyWith(
      text: event.text,
      formattingRanges: updatedRanges,
    ));
  }

  void _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) {
    final text = event.text.trim();
    if (text.isNotEmpty || event.imageData != null) {
      final newMessage = Message(text, imageData: event.imageData,     formattingRanges: event.formattingRanges,);
      emit(ChatState(
       text: '', // Clear text after sending
        messages: [...state.messages, newMessage],
        previewImage: null, // Clear preview image after sending
          formattingRanges: const []
      ));
    } else {
      print('No content to send');
    }
  }

  void _onToggleBold(ToggleBoldEvent event, Emitter<ChatState> emit) {
    final newRanges = _toggleFormatting(
      state.formattingRanges,
      event.selection,
      isBold: true,
    );
    emit(state.copyWith(formattingRanges: newRanges));
  }

  void _onToggleItalic(ToggleItalicEvent event, Emitter<ChatState> emit) {
    final newRanges = _toggleFormatting(
      state.formattingRanges,
      event.selection,
      isItalic: true,
    );
    emit(state.copyWith(formattingRanges: newRanges));
  }

  void _onToggleStrikethrough(ToggleStrikethroughEvent event, Emitter<ChatState> emit) {
    final newRanges = _toggleFormatting(
      state.formattingRanges,
      event.selection,
      isStrikethrough: true,
    );
    emit(state.copyWith(formattingRanges: newRanges));
  }

  List<FormattingRange> _toggleFormatting(
    List<FormattingRange> ranges,
    TextSelection selection, {
    bool isBold = false,
    bool isItalic = false,
    bool isStrikethrough = false,
  }) {
    if (selection.start == -1 || selection.end == -1 || selection.start == selection.end) {
      return ranges;
    }

    final newRanges = List<FormattingRange>.from(ranges);
    final start = selection.start;
    final end = selection.end;
    FormattingRange? existingRange;

    for (var range in newRanges) {
      if (range.start == start && range.end == end) {
        existingRange = range;
        break;
      }
    }

    if (existingRange != null) {
      if (isBold) existingRange.isBold = !existingRange.isBold;
      if (isItalic) existingRange.isItalic = !existingRange.isItalic;
      if (isStrikethrough) existingRange.isStrikethrough = !existingRange.isStrikethrough;

      if (!existingRange.isBold && !existingRange.isItalic && !existingRange.isStrikethrough) {
        newRanges.remove(existingRange);
      }
    } else {
      newRanges.add(FormattingRange(
        start: start,
        end: end,
        isBold: isBold,
        isItalic: isItalic,
        isStrikethrough: isStrikethrough,
      ));
    }

    newRanges.sort((a, b) => a.start.compareTo(b.start));
    return newRanges;
  }

  List<FormattingRange> _updateFormattingRanges(
    List<FormattingRange> ranges,
    String oldText,
    String newText,
    TextSelection selection,
  ) {
    final newRanges = <FormattingRange>[];

    if (newText.length > oldText.length) {
      final lengthDiff = newText.length - oldText.length;
      var insertPos = selection.baseOffset;
      if (insertPos < 0) insertPos = newText.length - lengthDiff;

      for (var range in ranges) {
        if (range.start >= insertPos) {
          newRanges.add(FormattingRange(
            start: range.start + lengthDiff,
            end: range.end + lengthDiff,
            isBold: range.isBold,
            isItalic: range.isItalic,
            isStrikethrough: range.isStrikethrough,
          ));
        } else if (range.end > insertPos) {
          newRanges.add(FormattingRange(
            start: range.start,
            end: range.end + lengthDiff,
            isBold: range.isBold,
            isItalic: range.isItalic,
            isStrikethrough: range.isStrikethrough,
          ));
        } else {
          newRanges.add(range);
        }
      }
    } else if (newText.length < oldText.length) {
      final charsDeleted = oldText.length - newText.length;
      final deleteStart = selection.start == selection.end ? selection.baseOffset : selection.start;
      final deleteEnd = deleteStart + charsDeleted;

      for (var range in ranges) {
        if (range.end <= deleteStart) {
          newRanges.add(range);
        } else if (range.start >= deleteEnd) {
          newRanges.add(FormattingRange(
            start: range.start - charsDeleted,
            end: range.end - charsDeleted,
            isBold: range.isBold,
            isItalic: range.isItalic,
            isStrikethrough: range.isStrikethrough,
          ));
        } else {
          if (range.start < deleteStart && range.end > deleteEnd) {
            newRanges.add(FormattingRange(
              start: range.start,
              end: deleteStart,
              isBold: range.isBold,
              isItalic: range.isItalic,
              isStrikethrough: range.isStrikethrough,
            ));
            newRanges.add(FormattingRange(
              start: deleteStart,
              end: range.end - charsDeleted,
              isBold: range.isBold,
              isItalic: range.isItalic,
              isStrikethrough: range.isStrikethrough,
            ));
          } else if (range.start >= deleteStart && range.start < deleteEnd) {
            if (range.end > deleteEnd) {
              newRanges.add(FormattingRange(
                start: deleteStart,
                end: range.end - charsDeleted,
                isBold: range.isBold,
                isItalic: range.isItalic,
                isStrikethrough: range.isStrikethrough,
              ));
            }
          } else if (range.end > deleteStart && range.end <= deleteEnd) {
            newRanges.add(FormattingRange(
              start: range.start,
              end: deleteStart,
              isBold: range.isBold,
              isItalic: range.isItalic,
              isStrikethrough: range.isStrikethrough,
            ));
          }
        }
      }
    } else {
      newRanges.addAll(ranges);
    }

    return newRanges.where((range) => range.start != range.end).toList();
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paste_snap_demo/model/formatting_range.dart';
import 'package:paste_snap_demo/model/message.dart';
import 'package:paste_snap_demo/utils/color.dart';
import 'package:paste_snap_demo/utils/custom_controller.dart';
import '../bloc/chat_bloc_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late StyleableTextFieldController _messageController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messageController = StyleableTextFieldController(formattingRanges: []);
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    context.read<ChatBloc>().add(UpdateTextEvent(
      _messageController.text,
      _messageController.selection,
    ));
  }

  void _handlePaste() {
    context.read<ChatBloc>().add(PasteImageEvent());
  }

  void _sendMessage() {
    final state = context.read<ChatBloc>().state;
    final text = _messageController.text.trim();
    final imageData = state.previewImage;
    if (text.isNotEmpty || imageData != null) {
      context.read<ChatBloc>().add(SendMessageEvent(
        text: text,
        imageData: imageData,
        formattingRanges: state.formattingRanges,
      ));
      _messageController.clear();
      setState(() {}); // Force rebuild to clear any residual state
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
 
  void _clearPreviewImage() {
    final currentState = context.read<ChatBloc>().state;
    context.read<ChatBloc>().emit(ChatState(
          text: currentState.text,
          messages: currentState.messages,
        ));
  }

  void _toggleBold() {
    final selection = _messageController.selection;
    if (selection.start == -1 || selection.end == -1 || selection.start == selection.end) return;

    context.read<ChatBloc>().add(ToggleBoldEvent(selection));
    _forceTextFieldRebuild();
    ContextMenuController.removeAny();
  }

  void _toggleItalic() {
    final selection = _messageController.selection;
    if (selection.start == -1 || selection.end == -1 || selection.start == selection.end) return;

    context.read<ChatBloc>().add(ToggleItalicEvent(selection));
    _forceTextFieldRebuild();
    ContextMenuController.removeAny();
  }

  void _toggleStrikethrough() {
    final selection = _messageController.selection;
    if (selection.start == -1 || selection.end == -1 || selection.start == selection.end) return;

    context.read<ChatBloc>().add(ToggleStrikethroughEvent(selection));
    _forceTextFieldRebuild();
    ContextMenuController.removeAny();
  }

  void _forceTextFieldRebuild() {
    final currentText = _messageController.text;
    final currentSelection = _messageController.selection;
    setState(() {
      _messageController.text = currentText;
      _messageController.selection = currentSelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildChatScreen(),
    );
  }

  Widget _buildChatScreen() {
    return Container(
      decoration: const BoxDecoration(
        color: PasteSnapColors.background,
      ),
      child: SafeArea(
        child: BlocConsumer<ChatBloc, ChatState>(
          listenWhen: (previous, current) =>
              previous.previewImage != current.previewImage ||
              previous.formattingRanges != current.formattingRanges,
          listener: (context, state) {
            _messageController.updateFormatting(state.formattingRanges);
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildAppBar(),
                _buildMessagesList(state),
                _buildImagePreview(state),
                _buildInputArea(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PasteSnapColors.primary, Color(0xFF7842FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: PasteSnapColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 18,
              child: Icon(
                Icons.content_paste_rounded,
                color: PasteSnapColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PasteSnap',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Instant Image Sharing',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState state) {
    return Expanded(
      child: state.messages.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: state.messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (context, index) {
                final message = state.messages[state.messages.length - 1 - index];
                return _buildMessageBubble(message, index, state);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: PasteSnapColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 60,
              color: PasteSnapColors.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Gallery Awaits',
            style: TextStyle(
              color: PasteSnapColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 240,
            child: const Text(
              'Paste images or capture moments to start sharing instantly',
              style: TextStyle(
                color: PasteSnapColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: PasteSnapColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: PasteSnapColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Tip: Long press TextField to paste images or format text',
                  style: TextStyle(
                    color: PasteSnapColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, int index, ChatState state) {
    final isLastMessage = index == state.messages.length - 1;
    final showDate = isLastMessage ||
        index < state.messages.length - 1 &&
            _shouldShowDateSeparator(message, index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showDate) _buildDateSeparator(message.timestamp),
        Container(
          margin: const EdgeInsets.only(top: 6, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 60),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        PasteSnapColors.messageBubble,
                        PasteSnapColors.messageBubbleGradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PasteSnapColors.primary.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (message.imageData != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: Image.memory(
                              message.imageData!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.error_outline),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      if (message.text != null && message.text!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RichText(
                            text: _buildFormattedTextSpan(
                              message.text!,
                              message.formattingRanges,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 8, bottom: 2, left: 8, top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMessageTime(message.timestamp),
                              style: const TextStyle(
                                color: PasteSnapColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: PasteSnapColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextSpan _buildFormattedTextSpan(String text, List<FormattingRange> ranges) {
    final textSpanChildren = <InlineSpan>[];
    var lastEnd = 0;

    final sortedRanges = List<FormattingRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final range in sortedRanges) {
      if (range.start < 0 || range.end > text.length || range.start >= range.end) {
        continue;
      }

      if (range.start > lastEnd) {
        final unstyledText = text.substring(lastEnd, range.start);
        textSpanChildren.add(TextSpan(
          text: unstyledText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ));
      }

      final rangeStyle = TextStyle(
        fontWeight: range.isBold ? FontWeight.bold : null,
        fontStyle: range.isItalic ? FontStyle.italic : null,
        decoration: range.isStrikethrough ? TextDecoration.lineThrough : null,
        color: Colors.white,
        fontSize: 16,
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ));
    }

    return TextSpan(children: textSpanChildren);
  }

  Widget _buildDateSeparator(String timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PasteSnapColors.primary.withOpacity(0.2),
                  PasteSnapColors.secondary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                color: PasteSnapColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(Message message, int index) {
    return false; // Implement date comparison as needed
  }

  String _formatMessageTime(String timestamp) {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildImagePreview(ChatState state) {
    if (state.previewImage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: 200,
              maxWidth: MediaQuery.of(context).size.width,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                state.previewImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 18,
            child: GestureDetector(
              onTap: _clearPreviewImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 18,
            child: Row(
              children: [
                _buildImageActionButton(Icons.crop, () {}),
                const SizedBox(width: 8),
                _buildImageActionButton(Icons.edit, () {}),
                const SizedBox(width: 8),
                _buildImageActionButton(Icons.filter, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageActionButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [PasteSnapColors.primary, Color(0xFF7842FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: PasteSnapColors.primary.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: PasteSnapColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  color: PasteSnapColors.primary),
              onPressed: _handlePaste,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: PasteSnapColors.inputBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: PasteSnapColors.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: state.previewImage != null
                            ? 'Add a caption...'
                            : 'Type a message...',
                        border: InputBorder.none,
                        hintStyle: const TextStyle(
                          color: PasteSnapColors.textSecondary,
                          fontSize: 15,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      maxLines: 5,
                      minLines: 1,
                      style: const TextStyle(
                        color: PasteSnapColors.textPrimary,
                        fontSize: 15,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      contextMenuBuilder: (context, editableTextState) {
                        final hasSelection =
                            editableTextState.textEditingValue.selection.start !=
                                    -1 &&
                                editableTextState.textEditingValue.selection.end !=
                                    -1 &&
                                editableTextState
                                        .textEditingValue.selection.start !=
                                    editableTextState
                                        .textEditingValue.selection.end;

                        final buttonItems = <ContextMenuButtonItem>[];

                        if (hasSelection) {
                          buttonItems.addAll([
                            ContextMenuButtonItem(
                              label: 'Bold',
                              onPressed: _toggleBold,
                            ),
                            ContextMenuButtonItem(
                              label: 'Italic',
                              onPressed: _toggleItalic,
                            ),
                            ContextMenuButtonItem(
                              label: 'Strikethrough',
                              onPressed: _toggleStrikethrough,
                            ),
                          ]);
                        }

                        buttonItems.add(ContextMenuButtonItem(
                          label: 'Paste',
                          onPressed: () {
                            ContextMenuController.removeAny();
                            _handlePaste();
                          },
                        ));

                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: editableTextState.contextMenuAnchors,
                          buttonItems: buttonItems,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: PasteSnapColors.primary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: PasteSnapColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [PasteSnapColors.primary, Color(0xFF7842FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: PasteSnapColors.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
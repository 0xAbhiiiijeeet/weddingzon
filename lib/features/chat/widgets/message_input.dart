import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(List<File>) onSendImages; // Changed to accept List<File>
  final VoidCallback? onTypingStarted;
  final VoidCallback? onTypingStopped;
  final bool isSending;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    required this.onSendImages,
    this.onTypingStarted,
    this.onTypingStopped,
    this.isSending = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        widget.onTypingStarted?.call();
      } else {
        widget.onTypingStopped?.call();
      }
    } else if (hasText) {
      // Still typing, reset timer
      widget.onTypingStarted?.call();
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _controller.clear();
    widget.onTypingStopped?.call();
  }

  Future<void> _pickImages() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery (upto 10 images)'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      List<XFile> images = [];

      if (source == ImageSource.gallery) {
        // Pick multiple images from gallery
        images = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
          limit: 10, // Limit to 10 images
        );
      } else {
        // Pick single image from camera
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (image != null) {
          images.add(image);
        }
      }

      if (images.isNotEmpty && mounted) {
        debugPrint('[MESSAGE_INPUT] Images picked: ${images.length}');

        if (images.length > 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can only send up to 10 images at once.'),
              ),
            );
          }
          images = images.take(10).toList();
        }

        widget.onSendImages(images.map((x) => File(x.path)).toList());
      }
    } catch (e) {
      debugPrint('[MESSAGE_INPUT] Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image picker button
            IconButton(
              onPressed: widget.isSending ? null : _pickImages,
              icon: const Icon(Icons.image_outlined),
              color: theme.colorScheme.primary,
            ),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: widget.isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _hasText ? _sendMessage : null,
                      icon: const Icon(Icons.arrow_upward),
                      color: theme.colorScheme.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: _hasText
                            ? theme.colorScheme.primaryContainer
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }
}

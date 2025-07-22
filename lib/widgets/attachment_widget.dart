import 'dart:io';
import 'package:flutter/material.dart';
import '../models/attachment.dart';
import '../services/attachment_service.dart';

class AttachmentWidget extends StatefulWidget {
  final Attachment attachment;
  final VoidCallback? onDelete;

  const AttachmentWidget({
    super.key,
    required this.attachment,
    this.onDelete,
  });

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  final AttachmentService _attachmentService = AttachmentService();
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _buildLeading(),
        title: Text(
          widget.attachment.fileName,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(),
        onTap: _handleTap,
        dense: true,
      ),
    );
  }

  Widget _buildLeading() {
    switch (widget.attachment.type) {
      case AttachmentType.image:
        if (File(widget.attachment.filePath).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(widget.attachment.filePath),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          );
        }
        return const Icon(Icons.image, size: 24);

      case AttachmentType.audio:
        return Icon(
          _isPlaying ? Icons.pause_circle : Icons.play_circle,
          size: 24,
          color: Theme.of(context).primaryColor,
        );

      case AttachmentType.text:
        return const Icon(Icons.text_snippet, size: 24);
    }
  }

  Widget? _buildSubtitle() {
    final parts = <String>[];

    if (widget.attachment.formattedFileSize.isNotEmpty) {
      parts.add(widget.attachment.formattedFileSize);
    }

    parts.add(widget.attachment.typeText);

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget? _buildTrailing() {
    return widget.onDelete != null
        ? IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline),
            iconSize: 18,
            color: Colors.red.shade400,
          )
        : null;
  }

  void _handleTap() {
    switch (widget.attachment.type) {
      case AttachmentType.image:
        _showImageDialog();
        break;
      case AttachmentType.audio:
        _toggleAudio();
        break;
      case AttachmentType.text:
        _showTextDialog();
        break;
    }
  }

  void _showImageDialog() {
    if (!File(widget.attachment.filePath).existsSync()) {
      _showErrorSnackBar('Image file not found');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(widget.attachment.fileName),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: Image.file(
                File(widget.attachment.filePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _toggleAudio() async {
    if (!File(widget.attachment.filePath).existsSync()) {
      _showErrorSnackBar('Audio file not found');
      return;
    }

    try {
      if (_isPlaying) {
        await _attachmentService.stopAudio();
        setState(() {
          _isPlaying = false;
        });
      } else {
        final success =
            await _attachmentService.playAudio(widget.attachment.filePath);
        if (success) {
          setState(() {
            _isPlaying = true;
          });

          // 监听播放完成（简单实现）
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && !_attachmentService.isPlaying) {
              setState(() {
                _isPlaying = false;
              });
            }
          });
        } else {
          _showErrorSnackBar('音频播放失败');
        }
      }
    } catch (e) {
      _showErrorSnackBar('音频播放出错: $e');
    }
  }

  void _showTextDialog() async {
    String? content = widget.attachment.textContent;

    if (content == null || content.isEmpty) {
      content =
          await _attachmentService.readTextFile(widget.attachment.filePath);
    }

    if (content == null) {
      _showErrorSnackBar('无法读取文本文件');
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(widget.attachment.fileName),
          content: SingleChildScrollView(
            child: Text(content!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class AttachmentListWidget extends StatelessWidget {
  final List<Attachment> attachments;
  final Function(int index)? onDelete;
  final Function(AttachmentType type)? onAdd;
  final bool showAddButton;

  const AttachmentListWidget({
    super.key,
    required this.attachments,
    this.onDelete,
    this.onAdd,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty && !showAddButton) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.attach_file, size: 20),
                const SizedBox(width: 8),
                Text(
                  '附件 (${attachments.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),

            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              // 附件列表
              ...attachments.asMap().entries.map((entry) {
                final index = entry.key;
                final attachment = entry.value;

                return AttachmentWidget(
                  attachment: attachment,
                  onDelete: onDelete != null ? () => onDelete!(index) : null,
                );
              }),
            ],

            // 添加按钮
            if (showAddButton) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _AddAttachmentButton(
                    icon: Icons.photo,
                    label: '图片',
                    onPressed: () => onAdd?.call(AttachmentType.image),
                  ),
                  _AddAttachmentButton(
                    icon: Icons.mic,
                    label: '音频',
                    onPressed: () => onAdd?.call(AttachmentType.audio),
                  ),
                  _AddAttachmentButton(
                    icon: Icons.text_snippet,
                    label: '文本',
                    onPressed: () => onAdd?.call(AttachmentType.text),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddAttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _AddAttachmentButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}

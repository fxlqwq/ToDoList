import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class MarkdownToggleWidget extends StatefulWidget {
  final String text;
  final bool useMarkdown;
  final Function(String)? onTextChanged;
  final Function(bool)? onMarkdownToggle;
  final bool isEditing;
  final String? hintText;
  final TextStyle? style;
  final int? maxLines;

  const MarkdownToggleWidget({
    super.key,
    required this.text,
    required this.useMarkdown,
    this.onTextChanged,
    this.onMarkdownToggle,
    this.isEditing = false,
    this.hintText,
    this.style,
    this.maxLines,
  });

  @override
  State<MarkdownToggleWidget> createState() => _MarkdownToggleWidgetState();
}

class _MarkdownToggleWidgetState extends State<MarkdownToggleWidget> {
  late TextEditingController _controller;
  late bool _previewMode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _previewMode = !widget.isEditing && widget.useMarkdown;
  }

  @override
  void didUpdateWidget(MarkdownToggleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.text = widget.text;
    }
    if (oldWidget.isEditing != widget.isEditing ||
        oldWidget.useMarkdown != widget.useMarkdown) {
      _previewMode = !widget.isEditing && widget.useMarkdown;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) {
      return _buildDisplay();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditor(),
        if (widget.useMarkdown) ...[
          const SizedBox(height: 8),
          _buildMarkdownControls(),
        ],
      ],
    );
  }

  Widget _buildDisplay() {
    if (widget.text.isEmpty) {
      return Text(
        widget.hintText ?? '',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (widget.useMarkdown) {
      return MarkdownBody(
        data: widget.text,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: widget.style ?? Theme.of(context).textTheme.bodyMedium,
          blockquotePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          blockquoteDecoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              left: BorderSide(color: Colors.grey.shade400, width: 4),
            ),
          ),
        ),
        extensionSet: md.ExtensionSet(
          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
        ),
      );
    } else {
      return Text(
        widget.text,
        style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
        maxLines: widget.maxLines,
        overflow: widget.maxLines != null ? TextOverflow.ellipsis : null,
      );
    }
  }

  Widget _buildEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Markdown切换开关
        Row(
          children: [
            Switch.adaptive(
              value: widget.useMarkdown,
              onChanged: widget.onMarkdownToggle,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Text(
              'Markdown',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Spacer(),
            if (widget.useMarkdown && _previewMode)
              TextButton.icon(
                onPressed: () => setState(() => _previewMode = false),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('编辑'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (widget.useMarkdown && !_previewMode)
              TextButton.icon(
                onPressed: () => setState(() => _previewMode = true),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('预览'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 编辑器或预览
        if (widget.useMarkdown && _previewMode)
          _buildPreview()
        else
          _buildTextField(),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      onChanged: widget.onTextChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: widget.maxLines ?? 4,
      style: widget.style,
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: widget.text.isEmpty
          ? Text(
              widget.hintText ?? 'Enter text to preview...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          : MarkdownBody(
              data: widget.text,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: widget.style ?? Theme.of(context).textTheme.bodyMedium,
              ),
              extensionSet: md.ExtensionSet(
                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                [
                  md.EmojiSyntax(),
                  ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
                ],
              ),
            ),
    );
  }

  Widget _buildMarkdownControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Markdown快捷工具',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                _MarkdownButton(
                  label: 'B',
                  tooltip: '粗体',
                  onPressed: () => _insertMarkdown('**', '**'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _MarkdownButton(
                  label: 'I',
                  tooltip: '斜体',
                  onPressed: () => _insertMarkdown('*', '*'),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                _MarkdownButton(
                  label: '~',
                  tooltip: '删除线',
                  onPressed: () => _insertMarkdown('~~', '~~'),
                ),
                _MarkdownButton(
                  label: 'H',
                  tooltip: '标题',
                  onPressed: () => _insertMarkdown('## ', ''),
                ),
                _MarkdownButton(
                  label: '•',
                  tooltip: '项目列表',
                  onPressed: () => _insertMarkdown('- ', ''),
                ),
                _MarkdownButton(
                  label: '1.',
                  tooltip: '数字列表',
                  onPressed: () => _insertMarkdown('1. ', ''),
                ),
                _MarkdownButton(
                  label: '>"',
                  tooltip: '引用',
                  onPressed: () => _insertMarkdown('> ', ''),
                ),
                _MarkdownButton(
                  label: '`',
                  tooltip: '代码',
                  onPressed: () => _insertMarkdown('`', '`'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isValid) {
      final before = text.substring(0, selection.start);
      final selected = text.substring(selection.start, selection.end);
      final after = text.substring(selection.end);

      final newText = before + prefix + selected + suffix + after;
      _controller.text = newText;

      // 设置新的光标位置
      final newSelection = TextSelection.collapsed(
        offset:
            selection.start + prefix.length + selected.length + suffix.length,
      );
      _controller.selection = newSelection;

      widget.onTextChanged?.call(newText);
    }
  }
}

class _MarkdownButton extends StatelessWidget {
  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final TextStyle? style;

  const _MarkdownButton({
    required this.label,
    this.tooltip,
    this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: style?.copyWith(fontSize: 12) ?? const TextStyle(fontSize: 12),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with WidgetsBindingObserver {
  final DatabaseService _db = DatabaseService();
  final ImageService _imageService = ImageService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _saveTimer;
  Timer? _dateCheckTimer;

  late String _currentDate;
  late String _today;
  Entry? _currentEntry;
  bool _isLoading = true;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _today = _formatDate(DateTime.now());
    _currentDate = _today;
    _loadEntry();
    _controller.addListener(_onTextChanged);
    _startDateCheckTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _dateCheckTimer?.cancel();
    _saveCurrentEntrySync();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDateChange();
    }
  }

  void _startDateCheckTimer() {
    _dateCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkDateChange();
    });
  }

  void _checkDateChange() {
    final newToday = _formatDate(DateTime.now());
    if (newToday != _today) {
      final wasViewingToday = _currentDate == _today;

      // Save current entry before date change
      if (wasViewingToday) {
        _saveCurrentEntrySync();
      }

      setState(() {
        _today = newToday;
        // If we were viewing "today", stay on that date (now read-only)
        // User can navigate forward to the new today
      });
    }
  }

  void _onTextChanged() {
    if (!_isToday) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveCurrentEntry();
    });
  }

  void _saveCurrentEntrySync() {
    if (!_isToday) return;
    final content = _controller.text;
    if (content.isEmpty && _currentEntry == null) return;

    final now = DateTime.now();
    final entry = Entry(
      date: _currentDate,
      content: content,
      createdAt: _currentEntry?.createdAt ?? now,
      updatedAt: now,
    );

    // Fire and forget - best effort on dispose
    _db.saveEntry(entry);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDisplayDate(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('EEEE, MMMM d, yyyy').format(parsed);
  }

  bool get _isToday => _currentDate == _today;

  Future<void> _loadEntry() async {
    setState(() => _isLoading = true);

    final entry = await _db.getEntry(_currentDate);
    setState(() {
      _currentEntry = entry;
      _controller.text = entry?.content ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveCurrentEntry() async {
    if (!_isToday) return;

    final content = _controller.text;
    if (content.isEmpty && _currentEntry == null) return;

    final now = DateTime.now();
    final entry = Entry(
      date: _currentDate,
      content: content,
      createdAt: _currentEntry?.createdAt ?? now,
      updatedAt: now,
    );

    await _db.saveEntry(entry);
    _currentEntry = entry;
  }

  Future<void> _navigateToPreviousDay() async {
    await _saveCurrentEntry();

    // First check if there's a previous entry in the database
    final previousDate = await _db.getPreviousEntryDate(_currentDate);
    if (previousDate != null) {
      setState(() => _currentDate = previousDate);
      await _loadEntry();
    } else {
      // Navigate to previous calendar day
      final current = DateTime.parse(_currentDate);
      final previous = current.subtract(const Duration(days: 1));
      setState(() => _currentDate = _formatDate(previous));
      await _loadEntry();
    }
  }

  Future<void> _navigateToNextDay() async {
    if (_isToday) return;

    await _saveCurrentEntry();

    final current = DateTime.parse(_currentDate);
    final next = current.add(const Duration(days: 1));
    final nextDate = _formatDate(next);

    // Don't go past today
    if (nextDate.compareTo(_today) > 0) return;

    setState(() => _currentDate = nextDate);
    await _loadEntry();
  }

  Future<void> _goToToday() async {
    if (_isToday) return;

    await _saveCurrentEntry();
    setState(() => _currentDate = _today);
    await _loadEntry();
  }

  Future<void> _addImage() async {
    final imagePath = await _imageService.pickAndSaveImage(_currentDate);
    if (imagePath == null) return;

    final markdownLink = _imageService.getMarkdownImageLink(imagePath);
    final cursorPos = _controller.selection.baseOffset;
    final text = _controller.text;

    final newText = cursorPos >= 0
        ? '${text.substring(0, cursorPos)}\n$markdownLink\n${text.substring(cursorPos)}'
        : '$text\n$markdownLink\n';

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: cursorPos >= 0 ? cursorPos + markdownLink.length + 2 : newText.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_formatDisplayDate(_currentDate)),
        actions: [
          if (_isToday)
            IconButton(
              icon: Icon(_showPreview ? Icons.edit : Icons.preview),
              tooltip: _showPreview ? 'Edit' : 'Preview',
              onPressed: () => setState(() => _showPreview = !_showPreview),
            ),
          if (!_isToday)
            TextButton.icon(
              icon: const Icon(Icons.today),
              label: const Text('Today'),
              onPressed: _goToToday,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildNavigationBar(),
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous day',
            onPressed: _navigateToPreviousDay,
          ),
          if (!_isToday)
            Chip(
              label: const Text('Read Only'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          if (_isToday)
            Chip(
              label: const Text('Today'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next day',
            onPressed: _isToday ? null : _navigateToNextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_isToday || _showPreview) {
      return _buildMarkdownView();
    }
    return _buildEditor();
  }

  Widget _buildEditor() {
    // Request focus when editor is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write your journal entry...\n\nSupports Markdown formatting.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addImage,
                icon: const Icon(Icons.image),
                label: const Text('Add Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownView() {
    final content = _controller.text;
    if (content.isEmpty) {
      return Center(
        child: Text(
          _isToday ? 'No entry yet. Start writing!' : 'No entry for this day.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Markdown(
      data: content,
      selectable: true,
      imageBuilder: (uri, title, alt) {
        final file = File(uri.toFilePath());
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text('Image not found: ${uri.path}'),
              );
            },
          );
        }
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Text('Image not found: ${uri.path}'),
        );
      },
      padding: const EdgeInsets.all(16),
    );
  }
}

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

```bash
# Install dependencies
flutter pub get

# Run on macOS (primary target platform)
flutter run -d macos

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

### macOS Setup (Apple Silicon)
```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

## Architecture

This is a Flutter daily journal app targeting macOS. The app allows users to write one journal entry per day with markdown support and image embedding.

### Core Concepts
- **One entry per day**: Entries are keyed by date (YYYY-MM-DD format). Only today's entry is editable; past entries are read-only.
- **Auto-save**: Changes are debounced (500ms) and automatically saved to SQLite.
- **Markdown rendering**: Entries support markdown formatting with live preview toggle.
- **Image storage**: Images are copied to `~/Library/Application Support/daily_journal/images/{date}/` and embedded via markdown links.

### Code Structure
- `lib/main.dart` - App entry point with MaterialApp and theme configuration
- `lib/screens/journal_screen.dart` - Main UI with editor, markdown preview, and date navigation
- `lib/services/database_service.dart` - SQLite persistence using sqflite
- `lib/services/image_service.dart` - Image picking and storage with file_picker
- `lib/models/entry.dart` - Entry data model with date as primary key

### Key Dependencies
- `sqflite` - SQLite database
- `flutter_markdown` - Markdown rendering
- `file_picker` - Image selection
- `intl` - Date formatting

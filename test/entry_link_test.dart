import 'package:flutter_test/flutter_test.dart';

import 'package:daily_journal/utils/entry_link.dart';

void main() {
  test('markdownFor builds a labelled journal link', () {
    expect(
      EntryLink.markdownFor('2026-11-20'),
      '[Friday, November 20, 2026](journal:2026-11-20)',
    );
  });

  test('parseDate extracts the date from a journal link', () {
    expect(EntryLink.parseDate('journal:2026-11-20'), '2026-11-20');
  });

  test('parseDate ignores other links and malformed dates', () {
    expect(EntryLink.parseDate(null), isNull);
    expect(EntryLink.parseDate('https://example.com'), isNull);
    expect(EntryLink.parseDate('journal:yesterday'), isNull);
    expect(EntryLink.parseDate('journal:2026-1-2'), isNull);
  });
}

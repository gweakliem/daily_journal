import 'package:intl/intl.dart';

/// Links between entries are stored as markdown links with a custom scheme:
/// `[Thursday, November 20, 2026](journal:2026-11-20)`.
class EntryLink {
  static const scheme = 'journal';
  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Builds a markdown link to the entry for [date] (YYYY-MM-DD).
  static String markdownFor(String date) {
    final label = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(date));
    return '[$label]($scheme:$date)';
  }

  /// Returns the YYYY-MM-DD date an entry link points to, or null if [href]
  /// is not an entry link.
  static String? parseDate(String? href) {
    if (href == null) return null;
    final prefix = '$scheme:';
    if (!href.startsWith(prefix)) return null;
    final date = href.substring(prefix.length);
    if (!_datePattern.hasMatch(date)) return null;
    return DateTime.tryParse(date) == null ? null : date;
  }
}

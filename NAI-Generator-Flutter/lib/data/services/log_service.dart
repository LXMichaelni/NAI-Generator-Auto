import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LogService {
  static final LogService _instance = LogService._();
  factory LogService() => _instance;
  LogService._();

  File? _logFile;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final now = DateTime.now();
      final fileName = _formatFileName(now);
      final appDir = await getApplicationSupportDirectory();
      final logsDir = Directory(
        '${appDir.path}${Platform.pathSeparator}logs',
      );
      await logsDir.create(recursive: true);
      _logFile = File('${logsDir.path}${Platform.pathSeparator}$fileName.log');
      await _logFile!.writeAsString('', mode: FileMode.append, flush: true);
    } catch (_) {
      // Fail silently to avoid affecting app runtime.
      _logFile = null;
    }
  }

  Future<void> logRateLimit429() async {
    await _writeLine('429 Concurrent generation is locked');
  }

  Future<void> logHandshakeException(String detail) async {
    await _writeLine('HandshakeException: $detail');
  }

  Future<void> _writeLine(String message) async {
    if (_logFile == null) return;
    final ts = _formatTimestamp(DateTime.now());
    try {
      await _logFile!
          .writeAsString('[$ts] $message\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Ignore write errors.
    }
  }

  String _formatFileName(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

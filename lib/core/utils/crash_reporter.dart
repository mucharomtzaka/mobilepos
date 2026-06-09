import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CrashReporter {
  static final CrashReporter _instance = CrashReporter._();
  factory CrashReporter() => _instance;
  CrashReporter._();

  Timer? _anrTimer;
  DateTime _lastFrame = DateTime.now();
  final List<String> _logs = [];

  static Future<void> init() async {
    final reporter = CrashReporter();

    FlutterError.onError = (details) {
      reporter._logError(details.exceptionAsString(), details.stack.toString());
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      reporter._logError(error.toString(), stack.toString());
      return true;
    };

    reporter._startAnrDetector();

    await reporter._loadPending();
  }

  void _startAnrDetector() {
    _anrTimer?.cancel();
    _anrTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final elapsed = DateTime.now().difference(_lastFrame).inMilliseconds;
      if (elapsed > 3000) {
        _logWarning('ANR suspected: UI frozen for ${elapsed}ms');
      }
      _lastFrame = DateTime.now();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastFrame = DateTime.now();
    });
  }

  void _logError(String error, String stack) {
    final entry = '[${DateTime.now().toIso8601String()}] ERROR: $error\n$stack';
    _logs.add(entry);
    _save(entry);
  }

  void _logWarning(String msg) {
    final entry = '[${DateTime.now().toIso8601String()}] WARN: $msg';
    _logs.add(entry);
    _save(entry);
  }

  Future<File> get _logFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/crash_logs.txt');
  }

  Future<void> _save(String entry) async {
    try {
      final file = await _logFile;
      await file.writeAsString('$entry\n', mode: FileMode.append);
    } catch (_) {}
  }

  Future<void> _loadPending() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          _logs.addAll(content.trim().split('\n').where((l) => l.isNotEmpty));
        }
      }
    } catch (_) {}
  }

  Future<void> sendReport() async {
    final file = await _logFile;
    if (!await file.exists()) {
      return;
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return;
    }

    final dir = await getTemporaryDirectory();
    final copy = File('${dir.path}/crash_report.txt');
    await file.copy(copy.path);

    await Share.shareXFiles(
      [XFile(copy.path)],
      subject: 'Laporan Crash / ANR - Drone POS',
      text: 'Berikut laporan error dan ANR dari aplikasi Drone POS.',
    );
  }

  Future<bool> hasPendingReports() async {
    try {
      final file = await _logFile;
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      return content.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    _logs.clear();
    try {
      final file = await _logFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

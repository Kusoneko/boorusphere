import 'package:boorusphere/data/repository/download/entity/download_entry.dart';
import 'package:boorusphere/data/repository/download/entity/download_progress.dart';
import 'package:boorusphere/data/repository/download/entity/download_status.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';

class DownloaderSource {
  DownloaderSource({required this.entryBox, required this.progressBox});

  final Box<DownloadEntry> entryBox;
  final Box<DownloadProgress> progressBox;

  Iterable<DownloadEntry> get entries => entryBox.values;
  Iterable<DownloadProgress> get progresses => progressBox.values;

  Future<void> add(DownloadEntry entry) async {
    await entryBox.put(entry.id, entry);
  }

  Future<void> updateProgress(DownloadProgress progress) async {
    await progressBox.put(progress.id, progress);
  }

  Future<void> remove(String id) async {
    await entryBox.delete(id);
    await progressBox.delete(id);
  }

  Future<void> clear() async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks != null) {
      await Future.wait(tasks.map(
        (e) async => await FlutterDownloader.remove(
            taskId: e.taskId, shouldDeleteContent: false),
      ));
    }

    await entryBox.deleteAll(entryBox.keys);
    await progressBox.deleteAll(progressBox.keys);
  }

  static const String entryKey = 'downloads';
  static const String progressKey = 'download_progresses';

  static Future<void> prepare() async {
    await Hive.openBox<DownloadEntry>(entryKey);
    await Hive.openBox<DownloadProgress>(progressKey);
    await _migrateFlutterDownloaderProgress();
    await FlutterDownloader.initialize();
  }

  static Future<void> _migrateFlutterDownloaderProgress() async {
    final db = await openDatabase('download_tasks.db');
    try {
      final table = await db.query('task',
          columns: ['task_id', 'progress', 'time_created', 'status']);
      final progs = table.map((x) {
        String id = x['task_id'].toString();
        int prog = int.tryParse(x['progress'].toString()) ?? 0;
        int timestamp = int.tryParse(x['time_created'].toString()) ?? 0;
        int status = x['status'] as int;
        final progress = DownloadProgress(
          id: id,
          status: switch (status) {
            1 => DownloadStatus.pending,
            2 => DownloadStatus.downloading,
            3 => DownloadStatus.downloaded,
            4 => DownloadStatus.failed,
            5 => DownloadStatus.canceled,
            6 => DownloadStatus.paused,
            _ => DownloadStatus.empty
          },
          progress: prog,
          timestamp: timestamp,
        );
        return MapEntry(id, progress);
      });

      if (progs.isNotEmpty) {
        final box = Hive.box<DownloadProgress>(progressKey);
        final absentProgs = progs.where((x) => box.keys.contains(x.key));
        await box.putAll(Map.fromEntries(absentProgs));
      }
    } finally {
      await db.close();
    }
  }
}

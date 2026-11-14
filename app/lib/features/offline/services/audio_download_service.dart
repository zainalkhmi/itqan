import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../quran/data/quran_catalog.dart';

/// Service managing offline Quran audio recitations (Download, Cache & Playback)
class AudioDownloadService {
  static final AudioDownloadService _instance = AudioDownloadService._internal();
  factory AudioDownloadService() => _instance;
  AudioDownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 25),
  ));

  String? _audioDir;
  bool _isInitialized = false;

  final Map<int, double> _surahProgress = {};
  final Set<int> _activeSurahDownloads = {};

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (!kIsWeb) {
        final docDir = await getApplicationDocumentsDirectory();
        final dir = Directory('${docDir.path}/quran_audio/alafasy');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _audioDir = dir.path;
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[AudioDownloadService] Init error: $e');
    }
  }

  @visibleForTesting
  void setBaseDirForTesting(String path) {
    _audioDir = path;
    _isInitialized = true;
  }

  String getCdnUrl(int surahNumber, int ayahNumber) {
    final sPadded = surahNumber.toString().padLeft(3, '0');
    final aPadded = ayahNumber.toString().padLeft(3, '0');
    return 'https://verses.quran.com/Alafasy/mp3/$sPadded$aPadded.mp3';
  }

  String? getLocalAudioPath(int surahNumber, int ayahNumber) {
    if (_audioDir == null) return null;
    return '$_audioDir/${surahNumber}_$ayahNumber.mp3';
  }

  bool isAyahAudioDownloaded(int surahNumber, int ayahNumber) {
    if (kIsWeb || _audioDir == null) return false;
    final path = getLocalAudioPath(surahNumber, ayahNumber);
    if (path == null) return false;
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 1024;
  }

  int getSurahDownloadedCount(int surahNumber) {
    if (kIsWeb || _audioDir == null) return 0;
    final total = QuranCatalog.getAyahCount(surahNumber);
    int count = 0;
    for (int i = 1; i <= total; i++) {
      if (isAyahAudioDownloaded(surahNumber, i)) {
        count++;
      }
    }
    return count;
  }

  bool isSurahAudioDownloaded(int surahNumber) {
    final total = QuranCatalog.getAyahCount(surahNumber);
    return getSurahDownloadedCount(surahNumber) >= total;
  }

  bool isSurahDownloading(int surahNumber) {
    return _activeSurahDownloads.contains(surahNumber);
  }

  double getSurahProgress(int surahNumber) {
    return _surahProgress[surahNumber] ?? 0.0;
  }

  Future<bool> downloadAyahAudio(int surahNumber, int ayahNumber) async {
    if (kIsWeb || _audioDir == null) return false;
    final targetPath = getLocalAudioPath(surahNumber, ayahNumber);
    if (targetPath == null) return false;

    final targetFile = File(targetPath);
    if (targetFile.existsSync() && targetFile.lengthSync() > 1024) {
      return true; // Already downloaded
    }

    final tempPath = '$targetPath.tmp';
    final url = getCdnUrl(surahNumber, ayahNumber);

    try {
      await _dio.download(url, tempPath);
      final tempFile = File(tempPath);
      if (await tempFile.exists() && await tempFile.length() > 512) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetPath);
        return true;
      }
    } catch (e) {
      debugPrint('[AudioDownloadService] Failed to download ayah $surahNumber:$ayahNumber: $e');
      try {
        final tempFile = File(tempPath);
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}
    }
    return false;
  }

  /// Downloads all ayahs of a surah in parallel chunks
  Future<bool> downloadSurah(
    int surahNumber, {
    Function(int downloaded, int total, double progress)? onProgress,
  }) async {
    await init();
    if (kIsWeb || _audioDir == null) return false;

    _activeSurahDownloads.add(surahNumber);
    final totalAyahs = QuranCatalog.getAyahCount(surahNumber);
    int downloadedCount = getSurahDownloadedCount(surahNumber);

    _surahProgress[surahNumber] = totalAyahs > 0 ? downloadedCount / totalAyahs : 0.0;
    onProgress?.call(downloadedCount, totalAyahs, _surahProgress[surahNumber]!);

    const chunkSize = 4;
    for (int i = 1; i <= totalAyahs; i += chunkSize) {
      if (!_activeSurahDownloads.contains(surahNumber)) break; // Cancelled

      final chunkEnd = (i + chunkSize - 1).clamp(1, totalAyahs);
      final futures = <Future<bool>>[];

      for (int a = i; a <= chunkEnd; a++) {
        futures.add(downloadAyahAudio(surahNumber, a));
      }

      final results = await Future.wait(futures);
      downloadedCount += results.where((r) => r).length;

      final progress = totalAyahs > 0 ? (downloadedCount / totalAyahs).clamp(0.0, 1.0) : 1.0;
      _surahProgress[surahNumber] = progress;
      onProgress?.call(downloadedCount, totalAyahs, progress);
    }

    _activeSurahDownloads.remove(surahNumber);
    final isDone = getSurahDownloadedCount(surahNumber) >= totalAyahs;
    return isDone;
  }

  void cancelDownload(int surahNumber) {
    _activeSurahDownloads.remove(surahNumber);
    _surahProgress.remove(surahNumber);
  }

  Future<void> deleteSurahAudio(int surahNumber) async {
    if (kIsWeb || _audioDir == null) return;
    final totalAyahs = QuranCatalog.getAyahCount(surahNumber);
    for (int i = 1; i <= totalAyahs; i++) {
      final path = getLocalAudioPath(surahNumber, i);
      if (path != null) {
        final f = File(path);
        if (f.existsSync()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    }
    _surahProgress.remove(surahNumber);
  }

  Future<int> getTotalAudioStorageBytes() async {
    if (kIsWeb || _audioDir == null) return 0;
    try {
      final dir = Directory(_audioDir!);
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double dBytes = bytes.toDouble();
    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    return '${dBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }
}


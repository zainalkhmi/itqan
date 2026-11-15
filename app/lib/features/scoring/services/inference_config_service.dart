import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum InferenceMode { auto, tajweedFormer, onDevice, mlServer, acoustic }

class InferenceEngineStatus {
  final InferenceMode mode;
  final bool isServerOnline;
  final bool isOnDeviceModelPresent;
  final bool isTajweedFormerAvailable;
  final String modelName;
  final int latencyMs;

  const InferenceEngineStatus({
    required this.mode,
    required this.isServerOnline,
    required this.isOnDeviceModelPresent,
    this.isTajweedFormerAvailable = true,
    required this.modelName,
    required this.latencyMs,
  });
}

final inferenceConfigProvider = StateNotifierProvider<InferenceConfigNotifier, InferenceMode>((ref) {
  return InferenceConfigNotifier();
});

class InferenceConfigNotifier extends StateNotifier<InferenceMode> {
  String _serverUrl = defaultServerUrl;

  InferenceConfigNotifier() : super(InferenceMode.auto) {
    _load();
  }

  static String get defaultServerUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  String get serverUrl => _serverUrl;

  Future<void> _load() async {
    try {
      if (!Hive.isBoxOpen('inference_config')) {
        await Hive.openBox('inference_config');
      }
      final box = Hive.box('inference_config');
      final val = box.get('mode', defaultValue: 'auto') as String;
      _serverUrl = box.get('server_url', defaultValue: defaultServerUrl) as String;
      state = switch (val) {
        'tajweedFormer' => InferenceMode.tajweedFormer,
        'onDevice' => InferenceMode.onDevice,
        'mlServer' => InferenceMode.mlServer,
        'acoustic' => InferenceMode.acoustic,
        _ => InferenceMode.auto,
      };
    } catch (_) {}
  }

  Future<void> setMode(InferenceMode mode) async {
    state = mode;
    try {
      if (!Hive.isBoxOpen('inference_config')) {
        await Hive.openBox('inference_config');
      }
      final box = Hive.box('inference_config');
      await box.put('mode', mode.name);
    } catch (_) {}
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url.trim();
    try {
      if (!Hive.isBoxOpen('inference_config')) {
        await Hive.openBox('inference_config');
      }
      final box = Hive.box('inference_config');
      await box.put('server_url', _serverUrl);
    } catch (_) {}
  }

  Future<InferenceEngineStatus> checkStatus() async {
    bool serverOnline = false;
    bool tajweedFormerAvailable = false;
    int latency = 0;
    String model = state == InferenceMode.tajweedFormer
        ? 'Quran-Lab/TajweedFormer-v4'
        : 'tarteel-ai/whisper-base-ar-quran';

    final stopwatch = Stopwatch()..start();
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 2)));
      final res = await dio.get('$_serverUrl/health');
      stopwatch.stop();
      if (res.statusCode == 200 && res.data is Map) {
        serverOnline = true;
        latency = stopwatch.elapsedMilliseconds;
        tajweedFormerAvailable = res.data['tajweedformer_available'] as bool? ?? true;
        if (state != InferenceMode.tajweedFormer) {
          model = res.data['model_id'] as String? ?? model;
        }
      }
    } catch (_) {
      stopwatch.stop();
    }

    bool onDevicePresent = false;
    try {
      final data = await rootBundle.load('assets/models/whisper-base-encoder.int8.onnx');
      onDevicePresent = data.lengthInBytes > 0;
    } catch (_) {
      onDevicePresent = false;
    }

    return InferenceEngineStatus(
      mode: state,
      isServerOnline: serverOnline,
      isOnDeviceModelPresent: onDevicePresent,
      isTajweedFormerAvailable: tajweedFormerAvailable,
      modelName: model,
      latencyMs: latency,
    );
  }
}


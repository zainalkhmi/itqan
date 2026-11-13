import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native mobile C++ JNI (Android) and Framework (iOS)
/// for 100% on-device embedded speech recognition with zero Python/server dependency.
class NativeAsrService {
  static const MethodChannel _channel = MethodChannel('com.itqan.app/asr');

  /// Checks if native C++ embedded ONNX Runtime is supported and loaded on this device
  static Future<bool> isNativeAvailable() async {
    if (kIsWeb) return false;
    try {
      final available = await _channel.invokeMethod<bool>('isAvailable');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves metadata of the bundled INT8 on-device model
  static Future<Map<String, dynamic>?> getModelInfo() async {
    if (kIsWeb) return null;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>('getModelInfo');
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Extracts the bundled ONNX model to the app's internal sandbox for direct memory-mapping
  static Future<String?> extractModel({String? assetPath}) async {
    if (kIsWeb) return null;
    try {
      final path = await _channel.invokeMethod<String>('extractModel', {
        'assetPath': assetPath ?? 'flutter_assets/assets/models/whisper-base-encoder.int8.onnx',
      });
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Runs on-device speech inference natively through the mobile C++ runtime
  static Future<Map<String, dynamic>?> transcribeNative(String audioPath) async {
    if (kIsWeb) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('transcribeAudio', {
        'audioPath': audioPath,
      });
      return result;
    } catch (_) {
      return null;
    }
  }
}


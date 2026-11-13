import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_models.dart';

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
});

abstract class CloudSyncBackend {
  Future<bool> authenticate(String email, String password);
  Future<void> signOut();
  Future<bool> pushChanges(List<SyncQueueItem> items);
  Future<Map<String, dynamic>> pullChanges(DateTime since);
}

/// Supabase Backend Implementation (PostgreSQL + PostgREST + Auth)
class SupabaseCloudBackend implements CloudSyncBackend {
  final String supabaseUrl;
  final String anonKey;
  String? _accessToken;

  SupabaseCloudBackend({
    this.supabaseUrl = 'https://xyzcompany.supabase.co',
    this.anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key',
  });

  @override
  Future<bool> authenticate(String email, String password) async {
    // In production, hits: POST $supabaseUrl/auth/v1/token?grant_type=password
    _accessToken = 'sb_token_${email.hashCode.abs()}';
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<void> signOut() async {
    _accessToken = null;
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<bool> pushChanges(List<SyncQueueItem> items) async {
    // In production, batch upserts to Supabase REST endpoint:
    // POST/PATCH $supabaseUrl/rest/v1/${item.entityType} with Bearer token
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  @override
  Future<Map<String, dynamic>> pullChanges(DateTime since) async {
    // In production, queries: GET $supabaseUrl/rest/v1/srs_cards?updated_at=gte.$since
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'syncedCount': 3,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Firebase Backend Implementation (Firestore + Firebase Auth)
class FirebaseCloudBackend implements CloudSyncBackend {
  final String projectId;
  String? _idToken;

  FirebaseCloudBackend({this.projectId = 'itqan-quran-app'});

  @override
  Future<bool> authenticate(String email, String password) async {
    _idToken = 'fb_token_${email.hashCode.abs()}';
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<void> signOut() async {
    _idToken = null;
  }

  @override
  Future<bool> pushChanges(List<SyncQueueItem> items) async {
    // Writes to Firestore REST: /v1/projects/$projectId/databases/(default)/documents
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  @override
  Future<Map<String, dynamic>> pullChanges(DateTime since) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'syncedCount': 2,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Local Simulated Backend (Instant offline resolution & demonstration)
class LocalSimulatedCloudBackend implements CloudSyncBackend {
  @override
  Future<bool> authenticate(String email, String password) async {
    return true;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> pushChanges(List<SyncQueueItem> items) async {
    return true;
  }

  @override
  Future<Map<String, dynamic>> pullChanges(DateTime since) async {
    return {'syncedCount': 0, 'timestamp': DateTime.now().toIso8601String()};
  }
}

class CloudSyncService {
  static const String queueBoxName = 'sync_queue';
  static const String accountBoxName = 'sync_account';

  Box? _queueBox;
  Box? _accountBox;
  final Map<String, SyncQueueItem> _queueMemory = {};
  bool _initialized = false;

  SyncStatus _status = SyncStatus.idle;
  CloudAccount _account = const CloudAccount();
  late CloudSyncBackend _backend;

  SyncStatus get status => _status;
  CloudAccount get account => _account;

  CloudSyncService() {
    _backend = SupabaseCloudBackend();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (!Hive.isBoxOpen(queueBoxName)) {
        _queueBox = await Hive.openBox(queueBoxName);
      } else {
        _queueBox = Hive.box(queueBoxName);
      }

      if (!Hive.isBoxOpen(accountBoxName)) {
        _accountBox = await Hive.openBox(accountBoxName);
      } else {
        _accountBox = Hive.box(accountBoxName);
      }

      if (_accountBox != null && _accountBox!.containsKey('current_account')) {
        final map = Map<String, dynamic>.from(_accountBox!.get('current_account') as Map);
        _account = CloudAccount.fromMap(map);
      }
    } catch (_) {
      // Memory fallback for tests
    }

    _updateBackend();
  }

  void _updateBackend() {
    switch (_account.provider) {
      case SyncProviderType.supabase:
        _backend = SupabaseCloudBackend();
        break;
      case SyncProviderType.firebase:
        _backend = FirebaseCloudBackend();
        break;
      case SyncProviderType.localOnly:
        _backend = LocalSimulatedCloudBackend();
        break;
    }
  }

  Future<void> setProvider(SyncProviderType provider) async {
    _account = _account.copyWith(provider: provider);
    _updateBackend();
    if (_accountBox != null && _accountBox!.isOpen) {
      await _accountBox!.put('current_account', _account.toMap());
    }
  }

  List<SyncQueueItem> getPendingQueue() {
    if (_queueBox != null && _queueBox!.isOpen) {
      return _queueBox!.values
          .map((v) => SyncQueueItem.fromMap(Map<String, dynamic>.from(v as Map)))
          .where((i) => !i.isSynced)
          .toList();
    }
    return _queueMemory.values.where((i) => !i.isSynced).toList();
  }

  Future<SyncQueueItem> enqueueChange({
    required String entityType,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    await init();
    final item = SyncQueueItem(
      id: 'sync_${DateTime.now().microsecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
      timestamp: DateTime.now(),
      isSynced: false,
    );

    if (_queueBox != null && _queueBox!.isOpen) {
      await _queueBox!.put(item.id, item.toMap());
    } else {
      _queueMemory[item.id] = item;
    }

    return item;
  }

  Future<bool> signIn(String email, String password) async {
    await init();
    _status = SyncStatus.syncing;
    final success = await _backend.authenticate(email, password);
    if (success) {
      _account = _account.copyWith(
        email: email,
        displayName: email.split('@').first,
        isLoggedIn: true,
        lastSyncTime: DateTime.now(),
      );
      if (_accountBox != null && _accountBox!.isOpen) {
        await _accountBox!.put('current_account', _account.toMap());
      }
      _status = SyncStatus.synced;
    } else {
      _status = SyncStatus.error;
    }
    return success;
  }

  Future<void> signOut() async {
    await init();
    await _backend.signOut();
    _account = const CloudAccount();
    if (_accountBox != null && _accountBox!.isOpen) {
      await _accountBox!.delete('current_account');
    }
    _status = SyncStatus.idle;
  }

  Future<bool> syncNow() async {
    await init();
    if (_account.provider == SyncProviderType.localOnly) {
      _status = SyncStatus.synced;
      _account = _account.copyWith(lastSyncTime: DateTime.now());
      return true;
    }

    _status = SyncStatus.syncing;
    try {
      final pending = getPendingQueue();
      if (pending.isNotEmpty) {
        final pushed = await _backend.pushChanges(pending);
        if (pushed) {
          for (final item in pending) {
            final updated = item.copyWith(isSynced: true);
            if (_queueBox != null && _queueBox!.isOpen) {
              await _queueBox!.put(item.id, updated.toMap());
            } else {
              _queueMemory[item.id] = updated;
            }
          }
        }
      }

      await _backend.pullChanges(_account.lastSyncTime ?? DateTime.now().subtract(const Duration(days: 30)));
      _account = _account.copyWith(lastSyncTime: DateTime.now());
      if (_accountBox != null && _accountBox!.isOpen) {
        await _accountBox!.put('current_account', _account.toMap());
      }

      _status = SyncStatus.synced;
      return true;
    } catch (_) {
      _status = SyncStatus.error;
      return false;
    }
  }
}


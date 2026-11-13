import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/sync/models/sync_models.dart';
import 'package:itqan/features/sync/services/cloud_sync_service.dart';

void main() {
  group('Sync Models Serialization Tests', () {
    test('SyncQueueItem toMap and fromMap round-trips correctly', () {
      final now = DateTime.now();
      final item = SyncQueueItem(
        id: 'sync_123',
        entityType: 'srs_card',
        entityId: '1_1',
        action: 'upsert',
        payload: {'score': 95.0, 'repetition': 3},
        timestamp: now,
        isSynced: false,
      );

      final map = item.toMap();
      final revived = SyncQueueItem.fromMap(map);

      expect(revived.id, equals('sync_123'));
      expect(revived.entityType, equals('srs_card'));
      expect(revived.entityId, equals('1_1'));
      expect(revived.action, equals('upsert'));
      expect(revived.payload['score'], equals(95.0));
      expect(revived.isSynced, isFalse);
    });

    test('CloudAccount copyWith and serialization works', () {
      const account = CloudAccount(
        email: 'user@itqan.app',
        displayName: 'User',
        provider: SyncProviderType.supabase,
        isLoggedIn: true,
      );

      final updated = account.copyWith(provider: SyncProviderType.firebase);
      expect(updated.provider, equals(SyncProviderType.firebase));

      final map = updated.toMap();
      final revived = CloudAccount.fromMap(map);
      expect(revived.email, equals('user@itqan.app'));
      expect(revived.provider, equals(SyncProviderType.firebase));
      expect(revived.isLoggedIn, isTrue);
    });
  });

  group('CloudSyncService Lifecycle Tests', () {
    late Directory tempDir;
    late CloudSyncService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sync_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(CloudSyncService.queueBoxName);
      await Hive.openBox(CloudSyncService.accountBoxName);
      service = CloudSyncService();
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk(CloudSyncService.queueBoxName);
      await Hive.deleteBoxFromDisk(CloudSyncService.accountBoxName);
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    test('enqueueChange adds item to pending queue', () async {
      await service.init();
      expect(service.getPendingQueue().length, equals(0));

      final item = await service.enqueueChange(
        entityType: 'srs_card',
        entityId: '1_2',
        action: 'upsert',
        payload: {'score': 85.0},
      );

      expect(item.entityType, equals('srs_card'));
      expect(service.getPendingQueue().length, equals(1));
    });

    test('syncNow drains pending queue and marks items synced', () async {
      await service.init();
      await service.enqueueChange(
        entityType: 'bookmark',
        entityId: 'page_5',
        action: 'upsert',
        payload: {'page': 5},
      );

      expect(service.getPendingQueue().length, equals(1));

      final success = await service.syncNow();
      expect(success, isTrue);
      expect(service.status, equals(SyncStatus.synced));
      expect(service.getPendingQueue().length, equals(0));
    });

    test('signIn authenticates and updates account state', () async {
      await service.init();
      expect(service.account.isLoggedIn, isFalse);

      final success = await service.signIn('student@itqan.app', 'password');
      expect(success, isTrue);
      expect(service.account.isLoggedIn, isTrue);
      expect(service.account.email, equals('student@itqan.app'));

      await service.signOut();
      expect(service.account.isLoggedIn, isFalse);
    });
  });
}


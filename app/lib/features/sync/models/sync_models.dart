enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

enum SyncProviderType {
  supabase,
  firebase,
  localOnly,
}

class SyncQueueItem {
  final String id;
  final String entityType; // e.g. 'srs_card', 'bookmark', 'tashih_submission', 'settings'
  final String entityId;
  final String action; // 'upsert', 'delete'
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final bool isSynced;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.timestamp,
    this.isSynced = false,
  });

  SyncQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'action': action,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
  };

  factory SyncQueueItem.fromMap(Map map) => SyncQueueItem(
    id: map['id']?.toString() ?? '',
    entityType: map['entityType']?.toString() ?? '',
    entityId: map['entityId']?.toString() ?? '',
    action: map['action']?.toString() ?? 'upsert',
    payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
    timestamp: map['timestamp'] != null
        ? DateTime.parse(map['timestamp'])
        : DateTime.now(),
    isSynced: map['isSynced'] as bool? ?? false,
  );
}

class CloudAccount {
  final String email;
  final String displayName;
  final SyncProviderType provider;
  final bool isLoggedIn;
  final DateTime? lastSyncTime;
  final String? token;

  const CloudAccount({
    this.email = 'guest@itqan.local',
    this.displayName = 'Guest User',
    this.provider = SyncProviderType.supabase,
    this.isLoggedIn = false,
    this.lastSyncTime,
    this.token,
  });

  CloudAccount copyWith({
    String? email,
    String? displayName,
    SyncProviderType? provider,
    bool? isLoggedIn,
    DateTime? lastSyncTime,
    String? token,
  }) {
    return CloudAccount(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      provider: provider ?? this.provider,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'provider': provider.name,
    'isLoggedIn': isLoggedIn,
    'lastSyncTime': lastSyncTime?.toIso8601String(),
    'token': token,
  };

  factory CloudAccount.fromMap(Map map) => CloudAccount(
    email: map['email']?.toString() ?? 'guest@itqan.local',
    displayName: map['displayName']?.toString() ?? 'Guest User',
    provider: SyncProviderType.values.firstWhere(
      (p) => p.name == map['provider'],
      orElse: () => SyncProviderType.supabase,
    ),
    isLoggedIn: map['isLoggedIn'] as bool? ?? false,
    lastSyncTime: map['lastSyncTime'] != null
        ? DateTime.parse(map['lastSyncTime'])
        : null,
    token: map['token']?.toString(),
  );
}


import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'models/sync_models.dart';
import 'services/cloud_sync_service.dart';

class SyncManagementScreen extends StatefulWidget {
  const SyncManagementScreen({super.key});

  @override
  State<SyncManagementScreen> createState() => _SyncManagementScreenState();
}

class _SyncManagementScreenState extends State<SyncManagementScreen> {
  final CloudSyncService _service = CloudSyncService();
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    await _service.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    await _service.syncNow();
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  void _showSignInDialog() {
    final emailCtrl = TextEditingController(text: 'user@example.com');
    final passCtrl = TextEditingController(text: 'password123');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ItqanRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: ItqanSpacing.lg,
          right: ItqanSpacing.lg,
          top: ItqanSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + ItqanSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connect Cloud Account', style: ItqanTypography.heading2),
                IconButton(
                  icon: const Icon(Icons.close, color: ItqanColors.mist),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: ItqanSpacing.sm),
            Text(
              'Sign in to synchronize your memorization progress, bookmarks, and Tashih records across all your devices.',
              style: ItqanTypography.caption,
            ),
            const SizedBox(height: ItqanSpacing.md),
            TextField(
              controller: emailCtrl,
              style: ItqanTypography.body,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: ItqanColors.mist),
                fillColor: ItqanColors.charcoal,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
              ),
            ),
            const SizedBox(height: ItqanSpacing.sm),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: ItqanTypography.body,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: ItqanColors.mist),
                fillColor: ItqanColors.charcoal,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
              ),
            ),
            const SizedBox(height: ItqanSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _service.signIn(emailCtrl.text.trim(), passCtrl.text.trim());
                  setState(() {});
                },
                icon: const Icon(Icons.cloud_done_rounded, color: ItqanColors.void_),
                label: const Text('Sign In & Sync Now', style: TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSync(DateTime? time) {
    if (time == null) return 'Never synced';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute(s) ago';
    if (diff.inHours < 24) return '${diff.inHours} hour(s) ago';
    return '${diff.inDays} day(s) ago';
  }

  @override
  Widget build(BuildContext context) {
    final account = _service.account;
    final pendingCount = _service.getPendingQueue().length;

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Cloud Sync & Backup', style: ItqanTypography.heading2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ItqanColors.gold))
          : ListView(
              padding: const EdgeInsets.all(ItqanSpacing.lg),
              children: [
                // Top Sync Status Banner
                Container(
                  padding: const EdgeInsets.all(ItqanSpacing.lg),
                  decoration: BoxDecoration(
                    color: ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.lg),
                    border: Border.all(color: ItqanColors.gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ItqanColors.gold.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: ItqanColors.goldGlow),
                            ),
                            child: Icon(
                              _service.status == SyncStatus.syncing || _isSyncing
                                  ? Icons.sync_rounded
                                  : Icons.cloud_done_rounded,
                              color: ItqanColors.gold,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: ItqanSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _service.status == SyncStatus.syncing || _isSyncing
                                      ? 'Synchronizing...'
                                      : 'Cloud Status: Online & Synced',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last sync: ${_formatLastSync(account.lastSyncTime)}',
                                  style: ItqanTypography.caption,
                                ),
                                if (pendingCount > 0)
                                  Text(
                                    '$pendingCount item(s) pending in offline queue',
                                    style: const TextStyle(color: ItqanColors.warning, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ItqanSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _triggerSync,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: ItqanColors.void_),
                                )
                              : const Icon(Icons.sync_rounded, color: ItqanColors.void_, size: 18),
                          label: Text(
                            _isSyncing ? 'Syncing with Cloud...' : 'Sync Now',
                            style: const TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ItqanColors.gold,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: ItqanSpacing.lg),
                const Text('ACCOUNT SETTINGS', style: ItqanTypography.label),
                const SizedBox(height: ItqanSpacing.sm),

                // Account card
                Container(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.lg),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: ItqanColors.charcoal,
                        child: Icon(Icons.person_rounded, color: ItqanColors.gold),
                      ),
                      const SizedBox(width: ItqanSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.isLoggedIn ? account.displayName : 'Guest Profile',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              account.isLoggedIn ? account.email : 'Local only (Sign in to sync)',
                              style: ItqanTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: account.isLoggedIn
                            ? () async {
                                await _service.signOut();
                                setState(() {});
                              }
                            : _showSignInDialog,
                        child: Text(
                          account.isLoggedIn ? 'Sign Out' : 'Connect',
                          style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: ItqanSpacing.lg),
                const Text('CLOUD BACKEND PROVIDER', style: ItqanTypography.label),
                const SizedBox(height: ItqanSpacing.sm),

                // Provider selection
                Container(
                  decoration: BoxDecoration(
                    color: ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.lg),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<SyncProviderType>(
                        value: SyncProviderType.supabase,
                        groupValue: account.provider,
                        activeColor: ItqanColors.gold,
                        title: const Text('Supabase Cloud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('PostgreSQL backend with Row-Level Security', style: ItqanTypography.caption),
                        onChanged: (v) async {
                          if (v != null) {
                            await _service.setProvider(v);
                            setState(() {});
                          }
                        },
                      ),
                      const Divider(color: ItqanColors.charcoal, height: 1),
                      RadioListTile<SyncProviderType>(
                        value: SyncProviderType.firebase,
                        groupValue: account.provider,
                        activeColor: ItqanColors.gold,
                        title: const Text('Firebase Firestore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('Google Cloud Firestore multi-region database', style: ItqanTypography.caption),
                        onChanged: (v) async {
                          if (v != null) {
                            await _service.setProvider(v);
                            setState(() {});
                          }
                        },
                      ),
                      const Divider(color: ItqanColors.charcoal, height: 1),
                      RadioListTile<SyncProviderType>(
                        value: SyncProviderType.localOnly,
                        groupValue: account.provider,
                        activeColor: ItqanColors.gold,
                        title: const Text('Local Storage Only', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('Data never leaves this device', style: ItqanTypography.caption),
                        onChanged: (v) async {
                          if (v != null) {
                            await _service.setProvider(v);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: ItqanSpacing.lg),
                const Text('SYNCED COLLECTIONS', style: ItqanTypography.label),
                const SizedBox(height: ItqanSpacing.sm),

                Container(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: ItqanColors.onyx,
                    borderRadius: BorderRadius.circular(ItqanRadius.lg),
                  ),
                  child: Column(
                    children: const [
                      _CollectionRow(icon: Icons.psychology_rounded, label: 'Spaced Repetition (SRS) Cards', status: 'In Sync'),
                      Divider(color: ItqanColors.charcoal),
                      _CollectionRow(icon: Icons.bookmark_rounded, label: 'Bookmarks & Reading History', status: 'In Sync'),
                      Divider(color: ItqanColors.charcoal),
                      _CollectionRow(icon: Icons.school_rounded, label: 'Teacher / Student Tashih Records', status: 'In Sync'),
                      Divider(color: ItqanColors.charcoal),
                      _CollectionRow(icon: Icons.tune_rounded, label: 'App Settings & Scoring Weights', status: 'In Sync'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;

  const _CollectionRow({
    required this.icon,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: ItqanColors.gold, size: 20),
          const SizedBox(width: ItqanSpacing.md),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ItqanColors.correct.withOpacity(0.15),
              borderRadius: BorderRadius.circular(ItqanRadius.sm),
            ),
            child: Text(status, style: const TextStyle(color: ItqanColors.correct, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'models/ijazah_models.dart';
import 'services/ijazah_service.dart';

class IjazahScreen extends StatefulWidget {
  const IjazahScreen({super.key});

  @override
  State<IjazahScreen> createState() => _IjazahScreenState();
}

class _IjazahScreenState extends State<IjazahScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final IjazahService _service = IjazahService();
  bool _isLoading = true;
  List<IjazahCertificate> _certificates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    await _service.init();
    if (mounted) {
      setState(() {
        _certificates = _service.getCertificates();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chain = _service.getSanadChain();

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Ijazah & Sanad Passport', style: ItqanTypography.heading2),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ItqanColors.gold,
          labelColor: ItqanColors.gold,
          unselectedLabelColor: ItqanColors.mist,
          tabs: const [
            Tab(text: 'My Certificates', icon: Icon(Icons.workspace_premium_rounded, size: 20)),
            Tab(text: 'Sanad Chain Tree', icon: Icon(Icons.account_tree_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ItqanColors.gold))
          : TabBarView(
              controller: _tabController,
              children: [
                _CertificatesTab(certificates: _certificates),
                _SanadChainTab(chain: chain),
              ],
            ),
    );
  }
}

class _CertificatesTab extends StatelessWidget {
  final List<IjazahCertificate> certificates;
  const _CertificatesTab({required this.certificates});

  @override
  Widget build(BuildContext context) {
    if (certificates.isEmpty) {
      return Center(
        child: Text(
          'No Ijazah certificates registered yet.\nComplete recitation khatam to earn your certified sanad.',
          textAlign: TextAlign.center,
          style: ItqanTypography.body.copyWith(color: ItqanColors.mist),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      itemCount: certificates.length,
      itemBuilder: (ctx, i) {
        final cert = certificates[i];
        return _CertificateCard(cert: cert);
      },
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final IjazahCertificate cert;
  const _CertificateCard({required this.cert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ItqanSpacing.lg),
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.xl),
        border: Border.all(color: ItqanColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.gold.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ornate Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded, color: ItqanColors.gold, size: 24),
              const SizedBox(width: 8),
              Text(
                'إِجَازَة فِي تِلَاوَةِ الْقُرْآنِ الْكَرِيمِ',
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 20,
                  color: ItqanColors.gold,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('AUTHENTICATED SANAD IJAZAH CERTIFICATE', style: TextStyle(color: ItqanColors.mist, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: ItqanSpacing.lg),

          Text(
            cert.studentName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ItqanColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(ItqanRadius.full),
            ),
            child: Text(
              cert.riwayah,
              style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          const SizedBox(height: ItqanSpacing.md),
          Text(cert.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Grade: ${cert.grade}', style: const TextStyle(color: ItqanColors.correct, fontWeight: FontWeight.w600, fontSize: 12)),

          const SizedBox(height: ItqanSpacing.lg),
          const Divider(color: ItqanColors.charcoal),
          const SizedBox(height: ItqanSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Presiding Shaykh:', style: ItqanTypography.caption),
                  Text(cert.presidingShaykh, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Chain Degree:', style: ItqanTypography.caption),
                  Text('${cert.generationDegree}th from Prophet ﷺ', style: const TextStyle(color: ItqanColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: ItqanSpacing.md),
          Container(
            padding: const EdgeInsets.all(ItqanSpacing.sm),
            decoration: BoxDecoration(
              color: ItqanColors.charcoal,
              borderRadius: BorderRadius.circular(ItqanRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: ItqanColors.gold, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verification Hash: ${cert.id}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(cert.verificationHash, style: ItqanTypography.caption.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ItqanColors.correct.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ItqanRadius.sm),
                  ),
                  child: const Text('VERIFIED', style: TextStyle(color: ItqanColors.correct, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SanadChainTab extends StatelessWidget {
  final List<SanadNode> chain;
  const _SanadChainTab({required this.chain});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      itemCount: chain.length,
      itemBuilder: (ctx, i) {
        final node = chain[i];
        final isLast = i == chain.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: node.generation == 0
                        ? ItqanColors.gold
                        : (node.generation == 29 ? ItqanColors.correct : ItqanColors.charcoal),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: node.generation == 0 ? ItqanColors.gold : ItqanColors.goldGlow,
                    ),
                  ),
                  child: Text(
                    '${node.generation}',
                    style: TextStyle(
                      color: node.generation == 0 ? ItqanColors.void_ : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: ItqanColors.gold.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: ItqanSpacing.md),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
                padding: const EdgeInsets.all(ItqanSpacing.md),
                decoration: BoxDecoration(
                  color: ItqanColors.onyx,
                  borderRadius: BorderRadius.circular(ItqanRadius.lg),
                  border: Border.all(
                    color: node.generation == 0 ? ItqanColors.gold.withOpacity(0.5) : ItqanColors.charcoal,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            node.name,
                            style: TextStyle(
                              color: node.generation == 0 ? ItqanColors.gold : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ItqanColors.charcoal,
                            borderRadius: BorderRadius.circular(ItqanRadius.sm),
                          ),
                          child: Text(
                            node.deathYearH,
                            style: const TextStyle(color: ItqanColors.mist, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.arabicName,
                      style: const TextStyle(fontFamily: 'NotoNaskhArabic', color: ItqanColors.gold, fontSize: 14),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text('${node.role} • ${node.city}', style: ItqanTypography.caption.copyWith(color: ItqanColors.cloud)),
                    const SizedBox(height: 6),
                    Text(node.notes, style: ItqanTypography.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

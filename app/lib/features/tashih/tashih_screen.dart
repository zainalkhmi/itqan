import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'models/tashih_submission.dart';
import 'services/tashih_service.dart';

class TashihScreen extends StatefulWidget {
  final String? initialRole; // 'student' or 'teacher'
  const TashihScreen({super.key, this.initialRole});

  @override
  State<TashihScreen> createState() => _TashihScreenState();
}

class _TashihScreenState extends State<TashihScreen> {
  final TashihService _service = TashihService();
  late String _role; // 'student' or 'teacher'
  bool _isLoading = true;
  List<TashihSubmission> _submissions = [];

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole ?? _service.currentRole;
    _service.setRole(_role);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _service.init();
    final all = _service.getAllSubmissions();
    if (mounted) {
      setState(() {
        _submissions = all;
        _isLoading = false;
      });
    }
  }

  void _openReviewSheet(TashihSubmission sub) {
    double teacherScore = sub.aiScore;
    TashihStatus status = TashihStatus.approved;
    final tajweedCtrl = TextEditingController(text: sub.tajweedNotes ?? '');
    final makhrajCtrl = TextEditingController(text: sub.makhrajNotes ?? '');
    final generalCtrl = TextEditingController(text: sub.generalNotes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ItqanRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: ItqanSpacing.lg,
            right: ItqanSpacing.lg,
            top: ItqanSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + ItqanSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teacher Tashih Review', style: ItqanTypography.heading2),
                        Text('Student: ${sub.studentName}', style: ItqanTypography.caption),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: ItqanColors.mist),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: ItqanSpacing.md),
                // Quran Ayah snippet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: ItqanColors.charcoal,
                    borderRadius: BorderRadius.circular(ItqanRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${sub.surahName} • Ayah ${sub.ayahNumber}', style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        sub.textUthmani,
                        style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 18, color: Colors.white, height: 1.8),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 6),
                      Text('AI Diagnostic Score: ${sub.aiScore.round()}% (${sub.aiGrade})', style: ItqanTypography.caption),
                    ],
                  ),
                ),
                const SizedBox(height: ItqanSpacing.md),
                // Teacher Score Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Teacher Assigned Score:', style: ItqanTypography.caption),
                    Text('${teacherScore.round()}%', style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Slider(
                  value: teacherScore,
                  min: 50,
                  max: 100,
                  divisions: 50,
                  activeColor: ItqanColors.gold,
                  inactiveColor: ItqanColors.charcoal,
                  onChanged: (v) => setModalState(() => teacherScore = v),
                ),
                const SizedBox(height: ItqanSpacing.sm),
                // Decision status
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Approved (Mumtaz)')),
                        selected: status == TashihStatus.approved,
                        selectedColor: ItqanColors.correct.withOpacity(0.3),
                        onSelected: (sel) => setModalState(() => status = TashihStatus.approved),
                      ),
                    ),
                    const SizedBox(width: ItqanSpacing.sm),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Needs Revision')),
                        selected: status == TashihStatus.needsRevision,
                        selectedColor: ItqanColors.error.withOpacity(0.3),
                        onSelected: (sel) => setModalState(() => status = TashihStatus.needsRevision),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ItqanSpacing.md),
                // Notes inputs
                TextField(
                  controller: tajweedCtrl,
                  style: ItqanTypography.body,
                  decoration: InputDecoration(
                    labelText: 'Tajweed Feedback (Madd, Ghunnah, Qalqalah)',
                    labelStyle: const TextStyle(color: ItqanColors.mist, fontSize: 12),
                    fillColor: ItqanColors.charcoal,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
                  ),
                ),
                const SizedBox(height: ItqanSpacing.sm),
                TextField(
                  controller: makhrajCtrl,
                  style: ItqanTypography.body,
                  decoration: InputDecoration(
                    labelText: 'Makharij al-Huruf Notes (Articulatory guidance)',
                    labelStyle: const TextStyle(color: ItqanColors.mist, fontSize: 12),
                    fillColor: ItqanColors.charcoal,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
                  ),
                ),
                const SizedBox(height: ItqanSpacing.sm),
                TextField(
                  controller: generalCtrl,
                  style: ItqanTypography.body,
                  decoration: InputDecoration(
                    labelText: 'General Motivation & Advice',
                    labelStyle: const TextStyle(color: ItqanColors.mist, fontSize: 12),
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
                      await _service.reviewSubmission(
                        sub.id,
                        teacherName: 'Ustadz Abdullah, Lc.',
                        teacherScore: teacherScore,
                        status: status,
                        tajweedNotes: tajweedCtrl.text.trim(),
                        makhrajNotes: makhrajCtrl.text.trim(),
                        generalNotes: generalCtrl.text.trim(),
                      );
                      _loadData();
                    },
                    icon: const Icon(Icons.send_rounded, color: ItqanColors.void_),
                    label: const Text('Send Tashih to Student', style: TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }

  void _showNewSubmissionDialog() {
    int surah = 1;
    int ayah = 1;
    final nameCtrl = TextEditingController(text: _service.currentUserName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ItqanColors.onyx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ItqanRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                  const Text('Submit Recitation for Tashih', style: ItqanTypography.heading2),
                  IconButton(
                    icon: const Icon(Icons.close, color: ItqanColors.mist),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: ItqanSpacing.md),
              TextField(
                controller: nameCtrl,
                style: ItqanTypography.body,
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  labelStyle: const TextStyle(color: ItqanColors.mist),
                  fillColor: ItqanColors.charcoal,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
                ),
              ),
              const SizedBox(height: ItqanSpacing.md),
              DropdownButtonFormField<int>(
                value: surah,
                dropdownColor: ItqanColors.onyx,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Surah 1: Al-Fatiha', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 112, child: Text('Surah 112: Al-Ikhlas', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 113, child: Text('Surah 113: Al-Falaq', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 114, child: Text('Surah 114: An-Nas', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setModalState(() => surah = v ?? 1),
                decoration: InputDecoration(
                  labelText: 'Select Surah',
                  labelStyle: const TextStyle(color: ItqanColors.mist),
                  fillColor: ItqanColors.charcoal,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(ItqanRadius.md)),
                ),
              ),
              const SizedBox(height: ItqanSpacing.md),
              Text('Ayah Number: $ayah', style: ItqanTypography.caption),
              Slider(
                value: ayah.toDouble(),
                min: 1,
                max: surah == 1 ? 7 : (surah == 112 ? 4 : 6),
                divisions: surah == 1 ? 6 : (surah == 112 ? 3 : 5),
                activeColor: ItqanColors.gold,
                inactiveColor: ItqanColors.charcoal,
                onChanged: (v) => setModalState(() => ayah = v.round()),
              ),
              const SizedBox(height: ItqanSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _service.submitRecitation(
                      studentName: nameCtrl.text.trim().isEmpty ? 'Student' : nameCtrl.text.trim(),
                      surahNumber: surah,
                      ayahNumber: ayah,
                      surahName: surah == 1 ? 'Al-Fatiha' : (surah == 112 ? 'Al-Ikhlas' : 'Surah $surah'),
                      textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      aiScore: 88.0,
                      aiGrade: 'Very Good',
                    );
                    _loadData();
                  },
                  icon: const Icon(Icons.send_rounded, color: ItqanColors.void_),
                  label: const Text('Send to Teacher Queue', style: TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentList = _service.getStudentSubmissions(_service.currentUserName);
    final teacherQueue = _service.getAllSubmissions();
    final activeList = _role == 'student' ? studentList : teacherQueue;

    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        backgroundColor: ItqanColors.void_,
        title: const Text('Teacher / Student Tashih', style: ItqanTypography.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ItqanColors.gold),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: _role == 'student'
          ? FloatingActionButton.extended(
              backgroundColor: ItqanColors.gold,
              foregroundColor: ItqanColors.void_,
              icon: const Icon(Icons.add),
              label: const Text('Submit Recitation', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _showNewSubmissionDialog,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ItqanColors.gold))
          : Column(
              children: [
                // Role Switcher Bar
                Padding(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: ItqanColors.onyx,
                      borderRadius: BorderRadius.circular(ItqanRadius.full),
                      border: Border.all(color: ItqanColors.gold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _role = 'student');
                              _service.setRole('student');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _role == 'student' ? ItqanColors.gold : Colors.transparent,
                                borderRadius: BorderRadius.circular(ItqanRadius.full),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_rounded, size: 16, color: _role == 'student' ? ItqanColors.void_ : ItqanColors.mist),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Student View',
                                    style: TextStyle(
                                      color: _role == 'student' ? ItqanColors.void_ : ItqanColors.mist,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _role = 'teacher');
                              _service.setRole('teacher');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _role == 'teacher' ? ItqanColors.gold : Colors.transparent,
                                borderRadius: BorderRadius.circular(ItqanRadius.full),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.school_rounded, size: 16, color: _role == 'teacher' ? ItqanColors.void_ : ItqanColors.mist),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Teacher View',
                                    style: TextStyle(
                                      color: _role == 'teacher' ? ItqanColors.void_ : ItqanColors.mist,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Info Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ItqanSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ItqanColors.charcoal,
                      borderRadius: BorderRadius.circular(ItqanRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _role == 'student' ? Icons.info_outline : Icons.queue_music_rounded,
                          color: ItqanColors.gold,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _role == 'student'
                                ? 'Track your recitation submissions and review notes given by your teacher.'
                                : 'Teacher review portal: listen to recordings and give detailed Tajweed tashih.',
                            style: ItqanTypography.caption.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: ItqanSpacing.sm),

                // Submissions List
                Expanded(
                  child: activeList.isEmpty
                      ? Center(
                          child: Text(
                            _role == 'student'
                                ? 'No recitation submissions yet.\nTap "+ Submit Recitation" to send one to your teacher!'
                                : 'No submissions in the teacher review queue.',
                            textAlign: TextAlign.center,
                            style: ItqanTypography.body.copyWith(color: ItqanColors.mist),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(ItqanSpacing.md),
                          itemCount: activeList.length,
                          itemBuilder: (ctx, i) {
                            final item = activeList[i];
                            return _SubmissionCard(
                              item: item,
                              isTeacher: _role == 'teacher',
                              onReview: () => _openReviewSheet(item),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final TashihSubmission item;
  final bool isTeacher;
  final VoidCallback onReview;

  const _SubmissionCard({
    required this.item,
    required this.isTeacher,
    required this.onReview,
  });

  Color _statusColor(TashihStatus status) {
    switch (status) {
      case TashihStatus.pending:
        return ItqanColors.warning;
      case TashihStatus.approved:
        return ItqanColors.correct;
      case TashihStatus.needsRevision:
        return ItqanColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
      padding: const EdgeInsets.all(ItqanSpacing.md),
      decoration: BoxDecoration(
        color: ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: ItqanColors.mist),
                  const SizedBox(width: 4),
                  Text(item.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(ItqanRadius.full),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: ItqanSpacing.sm),
          Text(
            '${item.surahName} • Ayah ${item.ayahNumber}',
            style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            item.textUthmani,
            style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 17, color: Colors.white, height: 1.8),
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ItqanSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ItqanColors.charcoal,
                  borderRadius: BorderRadius.circular(ItqanRadius.sm),
                ),
                child: Text('AI: ${item.aiScore.round()}%', style: ItqanTypography.caption.copyWith(fontSize: 11)),
              ),
              if (item.teacherScore != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ItqanColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(ItqanRadius.sm),
                  ),
                  child: Text(
                    'Teacher: ${item.teacherScore!.round()}%',
                    style: const TextStyle(color: ItqanColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          if (item.tajweedNotes != null && item.tajweedNotes!.isNotEmpty) ...[
            const SizedBox(height: ItqanSpacing.sm),
            Container(
              padding: const EdgeInsets.all(ItqanSpacing.sm),
              decoration: BoxDecoration(
                color: ItqanColors.charcoal,
                borderRadius: BorderRadius.circular(ItqanRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tashih from ${item.teacherName ?? "Teacher"}:', style: const TextStyle(color: ItqanColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('• Tajweed: ${item.tajweedNotes}', style: ItqanTypography.caption.copyWith(fontSize: 11)),
                  if (item.makhrajNotes != null && item.makhrajNotes!.isNotEmpty)
                    Text('• Makhraj: ${item.makhrajNotes}', style: ItqanTypography.caption.copyWith(fontSize: 11)),
                  if (item.generalNotes != null && item.generalNotes!.isNotEmpty)
                    Text('• Advice: ${item.generalNotes}', style: ItqanTypography.caption.copyWith(fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
          if (isTeacher) ...[
            const SizedBox(height: ItqanSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.edit_note_rounded, size: 16, color: ItqanColors.void_),
                label: Text(
                  item.status == TashihStatus.pending ? 'Review & Grade' : 'Edit Tashih',
                  style: const TextStyle(color: ItqanColors.void_, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ItqanRadius.full)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

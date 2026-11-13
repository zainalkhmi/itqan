import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import 'learning_data.dart';

class LearningScreen extends StatefulWidget {
  final int initialTabIndex;
  const LearningScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  // Quiz state
  int _currentQuestionIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _quizScore = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: ItqanColors.void_,
        appBar: AppBar(
          backgroundColor: ItqanColors.void_,
          title: const Text('Tajweed & Makhraj Academy', style: ItqanTypography.heading2),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: ItqanColors.gold,
            labelColor: ItqanColors.gold,
            unselectedLabelColor: ItqanColors.mist,
            tabs: [
              Tab(icon: Icon(Icons.auto_stories_rounded, size: 20), text: 'Tajweed Rules'),
              Tab(icon: Icon(Icons.record_voice_over_rounded, size: 20), text: 'Makhraj Drills'),
              Tab(icon: Icon(Icons.compare_arrows_rounded, size: 20), text: 'Minimal Pairs'),
              Tab(icon: Icon(Icons.quiz_rounded, size: 20), text: 'Interactive Quiz'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTajweedRulesTab(),
            _buildMakhrajDrillsTab(),
            _buildMinimalPairsTab(),
            _buildQuizTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: TAJWEED RULES
  // ==========================================
  Widget _buildTajweedRulesTab() {
    final rules = LearningData.tajweedRules;
    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
          padding: const EdgeInsets.all(ItqanSpacing.md),
          decoration: BoxDecoration(
            color: ItqanColors.onyx,
            borderRadius: BorderRadius.circular(ItqanRadius.lg),
            border: Border.all(color: rule.color.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(rule.title, style: ItqanTypography.heading2.copyWith(fontSize: 18, color: rule.color)),
                  ),
                  Text(
                    rule.titleArabic,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: rule.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(rule.description, style: ItqanTypography.body.copyWith(fontSize: 13)),
              const SizedBox(height: ItqanSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ItqanColors.charcoal,
                  borderRadius: BorderRadius.circular(ItqanRadius.sm),
                ),
                child: Text(
                  'Timing: ${rule.countsOrDetail}',
                  style: const TextStyle(fontSize: 11, color: ItqanColors.goldLight),
                ),
              ),
              const SizedBox(height: ItqanSpacing.md),
              const Text('Quranic Examples:', style: ItqanTypography.caption),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                textDirection: TextDirection.rtl,
                children: rule.examples.map((ex) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: rule.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(ItqanRadius.md),
                      border: Border.all(color: rule.color.withOpacity(0.3)),
                    ),
                    child: Text(
                      ex,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 18,
                        color: rule.color,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: MAKHRAJ DRILLS
  // ==========================================
  Widget _buildMakhrajDrillsTab() {
    final letters = LearningData.makhrajLetters;
    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final item = letters[index];
        return Container(
          margin: const EdgeInsets.only(bottom: ItqanSpacing.md),
          padding: const EdgeInsets.all(ItqanSpacing.md),
          decoration: BoxDecoration(
            color: ItqanColors.onyx,
            borderRadius: BorderRadius.circular(ItqanRadius.lg),
            border: Border.all(color: ItqanColors.charcoal),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ItqanColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: ItqanColors.gold, width: 1.5),
                ),
                child: Text(
                  item.letter,
                  style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: ItqanSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: ItqanTypography.heading2.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      item.articulationArea,
                      style: const TextStyle(fontSize: 12, color: ItqanColors.goldLight, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(item.description, style: ItqanTypography.caption),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Drill Word: ', style: TextStyle(fontSize: 12, color: ItqanColors.mist)),
                        Text(
                          item.exampleWord,
                          style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 16, color: ItqanColors.white),
                        ),
                        Text(' (${item.transliteration})', style: const TextStyle(fontSize: 11, color: ItqanColors.mist)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: MINIMAL PAIRS
  // ==========================================
  Widget _buildMinimalPairsTab() {
    final pairs = LearningData.minimalPairs;
    return ListView.builder(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: ItqanSpacing.lg),
          padding: const EdgeInsets.all(ItqanSpacing.md),
          decoration: BoxDecoration(
            color: ItqanColors.onyx,
            borderRadius: BorderRadius.circular(ItqanRadius.lg),
            border: Border.all(color: ItqanColors.charcoal),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pair A (Target)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(ItqanSpacing.md),
                      decoration: BoxDecoration(
                        color: ItqanColors.correct.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ItqanRadius.md),
                        border: Border.all(color: ItqanColors.correct.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            pair.letterA,
                            style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 32, color: ItqanColors.correct),
                          ),
                          Text(pair.nameA, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ItqanColors.correct)),
                          const SizedBox(height: 4),
                          Text(pair.wordA, style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 20, color: ItqanColors.white)),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: ItqanColors.gold)),
                  ),
                  // Pair B (Common Substitution)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(ItqanSpacing.md),
                      decoration: BoxDecoration(
                        color: ItqanColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ItqanRadius.md),
                        border: Border.all(color: ItqanColors.error.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            pair.letterB,
                            style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 32, color: ItqanColors.error),
                          ),
                          Text(pair.nameB, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ItqanColors.error)),
                          const SizedBox(height: 4),
                          Text(pair.wordB, style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 20, color: ItqanColors.mist)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ItqanSpacing.md),
              Text(
                pair.contrastDescription,
                style: const TextStyle(fontSize: 13, color: ItqanColors.cloud, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: INTERACTIVE QUIZ
  // ==========================================
  Widget _buildQuizTab() {
    final questions = LearningData.quizQuestions;
    final isFinished = _currentQuestionIndex >= questions.length;

    if (isFinished) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ItqanSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 72, color: ItqanColors.gold),
              const SizedBox(height: ItqanSpacing.md),
              const Text('Quiz Completed!', style: ItqanTypography.heading1),
              const SizedBox(height: ItqanSpacing.sm),
              Text('Your Score: $_quizScore / ${questions.length}', style: ItqanTypography.heading2.copyWith(color: ItqanColors.gold)),
              const SizedBox(height: ItqanSpacing.xl),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.gold,
                  foregroundColor: ItqanColors.void_,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex = 0;
                    _selectedOption = null;
                    _answered = false;
                    _quizScore = 0;
                  });
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Retake Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                style: const TextStyle(color: ItqanColors.gold, fontWeight: FontWeight.bold),
              ),
              Text('Score: $_quizScore', style: const TextStyle(color: ItqanColors.mist)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
              backgroundColor: ItqanColors.charcoal,
              valueColor: const AlwaysStoppedAnimation(ItqanColors.gold),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: ItqanSpacing.lg),
          Text(q.question, style: ItqanTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: ItqanSpacing.md),
          // Sample word box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: ItqanColors.onyx,
              borderRadius: BorderRadius.circular(ItqanRadius.lg),
              border: Border.all(color: ItqanColors.charcoal),
            ),
            child: Center(
              child: Text(
                q.sampleWord,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 32,
                  color: ItqanColors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: ItqanSpacing.lg),
          // Options
          ...List.generate(q.options.length, (optIdx) {
            Color borderColor = ItqanColors.charcoal;
            Color bgColor = ItqanColors.obsidian;

            if (_answered) {
              if (optIdx == q.correctIndex) {
                borderColor = ItqanColors.correct;
                bgColor = ItqanColors.correct.withOpacity(0.15);
              } else if (optIdx == _selectedOption) {
                borderColor = ItqanColors.error;
                bgColor = ItqanColors.error.withOpacity(0.15);
              }
            } else if (_selectedOption == optIdx) {
              borderColor = ItqanColors.gold;
              bgColor = ItqanColors.gold.withOpacity(0.12);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _answered
                    ? null
                    : () {
                        setState(() {
                          _selectedOption = optIdx;
                          _answered = true;
                          if (optIdx == q.correctIndex) {
                            _quizScore++;
                          }
                        });
                      },
                borderRadius: BorderRadius.circular(ItqanRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(ItqanRadius.md),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        String.fromCharCode(65 + optIdx),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: borderColor == ItqanColors.charcoal ? ItqanColors.mist : borderColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          q.options[optIdx],
                          style: const TextStyle(fontSize: 15, color: ItqanColors.white),
                        ),
                      ),
                      if (_answered && optIdx == q.correctIndex)
                        const Icon(Icons.check_circle_rounded, color: ItqanColors.correct, size: 20)
                      else if (_answered && optIdx == _selectedOption)
                        const Icon(Icons.cancel_rounded, color: ItqanColors.error, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          // Explanation
          if (_answered) ...[
            const SizedBox(height: ItqanSpacing.md),
            Container(
              padding: const EdgeInsets.all(ItqanSpacing.md),
              decoration: BoxDecoration(
                color: ItqanColors.onyx,
                borderRadius: BorderRadius.circular(ItqanRadius.md),
                border: Border.all(color: ItqanColors.gold.withOpacity(0.4)),
              ),
              child: Text(
                '💡 ${q.explanation}',
                style: const TextStyle(fontSize: 13, color: ItqanColors.goldLight, height: 1.4),
              ),
            ),
            const SizedBox(height: ItqanSpacing.lg),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ItqanColors.gold,
                foregroundColor: ItqanColors.void_,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                setState(() {
                  _currentQuestionIndex++;
                  _selectedOption = null;
                  _answered = false;
                });
              },
              child: Text(
                _currentQuestionIndex < questions.length - 1 ? 'Next Question' : 'View Results',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  final List<double>? waveform;
  final String? engineLabel;

  const WaveformVisualizer({
    super.key,
    required this.isActive,
    this.waveform,
    this.engineLabel = 'TajweedFormer V4',
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> with TickerProviderStateMixin {
  static const int barCount = 40;
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  final List<Timer> _timers = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < barCount; i++) {
      final duration = Duration(milliseconds: 350 + _random.nextInt(350));
      final ctrl = AnimationController(vsync: this, duration: duration);
      final anim = Tween<double>(begin: 0.08, end: 0.95).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
      _controllers.add(ctrl);
      _animations.add(anim);
      final timer = Timer(Duration(milliseconds: _random.nextInt(250)), () {
        if (mounted && widget.isActive) ctrl.repeat(reverse: true);
      });
      _timers.add(timer);
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      for (final c in _controllers) c.repeat(reverse: true);
    } else if (!widget.isActive && old.isActive) {
      for (final c in _controllers) {
        c.animateTo(0.08);
      }
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, _) {
              return Container(
                width: 4,
                height: 4 + 44 * _animations[i].value,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: ItqanColors.gold.withOpacity(0.6 + 0.4 * _animations[i].value),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

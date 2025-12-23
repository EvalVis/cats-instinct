import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/speed_meter.dart';

class CupSandboxConfig {
  final double shuffleDelay;
  final int cupCount;
  final int swapCount;
  final int groupSize;

  CupSandboxConfig({
    required this.shuffleDelay,
    required this.cupCount,
    required this.swapCount,
    required this.groupSize,
  });
}

class CupSwitchingGame extends StatefulWidget {
  final bool sandbox;
  final CupSandboxConfig? sandboxConfig;

  const CupSwitchingGame({super.key, this.sandbox = false, this.sandboxConfig});

  @override
  State<CupSwitchingGame> createState() => _CupSwitchingGameState();
}

class _CupSwitchingGameState extends State<CupSwitchingGame> {
  static const int _cupCap = 20;
  static const int _swapCap = 40;
  int _score = 0;
  int _highScore = 0;
  int _beanCupId = 0;
  bool _isShuffling = false;
  bool _canGuess = false;
  bool _showBean = false;
  double _shuffleDelay = 600.0;
  int _cupCount = 3;
  int _swapCount = 3;
  int _groupSize = 2;
  double _animationDurationMs = 500.0;

  double _initialAnimationDurationFor(double delay) {
    final scaled = delay * 0.6;
    return scaled.clamp(300, 1500);
  }

  late List<int> _slotToCup;
  final Random _random = Random.secure();

  @override
  void initState() {
    super.initState();
    if (widget.sandbox && widget.sandboxConfig != null) {
      _shuffleDelay = widget.sandboxConfig!.shuffleDelay.clamp(20, 3000);
      _cupCount = widget.sandboxConfig!.cupCount.clamp(3, _cupCap);
      _swapCount = widget.sandboxConfig!.swapCount.clamp(1, _swapCap);
      _groupSize = widget.sandboxConfig!.groupSize.clamp(
        2,
        widget.sandboxConfig!.cupCount,
      );
      _animationDurationMs = _initialAnimationDurationFor(_shuffleDelay);
    }
    _slotToCup = List.generate(_cupCount, (index) => index);
    _loadHighScore();
    _startNewRound();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('cup_game_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    if (score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cup_game_high_score', score);
      setState(() {
        _highScore = score;
      });
    }
  }

  void _startNewRound() {
    setState(() {
      _slotToCup = List.generate(_cupCount, (index) => index);
      _beanCupId = _random.nextInt(_cupCount);
      _canGuess = false;
      _isShuffling = false;
      _showBean = true;
    });
    _showBeanThenShuffle();
  }

  Future<void> _showBeanThenShuffle() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _showBean = false;
      _isShuffling = true;
    });
    _shuffleCups();
  }

  Future<void> _shuffleCups() async {
    for (int i = 0; i < _swapCount; i++) {
      await Future.delayed(Duration(milliseconds: _shuffleDelay.round()));
      if (!mounted) return;
      final count = _groupSize.clamp(2, _cupCount);
      final indices = <int>{};
      while (indices.length < count) {
        indices.add(_random.nextInt(_cupCount));
      }
      final list = indices.toList();
      final temp = _slotToCup[list.last];
      for (int j = list.length - 1; j > 0; j--) {
        _slotToCup[list[j]] = _slotToCup[list[j - 1]];
      }
      _slotToCup[list.first] = temp;
      setState(() {});
    }
    if (!mounted) return;
    setState(() {
      _isShuffling = false;
      _canGuess = true;
    });
  }

  void _onCupTap(int slotIndex) {
    if (!_canGuess || _isShuffling) return;
    final tappedCupId = _slotToCup[slotIndex];
    final isCorrect = tappedCupId == _beanCupId;
    setState(() {
      _canGuess = false;
      _showBean = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (isCorrect) {
        if (!widget.sandbox) {
          setState(() {
            _score++;
          });
        }
        if (!widget.sandbox) {
          _applyDifficultyProgression();
          _saveHighScore(_score);
        }
      } else {
        if (!widget.sandbox) {
          setState(() {
            _score = 0;
            _shuffleDelay = 600.0;
            _swapCount = 3;
            _groupSize = 2;
            _cupCount = 3;
            _animationDurationMs = 500.0;
          });
        }
      }
      _startNewRound();
    });
  }

  void _applyDifficultyProgression() {
    if (widget.sandbox) return;
    _shuffleDelay *= 0.9;
    if (_shuffleDelay < 100) _shuffleDelay = 100;
    _animationDurationMs *= 0.9;
    if (_animationDurationMs < 20) _animationDurationMs = 20;
    if (_cupCount < _cupCap) _cupCount++;
    if (_swapCount < _swapCap) _swapCount++;
    if (_groupSize < _cupCount) {
      _groupSize++;
    }
    if (_swapCount > _swapCap) _swapCount = _swapCap;
    if (_cupCount > _cupCap) _cupCount = _cupCap;
    if (_groupSize > _cupCount) _groupSize = _cupCount;
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'How to play',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Watch the bean under a cup, then the cups shuffle. Tap the cup hiding the bean.\n\nEach correct guess speeds up shuffling, increases swaps, and adds cups over time. A wrong guess resets difficulty.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCup({
    required int slotIndex,
    required double size,
    required Offset center,
    required double radius,
  }) {
    final cupId = _slotToCup[slotIndex];
    final hasBean = cupId == _beanCupId && _showBean;
    final angle = (2 * pi * slotIndex / _cupCount) - pi / 2;
    final position = Offset(
      center.dx + radius * cos(angle) - size / 2,
      center.dy + radius * sin(angle) - size / 2,
    );
    final animationDuration = Duration(
      milliseconds: _animationDurationMs.clamp(20, 1500).round(),
    );
    return AnimatedPositioned(
      key: ValueKey(cupId),
      duration: animationDuration,
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => _onCupTap(slotIndex),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.brown[600],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.brown[900]!.withOpacity(0.6),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: hasBean
              ? Center(
                  child: Container(
                    width: size * 0.32,
                    height: size * 0.32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cup Switching',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (widget.sandbox)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Sandbox mode',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  if (!widget.sandbox) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Score: $_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'High Score: $_highScore',
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize = min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final baseCupSize = canvasSize * 0.12;
                  final cupSize = baseCupSize.clamp(28.0, 64.0);
                  final radius = (canvasSize * 0.42) - cupSize / 2;
                  final center = Offset(canvasSize / 2, canvasSize / 2);
                  return SizedBox(
                    width: canvasSize,
                    height: canvasSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: List.generate(
                        _cupCount,
                        (index) => _buildCup(
                          slotIndex: index,
                          size: cupSize.toDouble(),
                          center: center,
                          radius: radius,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SpeedMeter(
                currentDelay: _shuffleDelay,
                maxDelay: widget.sandbox ? 3000.0 : 600.0,
                minDelay: 100.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _showBean
                    ? 'Watch where the bean goes...'
                    : _isShuffling
                    ? 'Watch the cups shuffle...'
                    : _canGuess
                    ? 'Tap the cup with the bean!'
                    : 'Loading...',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

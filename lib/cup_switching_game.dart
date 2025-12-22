import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/speed_meter.dart';

class CupSwitchingGame extends StatefulWidget {
  const CupSwitchingGame({super.key});

  @override
  State<CupSwitchingGame> createState() => _CupSwitchingGameState();
}

class _CupSwitchingGameState extends State<CupSwitchingGame>
    with TickerProviderStateMixin {
  int _score = 0;
  int _highScore = 0;
  int _beanPosition = 0;
  bool _isAnimating = false;
  bool _canGuess = false;
  bool _showBean = false;
  double _shuffleDelay = 600.0;
  final List<int> _cupPositions = [0, 1, 2];
  int? _swappingIndex1;
  int? _swappingIndex2;
  final Random _random = Random.secure();
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _animationControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _animationControllers
        .map(
          (controller) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
    _startNewRound();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
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
      _beanPosition = _random.nextInt(3);
      _canGuess = false;
      _isAnimating = false;
      _showBean = true;
    });
    _showBeanThenShuffle();
  }

  Future<void> _showBeanThenShuffle() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _showBean = false;
      _isAnimating = true;
    });
    _shuffleCups();
  }

  Future<void> _shuffleCups() async {
    const shuffleCount = 5;
    for (int i = 0; i < shuffleCount; i++) {
      await Future.delayed(Duration(milliseconds: _shuffleDelay.round()));
      if (!mounted) return;

      final cup1 = _random.nextInt(3);
      int cup2 = _random.nextInt(3);
      while (cup2 == cup1) {
        cup2 = _random.nextInt(3);
      }

      await _swapCups(cup1, cup2);
    }

    setState(() {
      _isAnimating = false;
      _canGuess = true;
    });
  }

  Future<void> _swapCups(int physicalIndex1, int physicalIndex2) async {
    final controller1 = _animationControllers[physicalIndex1];
    final controller2 = _animationControllers[physicalIndex2];

    setState(() {
      _swappingIndex1 = physicalIndex1;
      _swappingIndex2 = physicalIndex2;
    });

    controller1.reset();
    controller2.reset();

    await Future.wait([controller1.forward(), controller2.forward()]);

    setState(() {
      final temp = _cupPositions[physicalIndex1];
      _cupPositions[physicalIndex1] = _cupPositions[physicalIndex2];
      _cupPositions[physicalIndex2] = temp;
      _swappingIndex1 = null;
      _swappingIndex2 = null;
    });

    await Future.delayed(const Duration(milliseconds: 50));
    controller1.reset();
    controller2.reset();
  }

  void _onCupTap(int tappedIndex) {
    if (!_canGuess || _isAnimating) return;

    final actualPosition = _cupPositions[tappedIndex];
    final isCorrect = actualPosition == _beanPosition;

    setState(() {
      _canGuess = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (isCorrect) {
        setState(() {
          _score++;
          _shuffleDelay *= 0.99;
          if (_shuffleDelay < 100) {
            _shuffleDelay = 100;
          }
        });
        _saveHighScore(_score);
        _startNewRound();
      } else {
        setState(() {
          _score = 0;
          _shuffleDelay = 600.0;
        });
        _startNewRound();
      }
    });
  }

  Widget _buildCup(int physicalIndex, int cupNumber) {
    final logicalPosition = _cupPositions[physicalIndex];
    final hasBean = logicalPosition == _beanPosition && _showBean;
    final animation = _animations[physicalIndex];
    final isSwapping =
        _swappingIndex1 == physicalIndex || _swappingIndex2 == physicalIndex;
    final swapPartner = _swappingIndex1 == physicalIndex
        ? _swappingIndex2
        : (_swappingIndex2 == physicalIndex ? _swappingIndex1 : null);

    return GestureDetector(
      onTap: () => _onCupTap(physicalIndex),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          double offset = 0;
          if (isSwapping && swapPartner != null) {
            offset = (swapPartner - physicalIndex) * 120.0 * animation.value;
          }
          return Transform.translate(
            offset: Offset(offset, 0),
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.brown[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown[900]!,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasBean)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
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
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildCup(0, 0),
                        const SizedBox(width: 20),
                        _buildCup(1, 1),
                        const SizedBox(width: 20),
                        _buildCup(2, 2),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SpeedMeter(
                      currentDelay: _shuffleDelay,
                      maxDelay: 600.0,
                      minDelay: 100.0,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _showBean
                    ? 'Watch where the bean goes...'
                    : _isAnimating
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

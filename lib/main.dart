import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: GameScreen());
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  Color _targetColor = Colors.red;
  Color _centerColor = Colors.blue;
  int _lastCenterColorIndex = -1;
  double _score = 0.0;
  double _highScore = 0.0;
  Timer? _colorSwitchTimer;
  Timer? _clickTimer;
  int _timeRemaining = 60;
  double _colorSwitchDelay = 1000.0;
  final Random _random = Random();
  final List<int> _speedLabels = [
    0,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
  ];

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _pickNewTargetColor();
    _startColorSwitching();
    _startClickTimer();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getDouble('high_score') ?? 0.0;
    });
  }

  Future<void> _saveHighScore(double score) async {
    if (score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('high_score', score);
      setState(() {
        _highScore = score;
      });
    }
  }

  @override
  void dispose() {
    _colorSwitchTimer?.cancel();
    _clickTimer?.cancel();
    super.dispose();
  }

  void _pickNewTargetColor() {
    int newIndex;
    do {
      newIndex = _random.nextInt(_colors.length);
    } while (_colors[newIndex] == _targetColor);

    setState(() {
      _targetColor = _colors[newIndex];
    });
  }

  void _startColorSwitching() {
    _colorSwitchTimer?.cancel();
    _colorSwitchTimer = Timer.periodic(
      Duration(milliseconds: _colorSwitchDelay.round()),
      (timer) {
        int newIndex;
        do {
          newIndex = _random.nextInt(_colors.length);
        } while (newIndex == _lastCenterColorIndex);

        setState(() {
          _centerColor = _colors[newIndex];
          _lastCenterColorIndex = newIndex;
        });
      },
    );
  }

  void _startClickTimer() {
    _clickTimer?.cancel();
    _timeRemaining = 60;
    _clickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _score = 0.0;
          _clickTimer?.cancel();
          _startClickTimer();
        }
      });
    });
  }

  void _resetClickTimer() {
    _startClickTimer();
  }

  void _onCenterSquareTap() {
    if (_centerColor == _targetColor) {
      double timeBonus = _timeRemaining / 100.0;
      double pointsGained = 1.0 + timeBonus;
      _resetClickTimer();
      setState(() {
        _score += pointsGained;
        _colorSwitchDelay *= 0.99;
        if (_colorSwitchDelay < 0) {
          _colorSwitchDelay = 0;
        }
      });
      _saveHighScore(_score);
      _pickNewTargetColor();
      _startColorSwitching();
    } else {
      _resetClickTimer();
      setState(() {
        _score = 0.0;
        _colorSwitchDelay = 1000.0;
      });
      _startColorSwitching();
    }
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            'How to Play',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Match the Colors!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionRow(
                  Icons.square,
                  'Tap the center square when it matches the target color (top left).',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.timer,
                  'You have 60 seconds to match colors. Timer resets on each match.',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.speed,
                  'Each successful match increases the speed of colour switch.',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.warning,
                  'Wrong match resets your score and speed to starting values.',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.trending_up,
                  'The speed bar shows your current color switch speed (0 = fastest, 1000 = slowest).',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: _targetColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _targetColor.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Score: ${_score.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'High Score: ${_highScore.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 30,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[600]!, width: 2),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    width: 26,
                    height: (_timeRemaining / 60.0) * 296,
                    decoration: BoxDecoration(
                      color: _timeRemaining > 30
                          ? Colors.green
                          : _timeRemaining > 10
                          ? Colors.orange
                          : Colors.red,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: GestureDetector(
                onTap: () => _showInstructions(context),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[600]!, width: 2),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _onCenterSquareTap,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _centerColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _centerColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 260,
                        child: Stack(
                          children: _speedLabels.reversed
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                                int index = entry.key;
                                int label = entry.value;
                                double position = (index / 10.0) * (260 - 12);
                                return Positioned(
                                  top: position,
                                  right: 0,
                                  child: Text(
                                    label.toString(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 40,
                        height: 260,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey[600]!,
                                  width: 2,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                width: 36,
                                height:
                                    ((1000 - _colorSwitchDelay) / 1000.0) * 256,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                      ((1000 - _colorSwitchDelay) / 1000.0) *
                                              256 >
                                          250
                                      ? BorderRadius.circular(18)
                                      : const BorderRadius.vertical(
                                          bottom: Radius.circular(18),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

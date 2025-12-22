import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/speed_meter.dart';

class ColorMatchGame extends StatefulWidget {
  final bool colorBlindMode;

  const ColorMatchGame({super.key, required this.colorBlindMode});

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends State<ColorMatchGame> {
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
  final Random _random = Random.secure();

  final Map<Color, String> _colorSymbols = {
    Colors.red: '●',
    Colors.blue: '■',
    Colors.yellow: '▲',
    Colors.green: '◆',
    Colors.orange: '★',
    Colors.purple: '▼',
  };

  String _getColorSymbol(Color color) {
    return _colorSymbols[color] ?? '';
  }

  Widget _buildColorSquare(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: widget.colorBlindMode
          ? Center(
              child: Text(
                _getColorSymbol(color),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            )
          : null,
    );
  }


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
    final availableColors = _colors
        .where((color) => color != _targetColor)
        .toList();
    if (availableColors.isEmpty) {
      availableColors.addAll(_colors);
    }
    availableColors.shuffle(_random);
    setState(() {
      _targetColor = availableColors.first;
    });
  }

  void _startColorSwitching() {
    _colorSwitchTimer?.cancel();
    _colorSwitchTimer = Timer.periodic(
      Duration(milliseconds: _colorSwitchDelay.round()),
      (timer) {
        final availableIndices = List.generate(
          _colors.length,
          (i) => i,
        ).where((i) => i != _lastCenterColorIndex).toList();
        if (availableIndices.isEmpty) {
          availableIndices.addAll(List.generate(_colors.length, (i) => i));
        }
        availableIndices.shuffle(_random);
        final newIndex = availableIndices.first;

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
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: _buildColorSquare(_targetColor, 75),
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
                    const SizedBox(height: 12),
                    Container(
                      width: 300,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[600]!, width: 2),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut,
                          width: (_timeRemaining / 60.0) * 296,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _timeRemaining > 30
                                ? Colors.green
                                : _timeRemaining > 10
                                ? Colors.orange
                                : Colors.red,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    child: _buildColorSquare(_centerColor, 200),
                  ),
                  const SizedBox(height: 60),
                  SpeedMeter(
                    currentDelay: _colorSwitchDelay,
                    maxDelay: 1000.0,
                    minDelay: 0.0,
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

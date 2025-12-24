import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HamsterHammerGame extends StatefulWidget {
  const HamsterHammerGame({super.key});

  @override
  State<HamsterHammerGame> createState() => _HamsterHammerGameState();
}

class _HamsterHammerGameState extends State<HamsterHammerGame> {
  static const int gridSize = 10;
  final List<List<bool>> _grid = List.generate(
    gridSize,
    (_) => List.generate(gridSize, (_) => false),
  );
  int _score = 0;
  int _highScore = 0;
  int _timeRemaining = 60;
  Timer? _gameTimer;
  Timer? _hamsterTimer;
  double _spawnDelay = 1500.0;
  final Random _random = Random.secure();
  int? _lastHamsterRow;
  int? _lastHamsterCol;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startGameTimer();
    _spawnHamster();
    _startHamsterTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _hamsterTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('hamster_hammer_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    if (score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hamster_hammer_high_score', score);
      setState(() {
        _highScore = score;
      });
    }
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _endGame();
        }
      });
    });
  }

  void _startHamsterTimer() {
    _hamsterTimer?.cancel();
    _hamsterTimer = Timer.periodic(
      Duration(milliseconds: _spawnDelay.round()),
      (timer) {
        _spawnHamster();
      },
    );
  }

  void _spawnHamster() {
    setState(() {
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          _grid[row][col] = false;
        }
      }
    });

    final availablePositions = <List<int>>[];
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (row != _lastHamsterRow || col != _lastHamsterCol) {
          availablePositions.add([row, col]);
        }
      }
    }

    if (availablePositions.isEmpty) {
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          availablePositions.add([row, col]);
        }
      }
    }

    availablePositions.shuffle(_random);
    final position = availablePositions.first;
    final row = position[0];
    final col = position[1];

    setState(() {
      _grid[row][col] = true;
      _lastHamsterRow = row;
      _lastHamsterCol = col;
    });
  }

  void _onCellTap(int row, int col) {
    if (_grid[row][col]) {
      setState(() {
        _grid[row][col] = false;
        _score++;
        _spawnDelay = (_spawnDelay * 0.98).clamp(500.0, 3000.0);
        _saveHighScore(_score);
      });
      _startHamsterTimer();
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    _hamsterTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            'Game Over!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score: $_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'High Score: $_highScore',
                style: TextStyle(
                  color: Colors.green[300],
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Back to Menu',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          _grid[row][col] = false;
        }
      }
      _score = 0;
      _timeRemaining = 60;
      _spawnDelay = 1500.0;
      _lastHamsterRow = null;
      _lastHamsterCol = null;
    });
    _startGameTimer();
    _spawnHamster();
    _startHamsterTimer();
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
                  'Hamster & Hammer!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionRow(
                  Icons.grid_view,
                  'Tap hamsters as they appear on the 10x10 grid.',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.timer,
                  'You have 60 seconds to catch as many hamsters as possible.',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.speed,
                  'Each catch increases the spawn speed of hamsters.',
                ),
                const SizedBox(height: 12),
                _buildInstructionRow(
                  Icons.star,
                  'Try to beat your high score!',
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
          onPressed: () {
            _gameTimer?.cancel();
            _hamsterTimer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: const Text('Hamster & Hammer', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showInstructions(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Score',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$_score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'High Score',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$_highScore',
                        style: TextStyle(
                          color: Colors.green[300],
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$_timeRemaining',
                        style: TextStyle(
                          color: _timeRemaining > 30
                              ? Colors.white
                              : _timeRemaining > 10
                                  ? Colors.orange
                                  : Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableSize = constraints.maxWidth - 32;
                    final cellSize = (availableSize / gridSize).floor().toDouble();
                    final gridWidth = cellSize * gridSize;

                    return Container(
                      width: gridWidth,
                      height: gridWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 2,
                        ),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                        itemCount: gridSize * gridSize,
                        itemBuilder: (context, index) {
                          final row = index ~/ gridSize;
                          final col = index % gridSize;
                          final hasHamster = _grid[row][col];

                          return GestureDetector(
                            onTap: () => _onCellTap(row, col),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: hasHamster
                                  ? Center(
                                      child: Text(
                                        '🐹',
                                        style: TextStyle(
                                          fontSize: cellSize * 0.5,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


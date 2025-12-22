import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameType { colorMatch, cupSwitching }

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MenuScreen());
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _colorBlindMode = false;

  @override
  void initState() {
    super.initState();
    _loadColorBlindMode();
  }

  Future<void> _loadColorBlindMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _colorBlindMode = prefs.getBool('color_blind_mode') ?? false;
    });
  }

  Future<void> _saveColorBlindMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('color_blind_mode', value);
    setState(() {
      _colorBlindMode = value;
    });
  }

  void _startGame(GameType gameType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => gameType == GameType.colorMatch
            ? ColorMatchGame(colorBlindMode: _colorBlindMode)
            : CupSwitchingGame(),
      ),
    );
  }

  void _quitGame() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chameleon Effect - Boost your reflexes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Color Blind Mode:',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _colorBlindMode,
                    onChanged: _saveColorBlindMode,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _startGame(GameType.colorMatch),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Color Match',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _startGame(GameType.cupSwitching),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cup Switching',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _quitGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Quit',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double barWidth = constraints.maxWidth;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: barWidth,
                              height: 20,
                              child: Stack(
                                children: _speedLabels
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      int index = entry.key;
                                      int label = entry.value;
                                      double availableWidth = barWidth - 36;
                                      double position =
                                          (index / 10.0) * availableWidth;
                                      return Positioned(
                                        left: position,
                                        top: 0,
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
                            const SizedBox(height: 10),
                            SizedBox(
                              width: barWidth,
                              height: 40,
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
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOut,
                                      width:
                                          ((1000 - _colorSwitchDelay) /
                                              1000.0) *
                                          (barWidth - 4),
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius:
                                            ((1000 - _colorSwitchDelay) /
                                                        1000.0) *
                                                    (barWidth - 4) >
                                                (barWidth - 8)
                                            ? BorderRadius.circular(18)
                                            : const BorderRadius.horizontal(
                                                left: Radius.circular(18),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
      await Future.delayed(const Duration(milliseconds: 600));
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
        });
        _saveHighScore(_score);
        _startNewRound();
      } else {
        setState(() {
          _score = 0;
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
                        color: Colors.yellow,
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
                child: Row(
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

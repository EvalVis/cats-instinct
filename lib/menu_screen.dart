import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color_match_game.dart';
import 'cup_switching_game.dart';

enum GameType { colorMatch, cupSwitching }

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
            : const CupSwitchingGame(),
      ),
    );
  }

  void _startSandbox(CupSandboxConfig config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CupSwitchingGame(sandbox: true, sandboxConfig: config),
      ),
    );
  }

  void _openSandboxSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) {
        const double minDelay = 100;
        const double maxDelay = 3000;
        double speed = 0;
        double delay = maxDelay - speed * (maxDelay - minDelay);
        int cupCount = 3;
        int swapCount = 3;
        int groupSize = 2;
        return StatefulBuilder(
          builder: (context, setModalState) {
            double groupMax = cupCount.toDouble();
            if (groupSize > cupCount) groupSize = cupCount;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sandbox Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SliderRow(
                    label: 'Speed',
                    value: speed,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    displayValue: '${delay.round()} ms',
                    onChanged: (v) => setModalState(() {
                      speed = v;
                      delay = maxDelay - speed * (maxDelay - minDelay);
                    }),
                  ),
                  _SliderRow(
                    label: 'Cup count',
                    value: cupCount.toDouble(),
                    min: 3,
                    max: 20,
                    divisions: 17,
                    displayValue: '$cupCount',
                    onChanged: (v) => setModalState(() {
                      cupCount = v.round();
                      if (groupSize > cupCount) groupSize = cupCount;
                    }),
                  ),
                  _SliderRow(
                    label: 'Swap count',
                    value: swapCount.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    displayValue: '$swapCount',
                    onChanged: (v) =>
                        setModalState(() => swapCount = v.round()),
                  ),
                  _SliderRow(
                    label: 'Cups swapped together',
                    value: groupSize.toDouble(),
                    min: 2,
                    max: groupMax,
                    divisions: (groupMax - 2).clamp(0, 50).round(),
                    displayValue: '$groupSize',
                    onChanged: (v) =>
                        setModalState(() => groupSize = v.round()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startSandbox(
                          CupSandboxConfig(
                            shuffleDelay: delay,
                            cupCount: cupCount,
                            swapCount: swapCount,
                            groupSize: groupSize,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Sandbox',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                  onPressed: _openSandboxSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cup Sandbox',
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

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions == 0 ? null : divisions,
            onChanged: onChanged,
            activeColor: Colors.green,
            inactiveColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

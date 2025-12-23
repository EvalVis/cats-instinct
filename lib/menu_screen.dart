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

  void _startColorSandbox() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ColorMatchGame(colorBlindMode: _colorBlindMode, sandbox: true),
      ),
    );
  }

  void _startSandbox() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CupSwitchingGame(sandbox: true),
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
                  onPressed: _startColorSandbox,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Color Sandbox',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startSandbox,
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

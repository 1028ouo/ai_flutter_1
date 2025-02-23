import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  // 常數定義
  static const double BLOCK_HEIGHT = 125.0;
  static const double BLOCK_WIDTH = 125.0;
  static const int INITIAL_TIME = 3;
  static const int INITIAL_COUNTDOWN = 3;

  // 通用樣式
  static const TextStyle commonTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontFamily: 'Crayon',
  );

  static const Shadow commonShadow = Shadow(
    offset: Offset(5, 5),
    blurRadius: 5,
    color: Color.fromARGB(255, 62, 50, 50),
  );

  static const Shadow subtleShadow = Shadow(
    offset: Offset(2, 2),
    blurRadius: 3,
    color: Color.fromARGB(255, 62, 50, 50),
  );

  // 狀態變數
  int score = 0;
  int bestScore = 0;
  bool isNewRecord = false;
  Timer? gameTimer;
  Timer? dropTimer;
  Timer? countdownTimer;
  final random = Random();
  late List<List<int>> grid;
  bool isGameOver = false;
  bool isGameStarted = false;
  int remainingTime = INITIAL_TIME;
  int countdown = INITIAL_COUNTDOWN;
  bool isPaused = false;
  late AnimationController _animationController;

  // 添加按鈕動畫相關變數
  Map<int, bool> buttonStates = {0: false, 1: false, 2: false};

  final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');
  AudioPlayer? _backgroundPlayer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadBestScore();
    _playTitleMusic();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestScore = prefs.getInt('bestScore') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('bestScore', bestScore);
  }

  Future<void> _resetBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bestScore');
    setState(() {
      bestScore = 0;
    });
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重置最佳紀錄'),
          content: const Text('你確定要重置最佳紀錄嗎？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('重置'),
              onPressed: () {
                _resetBestScore();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _playTitleMusic() async {
    _backgroundPlayer = await _audioCache.loop('title.mp3');
  }

  void _playGameMusic() async {
    _backgroundPlayer?.stop();
    _backgroundPlayer = await _audioCache.loop('playing_game.mp3');
  }

  void _playClickSound() {
    _audioCache.play('click.mp3');
  }

  void _playGameOverMusic() async {
    _backgroundPlayer?.stop();
    _backgroundPlayer = await _audioCache.play('game_over.mp3');
  }

  void _playTapButtonSound() {
    _audioCache.play('tap_button.mp3');
  }

  void _muteBackgroundMusic() {
    _backgroundPlayer?.setVolume(0);
  }

  void _unmuteBackgroundMusic() {
    _backgroundPlayer?.setVolume(1);
  }

  @override
  void dispose() {
    _animationController.dispose();
    gameTimer?.cancel();
    dropTimer?.cancel();
    countdownTimer?.cancel();
    _backgroundPlayer?.dispose();
    super.dispose();
  }

  List<List<int>> generateRandomGrid() {
    List<List<int>> newGrid = List.generate(6, (i) => List.filled(3, 0));
    for (int i = 0; i < 5; i++) {
      newGrid[i][random.nextInt(3)] = 1;
    }
    newGrid[5] = [2, 2, 2];
    return newGrid;
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      score = 0;
      isGameOver = false;
      isNewRecord = false;
      remainingTime = INITIAL_TIME;
      countdown = INITIAL_COUNTDOWN;
      grid = generateRandomGrid();
      _playGameMusic();
    });

    _animationController.forward().then((_) {
      countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          setState(() {
            if (countdown > 0) {
              countdown--;
            } else {
              timer.cancel();
              startMainGame();
            }
          });
        },
      );
    });
  }

  void startMainGame() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (!isPaused && remainingTime > 0) {
          remainingTime--;
        } else if (remainingTime == 0) {
          isGameOver = true;
          if (score > bestScore) {
            bestScore = score;
            isNewRecord = true;
            _saveBestScore();
          }
          timer.cancel();
          dropTimer?.cancel();
          _playGameOverMusic();
          setState(() {}); // 觸發重繪以顯示遊戲結束畫面
        }
      });
    });
  }

  void onButtonPressed(int column) {
    setState(() {
      if (grid[4][column] == 1) {
        grid[4][column] = 0;
        score++;
        int newColumn = random.nextInt(3);
        grid.insert(0, [0, 0, 0]);
        grid[0][newColumn] = 1;
        grid.removeLast();
        _playClickSound();
      }
    });
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        gameTimer?.cancel();
        countdownTimer?.cancel();
        _muteBackgroundMusic();
      } else {
        startMainGame();
        _unmuteBackgroundMusic();
      }
    });
  }

  void restartGame() {
    _playTapButtonSound();
    setState(() {
      isPaused = false;
      isGameStarted = false;
      isGameOver = false; // 確保遊戲結束狀態被重置
      startGame();
    });
  }

  Widget buildGameControls() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: GestureDetector(
            onTapDown: (_) => setState(() => buttonStates[index] = true),
            onTapUp: (_) {
              setState(() => buttonStates[index] = false);
              onButtonPressed(index);
            },
            onTapCancel: () => setState(() => buttonStates[index] = false),
            child: AnimatedScale(
              scale: buttonStates[index] == true ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Image.asset(
                'assets/images/star.png', // 確保圖片文件存在於此路徑
                fit: BoxFit.cover,
                height: 90,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '暫停',
                style: commonTextStyle.copyWith(
                  fontSize: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              for (var buttonData in [
                {
                  'text': '継続',
                  'onPressed': () {
                    _playTapButtonSound();
                    togglePause();
                  }
                },
                {
                  'text': '重新',
                  'onPressed': () {
                    restartGame();
                  }
                },
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: buttonData['onPressed'] as void Function(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 10,
                        splashFactory: NoSplash.splashFactory, // 移除漣漪效果
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 20,
                        ),
                        textStyle: commonTextStyle.copyWith(fontSize: 30),
                      ),
                      child: Text(buttonData['text'] as String),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: commonTextStyle.copyWith(fontSize: 70),
                  children: const [
                    TextSpan(
                      text: 'GAME',
                      style: TextStyle(
                        color: Color.fromARGB(255, 111, 166, 255),
                        shadows: [commonShadow],
                      ),
                    ),
                    TextSpan(
                      text: ' OVER!',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 101, 91),
                        shadows: [commonShadow],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: commonTextStyle.copyWith(fontSize: 50),
                  children: [
                    const TextSpan(
                      text: 'score: ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 220, 220, 220),
                        shadows: [commonShadow],
                      ),
                    ),
                    TextSpan(
                      text: '$score',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 234, 0),
                        shadows: [commonShadow],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: commonTextStyle.copyWith(fontSize: 50),
                  children: [
                    const TextSpan(
                      text: 'best: ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 220, 220, 220),
                        shadows: [commonShadow],
                      ),
                    ),
                    TextSpan(
                      text: '$bestScore',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 234, 0),
                        shadows: [commonShadow],
                      ),
                    ),
                  ],
                ),
              ),
              if (isNewRecord) const SizedBox(height: 20),
              if (isNewRecord)
                const Text(
                  '打破新紀録！',
                  style: TextStyle(
                    fontSize: 40,
                    color: Color.fromARGB(255, 172, 252, 154),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Crayon',
                    shadows: [commonShadow],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    _playTapButtonSound();
                    setState(() {
                      isGameOver = false;
                      startGame();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 10,
                    shadowColor: Colors.black,
                    splashFactory: NoSplash.splashFactory, // 移除漣漪效果
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 20,
                    ),
                    textStyle: commonTextStyle.copyWith(fontSize: 35),
                  ),
                  child: const Text('AGAIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(_animationController.value),
                          BlendMode.darken,
                        ),
                        child: Image.asset(
                          'assets/images/main_background.png', // 更新圖片路徑
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (_animationController.value > 0.1)
                      Positioned.fill(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black
                                .withOpacity(1.0 - _animationController.value),
                            BlendMode.darken,
                          ),
                          child: Image.asset(
                            'assets/images/inside_background.png', // 確保圖片文件存在於此路徑
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Column(
            children: [
              if (isGameStarted && countdown > 0)
                Expanded(
                  child: Center(
                    child: Text(
                      '準備\n$countdown',
                      textAlign: TextAlign.center,
                      style: commonTextStyle.copyWith(
                        fontSize: 60,
                        color: const Color.fromARGB(255, 246, 115, 106),
                        shadows: const [commonShadow],
                      ),
                    ),
                  ),
                ),
              if (isGameStarted && countdown == 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 50.0, 8.0, 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '時間: $remainingTime 秒',
                      style: commonTextStyle.copyWith(fontSize: 20),
                    ),
                  ),
                ),
              if (!isPaused && isGameStarted) buildGameGrid(),
              if (!isGameStarted) buildMainMenu(),
              if (isGameStarted && countdown == 0 && !isPaused) ...[
                buildGameControls(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 17.0),
                  child: Text(
                    '得分: $score',
                    style: commonTextStyle.copyWith(fontSize: 24),
                  ),
                ),
              ],
            ],
          ),
          if (isGameStarted && countdown == 0)
            Positioned(
              top: 40,
              right: 10,
              child: IconButton(
                icon: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  shadows: const [subtleShadow], // 添加陰影
                ),
                color: Colors.white,
                iconSize: 30,
                onPressed: () {
                  _playTapButtonSound();
                  togglePause();
                },
              ),
            ),
          if (!isGameStarted)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.white,
                iconSize: 30,
                onPressed: () {
                  _playTapButtonSound();
                  _showResetDialog();
                },
              ),
            ),
          if (isPaused) buildPauseOverlay(),
          if (isGameOver) buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget buildGameGrid() {
    return Expanded(
      child: Stack(
        children: [
          if (isGameStarted && countdown == 0)
            for (int i = 0; i < 5; i++)
              for (int j = 0; j < 3; j++)
                if (grid[i][j] == 1)
                  Positioned(
                    top: BLOCK_HEIGHT * i,
                    left: BLOCK_WIDTH * j,
                    child: SizedBox(
                      width: BLOCK_WIDTH,
                      height: BLOCK_HEIGHT,
                      child: Image.asset(
                        'assets/images/kirby01.png', // 確保圖片文件存在於此路徑
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget buildMainMenu() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: commonTextStyle.copyWith(fontSize: 50),
                children: const [
                  TextSpan(
                    text: 'カービィ\n',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 140, 140),
                      shadows: [commonShadow],
                    ),
                  ),
                  TextSpan(
                    text: '踏 ',
                    style: TextStyle(
                      color: Color.fromARGB(255, 203, 203, 203),
                      shadows: [commonShadow],
                    ),
                  ),
                  TextSpan(
                    text: '星 星',
                    style: TextStyle(
                      color: Colors.yellow,
                      shadows: [commonShadow],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _playTapButtonSound();
                _backgroundPlayer?.stop();
                startGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 112, 173, 237),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 10,
                shadowColor: Colors.black,
                splashFactory: NoSplash.splashFactory, // 移除漣漪效果
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                textStyle: commonTextStyle.copyWith(
                  fontSize: 35,
                  shadows: const [subtleShadow], // 添加較不明顯的陰影
                ),
              ),
              child: const Text('START！'),
            ),
          ],
        ),
      ),
    );
  }
}

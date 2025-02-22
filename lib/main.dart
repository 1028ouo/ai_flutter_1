import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // 常數定義
  static const double BLOCK_HEIGHT = 125.0;
  static const double BLOCK_WIDTH = 125.0;
  static const int INITIAL_TIME = 10;
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

  // 狀態變數
  int score = 0;
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

  @override
  void initState() {
    super.initState();
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
      remainingTime = INITIAL_TIME;
      countdown = INITIAL_COUNTDOWN;
      grid = generateRandomGrid();
    });

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
  }

  void startMainGame() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          isGameOver = true;
          timer.cancel();
          dropTimer?.cancel();
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
      }
    });
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        gameTimer?.cancel();
        countdownTimer?.cancel();
      } else {
        startMainGame();
      }
    });
  }

  void restartGame() {
    setState(() {
      isPaused = false;
      isGameStarted = false;
      startGame();
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    dropTimer?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  Widget buildGameControls() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: GestureDetector(
            onTap: () => onButtonPressed(index),
            child: Image.asset(
              'assets/star.png',
              fit: BoxFit.cover,
              height: 90,
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
                {'text': '継続', 'onPressed': togglePause},
                {'text': '重新', 'onPressed': restartGame},
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: buttonData['onPressed'] as void Function(),
                      style: ElevatedButton.styleFrom(
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
                  children: [
                    TextSpan(
                      text: 'GAME',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 111, 166, 255),
                        shadows: const [commonShadow],
                      ),
                    ),
                    TextSpan(
                      text: ' OVER!',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 255, 101, 91),
                        shadows: const [commonShadow],
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
                    TextSpan(
                      text: 'score: ',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 220, 220, 220),
                        shadows: const [commonShadow],
                      ),
                    ),
                    TextSpan(
                      text: '$score',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 255, 234, 0),
                        shadows: const [commonShadow],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isGameOver = false;
                      startGame();
                    });
                  },
                  style: ElevatedButton.styleFrom(
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
            child: Image.asset(
              isGameStarted
                  ? 'assets/inside_background.png'
                  : 'assets/main_background.png',
              fit: BoxFit.cover,
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
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                color: Colors.white,
                iconSize: 30,
                onPressed: togglePause,
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
                        'assets/kirby01.png',
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
                children: [
                  TextSpan(
                    text: 'カービィ\n踏 ',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 140, 140),
                      shadows: const [commonShadow],
                    ),
                  ),
                  TextSpan(
                    text: '星 星',
                    style: TextStyle(
                      color: Colors.yellow,
                      shadows: const [commonShadow],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                textStyle: commonTextStyle.copyWith(fontSize: 30),
              ),
              child: const Text('START！'),
            ),
          ],
        ),
      ),
    );
  }
}

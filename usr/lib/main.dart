import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SantaGameApp());
}

class SantaGameApp extends StatelessWidget {
  const SantaGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هدايا سانتا - الجزر الفضائية',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Game Settings
  static const double santaSize = 60.0;
  static const double giftSize = 40.0;
  static const double gameSpeedBase = 5.0;
  
  // Game State
  bool isPlaying = false;
  int score = 0;
  double santaX = 0.0; // Horizontal position (-1.0 to 1.0)
  List<Gift> gifts = [];
  List<Star> stars = [];
  Timer? gameLoopTimer;
  Random random = Random();
  double currentSpeed = gameSpeedBase;

  @override
  void initState() {
    super.initState();
    // Create background stars
    for (int i = 0; i < 80; i++) {
      stars.add(Star(
        x: random.nextDouble() * 2 - 1,
        y: random.nextDouble() * 2 - 1,
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.1,
      ));
    }
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      gifts.clear();
      santaX = 0.0;
      currentSpeed = gameSpeedBase;
    });

    gameLoopTimer?.cancel();
    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void stopGame() {
    gameLoopTimer?.cancel();
    setState(() {
      isPlaying = false;
    });
    showGameOverDialog();
  }

  void updateGame() {
    setState(() {
      // Increase speed slightly as score goes up
      currentSpeed = gameSpeedBase + (score / 500);

      // Move stars (parallax effect)
      for (var star in stars) {
        star.y += 0.002 * star.speed * currentSpeed;
        if (star.y > 1.0) {
          star.y = -1.0;
          star.x = random.nextDouble() * 2 - 1;
        }
      }

      // Move gifts
      for (var gift in gifts) {
        gift.y += 0.005 * currentSpeed;
        gift.rotation += 0.05;
      }

      // Remove off-screen gifts
      gifts.removeWhere((gift) => gift.y > 1.2);

      // Add new gifts
      if (random.nextInt(100) < (2 + (score / 1000))) { 
        gifts.add(Gift(
          x: random.nextDouble() * 2 - 1,
          y: -1.2,
          type: random.nextInt(4), // 0: Red, 1: Green, 2: Gold, 3: Bomb
          rotation: 0.0,
        ));
      }

      checkCollisions();
    });
  }

  void checkCollisions() {
    double santaY = 0.75; // Fixed vertical position
    double collisionThresholdW = 0.15;
    double collisionThresholdH = 0.10;

    List<Gift> collectedGifts = [];

    for (var gift in gifts) {
      double dx = (gift.x - santaX).abs();
      double dy = (gift.y - santaY).abs();

      if (dx < collisionThresholdW && dy < collisionThresholdH) {
        collectedGifts.add(gift);
        
        if (gift.type == 3) {
          // Bomb! Game Over
          stopGame();
          return;
        } else {
          // Gift collected
          score += 10 * (gift.type + 1);
        }
      }
    }

    for (var gift in collectedGifts) {
      gifts.remove(gift);
    }
  }

  void moveSanta(double delta) {
    if (!isPlaying) return;
    setState(() {
      santaX += delta;
      if (santaX < -1.0) santaX = -1.0;
      if (santaX > 1.0) santaX = 1.0;
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('انتهت اللعبة!', style: TextStyle(color: Colors.white)),
        content: Text('لقد جمعت $score نقطة!', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startGame();
            },
            child: const Text('لعب مرة أخرى', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0033),
      body: Stack(
        children: [
          // Stars Background
          ...stars.map((star) => Positioned(
            left: (star.x + 1) / 2 * MediaQuery.of(context).size.width,
            top: (star.y + 1) / 2 * MediaQuery.of(context).size.height,
            child: Container(
              width: star.size,
              height: star.size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.5),
                shape: BoxShape.circle,
              ),
            ),
          )),

          // Planet/Island at bottom
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2D1B4E).withOpacity(0.8),
                    const Color(0xFF0B0033),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
            ),
          ),

          // Falling Gifts
          ...gifts.map((gift) => Positioned(
            left: (gift.x + 1) / 2 * MediaQuery.of(context).size.width - giftSize / 2,
            top: (gift.y + 1) / 2 * MediaQuery.of(context).size.height - giftSize / 2,
            child: Transform.rotate(
              angle: gift.rotation,
              child: Icon(
                gift.type == 3 ? Icons.dangerous : Icons.card_giftcard,
                color: gift.getColor(),
                size: giftSize,
                shadows: [
                  Shadow(
                    color: gift.getColor().withOpacity(0.8),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
          )),

          // Santa Character
          Positioned(
            left: (santaX + 1) / 2 * MediaQuery.of(context).size.width - santaSize / 2,
            bottom: MediaQuery.of(context).size.height * 0.15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: const Icon(
                    Icons.face, // Santa Face placeholder
                    color: Colors.white,
                    size: santaSize,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: santaSize * 0.8,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.star, color: Colors.yellow, size: 10),
                  ),
                )
              ],
            ),
          ),

          // Score Display
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    '$score',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Start Screen
          if (!isPlaying)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.purpleAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch, size: 60, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'هدايا سانتا\nالجزر الفضائية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اجمع الهدايا وتجنب القنابل!',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                      ),
                      child: const Text('ابدأ اللعب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // Controls (Touch areas for left/right)
          if (isPlaying)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (_) => moveSanta(-0.3),
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.1), size: 50),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (_) => moveSanta(0.3),
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.1), size: 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          // Keyboard Listener for Desktop/Web
          if (isPlaying)
            RawKeyboardListener(
              focusNode: FocusNode(),
              autofocus: true,
              onKey: (event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    moveSanta(-0.1);
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    moveSanta(0.1);
                  }
                }
              },
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

// Helper Classes
class Gift {
  double x;
  double y;
  int type;
  double rotation;

  Gift({required this.x, required this.y, required this.type, required this.rotation});

  Color getColor() {
    switch (type) {
      case 0: return Colors.redAccent;
      case 1: return Colors.greenAccent;
      case 2: return Colors.amber;
      case 3: return Colors.grey; // Bomb color
      default: return Colors.white;
    }
  }
}

class Star {
  double x;
  double y;
  double size;
  double speed;

  Star({required this.x, required this.y, required this.size, required this.speed});
}

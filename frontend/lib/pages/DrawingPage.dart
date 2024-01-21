import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/components/SketchPainter.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/components/DrawingCanvas.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late Timer _timer;
  int _remainingTime = 120;

  final allSketches = ValueNotifier<List<Sketch>>([]);
  final currentSketch = ValueNotifier<Sketch?>(null);

  final List<Sketch> _undoStack = [];
  final List<Sketch> _redoStack = [];

  Color selectedColor = Colors.blue; // Default color
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow
  ]; // Add more as needed

  void selectColor(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (canUndo) {
      setState(() {
        Sketch lastSketch = _undoStack.removeLast();
        _redoStack.add(lastSketch);
        allSketches.value = List<Sketch>.from(allSketches.value)
          ..remove(lastSketch);
      });
    }
  }

  void redo() {
    if (canRedo) {
      setState(() {
        Sketch sketchToRedo = _redoStack.removeLast();
        _undoStack.add(sketchToRedo);
        allSketches.value = List<Sketch>.from(allSketches.value)
          ..add(sketchToRedo);
      });
    }
  }

  void handleSketchCompleted(Sketch sketch) {
    setState(() {
      _undoStack.add(sketch);
      _redoStack.clear();
    });
  }

  void handleSketchUndone() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    currentSketch.dispose(); // Dispose of the currentSketch ValueNotifier
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    String prompt = "PROMPT";
    String formattedTime =
        "${"${_remainingTime ~/ 60}".padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const HomePage(),
                  transitionDuration: Duration.zero,
                ),
              );
            },
            splashColor: Colors.transparent,
            splashRadius: 0.1,
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('App Title',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18), // Default style
              children: <TextSpan>[
                const TextSpan(
                  text: 'Draw a ',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: prompt,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const TextSpan(
                  text: ' in ',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: formattedTime,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const TextSpan(
                  text: ' mins',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Stack(children: [
            DrawingCanvas(
              width: screenSize.width,
              height: screenSize.height * 0.7,
              currentSketch: currentSketch,
              allSketches: allSketches,
              selectedColor: selectedColor,
              onSketchCompleted: handleSketchCompleted,
              onSketchUndone: handleSketchUndone,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  FloatingActionButton(
                    mini: true,
                    onPressed: canUndo ? undo : null,
                    backgroundColor: canUndo ? null : Colors.grey,
                    splashColor: Colors.transparent,
                    child: const Icon(Icons.undo),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    mini: true,
                    onPressed: canRedo ? redo : null,
                    backgroundColor: canRedo ? null : Colors.grey,
                    splashColor: Colors.transparent,
                    child: const Icon(Icons.redo),
                  ),
                ],
              ),
            ),
          ]),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              itemBuilder: (context, index) {
                bool isSelected = colors[index] == selectedColor;
                return GestureDetector(
                  onTap: () => selectColor(colors[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

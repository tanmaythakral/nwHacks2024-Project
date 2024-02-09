import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/SketchPainter.dart';
import 'package:frontend/pages/HomePage.dart';
import 'package:frontend/components/DrawingCanvas.dart';

import '../Notifiers/GroupNotifier.dart';
import '../main.dart';

class DrawingPage extends ConsumerStatefulWidget {
  DrawingPage({Key? key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends ConsumerState<DrawingPage> {
  final GlobalKey _canvasKey = GlobalKey();
  late Timer _timer;
  int _remainingTime = 10;

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

  Future<Uint8List?> capturePng() async {
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      return pngBytes;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }



  Future<String?> uploadDrawing(Uint8List pngBytes, String groupCode, String userId) async {
    try {
      // Modified file name format to use groupname/uid.jpg
      String fileName = "drawings/$groupCode/$userId.jpg";

      final storage = FirebaseStorage.instance;
      final storageRef = storage.ref();
      final uploadTask = storageRef.child(fileName).putData(pngBytes);
      await uploadTask.whenComplete(() {});
      String downloadURL = await storageRef.child(fileName).getDownloadURL();
      return downloadURL;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }




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
    currentSketch.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async { // Marked async
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
        // Asynchronously capture and upload drawing outside of setState.
        Uint8List? pngImage = await capturePng();
        if (pngImage != null) {
          final userId = ref.read(userContextProvider).value?.uid;
          final groupCode = ref.read(groupNotifierProvider.notifier).groupCode;
          String? downloadURL = await uploadDrawing(pngImage, groupCode!, userId!);
          print("Uploaded drawing URL: $downloadURL");
          // Now that async work is done, you can update the state or navigate as needed.
          _showTimeUpDialog();
        }
      }
    });
  }

  void _showTimeUpDialog() {
    // Showing dialog without directly calling setState,
    // but ensuring this is called in a context where async work has been completed.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          title: const Text('Time\'s Up!', style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold)),
          content: const Text('Your time for drawing has expired.', style: TextStyle(color: Colors.white, fontSize: 14.0)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.blue, fontSize: 18.0)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage())); // Navigate away
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
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
                color: Color.fromARGB(255, 250, 250, 250), size: 28),
            onPressed: () {
              Navigator.pop(context);
            },
            splashColor: Colors.transparent,
            splashRadius: 0.1,
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('IncSync',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 250, 250, 250))),
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
                  style: TextStyle(color: Color.fromARGB(255, 250, 250, 250)),
                ),
                TextSpan(
                  text: prompt,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 250, 250, 250)),
                ),
                const TextSpan(
                  text: ' in ',
                  style: TextStyle(color: Color.fromARGB(255, 250, 250, 250)),
                ),
                TextSpan(
                  text: formattedTime,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 250, 250, 250)),
                ),
                const TextSpan(
                  text: ' mins',
                  style: TextStyle(color: Color.fromARGB(255, 250, 250, 250)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Stack(children: [
            RepaintBoundary(
              key: _canvasKey,
              child: DrawingCanvas(
                width: screenSize.width,
                height: screenSize.height * 0.7,
                currentSketch: currentSketch,
                allSketches: allSketches,
                selectedColor: selectedColor,
                onSketchCompleted: handleSketchCompleted,
                onSketchUndone: handleSketchUndone,
              ),
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
                          ? Border.all(
                              color: const Color.fromARGB(255, 250, 250, 250),
                              width: 3)
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

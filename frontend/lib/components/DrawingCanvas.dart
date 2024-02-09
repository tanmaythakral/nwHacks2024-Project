import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:frontend/components/SketchPainter.dart';

class DrawingCanvas extends HookWidget {
  final double height;
  final double width;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final double strokeSize = 2;
  final Color selectedColor;
  final Function(Sketch) onSketchCompleted;
  final Function onSketchUndone;

  const DrawingCanvas({
    Key? key,
    required this.height,
    required this.width,
    required this.currentSketch,
    required this.allSketches,
    required this.selectedColor,
    required this.onSketchCompleted,
    required this.onSketchUndone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: Stack(
        children: [
          buildAllSketches(context),
          buildCurrentPath(context),
        ],
      ),
    );
  }

  void onPointerDown(PointerDownEvent details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.position);

    if (offset.dx >= 0 &&
        offset.dx <= width &&
        offset.dy >= 0 &&
        offset.dy <= height) {
      currentSketch.value = Sketch(
        points: [offset],
        size: strokeSize,
        color: selectedColor,
      );
    }
  }

  void onPointerMove(PointerMoveEvent details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.position);

    // Check if the offset is within the canvas bounds
    if (offset.dx >= 0 &&
        offset.dx <= width &&
        offset.dy >= 0 &&
        offset.dy <= height) {
      final points = List<Offset>.from(currentSketch.value?.points ?? [])
        ..add(offset);

      currentSketch.value = Sketch(
        points: points,
        size: strokeSize,
        color: selectedColor,
      );
    }
  }

  void onPointerUp(PointerUpEvent details) {
    if (currentSketch.value?.points.isNotEmpty == true) {
      allSketches.value = List<Sketch>.from(allSketches.value)
        ..add(currentSketch.value!);
      onSketchCompleted(currentSketch.value!);
    }
    currentSketch.value = null;
  }

  Widget buildAllSketches(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // Set the desired border radius
      child: SizedBox(
        height: height,
        width: width,
        child: ValueListenableBuilder<List<Sketch>>(
          valueListenable: allSketches,
          builder: (context, sketches, _) {
            return RepaintBoundary(
              child: Container(
                height: height,
                width: width,
                color: const Color.fromARGB(255, 250, 250,
                    250), // Background color for the initial canvas
                child: CustomPaint(
                  painter: SketchPainter(
                    sketches: sketches,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildCurrentPath(BuildContext context) {
    return Listener(
      onPointerDown: (details) => onPointerDown(details, context),
      onPointerMove: (details) => onPointerMove(details, context),
      onPointerUp: onPointerUp,
      child: ValueListenableBuilder(
        valueListenable: currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketch != null ? [sketch as Sketch] : [],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:test_canvas/canvas/canvas_board.dart';

class CanvasSidebar extends StatelessWidget {
  final Function changeDrawingMode;
  final Function changeStroke;
  final double strokeWidth;
  final CanvasBoardController controller;
  const CanvasSidebar(
      {super.key,
      required this.changeDrawingMode,
      required this.changeStroke,
      required this.strokeWidth,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 300,
          child: RotatedBox(
            quarterTurns: 3, // 270 degree
            child: Slider(
              value: strokeWidth,
              min: 1,
              max: 50,
              label: strokeWidth.round().toString(),
              onChanged: (value) => changeStroke(value),
            ),
          ),
        ),
        FloatingActionButton(
          mini: true,
          onPressed: () => changeDrawingMode(DrawingMode.draw),
          child: const Icon(Icons.edit),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
            mini: true,
          onPressed: () => changeDrawingMode(DrawingMode.eraser),
          child: const Icon(Icons.brush),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
            mini: true,
          onPressed: () {
            controller.clear();
          },
          child: const Icon(Icons.clear),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
            mini: true,
          onPressed: () {
            controller.undo();
          },
          child: const Icon(Icons.undo),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
            mini: true,
            // focusColor: Colors.red,
            // foregroundColor: Colors.blue,
            // splashColor: Colors.yellow,
          onPressed: () {
            controller.redo();
          },
          child: const Icon(Icons.redo),
        ),
      ],
    );
  }
}

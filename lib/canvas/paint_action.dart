import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:test_canvas/canvas/canvas_board.dart';
import 'package:test_canvas/canvas/sidebar/canvas_sidebar.dart';
import 'package:zoom_widget/zoom_widget.dart';

class PaintAction extends StatefulWidget {
  const PaintAction({super.key});
  @override
  State<StatefulWidget> createState() {
    return _PaintActionState();
  }
}

class _PaintActionState extends State<PaintAction> {
  late ui.Image image;
  bool isImageloaded = false;
  DrawingMode drawingMode = DrawingMode.draw; // DrawingMode eklenen satır
  double strokeWidth = 10;
  Color strokeColor = Colors.black;
  late CanvasBoardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CanvasBoardController();
    init();
  }

  Future<Null> init() async {
    final ByteData data = await rootBundle.load('assets/QuestionImage.png');
    image = await loadImage(Uint8List.view(data.buffer));
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.fromList(img), (ui.Image img) {
      setState(() {
        isImageloaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }

  void changeDrawingMode(DrawingMode mode) {
    setState(() {
      drawingMode = mode;
    });
  }

  void changeStroke(double value) {
    setState(() {
      strokeWidth = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Drawing App'), backgroundColor: Colors.amber),
        body: isImageloaded
            ? CanvasBoard(
                  controller: _controller,
                  drawingMode: drawingMode,
                  backgroundColor: Colors.transparent,
                  backgroundImage: image,
                  strokeColor: strokeColor,
                  strokeWidth: strokeWidth,
                )
            : const CircularProgressIndicator(
                color: Colors.amber,
                backgroundColor: Colors.white,
              ),
        floatingActionButton: CanvasSidebar(
          changeDrawingMode: changeDrawingMode,
          changeStroke: changeStroke,
          controller: _controller,
          strokeWidth: strokeWidth,
        ));
  }
}

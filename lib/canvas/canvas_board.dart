// ignore_for_file: unused_element

import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RedoUndoHistory {
  final VoidCallback undo;
  final VoidCallback redo;

  RedoUndoHistory({
    required this.undo,
    required this.redo,
  });
}

class _FreehandPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final Color backgroundColor;
  final ui.Image? backgroundImage;
  _FreehandPainter(
    this.strokes,
    this.backgroundColor,
    this.backgroundImage
  );

  @override
  void paint(Canvas canvas, Size size) {

    if(backgroundImage!=null){
       canvas.drawImage(backgroundImage!, const Offset(0,0), Paint());
    }
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    for (final stroke in strokes) {
      final paint = Paint()
        ..strokeWidth = stroke.width
        ..color = stroke.drawingMode == DrawingMode.eraser ? Colors.transparent : stroke.color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.drawingMode == DrawingMode.eraser ? BlendMode.clear : BlendMode.srcOver;
      canvas.drawPath(stroke.path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

typedef OnRedoUndo = void Function(bool isUndoAvailable, bool isRedoAvailable);

/// Whiteboard widget for canvas
class CanvasBoard extends StatefulWidget {
  /// WhiteBoardController for actions.
  final CanvasBoardController? controller;

  /// [Color] for background of whiteboard.
  final Color backgroundColor;

  //Backgroun of canvas

  final ui.Image? backgroundImage;

  /// [Color] of strokes.
  final Color strokeColor;

  /// Width of strokes
  final double strokeWidth;

  /// Flag for erase mode
  final DrawingMode drawingMode;

  /// Callback for [Canvas] when it converted to image data.
  /// Use [WhiteBoardController] to convert.
  final ValueChanged<Uint8List>? onConvertImage;

  /// This callback exposes if undo / redo is available and called successfully.
  final OnRedoUndo? onRedoUndo;

  const CanvasBoard({
    Key? key,
    this.controller,
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 4,
    this.drawingMode= DrawingMode.draw,
    this.onConvertImage,
    this.onRedoUndo,
    this.backgroundImage
  }) : super(key: key);

  @override
  _CanvasBoardState createState() => _CanvasBoardState();
}

class _CanvasBoardState extends State<CanvasBoard> {
  final _undoHistory = <RedoUndoHistory>[];
  final _redoStack = <RedoUndoHistory>[];

  final _strokes = <_Stroke>[];

  // cached current canvas size
  late Size _canvasSize;

  // convert current canvas to image data.
  Future<void> _convertToImage(ImageByteFormat format) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Emulate painting using _FreehandPainter
    // recorder will record this painting
    _FreehandPainter(
      _strokes,
      widget.backgroundColor,
      widget.backgroundImage as ui.Image
    ).paint(canvas, _canvasSize);

    // Stop emulating and convert to Image
    final result = await recorder
        .endRecording()
        .toImage(_canvasSize.width.floor(), _canvasSize.height.floor());

    // Cast image data to byte array with converting to given format
    final converted =
        (await result.toByteData(format: format))!.buffer.asUint8List();

    widget.onConvertImage?.call(converted);
  }

  @override
  void initState() {
    widget.controller?._delegate = _CanvasBoardControllerDelegate()
      ..saveAsImage = _convertToImage
      ..onUndo = () {
        if (_undoHistory.isEmpty) return false;

        _redoStack.add(_undoHistory.removeLast()..undo());
        widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);
        return true;
      }
      ..onRedo = () {
        if (_redoStack.isEmpty) return false;

        _undoHistory.add(_redoStack.removeLast()..redo());
        widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);
        return true;
      }
      ..onClear = () {
        if (_strokes.isEmpty) return;
        setState(() {
          final _removedStrokes = <_Stroke>[]..addAll(_strokes);
          _undoHistory.add(
            RedoUndoHistory(
              undo: () {
                setState(() => _strokes.addAll(_removedStrokes));
              },
              redo: () {
                setState(() => _strokes.clear());
              },
            ),
          );
          setState(() {
            _strokes.clear();
            _redoStack.clear();
          });
        });
        widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);
      };
    super.initState();
  }

  void _start(double startX, double startY) {
    final newStroke = _Stroke(
      color: widget.strokeColor,
      width: widget.strokeWidth,
      drawingMode: widget.drawingMode,
    );
    newStroke.path.moveTo(startX, startY);

    _strokes.add(newStroke);
    _undoHistory.add(
      RedoUndoHistory(
        undo: () {
          setState(() => _strokes.remove(newStroke));
        },
        redo: () {
          setState(() => _strokes.add(newStroke));
        },
      ),
    );
    _redoStack.clear();
    widget.onRedoUndo?.call(_undoHistory.isNotEmpty, _redoStack.isNotEmpty);
  }

  void _add(double x, double y) {
    setState(() {
      _strokes.last.path.lineTo(x, y);
    });
  }

  @override
Widget build(BuildContext context) {
  Size size = MediaQuery.of(context).size;
  return LayoutBuilder(
    builder: (context, constraints) {
      return GestureDetector(
        onPanStart: (details) => _start(
          details.localPosition.dx,
          details.localPosition.dy,
        ),
        onPanUpdate: (details) {
          _add(
            details.localPosition.dx,
            details.localPosition.dy,
          );
        },
        child: Container(
          height: size.height,
          width: size.width,
          child: CustomPaint(
            painter: _FreehandPainter(
              _strokes,
              widget.backgroundColor,
              widget.backgroundImage as ui.Image,
            ),
          ),
        ),
      );
    },
  );
}

}

class CanvasBoardController {
  late _CanvasBoardControllerDelegate _delegate;

  /// Convert [Whiteboard] into image data with given format.
  /// You can obtain converted image data via [onConvert] property of [Crop].
  void convertToImage({ImageByteFormat format = ImageByteFormat.png}) =>
      _delegate.saveAsImage(format);

  /// Undo last stroke
  /// Return [false] if there is no stroke to undo, otherwise return [true].
  bool undo() => _delegate.onUndo();

  /// Redo last undo stroke
  /// Return [false] if there is no stroke to redo, otherwise return [true].
  bool redo() => _delegate.onRedo();

  /// Clear all the strokes
  void clear() => _delegate.onClear();
}

class _CanvasBoardControllerDelegate {
  late Future<void> Function(ImageByteFormat format) saveAsImage;

  late bool Function() onUndo;

  late bool Function() onRedo;

  late VoidCallback onClear;
}

//Stroke
class _Stroke {
  final path = Path();
  final Color color;
  final double width;
  final DrawingMode drawingMode;

  _Stroke({
    this.color = Colors.black,
    this.width = 4,
    this.drawingMode = DrawingMode.draw,
  });
}

enum DrawingMode{
  draw,
  eraser,
  oval,
  rectangle,
  circle,
  line,
}
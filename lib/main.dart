import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
      home: DynamicRoomMap()
  ));
}

class DynamicRoomMap extends StatefulWidget {
  const DynamicRoomMap({super.key});

  @override
  State<DynamicRoomMap> createState() => _DynamicRoomMapState();
}

class _DynamicRoomMapState extends State<DynamicRoomMap> {
  Map<String, dynamic>? roomData;
  final TextEditingController xController = TextEditingController();
  final TextEditingController yController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadRoomData();
  }

  Future<void> loadRoomData() async {
    String jsonString = await rootBundle.loadString('assets/room.json');
    final data = json.decode(jsonString);

    List devices = data["devices"];
    double maxX = 0, maxY = 0;
    for (var device in devices) {
      double x = device["x"].toDouble();
      double y = device["y"].toDouble();
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }

    data["room"]["width"] = (maxX + 100).toInt();
    data["room"]["height"] = (maxY + 100).toInt();

    setState(() {
      roomData = data;
    });
  }

  void addDevice() {
    if (roomData == null) return;
    double? x = double.tryParse(xController.text);
    double? y = double.tryParse(yController.text);
    String type = typeController.text.trim();

    if (x == null || y == null || type.isEmpty) return;

    setState(() {
      roomData!["devices"].add({"x": x, "y": y, "type": type});

      double width = roomData!["room"]["width"].toDouble();
      double height = roomData!["room"]["height"].toDouble();
      if (x + 50 > width) roomData!["room"]["width"] = (x + 100).toInt();
      if (y + 50 > height) roomData!["room"]["height"] = (y + 100).toInt();
    });

    xController.clear();
    yController.clear();
    typeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (roomData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List devices = roomData!["devices"];
    double width = roomData!["room"]["width"].toDouble();
    double height = roomData!["room"]["height"].toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text("Room Map")),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.indigo.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  size: Size(width, height),
                  painter: DynamicRoomPainter(devices),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: xController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "X",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: yController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Y",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: "Type (Fan/Light/AC)",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Add",style: TextStyle(color: Colors.black),),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class DynamicRoomPainter extends CustomPainter {
  final List devices;
  DynamicRoomPainter(this.devices);

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw room boundary (rounded rectangle look)
    final rect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(12));
    canvas.drawRRect(rect, wallPaint);

    for (var device in devices) {
      double x = device["x"].toDouble();
      double y = device["y"].toDouble();
      String type = device["type"];
      Offset pos = Offset(x, y);

      final devicePaint = Paint()..color = _getColorByType(type);

      if (type == "Fan" || type == "Light") {
        canvas.drawCircle(pos, 14, devicePaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: pos, width: 35, height: 25),
            const Radius.circular(6),
          ),
          devicePaint,
        );
      }

      // Label as chip-like text
      _drawLabel(canvas, pos + const Offset(-20, -25), type);
    }
  }

  Color _getColorByType(String type) {
    switch (type) {
      case "Fan":
        return Colors.blue;
      case "Light":
        return Colors.orange;
      case "AC":
        return Colors.green;
      case "TV":
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  void _drawLabel(Canvas canvas, Offset offset, String text) {
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(style: textStyle, text: text),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final bgRect = RRect.fromLTRBR(
      offset.dx - 4,
      offset.dy - 2,
      offset.dx + textPainter.width + 6,
      offset.dy + textPainter.height + 4,
      const Radius.circular(6),
    );

    final bgPaint = Paint()..color = Colors.black87;
    canvas.drawRRect(bgRect, bgPaint);

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  late CameraDescription firstCamera;
  bool isStreaming = false;
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras!.isNotEmpty) {
        firstCamera = cameras!.first;
        controller = CameraController(
          firstCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        controller?.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        });
      }
    });
    connectToServer();
  }

  void connectToServer() {
    channel = IOWebSocketChannel.connect('ws://172.16.29.248:8888');
  }

  @override
  void dispose() {
    controller?.dispose();
    channel.sink.close();
    super.dispose();
  }

  Future<void> startVideoStreaming() async {
    if (!controller!.value.isInitialized) {
      return;
    }
    if (isStreaming) {
      return;
    }
    setState(() {
      isStreaming = true;
    });

    controller?.startImageStream((CameraImage image) {
      if (!isStreaming) return;
      final bytes = concatenatePlanes(image.planes);
      channel.sink.add(bytes);
    });
  }

  Future<void> stopVideoStreaming() async {
    if (!controller!.value.isStreamingImages) {
      return;
    }
    setState(() {
      isStreaming = false;
    });
    await controller?.stopImageStream();
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(controller!),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isStreaming ? Icons.stop : Icons.videocam),
                  onPressed: isStreaming ? stopVideoStreaming : startVideoStreaming,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

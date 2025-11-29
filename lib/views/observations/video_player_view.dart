import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerView extends StatefulWidget {
  final String path;
  const VideoPlayerView({super.key, required this.path});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      if (widget.path.startsWith('http')) {
        _controller = VideoPlayerController.network(widget.path);
      } else if (widget.path.startsWith('file://')) {
        _controller = VideoPlayerController.file(File(widget.path.replaceFirst('file://', '')));
      } else {
        _controller = VideoPlayerController.file(File(widget.path));
      }

      await _controller!.initialize();
      setState(() => _isInitializing = false);
      _controller!.play();
    } catch (e) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _isInitializing
                  ? const CircularProgressIndicator()
                  : (_controller != null && _controller!.value.isInitialized
                      ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))
                      : const Icon(Icons.broken_image, color: Colors.white, size: 64)),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            if (_controller != null && _controller!.value.isInitialized)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                        setState(() {});
                      },
                      icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 44),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


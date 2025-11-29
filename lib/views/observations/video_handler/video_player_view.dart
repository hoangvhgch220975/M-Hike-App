import 'dart:async';
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
  // Slider state
  bool _isDragging = false;
  double _dragValue = 0.0;
  // current playback position in milliseconds (used to drive the slider)
  int _currentPositionMs = 0;
  // last time we updated UI from listener (milliseconds since epoch)
  int _lastUpdateTs = 0;
  Timer? _positionTimer;

  String _formatDuration(Duration d) {
    final int minutes = d.inMinutes.remainder(60);
    final int seconds = d.inSeconds.remainder(60);
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

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
      // Listen for updates so the slider and UI refresh
      _controller!.addListener(_onControllerUpdate);
      // Initialize current position so the slider displays correctly
      _currentPositionMs = _controller!.value.position.inMilliseconds;
      _dragValue = _currentPositionMs.toDouble();
      _lastUpdateTs = DateTime.now().millisecondsSinceEpoch;
      setState(() => _isInitializing = false);
      _controller!.play();
      // Start a periodic timer to update position as a robust fallback so the
      // slider knob follows playback even if listener callbacks are throttled.
      _positionTimer?.cancel();
      _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        if (_controller == null || !_controller!.value.isInitialized) return;
        if (_isDragging) return;
        setState(() {
          _currentPositionMs = _controller!.value.position.inMilliseconds;
        });
      });
    } catch (e) {
      setState(() => _isInitializing = false);
    }
  }

  void _onControllerUpdate() {
    // Update UI when not actively dragging the slider. Keep updates simple so
    // the slider thumb follows the playback position.
    if (!mounted) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    final posMs = _controller!.value.position.inMilliseconds;
    if (!_isDragging) {
      _currentPositionMs = posMs;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.removeListener(_onControllerUpdate);
    _positionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _seekRelative(Duration offset) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final current = _controller!.value.position;
    final duration = _controller!.value.duration ?? Duration.zero;
    var target = current + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    await _controller!.seekTo(target);
    // Refresh UI after seek
    setState(() {
      _currentPositionMs = target.inMilliseconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Precompute duration and current position for the slider
    int durationMs = 1;
    double currentMsDouble = 0.0;
    if (_controller != null && _controller!.value.isInitialized) {
      durationMs = _controller!.value.duration?.inMilliseconds ?? 1;
      currentMsDouble = _isDragging ? _dragValue : _currentPositionMs.toDouble();
    }

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress row: current time, slider, duration
                    Row(
                      children: [
                        Text(
                          _formatDuration(Duration(milliseconds: currentMsDouble.toInt())),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
                            child: Slider(
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                              min: 0.0,
                              max: durationMs.toDouble(),
                              value: currentMsDouble,
                              onChangeStart: (v) {
                                setState(() {
                                  _isDragging = true;
                                  _dragValue = currentMsDouble;
                                });
                              },
                              onChanged: (v) {
                                setState(() => _dragValue = v);
                              },
                              onChangeEnd: (v) async {
                                setState(() => _isDragging = false);
                                await _controller!.seekTo(Duration(milliseconds: v.toInt()));
                                // update current position immediately after seek
                                setState(() => _currentPositionMs = v.toInt());
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_controller!.value.duration ?? Duration.zero),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rewind 10s
                        IconButton(
                          onPressed: () async {
                            await _seekRelative(const Duration(seconds: -10));
                          },
                          icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 12),
                        // Play / Pause
                        IconButton(
                          onPressed: () {
                            if (_controller == null) return;
                            if (_controller!.value.isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                            setState(() {});
                          },
                          icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 44),
                        ),
                        const SizedBox(width: 12),
                        // Forward 10s
                        IconButton(
                          onPressed: () async {
                            await _seekRelative(const Duration(seconds: 10));
                          },
                          icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                        ),
                      ],
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

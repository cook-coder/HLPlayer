// import 'package:flutter/material.dart';

// import 'src/app.dart';
// import 'src/settings/settings_controller.dart';
// import 'src/settings/settings_service.dart';

// void main() async {
//   // Set up the SettingsController, which will glue user settings to multiple
//   // Flutter Widgets.
//   final settingsController = SettingsController(SettingsService());

//   // Load the user's preferred theme while the splash screen is displayed.
//   // This prevents a sudden theme change when the app is first displayed.
//   await settingsController.loadSettings();

//   // Run the app and pass in the SettingsController. The app listens to the
//   // SettingsController for changes, then passes it further down to the
//   // SettingsView.
//   runApp(MyApp(settingsController: settingsController));
// }

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Learning Player',
      theme: ThemeData.dark(),
      home: const VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({Key? key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _showSubtitles = true;
  String? _subtitlePath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      _initializeVideo(file);
    }
  }

  Future<void> _initializeVideo(File file) async {
    _controller?.dispose();
    _controller = VideoPlayerController.file(file);

    await _controller!.initialize();
    setState(() {
      _duration = _controller!.value.duration;
    });

    _controller!.addListener(() {
      if (mounted) {
        setState(() {
          _position = _controller!.value.position;
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    });
  }

  Future<void> _pickSubtitle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt'],
    );

    if (result != null) {
      setState(() {
        _subtitlePath = result.files.single.path;
      });
    }
  }

  Future<void> _generateSubtitles() async {
    // TODO: 实现字幕生成功能
    // 这里需要集成语音识别API或其他字幕生成服务
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成字幕'),
        content: const Text('字幕生成功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Happy Learning Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickVideo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _controller != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : const Text('请选择要播放的视频文件'),
            ),
          ),
          if (_controller != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      _controller?.seekTo(Duration(seconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position)),
                      Text(_formatDuration(_duration)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      _controller?.seekTo(
                        _position - const Duration(seconds: 10),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        _isPlaying ? _controller?.pause() : _controller?.play();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      _controller?.seekTo(
                        _position + const Duration(seconds: 10),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(_showSubtitles
                        ? Icons.subtitles
                        : Icons.subtitles_off),
                    onPressed: () {
                      setState(() {
                        _showSubtitles = !_showSubtitles;
                      });
                    },
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'load',
                        child: Text('加载字幕文件'),
                      ),
                      const PopupMenuItem(
                        value: 'generate',
                        child: Text('生成字幕'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'load') {
                        _pickSubtitle();
                      } else if (value == 'generate') {
                        _generateSubtitles();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
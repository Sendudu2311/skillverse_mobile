import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoLessonPlayer extends StatefulWidget {
  final String? videoUrl;
  final int lessonId;

  const VideoLessonPlayer({
    super.key,
    required this.videoUrl,
    required this.lessonId,
  });

  @override
  State<VideoLessonPlayer> createState() => _VideoLessonPlayerState();
}

class _VideoLessonPlayerState extends State<VideoLessonPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Video URL không khả dụng';
      });
      return;
    }

    try {
      // Check if URL is valid
      final uri = Uri.tryParse(widget.videoUrl!);
      if (uri == null) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'URL video không hợp lệ';
        });
        return;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(uri);

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lỗi phát video',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Lỗi khởi tạo video: ${e.toString()}';
      });
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải video...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitializing = true;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null || _videoPlayerController == null) {
      return const Center(
        child: Text('Video không khả dụng'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Chewie(
            controller: _chewieController!,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thời lượng: ${_formatDuration(_videoPlayerController!.value.duration)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_videoPlayerController!.value.isPlaying)
                const Row(
                  children: [
                    Icon(Icons.play_arrow, size: 20, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Đang phát'),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}

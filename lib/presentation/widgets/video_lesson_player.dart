import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'common_loading.dart';

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
  PodPlayerController? _controller;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
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
      String playUrl = widget.videoUrl!;

      // Check if it's a YouTube URL
      if (_isYouTubeUrl(widget.videoUrl!)) {
        try {
          final yt = YoutubeExplode();
          final videoId = VideoId(widget.videoUrl!);
          final manifest = await yt.videos.streamsClient.getManifest(videoId);

          // Get the best quality muxed stream (video + audio)
          final streamInfo = manifest.muxed.bestQuality;
          playUrl = streamInfo.url.toString();

          yt.close();
        } catch (e) {
          debugPrint('Error extracting YouTube URL: $e');
          setState(() {
            _isInitializing = false;
            _errorMessage =
                'Không thể tải video YouTube. Vui lòng thử lại sau.';
          });
          return;
        }
      }

      _controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(playUrl),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: false,
          isLooping: false,
          videoQualityPriority: [720, 360],
        ),
      )..initialise();

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

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('m.youtube.com');
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: CommonLoading.center(message: 'Đang tải video...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
        ),
      );
    }

    if (_controller == null) {
      return const Center(child: Text('Video không khả dụng'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PodVideoPlayer(
          controller: _controller!,
          frameAspectRatio: 16 / 9,
          videoAspectRatio: 16 / 9,
          alwaysShowProgressBar: false,
          matchVideoAspectRatioToFrame: true,
          matchFrameAspectRatioToVideo: true,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _isYouTubeUrl(widget.videoUrl!) ? 'YouTube Video' : 'Video',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

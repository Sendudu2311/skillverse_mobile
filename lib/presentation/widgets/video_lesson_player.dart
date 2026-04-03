import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'common_loading.dart';
import 'error_state_widget.dart';

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

class _VideoLessonPlayerState extends State<VideoLessonPlayer> with WidgetsBindingObserver {
  PodPlayerController? _controller;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoLessonPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl || oldWidget.lessonId != widget.lessonId) {
      _disposeController();
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.isInitialised) {
        controller.pause();
        // Cho native player (ExoPlayer/AVPlayer) thời gian giải phóng audio decoder
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (_) {
      // Ignore errors during cleanup
    }
    controller.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_controller?.isInitialised == true && (_controller?.isVideoPlaying ?? false)) {
        _controller?.pause();
      }
    }
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
        playUrl = await _extractYouTubeUrl(widget.videoUrl!);
      }

      _controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(playUrl),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: false,
          isLooping: false,
          videoQualityPriority: [720, 360],
        ),
      );
      await _controller!.initialise();

      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Lỗi khởi tạo video: ${e.toString()}';
      });
      debugPrint('Error initializing video player: $e');
    }
  }

  /// Trích xuất URL stream từ YouTube với retry 1 lần (phòng URL hết hạn)
  Future<String> _extractYouTubeUrl(String youtubeUrl, {bool isRetry = false}) async {
    final yt = YoutubeExplode();
    try {
      final videoId = VideoId(youtubeUrl);
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.bestQuality;
      return streamInfo.url.toString();
    } catch (e) {
      debugPrint('Error extracting YouTube URL${isRetry ? " (retry)" : ""}: $e');
      if (!isRetry) {
        // Retry 1 lần — YouTube stream URL có thể hết hạn
        yt.close();
        return _extractYouTubeUrl(youtubeUrl, isRetry: true);
      }
      if (!mounted) rethrow;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Không thể tải video YouTube. Vui lòng thử lại sau.';
      });
      rethrow;
    } finally {
      yt.close();
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
      return ErrorStateWidget(
        icon: Icons.video_library_outlined,
        message: _errorMessage!,
        onRetry: () {
          setState(() {
            _isInitializing = true;
            _errorMessage = null;
          });
          _initializePlayer();
        },
      );
    }

    if (_controller == null) {
      return ErrorStateWidget(
        message: 'Video không khả dụng',
        onRetry: () {
          setState(() {
            _isInitializing = true;
          });
          _initializePlayer();
        },
      );
    }

    return PodVideoPlayer(
      controller: _controller!,
      frameAspectRatio: 16 / 9,
      videoAspectRatio: 16 / 9,
      alwaysShowProgressBar: false,
      matchVideoAspectRatioToFrame: true,
      matchFrameAspectRatioToVideo: true,
    );
  }
}

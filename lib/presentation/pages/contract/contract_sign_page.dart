import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/themed_scaffold.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/error_handler.dart';

/// Contract signing page with a built-in signature pad.
/// Uses CustomPainter to capture the user's signature, renders it to PNG,
/// then uploads to Cloudinary via the existing media endpoint before
/// calling the sign-contract API.
class ContractSignPage extends StatefulWidget {
  final int contractId;

  const ContractSignPage({super.key, required this.contractId});

  @override
  State<ContractSignPage> createState() => _ContractSignPageState();
}

class _ContractSignPageState extends State<ContractSignPage> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isUploading = false;
  bool _isDrawing = false; // Track active drawing to prevent scroll theft
  final GlobalKey _signatureKey = GlobalKey();

  bool get _hasSignature => _strokes.isNotEmpty;
  bool get _isBusy => _isUploading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemedScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SkillVerseAppBar(
          title: 'Ký hợp đồng',
          onBack: _isBusy ? null : () => context.pop(),
          actions: [
            if (_hasSignature && !_isBusy)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Xóa chữ ký',
                onPressed: _clearSignature,
              ),
          ],
        ),
        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                Expanded(
                  child: ListView(
                    // Disable scroll when actively drawing signature
                    physics: _isDrawing
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Instruction
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppTheme.accentCyan,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Vẽ chữ ký của bạn trong khung bên dưới. '
                                'Chữ ký này sẽ được lưu vào hợp đồng và có giá trị xác nhận ý chí.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Signature Pad
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.draw,
                                    size: 16,
                                    color: AppTheme.accentCyan,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Chữ ký',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_hasSignature)
                                    TextButton.icon(
                                      onPressed: _isBusy
                                          ? null
                                          : _clearSignature,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                      ),
                                      label: const Text('Xóa'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.errorColor,
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isDrawing
                                      ? AppTheme.accentCyan
                                      : _hasSignature
                                      ? AppTheme.successColor.withValues(
                                          alpha: 0.5,
                                        )
                                      : Colors.grey.withValues(alpha: 0.3),
                                  width: _isDrawing ? 2.5 : 2,
                                ),
                              ),
                              child: RepaintBoundary(
                                key: _signatureKey,
                                child: GestureDetector(
                                  // Claim all pan gestures so ListView cannot steal them
                                  onPanDown: (_) {
                                    setState(() => _isDrawing = true);
                                  },
                                  onPanStart: (details) {
                                    setState(() {
                                      _currentStroke = [details.localPosition];
                                    });
                                  },
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _currentStroke.add(details.localPosition);
                                    });
                                  },
                                  onPanEnd: (_) {
                                    setState(() {
                                      if (_currentStroke.isNotEmpty) {
                                        _strokes.add(List.from(_currentStroke));
                                      }
                                      _currentStroke = [];
                                      _isDrawing = false;
                                    });
                                  },
                                  onPanCancel: () {
                                    setState(() {
                                      _currentStroke = [];
                                      _isDrawing = false;
                                    });
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CustomPaint(
                                      painter: _SignaturePainter(
                                        strokes: List.unmodifiable(
                                          _strokes.map(
                                            (s) => List<Offset>.unmodifiable(s),
                                          ),
                                        ),
                                        currentStroke:
                                            List<Offset>.unmodifiable(
                                              _currentStroke,
                                            ),
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Disclaimer
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chữ ký điện tử tại màn hình này được xem là xác nhận ý chí '
                                'của bạn đối với toàn bộ nội dung hợp đồng. '
                                'Hãy đọc kỹ các điều khoản trước khi ký.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Confirm button
                _buildBottomAction(isDark),
              ],
            ),

            // Loading overlay — blocks all interaction during upload/sign
            if (_isBusy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CommonLoading.small(),
                          const SizedBox(height: 16),
                          Text(
                            'Đang ký hợp đồng...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vui lòng không tắt ứng dụng',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
          alpha: 0.95,
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Consumer<ContractProvider>(
            builder: (context, provider, _) {
              final busy = _isUploading || provider.isSubmitting;
              return ElevatedButton.icon(
                onPressed: (!_hasSignature || busy) ? null : _confirmAndSign,
                icon: busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CommonLoading.button(),
                      )
                    : const Icon(Icons.check, size: 20),
                label: Text(busy ? 'Đang xử lý...' : 'Xác nhận ký hợp đồng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  /// Show confirmation dialog, then proceed to sign.
  Future<void> _confirmAndSign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận ký hợp đồng?'),
        content: const Text(
          'Sau khi ký, bạn đã đồng ý với tất cả các điều khoản trong hợp đồng. '
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Đồng ý ký'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _handleSign();
    }
  }

  Future<void> _handleSign() async {
    if (!_hasSignature) return;

    setState(() => _isUploading = true);

    try {
      // 1. Capture the signature widget to PNG bytes
      final pngBytes = await _captureSignatureAsPng();
      if (pngBytes == null || !mounted) {
        throw Exception('Không thể tạo ảnh chữ ký');
      }

      // 2. Upload to Cloudinary via backend media endpoint
      final authProvider = context.read<AuthProvider>();
      final actorId = authProvider.user?.id;
      if (actorId == null) {
        throw Exception('Không tìm thấy thông tin phiên đăng nhập (actorId)');
      }
      final imageUrl = await _uploadSignatureImage(pngBytes, actorId);
      if (!mounted) return;

      // 3. Call sign contract API
      final provider = context.read<ContractProvider>();
      final success = await provider.signContract(widget.contractId, imageUrl);

      if (!mounted) return;

      if (success) {
        ErrorHandler.showSuccessSnackBar(context, '🎉 Ký hợp đồng thành công!');
        context.pop(); // Go back to detail page
      } else if (provider.errorMessage != null) {
        ErrorHandler.showErrorSnackBar(context, provider.errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Capture the RepaintBoundary containing the signature as a PNG Uint8List.
  Future<Uint8List?> _captureSignatureAsPng() async {
    try {
      final boundary =
          _signatureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Upload signature image bytes to backend/Cloudinary.
  Future<String> _uploadSignatureImage(Uint8List pngBytes, int actorId) async {
    final apiClient = ApiClient();
    final formData = dio.FormData.fromMap({
      'file': dio.MultipartFile.fromBytes(
        pngBytes,
        filename: 'signature_${DateTime.now().millisecondsSinceEpoch}.png',
      ),
      'actorId': actorId,
    });

    final response = await apiClient.dio.post<Map<String, dynamic>>(
      '/media/upload',
      data: formData,
    );

    final url = response.data?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Upload thất bại — không nhận được URL');
    }
    return url;
  }
}

// ==================== CUSTOM PAINTER ====================

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // White background (important for PNG export)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final paint = Paint()
      ..color =
          const Color(0xFF1E293B) // Dark ink
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // Draw current stroke
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }

    // Hint text when empty
    if (strokes.isEmpty && currentStroke.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Vẽ chữ ký tại đây',
          style: TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        // Use a separate paint for dots to avoid mutating the shared paint
        final dotPaint = Paint()
          ..color = paint.color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        canvas.drawPoints(ui.PointMode.points, points, dotPaint);
      }
      return;
    }
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) =>
      !identical(strokes, old.strokes) ||
      !identical(currentStroke, old.currentStroke);
}

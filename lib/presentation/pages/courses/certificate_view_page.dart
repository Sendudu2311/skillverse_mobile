import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../data/services/certificate_service.dart';
import '../../widgets/common_loading.dart';

/// Native Flutter certificate view page that mirrors
/// the web prototype's CertificateTemplate.tsx design.
class CertificateViewPage extends StatefulWidget {
  final int certificateId;

  const CertificateViewPage({super.key, required this.certificateId});

  @override
  State<CertificateViewPage> createState() => _CertificateViewPageState();
}

class _CertificateViewPageState extends State<CertificateViewPage> {
  final CertificateService _service = CertificateService();
  final GlobalKey _repaintKey = GlobalKey();

  CertificateDto? _cert;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    try {
      final cert = await _service.getCertificate(
        certificateId: widget.certificateId,
      );
      if (mounted) setState(() { _cert = cert; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải chứng chỉ.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _captureAndShare() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Copy to clipboard as a fallback notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ảnh chứng chỉ đã được chụp (${bytes.length ~/ 1024} KB). '
              'Bạn có thể chụp màn hình để lưu.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chụp ảnh chứng chỉ.')),
        );
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        title: const Text('Chứng chỉ khóa học'),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
        actions: [
          if (_cert != null) ...[
            IconButton(
              icon: const Icon(Icons.screenshot_outlined),
              tooltip: 'Chụp ảnh chứng chỉ',
              onPressed: _captureAndShare,
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Sao chép mã chứng chỉ',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _cert!.serial));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép: ${_cert!.serial}'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CommonLoading());
    }
    if (_error != null || _cert == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Không tìm thấy chứng chỉ.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: RepaintBoundary(
          key: _repaintKey,
          child: _CertificateCard(
            cert: _cert!,
            formattedDate: _formatDate(_cert!.issuedAt),
          ),
        ),
      ),
    );
  }
}

/// The actual certificate card widget — a self-contained,
/// stateless widget for clean separation and RepaintBoundary capture.
class _CertificateCard extends StatelessWidget {
  final CertificateDto cert;
  final String formattedDate;

  const _CertificateCard({
    required this.cert,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE1E1E1), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 40,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 11 / 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── LEFT COLUMN (75%) ───
            Expanded(
              flex: 75,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/skillverse.png',
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),

                    // Date
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF787878),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Recipient Name
                    Text(
                      cert.recipientName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Statement
                    const Text(
                      'đã hoàn thành khóa học trực tuyến trên nền tảng Skillverse',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF383838),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Course Name
                    Text(
                      cert.courseTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF383838),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'được cấp nội bộ bởi '),
                          TextSpan(
                            text: cert.issuerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text:
                                ' dựa trên dữ liệu hoàn thành khóa học đã được xác nhận trên nền tảng Skillverse.',
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ─── FOOTER ───
                    _buildFooter(),
                  ],
                ),
              ),
            ),

            // ─── RIGHT RIBBON (25%) ───
            Expanded(
              flex: 25,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7F8),
                  border: Border(
                    left: BorderSide(color: Color(0xFFE1E1E1)),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CHỨNG CHỈ\nKHÓA HỌC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0056D2),
                        letterSpacing: 1,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Seal
                    _buildSeal(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final hasSignature = cert.instructorSignatureUrl != null &&
        cert.instructorSignatureUrl!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Signature block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSignature)
                Image.network(
                  cert.instructorSignatureUrl!,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    cert.issuerName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontFamily: 'Roboto',
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                )
              else
                Text(
                  cert.issuerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              Container(
                width: 160,
                height: 1,
                color: const Color(0xFFCCCCCC),
                margin: const EdgeInsets.only(top: 4, bottom: 4),
              ),
              Text(
                hasSignature ? cert.instructorName : cert.issuerName,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF787878),
                ),
              ),
              Text(
                hasSignature
                    ? 'Chữ ký của người hướng dẫn'
                    : 'Xác thực nền tảng',
                style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF787878),
                ),
              ),
            ],
          ),
        ),

        // Verification block
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đơn vị cấp: ${cert.issuerName}',
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF787878),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Mã xác thực: ${cert.serial}',
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF787878),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Có thể xác thực công khai trên Skillverse\nbằng mã chứng chỉ ở trên.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 7,
                color: Color(0xFFAAAAAA),
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeal() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer border
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCCCCCC), width: 2),
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFDDDDDD),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.6, 0,
                    ]),
                    child: Image.asset(
                      'assets/skillverse.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

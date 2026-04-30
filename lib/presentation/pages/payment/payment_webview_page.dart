import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/common_loading.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String checkoutUrl;
  final String? successUrl;
  final String? cancelUrl;

  const PaymentWebViewPage({
    super.key,
    required this.checkoutUrl,
    this.successUrl,
    this.cancelUrl,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  String _lastUrl = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _lastUrl = url;
            });
            _checkUrlForCallback(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Nếu lỗi xảy ra trên callback URL → pop với kết quả
            // thay vì hiện lỗi (ví dụ ERR_BLOCKED_BY_ORB)
            if (_isCallbackUrl(_lastUrl)) {
              _handleCallback(_lastUrl);
              return;
            }
            setState(() {
              _error = 'Lỗi tải trang: ${error.description}';
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if URL matches success or cancel callback
            if (_isCallbackUrl(request.url)) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _isCallbackUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Check if matches success or cancel URL pattern
    if (widget.successUrl != null &&
        url.startsWith(widget.successUrl!.split('?')[0])) {
      return true;
    }
    if (widget.cancelUrl != null &&
        url.startsWith(widget.cancelUrl!.split('?')[0])) {
      return true;
    }

    // Check for common success/cancel patterns
    if (url.contains('payment/success') ||
        url.contains('payment/completed') ||
        url.contains('status=success') ||
        url.contains('status=completed')) {
      return true;
    }
    if (url.contains('payment/cancel') ||
        url.contains('payment/failed') ||
        url.contains('status=cancel') ||
        url.contains('status=failed')) {
      return true;
    }

    return false;
  }

  void _checkUrlForCallback(String url) {
    if (_isCallbackUrl(url)) {
      _handleCallback(url);
    }
  }

  void _handleCallback(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Determine if success or cancel
    bool isSuccess = false;
    if (widget.successUrl != null &&
        url.startsWith(widget.successUrl!.split('?')[0])) {
      isSuccess = true;
    } else if (url.contains('success') || url.contains('completed')) {
      isSuccess = true;
    }

    // Extract query parameters
    final queryParams = uri.queryParameters;

    // Pop with result
    if (mounted) {
      Navigator.pop(context, {
        'success': isSuccess,
        'url': url,
        'params': queryParams,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Thanh toán',
        icon: Icons.payment,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _showCancelDialog,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (_error != null)
              ErrorStateWidget(
                message: _error!,
                onRetry: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _controller.reload();
                },
              )
            else
              WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: CommonLoading.center(
                  message: 'Đang tải trang thanh toán...',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thanh toán'),
        content: const Text('Bạn có chắc muốn hủy thanh toán?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context, {'success': false, 'cancelled': true});
    }
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
            });
            _checkUrlForCallback(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
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
      appBar: AppBar(
        title: const Text('Thanh toán'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _showCancelDialog();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _controller.reload();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải trang thanh toán...'),
                  ],
                ),
              ),
            ),
        ],
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
      Navigator.pop(context, {
        'success': false,
        'cancelled': true,
      });
    }
  }
}

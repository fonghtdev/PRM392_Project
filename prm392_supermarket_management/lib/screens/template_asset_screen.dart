import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class TemplateAssetScreen extends StatefulWidget {
  const TemplateAssetScreen({
    super.key,
    required this.title,
    required this.assetPath,
    this.javascriptChannels = const {},
    this.showAppBar = true,
    this.actions,
    this.bottomNavigationBar,
  });

  final String title;
  final String assetPath;
  final Map<String, void Function(String message)> javascriptChannels;
  final bool showAppBar;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  @override
  State<TemplateAssetScreen> createState() => _TemplateAssetScreenState();
}

class _TemplateAssetScreenState extends State<TemplateAssetScreen> {
  bool get _isMobileWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isWindowsWebView =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  WebViewController? _mobileController;
  WebviewController? _windowsController;
  StreamSubscription<dynamic>? _windowsMessageSubscription;
  StreamSubscription<String>? _windowsUrlSubscription;
  Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();

    if (_isMobileWebView) {
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              if (_handleAppBridgeUrl(request.url)) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );
      for (final entry in widget.javascriptChannels.entries) {
        _mobileController!.addJavaScriptChannel(
          entry.key,
          onMessageReceived: (message) => entry.value(message.message),
        );
      }
      _loadFuture = _loadMobileHtml();
    } else if (_isWindowsWebView) {
      _windowsController = WebviewController();
      _windowsMessageSubscription = _windowsController!.webMessage.listen(
        _handleWindowsWebMessage,
      );
      _windowsUrlSubscription = _windowsController!.url.listen(
        _handleAppBridgeUrl,
      );
      _loadFuture = _loadWindowsHtml();
    }
  }

  Future<void> _loadMobileHtml() async {
    final html = _prepareHtml(await rootBundle.loadString(widget.assetPath));
    await _mobileController!.loadHtmlString(html);
  }

  Future<void> _loadWindowsHtml() async {
    final html = _prepareHtml(await rootBundle.loadString(widget.assetPath));
    await _windowsController!.initialize();
    await _windowsController!
        .setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    await _windowsController!.loadStringContent(html);
  }

  String _prepareHtml(String html) {
    const cdnMarker = 'https://cdn.tailwindcss.com';
    if (!html.contains(cdnMarker)) {
      return html;
    }

    const suppressScript = '''
<script>
(() => {
  const originalWarn = console.warn;
  console.warn = function (...args) {
    if (args.length > 0 && typeof args[0] === 'string' && args[0].includes('cdn.tailwindcss.com should not be used in production')) {
      return;
    }
    return originalWarn.apply(console, args);
  };
})();
</script>
''';

    if (html.contains('</head>')) {
      return html.replaceFirst('</head>', '$suppressScript</head>');
    }
    return '$suppressScript$html';
  }

  void _handleWindowsWebMessage(dynamic data) {
    if (widget.javascriptChannels.isEmpty) {
      return;
    }

    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final channel = decoded['channel']?.toString();
          final message = decoded['message']?.toString() ?? '';
          final handler = widget.javascriptChannels[channel];
          if (handler != null) {
            handler(message);
          }
        }
      } else if (data is Map) {
        final channel = data['channel']?.toString();
        final message = data['message']?.toString() ?? '';
        final handler = widget.javascriptChannels[channel];
        if (handler != null) {
          handler(message);
        }
      }
    } catch (_) {
      // Ignore malformed messages from template scripts.
    }
  }

  bool _handleAppBridgeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.toLowerCase() != 'app') {
      return false;
    }

    final channel = uri.host;
    final message = uri.pathSegments.isNotEmpty
        ? Uri.decodeComponent(uri.pathSegments.first)
        : '';
    final handler = widget.javascriptChannels[channel];
    if (handler != null) {
      handler(message);
    }
    return true;
  }

  @override
  void dispose() {
    _windowsMessageSubscription?.cancel();
    _windowsUrlSubscription?.cancel();
    _windowsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.title),
              actions: widget.actions,
            )
          : null,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isMobileWebView || _isWindowsWebView) {
      return FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load template: ${snapshot.error}'),
              ),
            );
          }

          if (_isMobileWebView) {
            return WebViewWidget(controller: _mobileController!);
          }

          return Webview(_windowsController!);
        },
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This platform is not supported for template preview. Use Android, iOS, or Windows.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// lib/screens/payment_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final Function(bool success) onComplete;

  const PaymentWebViewScreen({
    Key? key,
    required this.url,
    required this.onComplete,
  }) : super(key: key);

  @override
  _PaymentWebViewScreenState createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late WebViewController _controller;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('success')) {
              widget.onComplete(true);
              Navigator.pop(context);
              return NavigationDecision.prevent;
            } else if (request.url.contains('failed')) {
              widget.onComplete(false);
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            widget.onComplete(false);
            Navigator.pop(context);
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

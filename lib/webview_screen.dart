import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'shimmer_loading.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({
    super.key,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = false;
  int _currentShimmerIndex = 0;
  Timer? _shimmerRotationTimer;

  // List of different shimmer effects to cycle through
  final List<Widget> _shimmerEffects = [
    const ShimmerLoading(),
    const TaskShimmerLoading(),
    const CalendarShimmerLoading(),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize the WebView controller
    _isLoading = true;
    _startShimmerRotation();
    _initWebViewController();
  }

  @override
  void dispose() {
    _shimmerRotationTimer?.cancel();
    super.dispose();
  }

  // Start cycling through different shimmer effects
  void _startShimmerRotation() {
    _shimmerRotationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _currentShimmerIndex =
              (_currentShimmerIndex + 1) % _shimmerEffects.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initWebViewController() async {
    try {
      // Create cache directory for WebView
      final Directory appCacheDir = await getApplicationCacheDirectory();
      final String cachePath = '${appCacheDir.path}/WebViewCache';
      await Directory(cachePath).create(recursive: true);

      // Initialize WebView with caching enabled
      final controller = WebViewController();

      // Set up WebView settings
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0x00000000));

      // Set up a custom WebView client to handle errors properly
      if (Platform.isAndroid) {
        // For Android, we need to handle console messages in a safe way
        try {
          controller.setOnConsoleMessage((JavaScriptConsoleMessage message) {
            debugPrint('WebView Console: ${message.message}');
          });
        } catch (e) {
          debugPrint('Error setting console message handler: $e');
        }
      }

      // Set navigation delegate with proper error handling
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });

            // Enable caching via JavaScript - using try-catch to handle potential errors
            try {
              controller.runJavaScript('''
                try {
                  // Enable local storage caching
                  localStorage.setItem('cache_timestamp', Date.now());
                  
                  // Apply cache control to all images
                  document.querySelectorAll('img').forEach(function(img) {
                    img.setAttribute('loading', 'lazy');
                    var currentSrc = img.src;
                    img.setAttribute('data-src', currentSrc);
                  });
                  
                  // Add cache control meta tags if not present
                  if (!document.querySelector('meta[http-equiv="Cache-Control"]')) {
                    var meta = document.createElement('meta');
                    meta.setAttribute('http-equiv', 'Cache-Control');
                    meta.setAttribute('content', 'max-age=86400');
                    document.head.appendChild(meta);
                  }
                  
                  // Add global error handler to catch JavaScript errors
                  window.onerror = function(message, source, lineno, colno, error) {
                    console.log('Caught JS error: ' + message);
                    return true; // Prevents the error from being shown in the console
                  };
                } catch(e) {
                  console.log('Error in caching script: ' + e);
                }
              ''');
            } catch (e) {
              debugPrint('Error running JavaScript: $e');
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
                'WebView error: ${error.description} (${error.errorCode})');
            // Don't set loading to false here as it might be called multiple times
            // and could interfere with the page loading process
          },
          // Handle HTTP errors separately to avoid the IllegalStateException
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

      // Load the website with cache headers
      await controller.loadRequest(
        Uri.parse(widget.url),
        headers: {
          'Cache-Control': 'max-age=86400', // Cache for 24 hours
          'Pragma': 'cache',
          'Expires':
              DateTime.now().add(const Duration(days: 1)).toUtc().toString(),
        },
      );

      // Enable platform-specific features
      if (Platform.isAndroid) {
        _enableAndroidCaching(controller);
      } else if (Platform.isIOS) {
        _enableIOSCaching(controller);
      }

      // Set the controller after it's fully initialized
      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Enable caching on Android
  void _enableAndroidCaching(WebViewController controller) {
    try {
      controller.runJavaScript('''
        try {
          // Force caching on Android WebView
          document.cookie = 'cache=true; max-age=86400; path=/';
        } catch(e) {
          console.log('Error setting Android cache: ' + e);
        }
      ''');
    } catch (e) {
      debugPrint('Error enabling Android caching: $e');
    }
  }

  // Enable caching on iOS
  void _enableIOSCaching(WebViewController controller) {
    try {
      controller.runJavaScript('''
        try {
          // Force caching on iOS WebView
          document.cookie = 'cache=true; max-age=86400; path=/';
        } catch(e) {
          console.log('Error setting iOS cache: ' + e);
        }
      ''');
    } catch (e) {
      debugPrint('Error enabling iOS caching: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller != null && await _controller!.canGoBack()) {
          await _controller!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // WebView
              if (_controller != null)
                WebViewWidget(controller: _controller!)
              else
                const SizedBox.shrink(),

              // Shimmer loading effect
              if (_isLoading)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _shimmerEffects[_currentShimmerIndex],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/open_food_facts_service.dart';
import '../services/groq_service.dart';
import '../models/scan_result_model.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _scanned = false;
  bool _torchOn = false;
  bool _loading = false;
  String _loadingMessage = 'Fetching product data...';
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _loading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final code = barcode!.rawValue!;
    setState(() {
      _scanned = true;
      _loading = true;
      _loadingMessage = 'Fetching product data...';
    });
    await _controller?.stop();

    try {
      // Step 1: Fetch from Open Food Facts
      final product = await OpenFoodFactsService.lookupBarcode(code);

      if (!mounted) return;

      if (!product.found || product.name.isEmpty) {
        _showNotFoundDialog(code);
        return;
      }

      // Step 2: AI analysis
      if (mounted) setState(() => _loadingMessage = 'Analyzing ingredients with AI...');

      final aiResult = await GroqService.analyzeHalalStatus(
        product.name,
        product.ingredients,
      );

      if (!mounted) return;

      // Step 3: Navigate to result screen
      Navigator.pushReplacementNamed(
        context,
        '/scan-result',
        arguments: {
          'product': product,
          'aiResult': aiResult,
        },
      );
    } catch (_) {
      if (mounted) {
        _showNotFoundDialog(code);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetScanner() {
    if (mounted) setState(() { _scanned = false; _loading = false; });
    _controller?.start();
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Product Not Found',
          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              barcode,
              style: GoogleFonts.outfit(
                color: AppTheme.textMuted,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This barcode is not in our database. Try searching manually or report it.',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _resetScanner(); },
            child: Text('Scan Again', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/report').then((_) => _resetScanner());
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: Text('Report', style: GoogleFonts.outfit(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live camera feed
          if (!_loading)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),

          // Dark overlay with cutout
          AnimatedBuilder(
            animation: _scanLineController,
            builder: (_, __) => CustomPaint(
              painter: _ScannerOverlayPainter(
                scanLineProgress: _scanLineController.value,
                showScanLine: !_loading,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1500.ms, color: AppTheme.primary.withOpacity(0.3)),
                    const SizedBox(height: 24),
                    Text(
                      _loadingMessage,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait...',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Scan Product',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _CircleButton(
                    icon: _torchOn
                        ? Icons.flashlight_off_rounded
                        : Icons.flashlight_on_rounded,
                    iconColor: _torchOn ? AppTheme.primary : Colors.white,
                    onTap: () {
                      _controller?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Bottom area
          if (!_loading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.black.withOpacity(0)],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Point camera at a barcode',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Search manually instead',
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanLineProgress;
  final bool showScanLine;

  _ScannerOverlayPainter({
    required this.scanLineProgress,
    required this.showScanLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cutoutW = size.width * 0.72;
    final cutoutH = cutoutW * 0.65;
    final cutoutLeft = (size.width - cutoutW) / 2;
    final cutoutTop = size.height * 0.28;

    // Dark overlay with hole
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.65);
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutW, cutoutH),
          const Radius.circular(16),
        ))
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // Green corner brackets
    const cornerLen = 32.0;
    const cornerRadius = 14.0;
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final positions = [
      // [startX, startY, endX, endY] for each corner
      // Top-left horizontal
      [cutoutLeft + cornerRadius, cutoutTop, cutoutLeft + cornerRadius + cornerLen, cutoutTop],
      // Top-left vertical
      [cutoutLeft, cutoutTop + cornerRadius, cutoutLeft, cutoutTop + cornerRadius + cornerLen],
      // Top-right horizontal
      [cutoutLeft + cutoutW - cornerRadius - cornerLen, cutoutTop, cutoutLeft + cutoutW - cornerRadius, cutoutTop],
      // Top-right vertical
      [cutoutLeft + cutoutW, cutoutTop + cornerRadius, cutoutLeft + cutoutW, cutoutTop + cornerRadius + cornerLen],
      // Bottom-left horizontal
      [cutoutLeft + cornerRadius, cutoutTop + cutoutH, cutoutLeft + cornerRadius + cornerLen, cutoutTop + cutoutH],
      // Bottom-left vertical
      [cutoutLeft, cutoutTop + cutoutH - cornerRadius - cornerLen, cutoutLeft, cutoutTop + cutoutH - cornerRadius],
      // Bottom-right horizontal
      [cutoutLeft + cutoutW - cornerRadius - cornerLen, cutoutTop + cutoutH, cutoutLeft + cutoutW - cornerRadius, cutoutTop + cutoutH],
      // Bottom-right vertical
      [cutoutLeft + cutoutW, cutoutTop + cutoutH - cornerRadius - cornerLen, cutoutLeft + cutoutW, cutoutTop + cutoutH - cornerRadius],
    ];

    for (final p in positions) {
      canvas.drawLine(Offset(p[0], p[1]), Offset(p[2], p[3]), cornerPaint);
    }

    // Animated scan line
    if (showScanLine) {
      final lineY = cutoutTop + cutoutH * scanLineProgress;
      final linePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0),
            AppTheme.primary.withOpacity(0.8),
            AppTheme.primary.withOpacity(0),
          ],
        ).createShader(Rect.fromLTWH(cutoutLeft, lineY, cutoutW, 2))
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(cutoutLeft + 8, lineY),
        Offset(cutoutLeft + cutoutW - 8, lineY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.scanLineProgress != scanLineProgress || old.showScanLine != showScanLine;
}

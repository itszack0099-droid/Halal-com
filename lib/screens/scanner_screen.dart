import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _scanned = false;
  bool _torchOn = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _loading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final code = barcode!.rawValue!;
    setState(() { _scanned = true; _loading = true; });
    await _controller?.stop();

    try {
      final product = await SupabaseService.getProductByBarcode(code);
      if (!mounted) return;
      if (product != null) {
        Navigator.pushNamed(context, '/product', arguments: product)
            .then((_) => _resetScanner());
      } else {
        _showNotFoundDialog(code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error looking up product')),
        );
        _resetScanner();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetScanner() {
    setState(() => _scanned = false);
    _controller?.start();
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Product Not Found',
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('Barcode: $barcode',
                style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontFamily: 'monospace')),
            const SizedBox(height: 12),
            Text('This product is not in our database yet.',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
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
            child: Text('Report Product', style: GoogleFonts.outfit(fontSize: 13)),
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
          // Camera
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const Spacer(),
                  Text('Barcode Scanner',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      _controller?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                    icon: Icon(
                        _torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
                        color: _torchOn ? AppTheme.primary : Colors.white,
                        size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Bottom hint
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_loading)
                  const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)
                else
                  Text(
                    'Point at a product barcode',
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/search'),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: Text('Search Instead', style: GoogleFonts.outfit(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final cutoutSize = size.width * 0.7;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2 - 40;

    final cutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
      const Radius.circular(16),
    );

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(cutout)
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Corner decorations
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    final cr = 16.0;

    // Top-left
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft + cr, cutoutTop)
      ..lineTo(cutoutLeft + cr + cornerLen, cutoutTop), cornerPaint);
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft, cutoutTop + cr)
      ..lineTo(cutoutLeft, cutoutTop + cr + cornerLen), cornerPaint);

    // Top-right
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft + cutoutSize - cr - cornerLen, cutoutTop)
      ..lineTo(cutoutLeft + cutoutSize - cr, cutoutTop), cornerPaint);
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft + cutoutSize, cutoutTop + cr)
      ..lineTo(cutoutLeft + cutoutSize, cutoutTop + cr + cornerLen), cornerPaint);

    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft + cr, cutoutTop + cutoutSize)
      ..lineTo(cutoutLeft + cr + cornerLen, cutoutTop + cutoutSize), cornerPaint);
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft, cutoutTop + cutoutSize - cr - cornerLen)
      ..lineTo(cutoutLeft, cutoutTop + cutoutSize - cr), cornerPaint);

    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft + cutoutSize - cr - cornerLen, cutoutTop + cutoutSize)
      ..lineTo(cutoutLeft + cutoutSize - cr, cutoutTop + cutoutSize), cornerPaint);
    canvas.drawPath(Path()
      ..moveTo(cutoutLeft + cutoutSize, cutoutTop + cutoutSize - cr - cornerLen)
      ..lineTo(cutoutLeft + cutoutSize, cutoutTop + cutoutSize - cr), cornerPaint);

    // Scan line
    final linePaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cutoutLeft + 16, cutoutTop + cutoutSize / 2),
      Offset(cutoutLeft + cutoutSize - 16, cutoutTop + cutoutSize / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) => false;
}

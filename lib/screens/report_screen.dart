import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _productNameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  String _issueType = 'Wrong halal status';
  bool _loading = false;
  bool _submitted = false;

  final _issues = [
    'Wrong halal status',
    'Incorrect ingredients',
    'Product info outdated',
    'Missing halal certification',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productNameCtrl.dispose();
    _barcodeCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_productNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name')),
      );
      return;
    }
    if (_detailsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.submitReport(
        productName: _productNameCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        issueType: _issueType,
        details: _detailsCtrl.text.trim(),
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Report a Product',
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64))
                .animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),
            const SizedBox(height: 20),
            Text('Report Submitted!',
                style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w700))
                .animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 12),
            Text(
              'Thank you for helping keep our database accurate. Our team will review your report.',
              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Done', style: GoogleFonts.outfit(fontSize: 16)),
            ).animate(delay: 300.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 14),
            tabs: const [Tab(text: 'Report Error'), Tab(text: 'New Product')],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildReportErrorForm(), _buildNewProductForm()],
          ),
        ),
      ],
    );
  }

  Widget _buildReportErrorForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Product Name *'),
          TextField(
            controller: _productNameCtrl,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Oreo Cookies',
              prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted, size: 20),
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 14),

          _label('Barcode (optional)'),
          TextField(
            controller: _barcodeCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. 012345678901',
              prefixIcon: Icon(Icons.qr_code, color: AppTheme.textMuted, size: 20),
            ),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 14),

          _label('Issue Type'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _issueType,
                dropdownColor: AppTheme.surface,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
                items: _issues.map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i, style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
                )).toList(),
                onChanged: (v) => setState(() => _issueType = v!),
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 14),

          _label('Details *'),
          TextField(
            controller: _detailsCtrl,
            maxLines: 4,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Describe the issue in detail...',
            ),
          ).animate(delay: 250.ms).fadeIn(),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_loading ? 'Submitting...' : 'Submit Report',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNewProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Product Name *'),
          TextField(
            controller: _productNameCtrl,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Brand X Chips',
              prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted, size: 20),
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 14),

          _label('Barcode'),
          TextField(
            controller: _barcodeCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Scan or type barcode',
              prefixIcon: Icon(Icons.qr_code, color: AppTheme.textMuted, size: 20),
            ),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 14),

          _label('Additional Info *'),
          TextField(
            controller: _detailsCtrl,
            maxLines: 4,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Include brand, country, ingredients, certifications...',
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(_loading ? 'Submitting...' : 'Submit Product',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
          ).animate(delay: 250.ms).fadeIn(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: GoogleFonts.outfit(
              color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

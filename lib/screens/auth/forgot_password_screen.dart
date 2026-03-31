import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  Future<void> _resetPassword() async {
    if (!_emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.resetPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('🔑', style: TextStyle(fontSize: 48))
            .animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),
        const SizedBox(height: 20),
        Text('Reset Password',
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700))
            .animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 8),
        Text('Enter your email to receive reset instructions.',
            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14))
            .animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 36),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.outfit(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
          ),
        ).animate(delay: 300.ms).fadeIn(),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _loading ? null : _resetPassword,
          child: _loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Send Reset Email',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
        ).animate(delay: 400.ms).fadeIn(),
      ],
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📧', style: TextStyle(fontSize: 64))
              .animate().fadeIn().scale(begin: const Offset(0.7, 0.7)),
          const SizedBox(height: 24),
          Text('Check Your Email',
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w700))
              .animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 12),
          Text(
            'We sent a password reset link to\n${_emailCtrl.text}',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text('Back to Sign In',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }
}

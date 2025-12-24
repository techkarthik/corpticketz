import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:corpticketz/providers/auth_provider.dart';
import 'package:corpticketz/services/api_service.dart';
import 'package:corpticketz/screens/registration_screen.dart';
import 'package:corpticketz/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _orgIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPersistedOrgId();
  }

  Future<void> _loadPersistedOrgId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOrgId = prefs.getString('last_org_id');
    if (lastOrgId != null) {
      setState(() {
        _orgIdController.text = lastOrgId;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _orgIdController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('LOGIN ERROR: $e'); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: $e')),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    int step = 0;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(step == 0 ? 'Reset Password' : 'Set New Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (step == 0) ...[
                TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: 'Organization ID')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              ] else ...[
                TextField(controller: otpCtrl, decoration: const InputDecoration(labelText: 'OTP from Email')),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
              ],
              if (loading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: loading ? null : () async {
                setState(() => loading = true);
                try {
                    if (step == 0) {
                        final res = await http.post(
                            Uri.parse('${ApiService.baseUrl}/auth/forgot-password'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'organization_id': orgCtrl.text, 'email': emailCtrl.text}),
                        );
                        if (res.statusCode == 200) {
                            setState(() => step = 1);
                        } else {
                            throw Exception(jsonDecode(res.body)['message']);
                        }
                    } else {
                        final res = await http.post(
                            Uri.parse('${ApiService.baseUrl}/auth/reset-password'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                                'organization_id': orgCtrl.text, 
                                'email': emailCtrl.text,
                                'otp': otpCtrl.text,
                                'newPassword': passCtrl.text
                            }),
                        );
                        if (res.statusCode == 200) {
                            if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Reset Success! Login now.')));
                            }
                        } else {
                            throw Exception(jsonDecode(res.body)['message']);
                        }
                    }
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                   setState(() => loading = false);
                }
              },
              child: Text(step == 0 ? 'Send OTP' : 'Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotOrgIdDialog() {
    final emailCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    int step = 0;
    bool loading = false;
    List<String> foundOrgs = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Recover Organization ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (step == 0) ...[
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Enter your Email')),
              ] else if (step == 1) ...[
                TextField(controller: otpCtrl, decoration: const InputDecoration(labelText: 'Enter OTP')),
              ] else ...[
                const Text('Your Organization IDs:'),
                const SizedBox(height: 10),
                ...foundOrgs.map((e) => SelectableText(e, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                const Text('We also sent this list to your email.'),
              ],
              if (loading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
            ],
          ),
          actions: [
            if (step != 2) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            if (step == 2) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            if (step != 2)
            FilledButton(
              onPressed: loading ? null : () async {
                setState(() => loading = true);
                try {
                  if (step == 0) {
                      final res = await http.post(
                          Uri.parse('${ApiService.baseUrl}/auth/forgot-org-id'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'email': emailCtrl.text}),
                      );
                      if (res.statusCode == 200) {
                          setState(() => step = 1);
                      } else {
                         throw Exception(jsonDecode(res.body)['message']);
                      }
                  } else if (step == 1) {
                      final res = await http.post(
                          Uri.parse('${ApiService.baseUrl}/auth/recover-org-id'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({'email': emailCtrl.text, 'otp': otpCtrl.text}),
                      );
                      if (res.statusCode == 200) {
                          final data = jsonDecode(res.body);
                          setState(() {
                              foundOrgs = List<String>.from(data['orgs']);
                              step = 2;
                          });
                      } else {
                          throw Exception(jsonDecode(res.body)['message']);
                      }
                  }
                } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                   setState(() => loading = false);
                }
              },
              child: Text(step == 0 ? 'Send OTP' : 'Verify'),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotDialog(String type) {
      // The original _showForgotDialog is now replaced by specific dialogs
      // This method can be removed or updated to call the new specific dialogs.
      // For now, I'll update it to call the new dialogs based on type.
      if (type == "Forgot Organization ID") {
        _showForgotOrgIdDialog();
      } else if (type == "Forgot Password") {
        _showForgotPasswordDialog();
      } else {
        showDialog(context: context, builder: (context) => AlertDialog(
            title: Text(type),
            content: const Text("Navigating to recovery... (Not implemented yet)"),
            actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Close"))],
        ));
      }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // Corporate Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1920&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay for Contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Glassmorphism Overlay
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/logo.png', height: 100),
                          const SizedBox(height: 16),
                          Text(
                            'CorpTicketz',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Multi-Tenant Login',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Organization ID
                          TextFormField(
                            controller: _orgIdController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Organization ID',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.business_rounded, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00D2FF), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          // Email
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00D2FF), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 20),
                          // Password
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00D2FF), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 10),
                          // Forgot Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => _showForgotDialog("Forgot Organization ID"),
                                child: const Text("Forgot Org ID?", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: () => _showForgotDialog("Forgot Password"),
                                child: const Text("Forgot Password?", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0056D2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen()));
                            },
                            child: const Text("Create Organization (Sign Up)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
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

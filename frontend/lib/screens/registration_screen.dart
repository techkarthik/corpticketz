import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:corpticketz/providers/auth_provider.dart';
import 'package:corpticketz/services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0: Email, 1: Details
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid email')));
        return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        // Generate Random Org ID
        final rng = Random();
        final orgId = (100000 + rng.nextInt(900000)).toString();

        setState(() {
          _step = 1;
          _orgIdController.text = orgId;
        });
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent. Org ID Is Auto Generated.')));
        }
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
          setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/create-org'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
          'orgName': _orgNameController.text.trim(),
          'orgId': _orgIdController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Organization Created! Please Login.')));
             Navigator.pop(context);
         }
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: $e')));
    } finally {
      if (mounted) {
          setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Professional Background
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1920&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Glassmorphism Overlay
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.business_center_outlined, size: 48, color: Colors.white),
                          const SizedBox(height: 16),
                          Text('Start Your Journey', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _emailController,
                            readOnly: _step == 1,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email Address', 
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
      
                          if (_step == 0)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify Email'),
                              ),
                            ),
      
                          if (_step == 1) ...[
                            TextFormField(
                              controller: _otpController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                  labelText: 'Enter OTP from Email', 
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                  border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _orgNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                  labelText: 'Organization Name', 
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.business, color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                  border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _orgIdController,
                              readOnly: true,
                              style: const TextStyle(color: Colors.white70),
                              decoration: InputDecoration(
                                  labelText: 'Organization ID (Assigned)', 
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.domain, color: Colors.white70),
                                  helperText: 'Auto-generated ID',
                                  helperStyle: const TextStyle(color: Colors.white54),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                                  border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                  labelText: 'Super Admin Name', 
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                  border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                  labelText: 'Password', 
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                                  border: const OutlineInputBorder(),
                              ),
                              validator: (v) => v!.length < 6 ? 'Too short' : null,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: OutlinedButton(
                                  onPressed: () => setState(() => _step = 0), 
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), foregroundColor: Colors.white),
                                  child: const Text('Back')
                                )),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _register,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Registration'),
                                  ),
                                ),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back arrow manually since it's a stack
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

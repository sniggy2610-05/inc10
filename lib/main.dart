import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawPals Signup',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7556C8),
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SignupPage(),
    );
  }
}

// AI service: mock fallback until the instructor's service is confirmed.
class SignupCoachService {
  // Replace with the instructor-provided HTTPS URL when available.
  static const String endpoint = '';

  Future<String> getTip({bool simulateFailure = false}) async {
    // This toggle lets you test the error and retry UI.
    if (simulateFailure) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      throw Exception('Simulated offline failure');
    }

    if (endpoint.isEmpty) {
      // Deterministic mock. No live AI model is called.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      const request = {
        'task': 'signup_tip',
        'topic': 'password_help',
      };
      assert(request['task'] == 'signup_tip');
      return 'Mock advice: Use a unique password with at least 8 '
          'characters. Consider a mix of words, numbers, and symbols.';
    }

    final response = await http
        .post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'task': 'signup_tip',
        'topic': 'password_help',
      }),
    )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('The tip service is unavailable.');
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> ||
        data['tip'] is! String ||
        (data['tip'] as String).trim().isEmpty) {
      throw Exception('The service returned an invalid tip.');
    }

    return (data['tip'] as String).trim();
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _coach = SignupCoachService();

  bool _loadingTip = false;
  bool _simulateFailure = false;
  String? _tip;
  String? _tipError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _getTip() async {
    setState(() {
      _loadingTip = true;
      _tip = null;
      _tipError = null;
    });

    try {
      final result = await _coach.getTip(
        simulateFailure: _simulateFailure,
      );
      if (!mounted) return;
      setState(() => _tip = result.trim().substring(
        0,
        result.trim().length > 240 ? 240 : result.trim().length,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tipError = 'We could not load a signup tip. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loadingTip = false);
    }
  }

  void _signUp() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome, ${_nameController.text.trim()}! Demo signup successful.',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;

    String strength;
    if (password.isEmpty) {
      strength = 'Password strength: Enter a password.';
    } else if (password.length < 8) {
      strength = 'Password strength: Needs improvement (under 8 characters).';
    } else {
      strength = 'Password strength: 8+ characters. Consider more variety.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 PawPals Signup'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets, size: 58, color: Color(0xFF7556C8)),
                const SizedBox(height: 8),
                const Text(
                  'Join the PawPals Club!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your demo account and meet new furry friends.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(strength, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) =>
                  value != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _signUp,
                  icon: const Icon(Icons.pets),
                  label: const Text('Sign Up'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                  ),
                ),
                const Divider(height: 36),
                const Text(
                  '✨ AI Signup Coach',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Get a general password tip. Your name, email, and '
                      'password are never included in the AI request.',
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Simulate offline error (for testing)'),
                  value: _simulateFailure,
                  onChanged: (value) =>
                      setState(() => _simulateFailure = value),
                ),
                ElevatedButton(
                  onPressed: _loadingTip ? null : _getTip,
                  child: Text(
                    _loadingTip ? 'Loading tip...' : 'Get a signup tip',
                  ),
                ),
                if (_loadingTip) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_tip != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'AI-generated advice (MOCK):\n$_tip',
                      ),
                    ),
                  ),
                ],
                if (_tipError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _tipError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: _loadingTip ? null : _getTip,
                    child: const Text('Retry'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Demo only: this form does not create or store an account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'success_screen.dart';

class SignupCoachService {
  // Add your instructor's HTTPS endpoint here if provided.
  static const String endpoint = '';

  Future<String> getTip({bool simulateFailure = false}) async {
    if (simulateFailure) {
      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );
      throw Exception('Simulated offline failure');
    }

    if (endpoint.isEmpty) {
      await Future<void>.delayed(
        const Duration(milliseconds: 700),
      );
      return 'Mock advice: Use a unique password with at least '
          '8 characters. Consider a mix of words, numbers, and symbols.';
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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _dateController = TextEditingController();

  final _coach = SignupCoachService();

  DateTime? _birthDate;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
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
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2008).isAfter(now)
          ? now
          : DateTime(2008),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Choose your birth date',
    );

    if (!mounted || picked == null) return;

    setState(() {
      _birthDate = picked;
      _dateController.text =
      '${picked.month}/${picked.day}/${picked.year}';
    });
  }

  Future<void> _submit() async {
    // Guard against repeated calls, even during the loading delay.
    if (_submitting) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await Future<void>.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            userName: _nameController.text.trim(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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

      final trimmed = result.trim();
      setState(() {
        _tip = trimmed.length > 240
            ? trimmed.substring(0, 240)
            : trimmed;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _tipError =
        'We could not load a signup tip. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingTip = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;

    final strength = password.isEmpty
        ? 'Password strength: Enter a password.'
        : password.length < 8
        ? 'Password strength: Needs improvement (under 8 characters).'
        : 'Password strength: 8+ characters. Consider more variety.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Signup Laboratory'),
        backgroundColor:
        Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.pets,
                  size: 54,
                  color: Color(0xFF7556C8),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join the Haunted Mansion!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 22),

                // Full name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
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

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Birth date
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  decoration: const InputDecoration(
                    labelText: 'Birth date',
                    prefixIcon: Icon(Icons.cake),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  validator: (_) => _birthDate == null
                      ? 'Pick your birth date'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password with visibility toggle
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                Text(
                  strength,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirm
                          ? 'Show confirmation'
                          : 'Hide confirmation',
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Loading state and navigation
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.meeting_room),
                  label: Text(
                    _submitting
                        ? 'Preparing your guest pass...'
                        : 'Join the Mansion',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const Divider(height: 36),

                const Text(
                  '✨ AI Signup Coach',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get a general password tip. Your name, email, '
                      'and password are not included in the tip request.',
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Simulate offline error'),
                  value: _simulateFailure,
                  onChanged: (value) {
                    setState(() => _simulateFailure = value);
                  },
                ),

                ElevatedButton(
                  onPressed: _loadingTip ? null : _getTip,
                  child: Text(
                    _loadingTip
                        ? 'Loading tip...'
                        : 'Get a signup tip',
                  ),
                ),

                if (_loadingTip) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],

                if (_tip != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Signup advice (MOCK):\n$_tip',
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
                  'Demo only: no account is created or stored.',
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/account_service.dart';
import '../widgets/social_auth_buttons.dart';
import '../widgets/banner_ad_placeholder.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Basic Email Validation
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Check for empty fields
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFields), backgroundColor: Colors.red));
      return;
    }

    // 2. Strict UI Validation
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidEmail), backgroundColor: Colors.orange));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordTooShort), backgroundColor: Colors.orange));
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordsDontMatch), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Talk to Firebase
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCred.user != null) {
        await AccountService.saveUserDisplayName(name);
      }
      
      // 4. Success! AuthGate will catch this automatically, but we pop to ensure smooth routing.
      if (mounted) {
        AnalyticsService.logSignUp('email');
        Navigator.pushReplacementNamed(context, '/home');
      }
      
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase errors
      String errorMsg = l10n.signUpFailed;
      if (e.code == 'email-already-in-use') {
        errorMsg = l10n.emailAlreadyRegistered;
      } else if (e.code == 'network-request-failed') {
        errorMsg = l10n.checkInternet;
      } else {
        errorMsg = e.message ?? errorMsg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdPlaceholder(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                context.isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
                height: 56,
              ),
              const SizedBox(height: 16),
              Text(l10n.createAccount, style: const TextStyle(color: AppColors.primaryTeal, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l10n.joinGuidyToday, style: TextStyle(fontSize: 16, color: context.textSecondary)),
              const SizedBox(height: 40),
              
              _buildTextField(l10n.nameLabel, l10n.nameHint, Icons.person_outline, _nameController),
              const SizedBox(height: 20),
              _buildTextField(l10n.emailLabel, l10n.emailHint, Icons.email_outlined, _emailController),
              const SizedBox(height: 20),
              _buildTextField(l10n.passwordLabel, l10n.passwordCreateHint, Icons.lock_outline, _passwordController, isPassword: true),
              const SizedBox(height: 20),
              _buildTextField(l10n.confirmPasswordLabel, l10n.confirmPasswordHint, Icons.lock_outline, _confirmPasswordController, isPassword: true),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(l10n.createAccount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
              const SocialAuthButtons(),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.hasAccountPrompt, style: TextStyle(color: context.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(l10n.signIn, style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: context.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1017), // Rich dark background matching orbital look
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is PasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF00D9A5),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Header
                      Column(
                        children: [
                          // Orbital Brand Emblem Placeholder
                          Container(
                            width: 80.0,
                            height: 80.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF6B4EEF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 20.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.track_changes,
                              color: Colors.white,
                              size: 40.0,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'GoalForge',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 32.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            _isSignUp ? 'Forging path to mastery.' : 'Welcome back, Recruit.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36.0),

                      // Auth Card Form
                      CustomCard(
                        padding: const EdgeInsets.all(24.0),
                        backgroundColor: const Color(0xFF1C1D26), // Flat charcoal color matching mockups
                        border: Border.all(color: const Color(0xFF2C2D35)),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full Name field (Sign Up Mode)
                              if (_isSignUp) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                              ],

                              // Email field
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!AuthValidator.isValidEmail(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16.0),

                              // Password field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.white54,
                                    size: 20.0,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (_isSignUp) {
                                    return AuthValidator.validateSignupPassword(value);
                                  } else {
                                    return AuthValidator.validateLoginPassword(value);
                                  }
                                },
                              ),

                              // Live Password Strength Checklist (Sign Up Mode)
                              if (_isSignUp)
                                ListenableBuilder(
                                  listenable: _passwordController,
                                  builder: (context, _) {
                                    return _buildPasswordStrengthChecklist(_passwordController.text);
                                  },
                                ),

                              // Forgot Password Link (Sign In Mode)
                              if (!_isSignUp) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _showForgotPasswordDialog(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24.0),

                              // Submit Button
                              ElevatedButton(
                                onPressed: isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                  elevation: 0.0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20.0,
                                        width: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? 'Create Account' : 'Sign In',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Toggle Auth Mode Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp ? 'Already a Recruit?' : 'New here?',
                            style: const TextStyle(color: Colors.white54, fontSize: 14.0),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isSignUp ? 'Sign In' : 'Create Account',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      // Or Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // Google Sign-In Button
                      OutlinedButton(
                        onPressed: isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2C2D35)),
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          backgroundColor: const Color(0xFF1C1D26),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.g_mobiledata, color: Colors.white, size: 24.0),
                            SizedBox(width: 12.0),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14.0),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20.0),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF13141C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF2C2D35), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordStrengthChecklist(String password) {
    final result = AuthValidator.validatePassword(password);

    Widget item(String label, bool isMet) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          children: [
            Icon(
              isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isMet ? const Color(0xFF00D9A5) : Colors.white30,
              size: 14.0,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isMet ? Colors.white : Colors.white38,
                  fontSize: 12.0,
                  fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2C2D35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),
          item('At least 8 characters long', result.hasMinLength),
          item('At least 1 uppercase letter (A-Z)', result.hasUppercase),
          item('At least 1 lowercase letter (a-z)', result.hasLowercase),
          item('At least 1 number (0-9)', result.hasDigit),
          item('At least 1 special character (!@#\$%^&*)', result.hasSpecialChar),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController(
      text: AuthValidator.normalizeEmail(_emailController.text),
    );
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1D26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: Color(0xFF2C2D35)),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your account email. We will send a link to reset your password.',
                style: TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
              const SizedBox(height: 16.0),
              Form(
                key: dialogFormKey,
                child: TextFormField(
                  controller: resetEmailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 14.0),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white30, size: 20.0),
                    filled: true,
                    fillColor: const Color(0xFF13141C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFF2C2D35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!AuthValidator.isValidEmail(val)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
              ),
              onPressed: () {
                if (dialogFormKey.currentState?.validate() ?? false) {
                  final email = AuthValidator.normalizeEmail(resetEmailController.text);
                  context.read<AuthBloc>().add(PasswordResetRequested(email));
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final bloc = context.read<AuthBloc>();
      final normalizedEmail = AuthValidator.normalizeEmail(_emailController.text);
      if (_isSignUp) {
        bloc.add(SignUpRequested(
          normalizedEmail,
          _passwordController.text,
          _nameController.text.trim(),
        ));
      } else {
        bloc.add(SignInRequested(
          normalizedEmail,
          _passwordController.text,
        ));
      }
    }
  }

  void _signInWithGoogle() {
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

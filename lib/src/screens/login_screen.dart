import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/src/base/base_page.dart';
import 'package:sample/src/blocs/login_bloc.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/util/app_enums.dart';
import 'package:sample/src/util/app_sizes.dart';
import 'package:sample/src/util/input_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController userIdTextField = TextEditingController();

  final TextEditingController pwdTextField = TextEditingController();

  final FocusNode _userIdFocusNode = FocusNode();
  final FocusNode _pwdFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userIdpwdValidation(context: context);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userIdFocusNode.dispose();
    _pwdFocusNode.dispose();
    userIdTextField.dispose();
    pwdTextField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: _getBody(context),
      padding: EdgeInsets.zero,
      menuRequired: false,
      appBarType: AppBarType.empty,
      preferredHeight: AppWidgetSizes.dimen_60,
      backgroundDecoration: BoxDecoration(color: Colors.grey[50]),
    );
  }

  _getBody(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),

                    // Logo Section with Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            // Logo with gradient shadow
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667eea).withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                            ),
                            SizedBox(height: 28),

                            // App name with gradient
                            ShaderMask(
                              shaderCallback:
                                  (bounds) => LinearGradient(
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ).createShader(bounds),
                              child: Text(
                                'FuelFlow',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Fuel Management System',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // Login Form Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: child,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome text
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF667eea),
                                          Color(0xFF764ba2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome Back',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        'Sign in to continue',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 32),

                              // Email field
                              _buildTextField(
                                context: context,
                                controller: userIdTextField,
                                focusNode: _userIdFocusNode,
                                icon: Icons.email_outlined,
                                label: 'Email Address',
                                inputFormatters:
                                    InputValidator.userIdValidator(),
                                onChanged: (val) {
                                  _userIdpwdValidation(context: context);
                                },
                              ),
                              SizedBox(height: 20),

                              // Password field
                              _buildTextField(
                                context: context,
                                controller: pwdTextField,
                                focusNode: _pwdFocusNode,
                                icon: Icons.lock_outline_rounded,
                                label: 'Password',
                                isPassword: true,
                                obscureText: _obscureText,
                                inputFormatters:
                                    InputValidator.passwordValidator(),
                                onChanged: (val) {
                                  _userIdpwdValidation(context: context);
                                },
                              ),

                              SizedBox(height: 36),

                              // Login button
                              _loginButtonWidget(context: context),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Footer
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'v1.0.0',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '© 2026 FuelFlow. All rights reserved.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String label,
    bool isPassword = false,
    bool obscureText = false,
    required List<dynamic> inputFormatters,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus ? Color(0xFF667eea) : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow:
            focusNode.hasFocus
                ? [
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ]
                : [],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF667eea).withOpacity(0.1),
                    Color(0xFF764ba2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Color(0xFF667eea), size: 22),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: isPassword ? obscureText : false,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                onChanged: onChanged,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: label,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  counterText: '',
                ),
                maxLength: isPassword ? 15 : null,
              ),
            ),
            if (isPassword)
              IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color:
                      _isLoading ? Colors.grey.shade400 : Colors.grey.shade600,
                  size: 22,
                ),
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
              ),
          ],
        ),
      ),
    );
  }

  _userIdpwdValidation({required BuildContext context}) {
    if (pwdTextField.text.length > 5 && userIdTextField.text.length > 7) {
      context.read<LoginBloc>().add(ButtonEnableEvent(buttonEnabled: true));
    } else {
      context.read<LoginBloc>().add(ButtonEnableEvent(buttonEnabled: false));
    }
  }

  _loginButtonWidget({required BuildContext context}) {
    final authController = context.watch<AuthController>();
    final isButtonEnabled = context.watch<LoginBloc>().state.buttonEnabled;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors:
              _isLoading || !isButtonEnabled
                  ? [Colors.grey.shade300, Colors.grey.shade400]
                  : [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          if (!_isLoading && isButtonEnabled)
            BoxShadow(
              color: Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.transparent,
        ),
        onPressed:
            (_isLoading || !isButtonEnabled)
                ? null
                : () async {
                  setState(() {
                    _isLoading = true;
                  });

                  _userIdFocusNode.unfocus();
                  _pwdFocusNode.unfocus();

                  final email = userIdTextField.text;
                  final password = pwdTextField.text;

                  try {
                    await authController.login(email, password);
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
        child:
            _isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Signing In...',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
      ),
    );
  }
}

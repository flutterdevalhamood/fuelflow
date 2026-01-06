// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sample/src/base/base_page.dart';
// import 'package:sample/src/blocs/login_bloc.dart';
// import 'package:sample/src/providers/login_controller.dart';
// import 'package:sample/src/util/app_enums.dart';
// import 'package:sample/src/util/app_sizes.dart';
// import 'package:sample/src/util/input_validator.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen>
//     with SingleTickerProviderStateMixin {
//   final TextEditingController userIdTextField = TextEditingController(
//     text: "gautam@fuelflow.com",
//   );
//
//   final TextEditingController pwdTextField = TextEditingController(
//     text: "gautam@9999",
//   );
//
//   final FocusNode _userIdFocusNode = FocusNode();
//   final FocusNode _pwdFocusNode = FocusNode();
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _userIdpwdValidation(context: context);
//
//     // Initialize animation controller
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Interval(0.2, 1.0, curve: Curves.easeOut),
//       ),
//     );
//
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BasePage(
//       body: _getBody(context),
//       padding: EdgeInsets.zero,
//       menuRequired: false,
//       appBarType: AppBarType.empty,
//       preferredHeight: AppWidgetSizes.dimen_60,
//       backgroundDecoration: BoxDecoration(
//         color: Theme.of(context).primaryColor,
//       ),
//     );
//   }
//
//   _getBody(BuildContext context) {
//     final authController = context.watch<AuthController>();
//     return BlocBuilder<LoginBloc, LoginState>(
//       builder: (context, state) {
//         return SafeArea(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 // Header section
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.fromLTRB(
//                     AppWidgetSizes.dimen_20,
//                     AppWidgetSizes.dimen_50,
//                     AppWidgetSizes.dimen_20,
//                     AppWidgetSizes.dimen_30,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor,
//                     borderRadius: BorderRadius.only(
//                       bottomLeft: Radius.circular(30),
//                       bottomRight: Radius.circular(30),
//                     ),
//                   ),
//                   child: FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Icon(
//                           Icons.local_gas_station,
//                           size: 56,
//                           color: Colors.white,
//                         ),
//                         SizedBox(height: 20),
//                         Text(
//                           'Welcome Back',
//                           style: Theme.of(
//                             context,
//                           ).textTheme.headlineSmall!.copyWith(
//                             fontWeight: FontWeight.w700,
//                             letterSpacing: 1,
//                             color: Colors.white,
//                           ),
//                         ),
//                         AppWidgetSizes.verticalSpace10,
//                         Text(
//                           'Please login to your account',
//                           style: Theme.of(
//                             context,
//                           ).textTheme.titleSmall!.copyWith(
//                             fontWeight: FontWeight.w500,
//                             letterSpacing: 0.5,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // Login form
//                 Container(
//                   padding: EdgeInsets.all(AppWidgetSizes.dimen_20),
//                   child: FadeTransition(
//                     opacity: _fadeAnimation,
//                     child: Column(
//                       children: [
//                         SizedBox(height: 30),
//                         _buildTextField(
//                           context: context,
//                           controller: userIdTextField,
//                           focusNode: _userIdFocusNode,
//                           icon: Icons.mail_outline_rounded,
//                           label: 'Username',
//                           inputFormatters: InputValidator.userIdValidator(),
//                           onChanged: (val) {
//                             _userIdpwdValidation(context: context);
//                           },
//                         ),
//                         SizedBox(height: 20),
//                         _buildTextField(
//                           context: context,
//                           controller: pwdTextField,
//                           focusNode: _pwdFocusNode,
//                           icon: Icons.lock_outline_rounded,
//                           label: 'Password',
//                           isPassword: true,
//                           obscureText: state.obsecureEnabled,
//                           inputFormatters: InputValidator.passwordValidator(),
//                           onChanged: (val) {
//                             _userIdpwdValidation(context: context);
//                           },
//                         ),
//                         SizedBox(height: 40),
//                         _loginButtonWidget(context: context),
//                         SizedBox(height: 30),
//                         Text(
//                           'Fuel Flow Management System',
//                           style: TextStyle(
//                             color: Theme.of(
//                               context,
//                             ).primaryColor.withOpacity(0.7),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildTextField({
//     required BuildContext context,
//     required TextEditingController controller,
//     required FocusNode focusNode,
//     required IconData icon,
//     required String label,
//     bool isPassword = false,
//     bool obscureText = false,
//     required List<dynamic> inputFormatters,
//     required Function(String) onChanged,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         child: Row(
//           children: [
//             Container(
//               padding: EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 icon,
//                 color: Theme.of(context).primaryColor,
//                 size: 24,
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: TextField(
//                 controller: controller,
//                 focusNode: focusNode,
//                 obscureText: isPassword ? obscureText : false,
//                 style: TextStyle(fontSize: 16, color: Colors.black87),
//                 onChanged: onChanged,
//                 // inputFormatters: inputFormatters,
//                 decoration: InputDecoration(
//                   border: InputBorder.none,
//                   labelText: label,
//                   labelStyle: TextStyle(fontSize: 15, color: Colors.black54),
//                   counterText: '',
//                 ),
//                 maxLength: isPassword ? 15 : null,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   _userIdpwdValidation({required BuildContext context}) {
//     if (pwdTextField.text.length > 5 && userIdTextField.text.length > 7) {
//       context.read<LoginBloc>().add(ButtonEnableEvent(buttonEnabled: true));
//     } else {
//       context.read<LoginBloc>().add(ButtonEnableEvent(buttonEnabled: false));
//     }
//   }
//
//   _loginButtonWidget({required BuildContext context}) {
//     final authController = context.watch<AuthController>();
//     return Container(
//       width: double.infinity,
//       height: 56,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).primaryColor,
//             Theme.of(context).primaryColor.withBlue(
//               (Theme.of(context).primaryColor.blue + 40).clamp(0, 255),
//             ),
//           ],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Theme.of(context).primaryColor.withOpacity(0.3),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         onPressed: () {
//           final email = userIdTextField.text;
//           final password = pwdTextField.text;
//           authController.login(email, password);
//         },
//         child: Text(
//           'Sign In',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1,
//           ),
//         ),
//       ),
//     );
//   }
// }

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
  final TextEditingController userIdTextField = TextEditingController(
    text: "fareed@fuelflow.com",
  );

  final TextEditingController pwdTextField = TextEditingController(
    text: "123456",
  );

  final FocusNode _userIdFocusNode = FocusNode();
  final FocusNode _pwdFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _userIdpwdValidation(context: context);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  _getBody(BuildContext context) {
    final authController = context.watch<AuthController>();
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header section with gradient background matching dashboard
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    AppWidgetSizes.dimen_20,
                    AppWidgetSizes.dimen_50,
                    AppWidgetSizes.dimen_20,
                    AppWidgetSizes.dimen_30,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.local_gas_station,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Fuel Flow',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Sign in to continue to your dashboard',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),

                // Login form
                Container(
                  padding: EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(height: 30),
                        // Email field
                        _buildTextField(
                          context: context,
                          controller: userIdTextField,
                          focusNode: _userIdFocusNode,
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          inputFormatters: InputValidator.userIdValidator(),
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
                          inputFormatters: InputValidator.passwordValidator(),
                          onChanged: (val) {
                            _userIdpwdValidation(context: context);
                          },
                        ),
                        SizedBox(height: 16),
                        // Forgot password option
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Forgot password functionality
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        // Login button
                        _loginButtonWidget(context: context),
                        SizedBox(height: 30),
                        // Footer text
                        Text(
                          'Fuel Flow Management System',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'v1.0.0',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: isPassword ? obscureText : false,
                style: TextStyle(fontSize: 16, color: Colors.black87),
                onChanged: onChanged,
                // inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: label,
                  labelStyle: TextStyle(fontSize: 15, color: Colors.black54),
                  counterText: '',
                ),
                maxLength: isPassword ? 15 : null,
              ),
            ),
            if (isPassword)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
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
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withBlue(
              (Theme.of(context).primaryColor.blue + 40).clamp(0, 255),
            ),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
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
        ),
        onPressed: () {
          final email = userIdTextField.text;
          final password = pwdTextField.text;
          authController.login(email, password);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}

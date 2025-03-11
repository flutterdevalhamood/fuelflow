import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_images.dart';
import 'package:sample/src/util/build_context.dart';
import 'package:sample/src/widgets/custom_app_bar.dart';

import '../util/input_validator.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  // void sendOTP() {
  //   if (_formKey.currentState!.validate()) {
  //     _formKey.currentState!.save();
  //     ref.read(resetPasswordProvider).sendotp(_emailController.text);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height: MediaQuery.of(context).size.height,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                const Spacer(),

                SvgPicture.asset(AppImages.imageForgotpassword, width: 135),
                SizedBox(height: 53),
                Text(
                  'Forgot password',
                  textAlign: TextAlign.center,
                  style: textStyle.headlineSmall!.copyWith(
                    color: Appcolors.darktext,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Provide your Email Id to\nreset the password',
                  textAlign: TextAlign.center,
                  style: textStyle.titleSmall!.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Appcolors.text.withOpacity(0.80),
                  ),
                ),
                SizedBox(height: 55),
                CustomTextfield(
                  controller: _emailController,
                  labelText: 'Email',
                  autoFocus: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: MultiValidator([
                    InputValidator.requiredValidator(),
                    InputValidator.emailValidator,
                  ]),
                ),
                //SizedBox(height: context.responsive(193.0)),
                const Spacer(),

                Consumer(
                  builder: (_, ref, __) {
                    // final data = ref.watch(resetPasswordProvider);
                    return CustomButton.primary(
                      height: context.responsive(44),
                      text: 'Send OTP',
                      // isLoading: SendStatus.loading == data.status,
                      onTap: () {},
                      // sendOTP,
                      //() => Navigator.pushNamed(context, AppRoutes.otp),
                      color: Appcolors.primary,
                      fontColor: Appcolors.white,
                      borderRadius: 6,
                    );
                  },
                ),
                // const Spacer(),
                // const Spacer(),
                const Spacer(),
                // sendotpProviderListener(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // sendotpProviderListener() {
  //   ref.listen<ResetPasswordProvider>(resetPasswordProvider, (previous, next) {
  //     if (next.status == SendStatus.success) {
  //       Navigator.pushNamed(context, AppRoutes.otp);
  //     }
  //     if (next.status == SendStatus.failed) {
  //       customSnackBar(
  //         context,
  //         message: next.message,
  //         type: SnackBarType.error,
  //       );
  //     }
  //   });
  //   return const SizedBox.shrink();
  // }
}

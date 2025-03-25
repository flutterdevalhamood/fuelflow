import 'package:flutter/material.dart';
import 'package:sample/src/theme/light_theme.dart';

abstract class Appcolors {
  static Color bottomSheetBgColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textWhiteColor).getColor(context);
  static Color appBarBgColor(BuildContext context) =>
      ThemedColor(light: LightTheme.lightBlueColor).getColor(context);

  static Color textWhiteColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textWhiteColor).getColor(context);
  static Color textColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textBlackColor).getColor(context);

  static Color textLightGrayColor(BuildContext context) =>
      ThemedColor(light: LightTheme.textLightGrayColor).getColor(context);

  static Color primaryBlue(BuildContext context) =>
      ThemedColor(light: LightTheme.primaryBlueColor).getColor(context);

  static Color secondaryBlue(BuildContext context) =>
      ThemedColor(light: LightTheme.secondaryBlueColor).getColor(context);

  static Color borderColor(BuildContext context) =>
      ThemedColor(light: LightTheme.dividerColor).getColor(context);

  static Color borderLightGreyColor(BuildContext context) =>
      ThemedColor(light: LightTheme.borderLightGreyColor).getColor(context);

  static Color get textDarkBlueColor => const Color(0xFF081B63);

  static Color blackColor = const Color(0xFF212121);

  static Color get btnTextColor => const Color(0xFFFFFFFF);

  static Gradient btnGradient = LinearGradient(
    colors: [LightTheme.primaryBlueColor, LightTheme.secondaryBlueColor],
  );

  static Gradient SignInbtnGradient = LinearGradient(
    colors: [Colors.black45, Colors.black12],
  );

  static Gradient btnDisableGradient = LinearGradient(
    colors: [LightTheme.secondaryBlueColor, LightTheme.secondaryBlueColor],
  );

  static const primary = Color(0xff298BFE);
  static const text = Color(0XFF2F384D);
  static const background = Color(0xFFEEF0F4);
  static const disabled = Color(0xFF7995B7);
  static const unselectedIcon = Color(0xffA0A7BA);
  static const transparent = Colors.transparent;

  static const black2 = Color(0xff2D2D2D);
  static const black3 = Color(0xff404A64);
  static const black4 = Color(0xFF303342);
  static const labelText = Color(0XFF8C8B8F);
  static const underline = Color(0XFFA0A0A0);
  static const underlineTwo = Color(0XFFEAEAEA);
  static const bgGradientOne = Color(0XFF1B001C);
  static const underlinethree = Color(0xff474747);

  static const white = Color(0xffffffff);
  static const black = Colors.black;
  static const blue = Color(0xFF4B8DF9);
  static const blue1 = Color(0xFf3793FF);
  static const blue2 = Color(0xFFE5F7FF);
  static const blue3 = Color(0xFF01589F);
  static const blue4 = Color(0xFF3E9FD7);
  static const blue5 = Color(0xFF0692E3);
  static const blue6 = Color(0xFFE9EFF6);
  static const blue7 = Color(0xFFEEF1FF);
  static const dullYellow = Color(0xFFFFEEB2);
  static const darkBlue = Color(0xFF4B8EF1);
  static const violet0 = Color(0xFf6633FF);
  static const violet1 = Color(0xFFECEAFE);
  static const violet = Color(0xFF8F6ED7);
  static const orange = Color(0xFFFF9900);
  static const orange1 = Color(0xFFFF983A);
  static const orange2 = Color(0xFFFF8E26);
  static const green = Color(0xFF5ACB91);
  static const green2 = Color(0xFF00CC8F);
  static const green3 = Color(0xffC7F2F5);
  static const green4 = Color(0xFF039381);
  static const green5 = Color(0xFF3DD3C1);
  static const green6 = Color(0xFF31B6B5);
  static const green7 = Color(0xFF2BD698);
  static const grey = Color(0xFFB0AFB6);
  static const grey1 = Color(0xFFD5D9E1);
  static const greyTwo = Color(0xFFD9D9D9);
  static const grey3 = Color(0xFF979DAE);
  static const grey4 = Color(0xFFE5E8EE);
  static const grey5 = Color(0xFFD1D6E1);
  static const grey6 = Color(0xFF707789);
  static const grey7 = Color(0xFf808080);
  static const grey8 = Color(0xFFEFF4F9);
  static const grey9 = Color(0xFFCBD2DC);
  static const grey10 = Color(0xFFDBE5EF);
  static const grey11 = Color(0xFFA9A9A9);
  static const grey12 = Color(0xFFDAE0EA);
  static const pink = Color(0xFFFB6FBB);
  static const pink1 = Color(0xFFFF606D);
  static const red = Color(0XFFFF4B4B);
  static const red0 = Colors.red;
  static const red1 = Color(0XFFFF5367);
  static const cyan = Color(0xFF2BC1D6);

  static const darktext = Color(0xFF3A3D4B);
  static const darktext2 = Color(0xff526185);
  static const darktext3 = Color(0xff676767);

  static const drawerDashboard = Color(0xFFFD6E27);
  static const drawerActivities = Color(0XFFFFB43B);
  static const drawerNotifications = Color(0XFFFA2959);
  static const drawerSupport = Color(0XFFFFDAB7);
  static const drawerSettings = Color(0XFF5733FB);
  static const arrowRight = Color(0XFFC8D7E5);
  static const biege = Color(0XFFEFEFEF);

  static const list1 = [green6, violet0, pink1, drawerNotifications];
}

class ThemedColor {
  final Color light;

  const ThemedColor({required this.light});
  Color getColor(BuildContext context) {
    return light;
  }
}

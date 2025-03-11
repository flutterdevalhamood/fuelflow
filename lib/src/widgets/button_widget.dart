import 'package:flutter/material.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/util/app_enums.dart';
import 'package:sample/src/util/app_sizes.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final Function()? onDisablePressed;

  final ElevatedButtonState buttonState;
  final double? height;
  final double? width;
  final double? fontSize;
  final bool? buttonWithIcon;
  final String? buttonIcon;
  final Color? buttonBgColor;
  final Color? buttonTextColor;

  const ButtonWidget({
    Key? key,
    required this.text,
    this.onPressed,
    required this.buttonState,
    this.height = 50,
    this.width,
    this.onDisablePressed,
    this.fontSize = 16,
    this.buttonWithIcon = false,
    this.buttonIcon,
    this.buttonBgColor,
    this.buttonTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (buttonState == ElevatedButtonState.active) {
      return _getActiveButton(context);
    }
    return _getDisableButton(context);
  }

  _getActiveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(
          context: context,
          buttonState: buttonState,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppWidgetSizes.dimen_10),
        ),
        padding: const EdgeInsets.all(0.0),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: Appcolors.btnGradient,
          borderRadius: BorderRadius.all(
            Radius.circular(AppWidgetSizes.dimen_10),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: Appcolors.btnGradient,
            borderRadius: BorderRadius.all(
              Radius.circular(AppWidgetSizes.dimen_10),
            ),
            boxShadow: [
              BoxShadow(
                color: _getBackgroundColor(
                  context: context,
                  buttonState: ElevatedButtonState.active,
                ).withOpacity(0.5),
                spreadRadius: 0,
                blurRadius: AppWidgetSizes.dimen_10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          height: height,
          alignment: Alignment.center,
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              color: Appcolors.btnTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  _getDisableButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(
          context: context,
          buttonState: buttonState,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppWidgetSizes.dimen_10),
        ),
        padding: const EdgeInsets.all(0.0),
      ),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(AppWidgetSizes.dimen_10),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(AppWidgetSizes.dimen_10),
            ),
            boxShadow: [
              BoxShadow(
                color: _getBackgroundColor(
                  context: context,
                  buttonState: buttonState,
                ),
                spreadRadius: 0,
                blurRadius: AppWidgetSizes.dimen_10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          height: height ?? AppWidgetSizes.dimen_56,
          alignment: Alignment.center,
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              color: Appcolors.textWhiteColor(context).withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  _getBackgroundColor({
    required BuildContext context,
    required ElevatedButtonState buttonState,
  }) {
    return (buttonState == ElevatedButtonState.active)
        ? Appcolors.primaryBlue(context)
        : Appcolors.secondaryBlue(context);
  }
}

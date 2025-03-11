import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sample/src/util/build_context.dart';
import 'package:sample/src/util/styles.dart';

import '../util/app_colors.dart';

class CustomButton extends StatefulWidget {
  const CustomButton.primary({
    super.key,
    this.width,
    this.height = 50.0,
    this.hPadding = 0,
    this.vPadding = 0,
    this.color = Appcolors.primary,
    this.fontColor = Appcolors.white,
    required this.text,
    required this.onTap,
    this.showStartUpAnimation,
    this.isLoading = false,
    this.borderRadius = 6,
    this.fontSize = 16,
    this.iconSize = 20,
    this.contentPdding = 10,
    this.leading = '',
    this.trailing = '',
    this.overrideLoadingButtonSize = false,
    this.isDisabled = false,
  }) : isSecondary = false,
       isOutlined = false;

  const CustomButton.secondary({
    super.key,
    this.width,
    this.height,
    this.hPadding = 0,
    this.vPadding = 0,
    this.color = Appcolors.white,
    this.fontColor = Appcolors.primary,
    required this.text,
    required this.onTap,
    this.showStartUpAnimation,
    this.isLoading = false,
    this.fontSize = 20,
    this.iconSize = 24,
    this.borderRadius = 6,
    this.leading = '',
    this.trailing = '',
    this.overrideLoadingButtonSize = false,
    this.isDisabled = false,
  }) : isSecondary = true,
       isOutlined = false,
       contentPdding = 10;

  const CustomButton.outlined({
    super.key,
    this.width,
    this.height,
    this.hPadding = 0,
    this.vPadding = 0,
    this.color = Appcolors.primary,
    required this.text,
    required this.onTap,
    this.showStartUpAnimation,
    this.isLoading = false,
    this.borderRadius = 6,
    this.fontSize = 16,
    this.leading = '',
    this.trailing = '',
    this.overrideLoadingButtonSize = false,
    this.isDisabled = false,
  }) : isSecondary = false,
       isOutlined = true,
       fontColor = Appcolors.primary,
       iconSize = 24,
       contentPdding = 10;

  final double? width;
  final double? height;
  final double vPadding;
  final double hPadding;
  final double borderRadius;
  final bool isSecondary;
  final bool isOutlined;
  final Color? color;
  final String text;
  final VoidCallback? onTap;
  final bool? showStartUpAnimation;
  final bool isLoading;
  final bool overrideLoadingButtonSize;
  final double fontSize;
  final double iconSize;
  final double contentPdding;
  final bool isDisabled;
  final Color fontColor;
  final String leading;
  final String trailing;

  @override
  State<CustomButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late Animation<double> _scale;
  late AnimationController _controller;
  final bool _isIOS = Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    showDefaultAnimation();
  }

  void showDefaultAnimation() {
    if (widget.showStartUpAnimation == true) {
      _scale = Tween<double>(
        begin: 0.5,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward().whenComplete(
        () =>
            _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
      );
    } else {
      _scale = Tween<double>(
        begin: 1.0,
        end: 0.9,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _tapDown(bool autoAnimate) {
    if (autoAnimate) {
      _controller.forward().whenComplete(_tapUp);
    } else {
      _controller.forward();
    }
  }

  void _tapUp() {
    _controller.reverse().whenComplete(() => widget.onTap!());
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;

    return Center(
      child: GestureDetector(
        onTapUp: (_) => _tapDown(false),
        onTapDown: (_) => _tapDown(false),
        onTapCancel: _tapUp,
        onTap: () {
          _tapDown(true);
        },
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: widget.width,
            height:
                widget.isOutlined ? (widget.height ?? 55) : widget.height ?? 55,
            margin: EdgeInsets.symmetric(
              horizontal: context.responsive(widget.hPadding),
              vertical: context.responsive(widget.vPadding),
            ),
            decoration: BoxDecoration(
              color:
                  widget.isDisabled
                      ? Appcolors.disabled
                      : widget.isOutlined
                      ? null
                      : widget.color,
              border:
                  widget.isOutlined
                      ? Border.all(
                        color:
                            widget.isDisabled
                                ? Appcolors.disabled
                                : widget.color ?? Appcolors.primary,
                      )
                      : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            alignment: Alignment.center,
            child:
                widget.isLoading
                    ? Padding(
                      padding: EdgeInsets.all(
                        widget.overrideLoadingButtonSize ? 6 : 10,
                      ),
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child:
                            _isIOS
                                ? CupertinoActivityIndicator(
                                  color:
                                      widget.isOutlined
                                          ? Appcolors.primary
                                          : widget.fontColor,
                                )
                                : CircularProgressIndicator(
                                  color:
                                      widget.isOutlined
                                          ? Appcolors.primary
                                          : widget.fontColor,
                                  strokeWidth: 2,
                                ),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leading.isNotEmpty) ...[
                          SvgPicture.asset(
                            widget.leading,
                            // color: AppColors.white,
                            height: widget.iconSize,
                          ),
                          SizedBox(width: widget.contentPdding),
                        ],
                        Text(
                          widget.text,
                          style:
                              widget.isOutlined
                                  ? widget.isDisabled
                                      ? textStyle.buttonStyle.copyWith(
                                        color: Appcolors.white,
                                        fontSize: widget.fontSize,
                                      )
                                      : textStyle.buttonStyle.copyWith(
                                        color: widget.color,
                                        fontSize: widget.fontSize,
                                      )
                                  : textStyle.buttonStyle.copyWith(
                                    fontSize: widget.fontSize,
                                    color: widget.fontColor,
                                  ),
                        ),
                        if (widget.trailing.isNotEmpty) ...[
                          SvgPicture.asset(
                            widget.trailing,
                            height: widget.iconSize,
                          ),
                          SizedBox(width: widget.contentPdding),
                        ],
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

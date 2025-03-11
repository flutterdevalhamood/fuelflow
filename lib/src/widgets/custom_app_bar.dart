import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/util/app_routes.dart';

import '../util/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.height = 60,
    this.leading,
    this.title,
    this.backgroundColor = Appcolors.background,
    this.actions,
    this.whiteArrow = false,
  });

  final double height;
  final Widget? leading;
  final Widget? title;
  final Color backgroundColor;
  final List<Widget>? actions;
  final bool whiteArrow;

  static final bool _isIOS = Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading:
          leading ??
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Screenroutes.login,
                  (route) => false,
                );
              }
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Icon(
                  _isIOS ? CupertinoIcons.back : Icons.arrow_back,
                  color: whiteArrow ? Appcolors.white : Appcolors.darktext,
                ),
              ),
            ),
          ),
      title: title,
      centerTitle: false,
      actions: actions,
      backgroundColor: backgroundColor,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

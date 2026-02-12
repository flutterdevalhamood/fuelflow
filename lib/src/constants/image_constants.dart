import 'package:flutter/material.dart';

class ImageConstants {
  static const String assetsDir = "lib/src/assets";
  static String background(BuildContext context) =>
      const ThemedImages(light: "$assetsDir/bg_light.png").getImage(context);

  static String sample(BuildContext context) =>
      const ThemedImages(light: "$assetsDir/sample.svg").getImage(context);

  static String heavyvehicle1(BuildContext context) =>
      '$assetsDir/heavyvehicle1.jpg';
  static String heavyvehicle2(BuildContext context) =>
      '$assetsDir/heavyvehicle2.jpg';
  static String heavyvehicle3(BuildContext context) =>
      '$assetsDir/heavyvehicle3.jpg';
  static String heavyvehicle4(BuildContext context) =>
      '$assetsDir/heavyvehicle4.jpg';
  static String heavyvehicle5(BuildContext context) =>
      '$assetsDir/heavyvehicle5.jpg';
  static String heavyvehicle6(BuildContext context) =>
      '$assetsDir/heavyvehicle6.jpg';
}

class ThemedImages {
  final String light;

  const ThemedImages({required this.light});

  String getImage(BuildContext context) {
    return light;
  }
}

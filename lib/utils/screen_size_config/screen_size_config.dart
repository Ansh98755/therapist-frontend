import 'package:flutter/material.dart';

abstract final class SizeConfig {
  const SizeConfig._();

  static late Size screenSize;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textMultiplier;
  static late double imageSizeMultiplier;
  static late double heightMultiplier;

  static void initSizeConfig(BuildContext context, {double designWidth = 360}) {
    final media = MediaQuery.of(context);
    screenWidth = MediaQuery.sizeOf(context).width;
    screenHeight = MediaQuery.sizeOf(context).height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    textMultiplier = blockSizeVertical;
    imageSizeMultiplier = blockSizeHorizontal;
    heightMultiplier = blockSizeVertical;

    // Calculate a scaling factor based on the design width
    final double scalingFactor = screenWidth / designWidth;

    // Update multipliers with scaling factor
    textMultiplier *= scalingFactor;
    imageSizeMultiplier *= scalingFactor;
    heightMultiplier *= scalingFactor;
  }
}

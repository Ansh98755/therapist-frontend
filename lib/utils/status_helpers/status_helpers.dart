import 'package:flutter/material.dart';
import '../color_constants/color_constants.dart';

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'booked':
      return ColorConstants.colorB2E5D1;
    case 'confirmed':
      return ColorConstants.colorEFE5DA;
    case 'pending':
      return ColorConstants.colorFFF8E1;
    case 'cancelled':
      return ColorConstants.redColor;
    case 'completed':
      return ColorConstants.colorEFE5DA;
    default:
      return ColorConstants.grey3;
  }
}

Color getStatusTextColor(String status) {
  switch (status.toLowerCase()) {
    case 'booked':
      return ColorConstants.color2E7D7D;
    case 'confirmed':
      return ColorConstants.primaryBrownColor;
    case 'pending':
      return ColorConstants.colorF7921E;
    case 'cancelled':
      return ColorConstants.whiteColor2;
    case 'completed':
      return ColorConstants.primaryBrownColor;
    default:
      return ColorConstants.color666666;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/color_constants/color_constants.dart';
import '../../utils/screen_size_config/screen_size_config.dart';

class SkeletonCommunityScreen extends StatelessWidget {
  const SkeletonCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.initSizeConfig(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const _SkeletonPost(),
      ),
    );
  }
}

class _SkeletonPost extends StatelessWidget {
  const _SkeletonPost();

  @override
  Widget build(BuildContext context) {
    final shimmerBase = ColorConstants.grey2;
    final shimmerHighlight = ColorConstants.grey3;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Height multiplier based on orientation
    final double vMultiplier = isLandscape ? 1.8 : 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 4.5 * SizeConfig.blockSizeHorizontal,
        vertical: 2.5 * SizeConfig.blockSizeVertical,
      ),
      child: Shimmer.fromColors(
        baseColor: shimmerBase,
        highlightColor: shimmerHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Name + Date
            Row(
              children: [
                Container(
                  width: 12 * SizeConfig.blockSizeHorizontal,
                  height: 12 * SizeConfig.blockSizeHorizontal,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.grey,
                  ),
                ),
                SizedBox(width: 4.5 * SizeConfig.blockSizeHorizontal),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 2.5 * vMultiplier * SizeConfig.blockSizeVertical,
                      width: 30 * SizeConfig.blockSizeHorizontal,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: ColorConstants.grey,
                      ),
                    ),
                    SizedBox(height: 1 * SizeConfig.blockSizeVertical),
                    Container(
                      height: 2.0 * vMultiplier * SizeConfig.blockSizeVertical,
                      width: 15 * SizeConfig.blockSizeHorizontal,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: ColorConstants.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 2 * SizeConfig.blockSizeVertical),

            // Message box
            Container(
              width: double.infinity,
              height: 14 * vMultiplier * SizeConfig.blockSizeVertical,
              margin: EdgeInsets.symmetric(
                vertical: 1.5 * SizeConfig.blockSizeVertical,
              ),
              decoration: BoxDecoration(
                color: ColorConstants.grey,
                borderRadius: BorderRadius.circular(14),
              ),
            ),

            // Like and Comment placeholders
            Row(
              children: [
                Container(
                  width: 18 * SizeConfig.blockSizeHorizontal,
                  height: 3.2 * vMultiplier * SizeConfig.blockSizeVertical,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: ColorConstants.grey,
                  ),
                ),
                SizedBox(width: 4.5 * SizeConfig.blockSizeHorizontal),
                Container(
                  width: 18 * SizeConfig.blockSizeHorizontal,
                  height: 3.2 * vMultiplier * SizeConfig.blockSizeVertical,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: ColorConstants.grey,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.5 * SizeConfig.blockSizeVertical),
          ],
        ),
      ),
    );
  }
}

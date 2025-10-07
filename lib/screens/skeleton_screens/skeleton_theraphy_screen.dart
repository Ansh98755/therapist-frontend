import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/color_constants/color_constants.dart';
import '../../utils/screen_size_config/screen_size_config.dart';

class TherapySkeletonScreen extends StatelessWidget {
  const TherapySkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.initSizeConfig(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor,
        appBar: AppBar(
          backgroundColor: ColorConstants.whiteColor,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: ColorConstants.colorFFB444,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: ColorConstants.whiteColor,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top horizontal shimmer cards
              SizedBox(
                height: isLandscape
                    ? SizeConfig.screenHeight * 0.6
                    : SizeConfig.blockSizeVertical * 26,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: shimmerBox(
                      height: isLandscape
                          ? SizeConfig.screenHeight * 0.2
                          : SizeConfig.blockSizeVertical * 18,
                      width: isLandscape
                          ? SizeConfig.blockSizeHorizontal * 40
                          : SizeConfig.blockSizeHorizontal * 80,
                      radius: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Therapist list
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    therapistCardSkeleton(isLandscape),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget shimmerBox({
    required double height,
    double? width,
    double radius = 8,
  }) {
    return Shimmer.fromColors(
      baseColor: ColorConstants.grey2,
      highlightColor: ColorConstants.grey3,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget shimmerCircle(double size) {
    return shimmerBox(height: size, width: size, radius: size / 2);
  }

  Widget therapistCardSkeleton(bool isLandscape) {
    double buttonHeight = isLandscape ? 36 : 30;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.colorE0E0E0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              shimmerBox(
                height: isLandscape ? 85 : 83,
                width: isLandscape ? 72 : 70,
                radius: 12,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(4, (index) {
                    double width = [80, 140, 100, 120, 100][index].toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: shimmerBox(height: 14, width: width, radius: 4),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: shimmerBox(height: buttonHeight, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: shimmerBox(height: buttonHeight, radius: 20)),
            ],
          ),
        ],
      ),
    );
  }
}

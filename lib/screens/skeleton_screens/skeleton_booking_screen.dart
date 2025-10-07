import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/screen_size_config/screen_size_config.dart';
class BookingSkeleton extends StatelessWidget {
  const BookingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.initSizeConfig(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4 * SizeConfig.blockSizeHorizontal,
              vertical: 2 * SizeConfig.blockSizeVertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBackArrow(),
                SizedBox(height: 2 * SizeConfig.blockSizeVertical),
                Row(
                  children: [
                    _shimmerButtonFlexible(context),
                    _shimmerButtonFlexible(context),
                  ],
                ),
                SizedBox(height: 2 * SizeConfig.blockSizeVertical),
                Row(
                  children: [
                    _shimmerButtonFlexible(context),
                    _shimmerButtonFlexible(context),
                  ],
                ),
                SizedBox(height: 3 * SizeConfig.blockSizeVertical),
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isLandscape = MediaQuery.of(context).orientation ==
                          Orientation.landscape;

                      return _shimmerBox(
                        height: isLandscape
                            ? 68 *
                                SizeConfig
                                    .blockSizeVertical // taller in landscape
                            : 30 * SizeConfig.blockSizeVertical,
                        width: isLandscape
                            ? 70 // narrower in landscape
                            : 100,
                      );
                    },
                  ),
                ),
                SizedBox(height: 3 * SizeConfig.blockSizeVertical),
                Row(
                  children: [
                    _shimmerButtonFlexible(context),
                    _shimmerButtonFlexible(context),
                  ],
                ),
                SizedBox(height: 2 * SizeConfig.blockSizeVertical),
                Row(
                  children: [
                    _shimmerButtonFlexible(context),
                    _shimmerButtonFlexible(context),
                  ],
                ),
                SizedBox(height: 3 * SizeConfig.blockSizeVertical),
                Row(
                  children: [
                    _shimmerButtonFlexible(context),
                    _shimmerButtonFlexible(context),
                  ],
                ),
                SizedBox(height: 3 * SizeConfig.blockSizeVertical),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isLandscape = MediaQuery.of(context).orientation ==
                        Orientation.landscape;

                    return _shimmerBox(
                      height: isLandscape
                          ? 14 *
                              SizeConfig
                                  .blockSizeVertical // taller in landscape
                          : 7 *
                              SizeConfig
                                  .blockSizeVertical, // slightly smaller in portrait
                      width: 100,
                    );
                  },
                ),
                SizedBox(height: 3 * SizeConfig.blockSizeVertical),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBackArrow() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 5 * SizeConfig.blockSizeVertical,
        width: 5 * SizeConfig.blockSizeVertical,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _shimmerButtonFlexible(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    double height = isLandscape
        ? 15 * SizeConfig.blockSizeVertical
        : 7 * SizeConfig.blockSizeVertical;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 1.5 * SizeConfig.blockSizeHorizontal,
        ),
        child: _shimmerBox(
          height: height,
          width: null,
        ), // width null = full available space
      ),
    );
  }

  Widget _shimmerBox({required double height, double? width}) {
    final effectiveWidth = width ?? 40;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: effectiveWidth * SizeConfig.blockSizeHorizontal,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _shimmerTimeSlots() {
    return Wrap(
      spacing: 3 * SizeConfig.blockSizeHorizontal,
      runSpacing: 2 * SizeConfig.blockSizeVertical,
      children: List.generate(6, (index) {
        return _shimmerBox(height: 48, width: 40); // Fixed height
      }),
    );
  }
}

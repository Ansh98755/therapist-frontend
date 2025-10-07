// booking_skeleton_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class MyBookingsSkeletonLoader extends StatelessWidget {
  const MyBookingsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 12, width: 100, color: Colors.white),
                            const SizedBox(height: 6),
                            Container(height: 10, width: 60, color: Colors.white),
                          ],
                        ),
                      ),
                      Container(height: 24, width: 24, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Detail Rows
                  _buildLine(width: 120),
                  const SizedBox(height: 8),
                  _buildLine(width: 100),
                  const SizedBox(height: 8),
                  _buildLine(width: 80),
                  const SizedBox(height: 8),
                  _buildLine(width: 140),
                  const SizedBox(height: 8),
                  _buildLine(width: double.infinity),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    children: [
                      Expanded(child: _buildButton()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildButton()),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLine({required double width}) {
    return Container(
      height: 10,
      width: width,
      color: Colors.white,
    );
  }

  Widget _buildButton() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// lib/shimmer_loading.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        color: Colors.white,
      ),
    );
  }
}

class TaskShimmerLoading extends StatelessWidget {
  const TaskShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(); // You can design this differently
  }
}

class CalendarShimmerLoading extends StatelessWidget {
  const CalendarShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(); // You can design this differently
  }
}

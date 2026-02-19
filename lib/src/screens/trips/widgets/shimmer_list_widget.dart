import 'package:flutter/material.dart';

class ShimmerList extends StatefulWidget {
  const ShimmerList();

  @override
  State<ShimmerList> createState() => ShimmerListState();
}

class ShimmerListState extends State<ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder:
          (_, __) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: 5,
            itemBuilder:
                (_, i) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment(-1 + _shimmer.value * 2, 0),
                      end: Alignment(1 + _shimmer.value * 2, 0),
                      colors: const [
                        Color(0xFFEEF0F7),
                        Color(0xFFF6F7FB),
                        Color(0xFFEEF0F7),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }
}

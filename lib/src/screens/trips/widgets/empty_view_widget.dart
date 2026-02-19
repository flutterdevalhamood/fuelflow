import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 60, color: Color(0xFFD0D5E8)),
          SizedBox(height: 16),
          Text(
            'No trips found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3A3F55),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 13, color: Color(0xFF8F9BB3)),
          ),
        ],
      ),
    );
  }
}

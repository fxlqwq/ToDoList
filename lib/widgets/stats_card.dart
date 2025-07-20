import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8), // 进一步减少内边距
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12), // 减小圆角
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.2), // 减少阴影
            blurRadius: 4, // 减小模糊半径
            offset: const Offset(0, 2), // 减小偏移
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11, // 进一步减小字体
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4), // 进一步减小padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4), // 减小圆角
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 12, // 进一步减小图标
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // 进一步减小间距
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18, // 进一步减小数值字体
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

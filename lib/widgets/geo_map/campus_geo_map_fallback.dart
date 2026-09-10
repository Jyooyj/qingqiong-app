import 'package:flutter/material.dart';

/// Non-blocking status: map overlays and the enclosing task page stay mounted.
class CampusGeoMapFallback extends StatelessWidget {
  const CampusGeoMapFallback({
    super.key,
    required this.onRetry,
    this.onFallback,
    this.message = '地图加载失败或网络不可用，位置与路线图层仍保留。',
  });
  final VoidCallback onRetry;
  final VoidCallback? onFallback;
  final String message;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xfffff1da),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(fontSize: 12)),
          Wrap(
            spacing: 8,
            children: [
              TextButton(onPressed: onRetry, child: const Text('重试底图')),
              if (onFallback != null)
                TextButton(onPressed: onFallback, child: const Text('打开备用地图')),
            ],
          ),
        ],
      ),
    ),
  );
}

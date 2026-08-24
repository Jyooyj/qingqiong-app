import 'package:flutter/material.dart';

class CurrentTaskCard extends StatelessWidget {
  const CurrentTaskCard({
    super.key,
    required this.title,
    required this.area,
    required this.statusText,
    required this.progress,
    required this.eta,
    this.onTap,
  });

  final String title;
  final String area;
  final String statusText;
  final int progress;
  final String eta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '当前任务',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    statusText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text(area),
                  const Spacer(),
                  Text('ETA: $eta'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress / 100, minHeight: 8),
              const SizedBox(height: 6),
              Text('$progress%'),
            ],
          ),
        ),
      ),
    );
  }
}

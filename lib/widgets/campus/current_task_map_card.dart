import 'package:flutter/material.dart';

enum CampusTaskStatus {
  preview,
  pending,
  running,
  paused,
  fault,
  emergency,
  completed,
}

/// Display values only. Percentages use 0..100; null means unavailable.
class CampusTaskViewData {
  const CampusTaskViewData({
    this.targetZoneName,
    this.status = CampusTaskStatus.preview,
    this.progress,
    this.cleanedArea,
    this.elapsed,
    this.battery,
    this.message,
  });
  final String? targetZoneName;
  final CampusTaskStatus status;
  final double? progress;
  final double? cleanedArea;
  final Duration? elapsed;
  final double? battery;
  final String? message;
}

/// The host must supply only callbacks currently permitted by Safety.
/// Null callbacks render disabled controls; no controller is read or mutated.
class CurrentTaskMapCard extends StatelessWidget {
  const CurrentTaskMapCard({
    super.key,
    required this.data,
    this.onPause,
    this.onResume,
    this.onEmergencyStop,
    this.onReset,
  });
  final CampusTaskViewData data;
  final VoidCallback? onPause, onResume, onEmergencyStop, onReset;

  @override
  Widget build(BuildContext context) {
    final status = switch (data.status) {
      CampusTaskStatus.preview => '路线预览',
      CampusTaskStatus.pending => '待执行',
      CampusTaskStatus.running => '清扫中',
      CampusTaskStatus.paused => '已暂停',
      CampusTaskStatus.fault => '故障',
      CampusTaskStatus.emergency => '急停锁定',
      CampusTaskStatus.completed => '已完成',
    };
    final color = switch (data.status) {
      CampusTaskStatus.fault ||
      CampusTaskStatus.emergency => Colors.red.shade800,
      CampusTaskStatus.paused => Colors.orange.shade900,
      _ => const Color(0xff126b61),
    };
    final progress = _percent(data.progress);
    final battery = _percent(data.battery);
    final area = data.cleanedArea;
    final elapsed = data.elapsed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  data.targetZoneName == null
                      ? '尚未选择目标'
                      : '当前目标：${data.targetZoneName}',
                  key: const Key('campus-target'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _metric(
                  '任务进度',
                  progress == null ? '—' : '${progress.round()}%',
                ),
                _metric(
                  '清扫面积',
                  area == null || !area.isFinite || area < 0
                      ? '—'
                      : '${area.toStringAsFixed(1)} m²',
                ),
                _metric(
                  '耗时',
                  elapsed == null || elapsed.isNegative
                      ? '—'
                      : '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                ),
                _metric('电量', battery == null ? '—' : '${battery.round()}%'),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress / 100,
                color: color,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            if (data.message != null) ...[
              const SizedBox(height: 12),
              Text(data.message!),
            ],
            if (data.status != CampusTaskStatus.preview) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('campus-pause'),
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('campus-resume'),
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('继续'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('campus-emergency'),
                    onPressed: onEmergencyStop,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade800,
                    ),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('急停'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('campus-reset'),
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('复位'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  double? _percent(double? value) =>
      value == null || !value.isFinite || value < 0 || value > 100
      ? null
      : value;
  Widget _metric(String name, String value) => SizedBox(
    width: 100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 12, color: Color(0xff526c66)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

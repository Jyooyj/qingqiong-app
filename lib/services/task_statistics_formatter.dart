class TaskStatisticsFormatter {
  const TaskStatisticsFormatter._();

  static String area(double squareMeters) {
    if (!squareMeters.isFinite || squareMeters < 0) return '—';
    if (squareMeters >= 10000) {
      return '${(squareMeters / 10000).toStringAsFixed(2)} 公顷';
    }
    final digits = squareMeters.round().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
    return '$grouped m²';
  }

  static String duration(Duration value) =>
      value.isNegative ? '—' : '${value.inMinutes} 分 ${value.inSeconds % 60} 秒';
}

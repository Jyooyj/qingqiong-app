import 'package:flutter/material.dart';

import '../controllers/robot_controller.dart';
import '../services/voice_control_service.dart';
import '../services/warning_service.dart';
import '../widgets/control_panel.dart';
import '../widgets/demo_fault_panel.dart';
import '../widgets/robot_status_card.dart';
import '../widgets/voice_control_sheet.dart';
import '../widgets/warning_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.controller});

  final RobotController? controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RobotController _controller;
  late final VoiceControlService _voiceService;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? RobotController();
    _voiceService = VoiceControlService(controller: _controller);
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _run(ControlResult Function() operation) {
    final result = operation();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? Colors.green.shade700
              : Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _showVoiceControl() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => VoiceControlSheet(service: _voiceService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final status = _controller.currentStatus;
        final warning = _controller.warningResult;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '清穹无人清扫车',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  avatar: Icon(
                    status.online ? Icons.cloud_done : Icons.cloud_off,
                    size: 18,
                    color: status.online
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  label: Text(status.online ? '在线' : '离线'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;
              final padding = desktop ? 20.0 : 12.0;
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _OverviewColumn(
                                  controller: _controller,
                                  warning: warning,
                                  onAreaSelected: (area) =>
                                      _run(() => _controller.selectArea(area)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 410,
                                child: Column(
                                  children: [
                                    _buildControlPanel(),
                                    const SizedBox(height: 12),
                                    DemoFaultPanel(controller: _controller),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              RobotStatusCard(status: status),
                              if (warning.hasWarning) ...[
                                const SizedBox(height: 10),
                                WarningCard(warning: warning),
                              ],
                              const SizedBox(height: 10),
                              _AreaSelector(
                                selectedArea: status.area,
                                enabled: _controller.canSelectArea,
                                onSelected: (area) =>
                                    _run(() => _controller.selectArea(area)),
                              ),
                              const SizedBox(height: 10),
                              _buildControlPanel(),
                              const SizedBox(height: 10),
                              DemoFaultPanel(controller: _controller),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  ControlPanel _buildControlPanel() {
    return ControlPanel(
      onStart: _controller.canStart ? () => _run(_controller.start) : null,
      onPause: _controller.canPause ? () => _run(_controller.pause) : null,
      onResume: _controller.canResume ? () => _run(_controller.resume) : null,
      onStop: _controller.canStop ? () => _run(_controller.stop) : null,
      onCharge: _controller.canCharge ? () => _run(_controller.charge) : null,
      onEmergency: _controller.canEmergencyStop
          ? () => _run(_controller.emergencyStop)
          : null,
      onReset: _controller.canReset ? () => _run(_controller.reset) : null,
      onVoice: _showVoiceControl,
    );
  }
}

class _OverviewColumn extends StatelessWidget {
  const _OverviewColumn({
    required this.controller,
    required this.warning,
    required this.onAreaSelected,
  });

  final RobotController controller;
  final WarningResult warning;
  final ValueChanged<String> onAreaSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RobotStatusCard(status: controller.currentStatus),
        if (warning.hasWarning) ...[
          const SizedBox(height: 12),
          WarningCard(warning: warning),
        ],
        const SizedBox(height: 12),
        _AreaSelector(
          selectedArea: controller.currentStatus.area,
          enabled: controller.canSelectArea,
          onSelected: onAreaSelected,
        ),
      ],
    );
  }
}

class _AreaSelector extends StatelessWidget {
  const _AreaSelector({
    required this.selectedArea,
    required this.enabled,
    required this.onSelected,
  });

  final String selectedArea;
  final bool enabled;
  final ValueChanged<String> onSelected;

  static const List<String> _areas = <String>['A区', 'B区', 'C区'];

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('area-selector'),
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '清扫区域',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(enabled ? '待机时可选' : '任务中已锁定'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var index = 0; index < _areas.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _AreaButton(
                      area: _areas[index],
                      selected: selectedArea == _areas[index],
                      enabled: enabled,
                      onPressed: () => onSelected(_areas[index]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaButton extends StatelessWidget {
  const _AreaButton({
    required this.area,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String area;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: selected
          ? FilledButton(
              key: Key('area-$area'),
              onPressed: enabled ? onPressed : null,
              child: Text(area, maxLines: 1),
            )
          : OutlinedButton(
              key: Key('area-$area'),
              onPressed: enabled ? onPressed : null,
              child: Text(area, maxLines: 1),
            ),
    );
  }
}

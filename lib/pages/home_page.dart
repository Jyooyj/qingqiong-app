import 'package:flutter/material.dart';

import '../widgets/control_panel.dart';
import '../widgets/robot_status_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedArea = "A区";

  bool online = true;

  int battery = 82;

  int progress = 0;

  String status = "待机";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("清穹无人清扫车"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RobotStatusCard(
              robotName: "清穹01",
              online: online,
              battery: battery,
              area: selectedArea,
              status: status,
              progress: progress,
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text("A区"),
                  selected: selectedArea == "A区",
                  onSelected: (_) {
                    setState(() {
                      selectedArea = "A区";
                    });
                  },
                ),

                ChoiceChip(
                  label: const Text("B区"),
                  selected: selectedArea == "B区",
                  onSelected: (_) {
                    setState(() {
                      selectedArea = "B区";
                    });
                  },
                ),

                ChoiceChip(
                  label: const Text("C区"),
                  selected: selectedArea == "C区",
                  onSelected: (_) {
                    setState(() {
                      selectedArea = "C区";
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            ControlPanel(
              onStart: () {
                debugPrint("开始清扫");

                setState(() {
                  status = "清扫中";
                });
              },

              onPause: () {
                debugPrint("暂停");

                setState(() {
                  status = "已暂停";
                });
              },

              onResume: () {
                debugPrint("继续");

                setState(() {
                  status = "清扫中";
                });
              },

              onStop: () {
                debugPrint("停止");

                setState(() {
                  status = "待机";
                  progress = 0;
                });
              },

              onCharge: () {
                debugPrint("返回充电");

                setState(() {
                  status = "充电中";
                });
              },

              onEmergency: () {
                debugPrint("紧急停止");

                setState(() {
                  status = "紧急停止";
                });
              },

              onVoice: () {
                debugPrint("语音按钮点击");
              },
            ),
          ],
        ),
      ),
    );
  }
}

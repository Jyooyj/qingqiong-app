import '../../controllers/robot_controller.dart';
import 'robot_device_adapter.dart';

class DemoRobotAdapter implements RobotDeviceAdapter {
  DemoRobotAdapter({required this.robotController});

  final RobotController robotController;

  @override
  Future<void> start() async {
    robotController.startCleaning();
  }

  @override
  Future<void> pause() async {
    robotController.pauseCleaning();
  }

  @override
  Future<void> resume() async {
    robotController.resumeCleaning();
  }

  @override
  Future<void> stop() async {
    robotController.stopCleaning();
  }

  @override
  Future<void> charge() async {
    robotController.returnToCharge();
  }

  @override
  Future<void> emergencyStop() async {
    robotController.emergencyStop();
  }

  @override
  Future<void> reset() async {
    robotController.resetEmergency();
  }
}

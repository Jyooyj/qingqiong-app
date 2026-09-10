abstract class RobotDeviceAdapter {
  Future<void> start();

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> charge();

  Future<void> emergencyStop();

  Future<void> reset();
}
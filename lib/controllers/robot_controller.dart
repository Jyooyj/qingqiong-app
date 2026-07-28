import 'dart:async';

import '../data/mock_robot_data.dart';
import '../models/robot_status.dart';


class RobotController {

  RobotStatus _robotStatus = mockRobotStatus;


  Timer? _progressTimer;


  // 给页面监听状态变化使用
  final StreamController<RobotStatus> _statusController =
      StreamController<RobotStatus>.broadcast();


  Stream<RobotStatus> get statusStream =>
      _statusController.stream;


  RobotStatus get currentStatus =>
      _robotStatus;



  // 更新状态，并通知监听者
  void _updateStatus(RobotStatus newStatus) {

    _robotStatus = newStatus;

    _statusController.add(_robotStatus);
  }



  // 开始清扫
  void startCleaning() {

    // 离线不能控制
    if (!_robotStatus.online) {
      return;
    }


    // 电量低于10禁止开始
    if (_robotStatus.battery < 10) {

      _updateStatus(
        _robotStatus.copyWith(
          warning: "电量过低，禁止开始清扫",
        ),
      );

      return;
    }



    // 只有idle可以开始
    if (_robotStatus.state != RobotState.idle) {
      return;
    }



    _updateStatus(
      _robotStatus.copyWith(
        state: RobotState.cleaning,
        warning: null,
      ),
    );


    _startProgress();
  }




  // 暂停清扫
  void pauseCleaning() {


    if (!_robotStatus.online) {
      return;
    }


    if (_robotStatus.state != RobotState.cleaning) {
      return;
    }


    _stopProgress();


    _updateStatus(
      _robotStatus.copyWith(
        state: RobotState.paused,
      ),
    );

  }




  // 继续清扫
  void resumeCleaning() {


    if (!_robotStatus.online) {
      return;
    }


    if (_robotStatus.state != RobotState.paused) {
      return;
    }


    _updateStatus(
      _robotStatus.copyWith(
        state: RobotState.cleaning,
      ),
    );


    _startProgress();

  }




  // 停止清扫
  void stopCleaning() {


    if (!_robotStatus.online) {
      return;
    }


    if (
      _robotStatus.state != RobotState.cleaning &&
      _robotStatus.state != RobotState.paused
    ) {
      return;
    }


    _stopProgress();


    _updateStatus(
      _robotStatus.copyWith(
        state: RobotState.idle,
        progress: 0,
      ),
    );

  }




  // 返回充电
  void returnToCharge() {


    if (!_robotStatus.online) {
      return;
    }


    if (
      _robotStatus.state != RobotState.idle &&
      _robotStatus.state != RobotState.paused
    ) {
      return;
    }


    _stopProgress();


    _updateStatus(
      _robotStatus.copyWith(
        state: RobotState.charging,
      ),
    );

  }





  // 紧急停止
  void emergencyStop() {


    _stopProgress();


    _updateStatus(
      _robotStatus.copyWith(
        state: RobotState.emergency,
        warning: "紧急停止已触发",
      ),
    );

  }





  // 急停复位
  void resetEmergency() {


    if (_robotStatus.state != RobotState.emergency) {
      return;
    }


    _updateStatus(
      _robotStatus.copyWith(
        state: RobotState.idle,
        warning: null,
      ),
    );

  }





  // 选择区域
  void selectArea(String area) {


    if (!_robotStatus.online) {
      return;
    }


    _updateStatus(
      _robotStatus.copyWith(
        area: area,
      ),
    );

  }





  // 设置在线状态
  void setOnline(bool online) {


    if (!online) {

      _stopProgress();


      _updateStatus(
        _robotStatus.copyWith(
          online: false,
          state: RobotState.offline,
          warning: "机器人离线",
        ),
      );

      return;
    }



    _updateStatus(
      _robotStatus.copyWith(
        online: true,
        state: RobotState.idle,
        warning: null,
      ),
    );

  }





  // 设置电量
  void setBattery(int battery) {


    int newBattery = battery;


    if (newBattery < 0) {
      newBattery = 0;
    }


    if (newBattery > 100) {
      newBattery = 100;
    }



    String? warning;


    if (newBattery < 20) {
      warning = "电量不足，建议返回充电";
    }


    if (newBattery < 10) {
      warning = "电量过低，禁止开始任务";
    }



    _updateStatus(
      _robotStatus.copyWith(
        battery: newBattery,
        warning: warning,
      ),
    );

  }





  // 模拟清扫进度
  void _startProgress() {


    _progressTimer?.cancel();



    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {


        if (_robotStatus.state != RobotState.cleaning) {

          timer.cancel();

          return;
        }



        int progress =
            _robotStatus.progress + 5;



        if (progress >= 100) {

          progress = 100;


          timer.cancel();


          _updateStatus(
            _robotStatus.copyWith(
              state: RobotState.idle,
              progress: progress,
            ),
          );


          return;
        }



        _updateStatus(
          _robotStatus.copyWith(
            progress: progress,
          ),
        );

      },
    );

  }





  // 停止进度计时
  void _stopProgress() {

    _progressTimer?.cancel();

    _progressTimer = null;

  }




  // 释放资源
  void dispose() {

    _stopProgress();

    _statusController.close();

  }

}
import 'package:flutter_test/flutter_test.dart';

import 'package:qingqiong_state/controllers/robot_controller.dart';
import 'package:qingqiong_state/models/robot_status.dart';


void main() {


  group('RobotController 状态测试', () {


    late RobotController controller;


    setUp(() {

      controller = RobotController();

    });



    tearDown(() {

      controller.dispose();

    });




    test('idle开始后变cleaning', () {


      controller.startCleaning();


      expect(
        controller.currentStatus.state,
        RobotState.cleaning,
      );


    });





    test('cleaning暂停后变paused', () {


      controller.startCleaning();


      controller.pauseCleaning();



      expect(
        controller.currentStatus.state,
        RobotState.paused,
      );


    });






    test('paused继续后变cleaning', () {


      controller.startCleaning();


      controller.pauseCleaning();


      controller.resumeCleaning();



      expect(
        controller.currentStatus.state,
        RobotState.cleaning,
      );


    });







    test('停止后回idle', () {


      controller.startCleaning();


      controller.stopCleaning();



      expect(
        controller.currentStatus.state,
        RobotState.idle,
      );


    });








    test('急停后不能继续', () {


      controller.startCleaning();


      controller.emergencyStop();



      expect(
        controller.currentStatus.state,
        RobotState.emergency,
      );



      controller.resumeCleaning();



      expect(
        controller.currentStatus.state,
        RobotState.emergency,
      );


    });









    test('reset后恢复idle', () {


      controller.emergencyStop();


      controller.resetEmergency();



      expect(
        controller.currentStatus.state,
        RobotState.idle,
      );


    });









    test('offline不能控制', () {


      controller.setOnline(false);



      controller.startCleaning();



      expect(
        controller.currentStatus.state,
        RobotState.offline,
      );


    });









    test('电量低于10不能开始', () {


      controller.setBattery(5);



      controller.startCleaning();



      expect(
        controller.currentStatus.state,
        RobotState.idle,
      );



      expect(
        controller.currentStatus.warning,
        '电量过低，禁止开始清扫',
      );


    });



  });

}
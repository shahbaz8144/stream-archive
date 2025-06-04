import 'package:get/instance_manager.dart';


import 'network_service.dart';

class DependencyInjection {
  static void init(){
    Get.put<NetworkController>(NetworkController(),permanent: true);
  }

}

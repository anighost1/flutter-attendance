import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  static Future<bool> isConnectedToOfficeWifi() async {
    final info = NetworkInfo();
    String? wifiName = await info.getWifiName();

    if (wifiName == '"Office_Wifi"') {
      return true;
    }

    return false;
  }
}

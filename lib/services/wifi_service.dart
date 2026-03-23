import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  static const String officeBSSID = "82:97:41:da:12:dc";

  static Future<bool> isConnectedToOffice() async {
    final info = NetworkInfo();
    // print("SSID: ${await info.getWifiName()}");
    // print("BSSID: ${await info.getWifiBSSID()}");

    try {
      String? bssid = await info.getWifiBSSID();

      if (bssid == null) return false;

      return bssid.toLowerCase() == officeBSSID.toLowerCase();
    } catch (e) {
      return false;
    }
  }
}

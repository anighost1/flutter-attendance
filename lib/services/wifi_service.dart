import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  static const String officeBSSID = "70:97:41:da:12:d4";

  static Future<bool> isConnectedToOffice() async {
    final info = NetworkInfo();

    try {
      String? bssid = await info.getWifiBSSID();

      if (bssid == null) return false;

    print('Attendance MArked');
      return bssid.toLowerCase() == officeBSSID.toLowerCase();
    } catch (e) {
      return false;
    }
  }
}

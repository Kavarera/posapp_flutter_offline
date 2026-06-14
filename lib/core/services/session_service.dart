import 'package:get/get.dart';

class SessionService extends GetxService {
  String? role;
  String? userId;

  void setSession(String uId, String userRole) {
    userId = uId;
    role = userRole;
  }

  void clearSession() {
    userId = null;
    role = null;
  }
}

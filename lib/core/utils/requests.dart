import 'package:flutter_contacts/flutter_contacts.dart';

class Requests {
  static Future<PermissionStatus> requestContactsPermission() async {
    final status = await FlutterContacts.permissions.request(PermissionType.readWrite); 
    return status;
  }
}

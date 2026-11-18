import 'dart:developer';
import 'package:chattin/core/utils/requests.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class Contacts {
  static Future<List<String>> getContacts({required String? selfNumber}) async {
    List<String> phoneNumbers = [];
    try {
      final status = await Requests.requestContactsPermission();
      if (status == PermissionStatus.granted) {
        List<Contact> contacts = await FlutterContacts.getAll(
          properties: ContactProperties.allProperties,
        );
        for (final contact in contacts) {
          String number = contact.phones.first.number;
          if (number.length > 10) {
            number = number.substring(number.length - 10);
          }
          if (number == selfNumber || number == "") {
            continue;
          } else {
            phoneNumbers.add(number);
          }
        }
      }
      return phoneNumbers;
    } catch (e) {
      log(e.toString());
      return [];
    }
  }
}

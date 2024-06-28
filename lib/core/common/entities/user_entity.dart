// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:chattin/core/enum/enums.dart';

class UserEntity {
  final String displayName;
  final String photoUrl;
  final String email;
  final String phoneNumber;
  final String phoneCode;
  final Status status;
  UserEntity({
    required this.displayName,
    required this.photoUrl,
    required this.email,
    required this.phoneNumber,
    required this.phoneCode,
    required this.status,
  });
}
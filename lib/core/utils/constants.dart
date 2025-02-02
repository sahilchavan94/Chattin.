import 'package:flutter/material.dart';

class Constants {
  //navigator key
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  //collection names
  static const String userCollection = "users";
  static const String storyCollection = "stories";
  static const String chatsSubCollection = "chats";
  static const String messagesSubCollection = "messages";
}

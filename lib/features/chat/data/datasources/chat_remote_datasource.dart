import 'package:chattin/core/common/models/user_model.dart';
import 'package:chattin/core/enum/enums.dart';
import 'package:chattin/core/errors/exceptions.dart';
import 'package:chattin/core/utils/constants.dart';
import 'package:chattin/core/utils/firebase_format.dart';
import 'package:chattin/core/utils/toast_messages.dart';
import 'package:chattin/features/chat/data/models/contact_model.dart';
import 'package:chattin/features/chat/data/models/message_model.dart';
import 'package:chattin/features/chat/domain/entities/contact_entity.dart';
import 'package:chattin/features/chat/domain/entities/message_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:uuid/uuid.dart';

abstract interface class ChatRemoteDataSource {
  Future<List<ContactEntity>> getAppContacts(
    List<String> phoneNumbers,
  );

  Future<String> addNewContacts({
    required String displayName,
    required String phoneCode,
    required String phoneNumber,
  });

  Future<String> sendTextMessage({
    required String text,
    required String recieverId,
    required UserModel sender,
  });

  Future<String> sendFileMessage({
    required String downloadedUrl,
    required String recieverId,
    required String messageId,
    required UserModel sender,
    required MessageType messageType,
  });

  Future<String> sendReplyMessage({
    required String text,
    required String repliedTo,
    required MessageType repliedToType,
    required String recieverId,
    required String senderId,
  });

  Future<String> deleteMessageForSender({
    required String messageId,
    required String senderId,
    required String receiverId,
  });

  Future<String> deleteMessageForEveryone({
    required String messageId,
    required String senderId,
    required String receiverId,
  });

  Future<String> forwardMessage({
    required String text,
    required List<String> receiverIdList,
    required UserModel sender,
    required MessageType messageType,
  });

  Stream<List<MessageEntity>> getChatStream({
    required String recieverId,
    required String senderId,
  });

  Stream<List<ContactEntity>> getChatContacts(
    String uid,
  );

  Stream<Status> getChatStatus(
    String uid,
  );

  Future<void> setChatStatus({
    required Status status,
    required String uid,
  });

  Future<void> setMessageStatus({
    required String receiverUserId,
    required String messageId,
    required String senderId,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firebaseFirestore;

  ChatRemoteDataSourceImpl({
    required this.firebaseFirestore,
  });

  //private methods//

  //saving the recent chat data in the chats sub collections
  _saveDataToContactsSubcollection({
    required UserModel sender,
    required UserModel? receiver,
    required String text,
    required DateTime timeSent,
  }) async {
    //create a chat contact for the receiver
    final receiverChatContact = ContactModel(
      uid: sender.uid,
      displayName: sender.displayName,
      imageUrl: sender.imageUrl,
      timeSent: timeSent,
      lastMessage: text,
    );

    //create a chat contact for the sender
    final senderChatContact = ContactModel(
      uid: receiver!.uid,
      displayName: receiver.displayName,
      imageUrl: receiver.imageUrl,
      timeSent: timeSent,
      lastMessage: text,
    );

    //add the reciver's doc inside the chat sub collection of sender
    await firebaseFirestore
        .collection(Constants.userCollection)
        .doc(receiver.uid)
        .collection(Constants.chatsSubCollection)
        .doc(sender.uid)
        .set(
          receiverChatContact.toMap(),
        );

    //add  the sender's doc inside the chat sub collection of receiver
    await firebaseFirestore
        .collection(Constants.userCollection)
        .doc(sender.uid)
        .collection(Constants.chatsSubCollection)
        .doc(receiver.uid)
        .set(
          senderChatContact.toMap(),
        );
  }

  //saving the sent message in the appropriate collections
  _saveMessageToMessageSubcollection({
    required UserModel sender,
    required UserModel? receiver,
    required String text,
    required String messageId,
    required DateTime timeSent,
    required MessageType messageType,
    required bool isReply,
    required bool isForwarded,
    String? repliedTo,
    MessageType? repliedToType,
  }) async {
    //create a message model representing a single message entity
    MessageModel message;

    if (isReply) {
      message = MessageModel(
        senderId: sender.uid,
        receiverId: receiver!.uid,
        text: text,
        timeSent: timeSent,
        messageId: messageId,
        status: false,
        messageType: messageType,
        isReply: isReply,
        repliedTo: repliedTo,
        repliedToType: repliedToType,
        isForwarded: isForwarded,
      );
    } else {
      message = MessageModel(
        senderId: sender.uid,
        receiverId: receiver!.uid,
        text: text,
        timeSent: timeSent,
        messageId: messageId,
        status: false,
        messageType: messageType,
        isReply: false,
        isForwarded: isForwarded,
      );
    }

    //save the message inside the messages sub collection of sender
    //user collection -> sender -> chats -> receiver -> messages -> add message
    await firebaseFirestore
        .collection(Constants.userCollection)
        .doc(sender.uid)
        .collection(Constants.chatsSubCollection)
        .doc(receiver.uid)
        .collection(Constants.messagesSubCollection)
        .doc(messageId)
        .set(
          message.toMap(),
        );

    //save the message inside the messages sub collection of receiver
    //user collection -> receiver -> chats -> sender -> messages -> add message
    await firebaseFirestore
        .collection(Constants.userCollection)
        .doc(receiver.uid)
        .collection(Constants.chatsSubCollection)
        .doc(sender.uid)
        .collection(Constants.messagesSubCollection)
        .doc(messageId)
        .set(
          message.toMap(),
        );
  }

  @override
  Future<List<ContactEntity>> getAppContacts(List<String> phoneNumbers) async {
    try {
      final List<ContactEntity> appContacts = [];
      const int chunkSize = 10;

      for (int i = 0; i < phoneNumbers.length; i += chunkSize) {
        //search for 10 contacts at a time, reduces the search time
        final List<String> chunk = phoneNumbers.sublist(
          i,
          i + chunkSize > phoneNumbers.length
              ? phoneNumbers.length
              : i + chunkSize,
        );

        final response = await firebaseFirestore
            .collection(Constants.userCollection)
            .where(
              "phoneNumber",
              whereIn: chunk,
            )
            .get();

        if (response.docs.isNotEmpty) {
          for (final doc in response.docs) {
            appContacts.add(ContactModel.fromMap(doc.data()));
          }
        }
      }
      return appContacts;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }

  @override
  Future<String> sendTextMessage({
    required String text,
    required String recieverId,
    required UserModel sender,
  }) async {
    try {
      final timeSent = DateTime.now();
      final messageId = const Uuid().v1();
      UserModel? receiver;

      //fetching the receiver's data
      final receiverData = await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(recieverId)
          .get();

      receiver = UserModel.fromMap(
        receiverData.data()!,
      );

      //save the data to the chats sub collection
      _saveDataToContactsSubcollection(
        sender: sender,
        receiver: receiver,
        text: text,
        timeSent: timeSent,
      );

      //save the message in sender and the receiver's appropriate sub collections
      _saveMessageToMessageSubcollection(
        sender: sender,
        receiver: receiver,
        text: text,
        messageId: messageId,
        timeSent: timeSent,
        messageType: MessageType.text,
        isReply: false,
        isForwarded: false,
      );
      //change it later
      return ToastMessages.welcomeSignInMessage;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }

  @override
  Future<String> sendFileMessage({
    required String downloadedUrl,
    required String recieverId,
    required String messageId,
    required UserModel sender,
    required MessageType messageType,
  }) async {
    try {
      final timeSent = DateTime.now();

      UserModel? receiver;

      //fetching the receiver's data
      final receiverData = await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(recieverId)
          .get();

      receiver = UserModel.fromMap(
        receiverData.data()!,
      );

      _saveDataToContactsSubcollection(
        sender: sender,
        receiver: receiver,
        text: messageType.convertMessageTypeToString(),
        timeSent: timeSent,
      );

      _saveMessageToMessageSubcollection(
        sender: sender,
        receiver: receiver,
        text: downloadedUrl,
        messageId: messageId,
        timeSent: timeSent,
        messageType: MessageType.image,
        isReply: false,
        isForwarded: false,
      );
      return ToastMessages.welcomeSignInMessage; //change it later
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(
        error: e.toString(),
      );
    }
  }

  @override
  Stream<List<MessageEntity>> getChatStream({
    required String recieverId,
    required String senderId,
  }) {
    try {
      final response = firebaseFirestore
          .collection(Constants.userCollection)
          .doc(senderId)
          .collection(Constants.chatsSubCollection)
          .doc(recieverId)
          .collection(Constants.messagesSubCollection)
          .orderBy('timeSent')
          .snapshots()
          .asyncMap(
        (event) {
          List<MessageModel> messages = [];
          for (final document in event.docs) {
            messages.add(
              MessageModel.fromMap(
                document.data(),
              ),
            );
          }
          return messages;
        },
      );
      return response;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(
        error: e.toString(),
      );
    }
  }

  @override
  Stream<List<ContactEntity>> getChatContacts(String uid) {
    try {
      final response = firebaseFirestore
          .collection(Constants.userCollection)
          .doc(uid)
          .collection(Constants.chatsSubCollection)
          .snapshots()
          .asyncMap((event) {
        List<ContactEntity> contacts = [];
        for (final document in event.docs) {
          contacts.add(
            ContactModel.fromMap(
              document.data(),
            ),
          );
        }
        return contacts;
      });
      return response;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }

  @override
  Stream<Status> getChatStatus(String uid) {
    try {
      final response = firebaseFirestore
          .collection(Constants.userCollection)
          .doc(uid)
          .snapshots()
          .asyncMap(
        (event) {
          final data = event.data();
          if (data == null) {
            return Status.unavailable;
          }
          return (data['status'] as String).convertStringToStatus();
        },
      );

      return response;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    }
  }

  @override
  Future<void> setChatStatus({
    required Status status,
    required String uid,
  }) async {
    try {
      await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(uid)
          .update(
        {
          'status': status.convertStatusToString(),
        },
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> setMessageStatus({
    required String receiverUserId,
    required String messageId,
    required String senderId,
  }) async {
    try {
      await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(senderId)
          .collection(Constants.chatsSubCollection)
          .doc(receiverUserId)
          .collection(Constants.messagesSubCollection)
          .doc(messageId)
          .update(
        {
          'status': true,
        },
      );
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(
        error: e.toString(),
      );
    }
  }

  @override
  Future<String> sendReplyMessage({
    required String text,
    required String repliedTo,
    required MessageType repliedToType,
    required String recieverId,
    required String senderId,
  }) async {
    try {
      final timeSent = DateTime.now();
      final messageId = const Uuid().v1();
      UserModel? sender;
      UserModel? receiver;

      //fetching the sender's data
      final senderData = await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(senderId)
          .get();

      //fetching the receiver's data
      final receiverData = await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(recieverId)
          .get();

      sender = UserModel.fromMap(
        senderData.data()!,
      );

      receiver = UserModel.fromMap(
        receiverData.data()!,
      );

      //save the data to the chats sub collection
      _saveDataToContactsSubcollection(
        sender: sender,
        receiver: receiver,
        text: text,
        timeSent: timeSent,
      );

      //save the message in sender and the receiver's appropriate sub collections
      _saveMessageToMessageSubcollection(
        sender: sender,
        receiver: receiver,
        text: text,
        messageId: messageId,
        timeSent: timeSent,
        messageType: MessageType.text,
        isReply: true,
        repliedTo: repliedTo,
        repliedToType: repliedToType,
        isForwarded: false,
      );
      //change it later
      return ToastMessages.welcomeSignInMessage;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }

  @override
  Future<String> deleteMessageForEveryone({
    required String messageId,
    required String senderId,
    required String receiverId,
  }) async {
    try {
      //update the sender's collection of messages
      //users -> sender -> chats -> receiver -> messageId -> update
      await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(senderId)
          .collection(Constants.chatsSubCollection)
          .doc(receiverId)
          .collection(Constants.messagesSubCollection)
          .doc(messageId)
          .update(
        {
          "text": ToastMessages.deletedMessage,
          "messageType": MessageType.deleted.convertMessageTypeToString(),
        },
      );

      //update the receiver's collection of messages
      //users -> receiver -> chats -> sender -> messageId -> update
      await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(receiverId)
          .collection(Constants.chatsSubCollection)
          .doc(senderId)
          .collection(Constants.messagesSubCollection)
          .doc(messageId)
          .update(
        {
          "text": ToastMessages.deletedMessage,
          "messageType": MessageType.deleted.convertMessageTypeToString(),
        },
      );

      return ToastMessages.messageDeleteEveryoneSuccess;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }

  @override
  Future<String> deleteMessageForSender({
    required String messageId,
    required String senderId,
    required String receiverId,
  }) async {
    //update the sender's collection of messages
    //users -> sender -> chats -> receiver -> messageId -> delete
    try {
      await firebaseFirestore
          .collection(Constants.userCollection)
          .doc(senderId)
          .collection(Constants.chatsSubCollection)
          .doc(receiverId)
          .collection(Constants.messagesSubCollection)
          .doc(messageId)
          .delete();
      return ToastMessages.messageDeleteForMeSuccess;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }

  @override
  Future<String> addNewContacts({
    required String displayName,
    required String phoneCode,
    required String phoneNumber,
  }) async {
    try {
      String phoneNo = "$phoneCode $phoneNumber";
      Contact contact = Contact(
        name: Name(first: displayName),
        phones: <Phone>[Phone(number: phoneNo)],
      );
      await FlutterContacts.create(contact);
      return ToastMessages.newContactAdded;
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }

  @override
  Future<String> forwardMessage({
    required String text,
    required List<String> receiverIdList,
    required UserModel sender,
    required MessageType messageType,
  }) async {
    try {
      final timeSent = DateTime.now();

      for (String receiverId in receiverIdList) {
        //generate the message id for each message
        final messageId = const Uuid().v1();
        UserModel? receiver;

        //fetching the receiver's data
        final receiverData = await firebaseFirestore
            .collection(Constants.userCollection)
            .doc(receiverId)
            .get();

        receiver = UserModel.fromMap(
          receiverData.data()!,
        );

        //save the data to the chats sub collection
        await _saveDataToContactsSubcollection(
          sender: sender,
          receiver: receiver,
          text: messageType == MessageType.text
              ? text
              : messageType.convertMessageTypeToString(),
          timeSent: timeSent,
        );

        //save the message in sender and the receiver's appropriate sub collections
        await _saveMessageToMessageSubcollection(
          sender: sender,
          receiver: receiver,
          text: text,
          messageId: messageId,
          timeSent: timeSent,
          messageType: messageType,
          isReply: false,
          isForwarded: true,
        );
      }
      return ToastMessages.forwardMessageSuccess;
    } on FirebaseException catch (e) {
      throw ServerException(
        error: FirebaseResponseFormat.firebaseFormatError(e.toString()),
      );
    } catch (e) {
      throw ServerException(error: e.toString());
    }
  }
}

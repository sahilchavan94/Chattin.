import 'package:chattin/core/errors/failure.dart';
import 'package:chattin/features/chat/domain/repositories/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteMessageForSenderUseCase {
  final ChatRepository chatRepository;

  DeleteMessageForSenderUseCase({required this.chatRepository});

  Future<Either<Failure, String>> call({
    required String messageId,
    required String senderId,
    required String receiverId,
  }) async {
    return await chatRepository.deleteMessageForSender(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
    );
  }
}

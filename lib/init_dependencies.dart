import 'package:chattin/core/common/features/upload/data/datasource/upload_remote_datasource.dart';
import 'package:chattin/core/common/features/upload/data/repositories/upload_repository_impl.dart';
import 'package:chattin/core/common/features/upload/domain/repositories/upload_repository.dart';
import 'package:chattin/core/common/features/upload/domain/usecases/general_upload.dart';
import 'package:chattin/core/common/providers/reply_message_provider.dart';
import 'package:chattin/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chattin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chattin/features/auth/domain/repositories/auth_repository.dart';
import 'package:chattin/features/auth/domain/usecases/check_account_details.dart';
import 'package:chattin/features/auth/domain/usecases/check_status.dart';
import 'package:chattin/features/auth/domain/usecases/delete_account.dart';
import 'package:chattin/features/auth/domain/usecases/email_auth.dart';
import 'package:chattin/features/auth/domain/usecases/email_verification.dart';
import 'package:chattin/features/auth/domain/usecases/reauthenticate_user.dart';
import 'package:chattin/features/auth/domain/usecases/set_account_details.dart';
import 'package:chattin/features/auth/domain/usecases/sign_in.dart';
import 'package:chattin/features/auth/domain/usecases/sign_out.dart';
import 'package:chattin/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chattin/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:chattin/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chattin/features/chat/domain/repositories/chat_repository.dart';
import 'package:chattin/features/chat/domain/usecases/add_new_contact.dart';
import 'package:chattin/features/chat/domain/usecases/delete_message_for_everyone.dart';
import 'package:chattin/features/chat/domain/usecases/delete_message_for_sender.dart';
import 'package:chattin/features/chat/domain/usecases/forward_message.dart';
import 'package:chattin/features/chat/domain/usecases/get_app_contacts.dart';
import 'package:chattin/features/chat/domain/usecases/get_chat_contacts.dart';
import 'package:chattin/features/chat/domain/usecases/get_chat_status.dart';
import 'package:chattin/features/chat/domain/usecases/get_chat_stream.dart';
import 'package:chattin/features/chat/domain/usecases/send_file_message.dart';
import 'package:chattin/features/chat/domain/usecases/send_message.dart';
import 'package:chattin/features/chat/domain/usecases/send_reply_message.dart';
import 'package:chattin/features/chat/domain/usecases/set_chat_status.dart';
import 'package:chattin/features/chat/domain/usecases/set_message_status.dart';
import 'package:chattin/features/chat/presentation/cubits/chat_cubit/chat_cubit.dart';
import 'package:chattin/features/chat/presentation/cubits/contacts_cubit/contacts_cubit.dart';
import 'package:chattin/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:chattin/features/profile/data/repositories/profile_repositoy_impl.dart';
import 'package:chattin/features/profile/domain/repositories/profile_repository.dart';
import 'package:chattin/features/profile/domain/usecases/get_profile.dart';
import 'package:chattin/features/profile/domain/usecases/set_profile.dart';
import 'package:chattin/features/profile/domain/usecases/set_profile_image.dart';
import 'package:chattin/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:chattin/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:chattin/features/stories/data/repositories/stories_repository_impl.dart';
import 'package:chattin/features/stories/domain/repositories/stories_repository.dart';
import 'package:chattin/features/stories/domain/usecases/get_stories.dart';
import 'package:chattin/features/stories/domain/usecases/upload_story.dart';
import 'package:chattin/features/stories/presentation/cubit/story_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

GetIt serviceLocator = GetIt.instance;

//register feature wise
Future<void> initDependencies() async {
  //register the firebase auth
  final firebaseAuthInstance = FirebaseAuth.instance;
  final firestoreInstance = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;
  serviceLocator.registerLazySingleton(() => firebaseAuthInstance);
  serviceLocator.registerLazySingleton(() => firestoreInstance);
  serviceLocator.registerLazySingleton(() => firebaseStorage);

  //providers
  serviceLocator.registerLazySingleton(
    () => ReplyMessageProvider(),
  );

  //general uploads
  serviceLocator.registerLazySingleton(
    () => UploadRemoteDataSourceImpl(
      firebaseStorage: firebaseStorage,
    ),
  );
  serviceLocator.registerLazySingleton<UploadRepository>(
    () => UploadRepositoryImpl(
      uploadRemoteDataSourceImpl: serviceLocator(),
    ),
  );
  initAuth();
  initProfile();
  initContacts();
  initChat();
  initStories();
}

void initAuth() {
  serviceLocator
    ..registerFactory(
      () => AuthRemoteDataSourceImpl(
        firebaseAuth: serviceLocator(),
        firebaseFirestore: serviceLocator(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        authRemoteDataSourceImpl: serviceLocator(),
      ),
    )
    ..registerLazySingleton<CreateAccountWithEmailAndPasswordUseCase>(
      () => CreateAccountWithEmailAndPasswordUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SendEmailVerificationLinkUseCase>(
      () => SendEmailVerificationLinkUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<CheckVerificationStatusUseCase>(
      () => CheckVerificationStatusUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SetAccountDetailsUseCase>(
      () => SetAccountDetailsUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<CheckTheAccountDetailsIfTheEmailIsVerifiedUseCase>(
      () => CheckTheAccountDetailsIfTheEmailIsVerifiedUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<GeneralUploadUseCase>(
      () => GeneralUploadUseCase(
        uploadRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SignInUseCase>(
      () => SignInUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<ReauthenticateUser>(
      () => ReauthenticateUser(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SignOutUseCase>(
      () => SignOutUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<DeleteAccountUseCase>(
      () => DeleteAccountUseCase(
        authRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<AuthCubit>(
      () => AuthCubit(
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
      ),
    );
}

void initContacts() {
  serviceLocator
    ..registerFactory(
      () => ChatRemoteDataSourceImpl(
        firebaseFirestore: serviceLocator(),
      ),
    )
    ..registerFactory<ChatRepository>(
      () => ChatRepositoryImpl(
        chatRemoteDataSourceImpl: serviceLocator(),
      ),
    )
    ..registerLazySingleton<GetContactsUseCase>(
      () => GetContactsUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<ContactsCubit>(
      () => ContactsCubit(
        serviceLocator(),
      ),
    );
}

void initChat() {
  serviceLocator
    ..registerLazySingleton<SendMessageUseCase>(
      () => SendMessageUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SendFileMessageUseCase>(
      () => SendFileMessageUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<GetChatStreamUseCase>(
      () => GetChatStreamUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<GetChatContactsUseCase>(
      () => GetChatContactsUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<GetChatStatusUseCase>(
      () => GetChatStatusUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SetChatStatusUseCase>(
      () => SetChatStatusUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SetMessageStatusUseCase>(
      () => SetMessageStatusUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SendReplyUseCase>(
      () => SendReplyUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<DeleteMessageForSenderUseCase>(
      () => DeleteMessageForSenderUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<DeleteMessageForEveryoneUseCase>(
      () => DeleteMessageForEveryoneUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<AddNewContactUseCase>(
      () => AddNewContactUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<ForwardMessageUseCase>(
      () => ForwardMessageUseCase(
        chatRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => ChatCubit(
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
      ),
    );
}

void initProfile() {
  serviceLocator
    ..registerFactory(
      () => ProfileRemoteDataSourceImpl(
        firebaseFirestore: serviceLocator(),
      ),
    )
    ..registerFactory<ProfileRepository>(
      () => ProfileRepositoryImpl(
        profileRemoteDataSourceImpl: serviceLocator(),
      ),
    )
    ..registerLazySingleton<GetProfileDataUseCase>(
      () => GetProfileDataUseCase(
        profileRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SetProfileDataUseCase>(
      () => SetProfileDataUseCase(
        profileRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<SetProfileImageUseCase>(
      () => SetProfileImageUseCase(
        profileRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => ProfileCubit(
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
      ),
    );
}

void initStories() {
  serviceLocator
    ..registerFactory(
      () => StoriesRemoteDataSourceImpl(
        firebaseFirestore: serviceLocator(),
      ),
    )
    ..registerFactory<StoriesRepository>(
      () => StoriesRepositoryImpl(
        storiesRemoteDataSourceImpl: serviceLocator(),
      ),
    )
    ..registerLazySingleton<UploadStoryUseCase>(
      () => UploadStoryUseCase(
        storiesRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton<GetStoriesUseCase>(
      () => GetStoriesUseCase(
        storiesRepository: serviceLocator(),
      ),
    )
    ..registerLazySingleton(
      () => StoryCubit(
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
      ),
    );
}

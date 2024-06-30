import 'package:bloc/bloc.dart';
import 'package:chattin/core/common/entities/user_entity.dart';
import 'package:chattin/core/utils/toast_messages.dart';
import 'package:chattin/core/utils/toasts.dart';
import 'package:chattin/features/profile/domain/usecases/get_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toastification/toastification.dart';
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileDataUseCase getProfileDataUseCase;
  final FirebaseAuth firebaseAuth;

  ProfileCubit(
    this.getProfileDataUseCase,
    this.firebaseAuth,
  ) : super(ProfileState.initial()) {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser != null) {
      getProfileData(currentUser.uid);
    }
  }

  //method for getting the profile data
  Future<void> getProfileData(String uid) async {
    emit(state.copyWith(profileStatus: ProfileStatus.loading));
    final response = await getProfileDataUseCase.call(uid);
    response.fold(
      (l) {
        emit(
          state.copyWith(
            profileStatus: ProfileStatus.failure,
          ),
        );
        showToast(
          content: ToastMessages.defaultFailureMessage,
          description: ToastMessages.profileFailure,
          type: ToastificationType.error,
        );
      },
      (r) {
        emit(
          state.copyWith(
            profileStatus: ProfileStatus.success,
            userData: r,
          ),
        );
      },
    );
  }
}
import 'package:chattin/core/common/entities/user_entity.dart';
import 'package:chattin/core/errors/exceptions.dart';
import 'package:chattin/core/errors/failure.dart';
import 'package:chattin/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:chattin/features/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSourceImpl profileRemoteDataSourceImpl;

  const ProfileRepositoryImpl({required this.profileRemoteDataSourceImpl});

  @override
  Future<Either<Failure, UserEntity>> getProfileData(String uid) async {
    try {
      final response = await profileRemoteDataSourceImpl.getProfileData(uid);
      return Right(response);
    } on ServerException catch (e) {
      return Left(
        Failure(e.error),
      );
    }
  }

  @override
  Future<Either<Failure, String>> setProfileData({
    required String uid,
    required String displayName,
    required String phoneNumber,
    required String about,
  }) async {
    try {
      final response = await profileRemoteDataSourceImpl.setProfileData(
        uid: uid,
        about: about,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(
        Failure(e.error),
      );
    }
  }

  @override
  Future<Either<Failure, String>> setProfileImage({
    required String uid,
    required String imageUrl,
  }) async {
    try {
      final response = await profileRemoteDataSourceImpl.setProfileImage(
        uid: uid,
        imageUrl: imageUrl,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(
        Failure(e.error),
      );
    }
  }
}

import 'package:chattin/core/common/entities/user_entity.dart';
import 'package:chattin/core/enum/enums.dart';
import 'package:chattin/core/router/route_path.dart';
import 'package:chattin/core/utils/app_pallete.dart';
import 'package:chattin/core/utils/app_spacing.dart';
import 'package:chattin/core/utils/app_theme.dart';
import 'package:chattin/core/utils/dates.dart';
import 'package:chattin/core/widgets/failure_widget.dart';
import 'package:chattin/core/widgets/image_widget.dart';
import 'package:chattin/core/widgets/user_info.dart';
import 'package:chattin/features/chat/domain/entities/message_entity.dart';
import 'package:chattin/features/chat/presentation/cubits/chat_cubit/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChatContactInformationView extends StatefulWidget {
  final String uid;
  const ChatContactInformationView({
    super.key,
    required this.uid,
  });

  @override
  State<ChatContactInformationView> createState() =>
      _ChatContactInformationViewState();
}

class _ChatContactInformationViewState
    extends State<ChatContactInformationView> {
  @override
  void initState() {
    context.read<ChatCubit>().getChatContactInformation(widget.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state.chatContactInformationStatus ==
            ChatContactInformationStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state.chatContactInformationStatus ==
            ChatContactInformationStatus.failure) {
          return const FailureWidget();
        }
        //get the user info
        final UserEntity userData = state.chatContactInformation!;
        final List<MessageEntity> imageMessages = state.currentChatMessages!
            .where((element) => element.messageType == MessageType.image)
            .toList();
        return SingleChildScrollView(
          physics: const RangeMaintainingScrollPhysics(),
          child: Container(
            color: AppPallete.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.push(
                              RoutePath.imageView.path,
                              extra: {
                                'imageUrl': userData.imageUrl,
                                'displayName': userData.displayName,
                                'isAnImageFromChat': false,
                              },
                            );
                          },
                          child: ImageWidget(
                            imagePath: userData.imageUrl.isEmpty
                                ? 'assets/images/default_profile.png'
                                : userData.imageUrl,
                            width: 100,
                            height: 100,
                            radius: BorderRadius.circular(100),
                            fit: BoxFit.cover,
                            isImageFromChat: true,
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 10,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor:
                                state.currentChatStatus == Status.offline ||
                                        state.currentChatStatus ==
                                            Status.unavailable
                                    ? AppPallete.errorColor
                                    : AppPallete.blueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  verticalSpacing(5),
                  Text(
                    userData.displayName,
                    style:
                        AppTheme.darkThemeData.textTheme.displayLarge!.copyWith(
                      color: AppPallete.blueColor,
                    ),
                  ),
                  Text(
                    userData.about!,
                    style:
                        AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
                      color: AppPallete.whiteColor,
                    ),
                  ),
                  Text(
                    "+${userData.phoneCode ?? ""}${userData.phoneNumber!}",
                    style:
                        AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
                      color: AppPallete.whiteColor,
                    ),
                  ),
                  verticalSpacing(35),
                  _chatContactsProfileDetails(
                    about: userData.about!,
                    email: userData.email!,
                    phoneCode: userData.phoneCode!,
                    displayName: userData.displayName,
                    phoneNumber: userData.phoneNumber!,
                  ),
                  verticalSpacing(35),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          "Media Shared",
                          style: AppTheme.darkThemeData.textTheme.displayLarge!
                              .copyWith(
                            color: AppPallete.whiteColor,
                            fontSize: 16,
                          ),
                        ),
                        horizontalSpacing(5),
                        Text(
                          "( Currently only images can be shared )",
                          style: AppTheme.darkThemeData.textTheme.displaySmall!
                              .copyWith(
                            color: AppPallete.greyColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  verticalSpacing(25),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 80,
                      child: imageMessages.isEmpty
                          ? Text(
                              "No media shared",
                              style: AppTheme
                                  .darkThemeData.textTheme.displaySmall!
                                  .copyWith(
                                color: AppPallete.errorColor,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: imageMessages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: GestureDetector(
                                    onTap: () {
                                      context.push(
                                        RoutePath.imageView.path,
                                        extra: {
                                          'displayName': 'Photo',
                                          'imageUrl': imageMessages[index].text,
                                          'isAnImageFromChat': true,
                                        },
                                      );
                                    },
                                    child: ImageWidget(
                                      height: 70,
                                      width: 80,
                                      imagePath: imageMessages[index].text,
                                      fit: BoxFit.cover,
                                      radius: BorderRadius.circular(2),
                                      isImageFromChat: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  verticalSpacing(40),
                  Text(
                    'Joined Chattin on ${DateFormatters.formatDateWithDate(userData.joinedOn!)}',
                    style:
                        AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
                      color: AppPallete.greyColor,
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _chatContactsProfileDetails({
  required String displayName,
  required String email,
  required String about,
  required String phoneCode,
  required String phoneNumber,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Profile Information",
        style: AppTheme.darkThemeData.textTheme.displayLarge!.copyWith(
          color: AppPallete.whiteColor,
          fontSize: 16,
        ),
      ),
      verticalSpacing(25),
      userInfo(
        'Display Name',
        const Icon(
          Icons.person,
          color: AppPallete.greyColor,
          size: 20,
        ),
        Text(
          displayName,
          style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
            color: AppPallete.whiteColor,
          ),
        ),
      ),
      userInfo(
        'Email',
        const Icon(
          Icons.email,
          color: AppPallete.greyColor,
          size: 20,
        ),
        Text(
          email,
          style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
            color: AppPallete.whiteColor,
          ),
        ),
      ),
      userInfo(
        'Phone no',
        const Icon(
          Icons.phone,
          color: AppPallete.greyColor,
          size: 20,
        ),
        Text(
          "+$phoneCode$phoneNumber",
          style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
            color: AppPallete.whiteColor,
          ),
        ),
      ),
      userInfo(
        'About',
        const Icon(
          Icons.info,
          color: AppPallete.greyColor,
          size: 20,
        ),
        Text(
          about,
          style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
            color: AppPallete.whiteColor,
          ),
        ),
      ),
    ],
  );
}

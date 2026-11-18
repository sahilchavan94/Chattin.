// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:chattin/core/common/entities/user_entity.dart';
import 'package:chattin/core/router/route_path.dart';
import 'package:chattin/core/utils/app_pallete.dart';
import 'package:chattin/core/utils/app_spacing.dart';
import 'package:chattin/core/utils/app_theme.dart';
import 'package:chattin/core/utils/contacts.dart';
import 'package:chattin/core/utils/picker.dart';
import 'package:chattin/core/utils/requests.dart';
import 'package:chattin/core/utils/toast_messages.dart';
import 'package:chattin/core/utils/toasts.dart';
import 'package:chattin/core/widgets/failure_widget.dart';
import 'package:chattin/core/widgets/image_widget.dart';
import 'package:chattin/core/widgets/input_widget.dart';
import 'package:chattin/features/chat/presentation/cubits/contacts_cubit/contacts_cubit.dart';
import 'package:chattin/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:chattin/features/stories/domain/entities/story_entity.dart';
import 'package:chattin/features/stories/presentation/cubit/story_cubit.dart';
import 'package:chattin/features/stories/presentation/widgets/story_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class StoryContactsView extends StatefulWidget {
  const StoryContactsView({super.key});

  @override
  State<StoryContactsView> createState() => _StoryContactsViewState();
}

class _StoryContactsViewState extends State<StoryContactsView> {
  final TextEditingController _searchController = TextEditingController();
  late UserEntity userData;
  String _searchQuery = '';

  @override
  void initState() {
    userData = context.read<ProfileCubit>().state.userData!;
    _getContactsFromPhone(isRefreshed: false);
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  Future<void> _getContactsFromPhone({bool isRefreshed = false}) async {
    final permission = await Requests.requestContactsPermission();
    if (permission != PermissionStatus.granted) {
      showToast(
        content: ToastMessages.contactsAccessFailure,
        description: ToastMessages.contactsAccessFailureDesc,
        type: ToastificationType.error,
      );
      return;
    }
    List<String> contactsList = await Contacts.getContacts(
      selfNumber: userData.phoneNumber!,
    );
    await context.read<ContactsCubit>().getAppContacts(
      [...contactsList, userData.phoneNumber!],
      isRefreshed: isRefreshed,
    );
    final phoneNumbers = context.read<ContactsCubit>().state.contactList;
    await context.read<StoryCubit>().getStories(
          phoneNumbers: phoneNumbers!.map((e) => e.phoneNumber!).toList(),
          selfNumber: userData.phoneNumber!,
        );
  }

  Future<void> _callUseCaseToUploadStoryImages() async {
    final pickedImages = await Picker.pickMultipleImages();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      final List<File> selectedFiles = [];
      selectedFiles.addAll(pickedImages);
      context.push(
        RoutePath.storyPreview.path,
        extra: {
          'selectedFiles': selectedFiles,
          'imageUrl': userData.imageUrl,
          'displayName': userData.displayName,
          'phoneNumber': userData.phoneNumber,
        },
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<StoryEntity> _filterStories(List<StoryEntity> stories) {
    if (_searchQuery.isEmpty) {
      return stories;
    }
    return stories.where((story) {
      return story.userEntity!.displayName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        centerTitle: true,
      ),
      body: BlocBuilder<ContactsCubit, ContactsState>(
        builder: (context, state) {
          if (state.contactsStatus == ContactsStatus.initial) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    _getContactsFromPhone();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "No contacts can be accessed due to permission issues",
                        style: AppTheme.darkThemeData.textTheme.displaySmall!
                            .copyWith(
                          color: AppPallete.errorColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        ToastMessages.contactsAccessFailureDesc,
                        style: AppTheme.darkThemeData.textTheme.displaySmall!
                            .copyWith(
                          color: AppPallete.greyColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (state.contactsStatus == ContactsStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state.contactsStatus == ContactsStatus.failure) {
            return const FailureWidget();
          }
          return BlocBuilder<StoryCubit, StoryState>(
            builder: (context, storiesState) {
              if (storiesState.storyStatus == StoryStatus.loading &&
                  storiesState.stories == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (storiesState.storyStatus == StoryStatus.failure) {
                return const FailureWidget();
              }

              final List<StoryEntity> stories =
                  _filterStories(storiesState.stories ?? []);
              final StoryEntity? myStory = storiesState.myStory;
              return RefreshIndicator(
                backgroundColor: AppPallete.bottomSheetColor,
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                color: AppPallete.blueColor,
                onRefresh: () => _getContactsFromPhone(isRefreshed: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InputWidget(
                          height: 45,
                          hintText: 'Search for stories',
                          textEditingController: _searchController,
                          validator: (String val) {},
                          suffixIcon: const Icon(
                            Icons.search,
                            color: AppPallete.greyColor,
                            size: 20,
                          ),
                          fillColor: AppPallete.bottomSheetColor,
                          borderRadius: 60,
                          showBorder: false,
                        ),
                        verticalSpacing(30),
                        // Show the information of your story
                        Text(
                          "Explore stories",
                          style: AppTheme.darkThemeData.textTheme.displaySmall!
                              .copyWith(
                            color: AppPallete.whiteColor,
                            fontSize: 16,
                          ),
                        ),
                        if (myStory == null)
                          Column(
                            children: [
                              verticalSpacing(20),
                              _NoStoryWidget(
                                userData: userData,
                                onPressed: _callUseCaseToUploadStoryImages,
                              ),
                              verticalSpacing(20),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              context.push(
                                RoutePath.storyView.path,
                                extra: [myStory],
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StoryWidget(
                                  displayName: "Your Story",
                                  firstStoryImageUrl:
                                      myStory.imageUrlList.first['url'],
                                  firestStoryUploadTime:
                                      DateTime.fromMillisecondsSinceEpoch(
                                    myStory.imageUrlList.first['uploadedAt'],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await _callUseCaseToUploadStoryImages();
                                  },
                                  child: Image.asset(
                                    'assets/images/story.png',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(
                          color: AppPallete.greyColor,
                          thickness: .15,
                          height: 1,
                        ),
                        if (stories.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 200),
                              child: Text(
                                "No Results Found",
                                style: AppTheme
                                    .darkThemeData.textTheme.displaySmall!
                                    .copyWith(
                                  color: AppPallete.greyColor,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stories.length,
                            itemBuilder: (context, index) {
                              final story = stories[index];
                              return GestureDetector(
                                onTap: () {
                                  context.push(
                                    RoutePath.storyView.path,
                                    extra: stories.sublist(
                                      index,
                                      stories.length,
                                    ),
                                  );
                                },
                                child: StoryWidget(
                                  displayName: story.userEntity!.displayName,
                                  firstStoryImageUrl:
                                      story.imageUrlList.first['url'],
                                  firestStoryUploadTime:
                                      DateTime.fromMillisecondsSinceEpoch(
                                    story.imageUrlList.first['uploadedAt'],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NoStoryWidget extends StatelessWidget {
  final UserEntity userData;
  final VoidCallback onPressed;
  const _NoStoryWidget({
    required this.userData,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          ImageWidget(
            imagePath: userData.imageUrl,
            height: 50,
            width: 50,
            radius: BorderRadius.circular(50),
            fit: BoxFit.cover,
          ),
          horizontalSpacing(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add your story",
                style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
                  color: AppPallete.blueColor,
                  fontSize: 16,
                ),
              ),
              verticalSpacing(5),
              Text(
                "Share stories by sharing awesome pics",
                style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
                  color: AppPallete.greyColor,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

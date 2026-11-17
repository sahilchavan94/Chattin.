// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:chattin/core/common/providers/reply_message_provider.dart';
import 'package:chattin/core/enum/enums.dart';
import 'package:chattin/core/router/route_path.dart';
import 'package:chattin/core/utils/app_pallete.dart';
import 'package:chattin/core/utils/picker.dart';
import 'package:chattin/core/widgets/bottom_sheet_for_image.dart';
import 'package:chattin/core/widgets/failure_widget.dart';
import 'package:chattin/core/widgets/input_widget.dart';
import 'package:chattin/core/widgets/message_operation_widget.dart';
import 'package:chattin/core/widgets/reply_widget.dart';
import 'package:chattin/features/chat/domain/entities/message_entity.dart';
import 'package:chattin/features/chat/presentation/cubits/chat_cubit/chat_cubit.dart';
import 'package:chattin/features/chat/presentation/pages/chat_contact_information_view.dart';
import 'package:chattin/features/chat/presentation/widgets/contact_widget.dart';
import 'package:chattin/features/chat/presentation/widgets/date_widget.dart';
import 'package:chattin/features/chat/presentation/widgets/message_widget.dart';
import 'package:chattin/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:swipe_to/swipe_to.dart';

class ChatView extends StatefulWidget {
  final String uid;
  final String displayName;
  final String imageUrl;
  const ChatView({
    super.key,
    required this.uid,
    required this.displayName,
    required this.imageUrl,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    context.read<ChatCubit>().getChatStream(receiverId: widget.uid);
    context.read<ChatCubit>().getChatStatus(widget.uid);
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  Future<void> _selectImage(ImageSource imageSource) async {
    final pickedImage = await Picker.pickImage(imageSource);
    if (pickedImage != null) {
      final sender = context.read<ProfileCubit>().state.userData!;
      context.push(
        RoutePath.imagePreview.path,
        extra: {
          'file': pickedImage,
          'onPressed': () {
            context.read<ChatCubit>().sendFileMessage(
                  recieverId: widget.uid,
                  sender: sender,
                  messageType: MessageType.image,
                  file: pickedImage,
                );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          colorFilter: ColorFilter.srgbToLinearGamma(),
          opacity: .3,
          image: AssetImage(
            "assets/images/bg.png",
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppPallete.transparent,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            systemNavigationBarColor: AppPallete.blackColor,
          ),
          toolbarHeight: 70,
          elevation: 10,
          shadowColor: AppPallete.bottomSheetColor,
          title: ContactWidget(
            uid: widget.uid,
            displayName: widget.displayName,
            imageUrl: widget.imageUrl,
            status: context
                    .watch<ChatCubit>()
                    .state
                    .currentChatStatus
                    ?.convertStatusToString() ??
                Status.unavailable.convertStatusToString(),
            radius: 50,
            isViewingStory: true,
          ),
          titleSpacing: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    elevation: 0,
                    showDragHandle: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    backgroundColor: AppPallete.backgroundColor,
                    constraints: BoxConstraints.expand(
                      height: MediaQuery.of(context).size.height * .9,
                    ),
                    builder: (context) {
                      return ChatContactInformationView(uid: widget.uid);
                    },
                  );
                },
                icon: const Icon(
                  Icons.info_outline,
                  color: AppPallete.blueColor,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Consumer<ReplyMessageProvider>(
          builder: (BuildContext context,
              ReplyMessageProvider replyMessageProvider, Widget? child) {
            return BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state.chatStreamStatus == ChatStreamStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (state.chatStreamStatus == ChatStreamStatus.failure) {
                  return const SizedBox.shrink();
                }
                // ignore: avoid_unnecessary_containers
                return Container(
                  child: Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (replyMessageProvider.isReplyWidgetOpened &&
                            replyMessageProvider.currentReplyChatId ==
                                widget.uid)
                          replyWidget(
                            context: context,
                            sender: replyMessageProvider.senderName,
                            messageType: replyMessageProvider.messageType,
                            senderImage: replyMessageProvider.senderImageUrl,
                            repliedTo: replyMessageProvider.repliedTo,
                            isMe: replyMessageProvider.isMe,
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: InputWidget(
                                hintText:
                                    replyMessageProvider.isReplyWidgetOpened
                                        ? 'Reply'
                                        : 'Message',
                                height: 47.5,
                                textEditingController: _messageController,
                                validator: (String val) {},
                                suffixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Icon(
                                    Icons.photo_library,
                                    color: AppPallete.greyColor,
                                  ),
                                ),
                                onSuffixIconPressed: () {
                                  showBottomSheetForPickingImage(
                                    context: context,
                                    onClick1: () {
                                      context.pop();
                                      _selectImage(ImageSource.camera);
                                    },
                                    onClick2: () {
                                      context.pop();
                                      _selectImage(ImageSource.gallery);
                                    },
                                    title: "Share images ",
                                    subTitle:
                                        "Sending images to each other is now easy 📸",
                                  );
                                },
                                fillColor: AppPallete.backgroundColor,
                                showBorder: false,
                                borderRadius: 60,
                              ),
                            ),
                            FloatingActionButton(
                              onPressed: () async {
                                if (_messageController.text
                                    .replaceAll(" ", "")
                                    .isEmpty) {
                                  return;
                                }

                                if (replyMessageProvider.isReplyWidgetOpened) {
                                  await context.read<ChatCubit>().sendReply(
                                        text: _messageController.text,
                                        repliedTo:
                                            replyMessageProvider.repliedTo,
                                        recieverId:
                                            replyMessageProvider.receiverId,
                                        repliedToType:
                                            replyMessageProvider.messageType,
                                        senderId: replyMessageProvider.senderId,
                                      );
                                  replyMessageProvider.clearReplyData();
                                  setState(() {
                                    _messageController.clear();
                                  });
                                  return;
                                }
                                context.read<ChatCubit>().sendMessage(
                                      text: _messageController.text,
                                      recieverId: widget.uid,
                                      sender: context
                                          .read<ProfileCubit>()
                                          .state
                                          .userData!,
                                    );
                                setState(() {
                                  _messageController.clear();
                                });
                              },
                              mini: true,
                              backgroundColor:
                                  context.watch<ChatCubit>().state.chatStatus ==
                                          ChatStatus.loading
                                      ? AppPallete.blueColor.withOpacity(.7)
                                      : AppPallete.blueColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  50,
                                ),
                              ),
                              child: context
                                          .watch<ChatCubit>()
                                          .state
                                          .sendingMessage ==
                                      true
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        color: AppPallete.whiteColor,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      size: 20,
                                      color: AppPallete.whiteColor,
                                    ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        body: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            if (state.chatStreamStatus == ChatStreamStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state.chatStreamStatus == ChatStreamStatus.failure) {
              return const FailureWidget();
            }

            final List<MessageEntity> messages =
                state.currentChatMessages ?? [];

            //needs to be properly configured to handle the scrolling only when required
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            return Consumer<ReplyMessageProvider>(
              builder: (context, replyMessageProvider, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0,
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        decelerationRate: ScrollDecelerationRate.normal,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final userData =
                            context.read<ProfileCubit>().state.userData!;
                        final isMe = messages[index].senderId == userData.uid;
                        if (!messages[index].status && !isMe) {
                          context.read<ChatCubit>().setMessageStatus(
                                receiverId: messages[index].receiverId,
                                senderId: messages[index].senderId,
                                messageId: messages[index].messageId,
                              );
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (index == 0 ||
                                index != messages.length - 1 &&
                                    messages[index - 1].timeSent!.day !=
                                        messages[index].timeSent!.day)
                              DateWidget(
                                timeSent: messages[index].timeSent!,
                              ),
                            SwipeTo(
                              iconSize: 18,
                              offsetDx: .175,
                              iconColor: AppPallete.whiteColor,
                              iconOnRightSwipe: Icons.reply,
                              iconOnLeftSwipe: Icons.more_vert_sharp,
                              onRightSwipe: (details) {
                                if (messages[index].messageType ==
                                    MessageType.deleted) {
                                      return;
                                    }
                                replyMessageProvider.setReplyParams(
                                  type: messages[index].messageType,
                                  message: messages[index].text,
                                  messageSender:
                                      isMe ? "You" : widget.displayName,
                                  messageSenderImage: isMe
                                      ? userData.imageUrl
                                      : widget.imageUrl,
                                  sId: userData.uid,
                                  rId: isMe
                                      ? messages[index].receiverId
                                      : messages[index].senderId,
                                  isMeP: isMe,
                                  currentChat: widget.uid,
                                );
                              },
                              onLeftSwipe: (details) {
                                if (replyMessageProvider.isReplyWidgetOpened) {
                                  return;
                                }
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  backgroundColor: AppPallete.bottomSheetColor,
                                  constraints: BoxConstraints.expand(
                                    height: messages[index].messageType ==
                                            MessageType.deleted
                                        ? MediaQuery.of(context).size.height *
                                            .25
                                        : MediaQuery.of(context).size.height *
                                            .35,
                                  ),
                                  builder: (context) {
                                    return MessageOperationsDialog(
                                      messageType: messages[index].messageType,
                                      messageId: messages[index].messageId,
                                      text: messages[index].text,
                                      receiverId: isMe
                                          ? messages[index].receiverId
                                          : messages[index].senderId,
                                      senderId: userData.uid,
                                      isMe: isMe,
                                    );
                                  },
                                );
                              },
                              child: MessageWidget(
                                isReply: messages[index].isReply,
                                isForwarded: messages[index].isForwarded,
                                repliedTo: messages[index].repliedTo,
                                repliedToType: messages[index].repliedToType,
                                messageType: messages[index].messageType,
                                text: messages[index].text,
                                name: isMe
                                    ? userData.displayName
                                    : widget.displayName,
                                isMe: isMe,
                                imageUrl:
                                    isMe ? userData.imageUrl : widget.imageUrl,
                                timeSent: messages[index].timeSent!,
                                status: messages[index].status,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

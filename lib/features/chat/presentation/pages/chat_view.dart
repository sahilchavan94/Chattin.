import 'package:chattin/core/utils/app_pallete.dart';
import 'package:chattin/core/utils/app_theme.dart';
import 'package:chattin/core/widgets/input_widget.dart';
import 'package:chattin/features/chat/presentation/cubits/chat_cubit/cubit/chat_cubit.dart';
import 'package:chattin/features/chat/presentation/widgets/contact_widget.dart';
import 'package:chattin/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppPallete.bottomSheetColor,
        title: ContactWidget(
          displayName: widget.displayName,
          imageUrl: widget.imageUrl,
          about: widget.uid,
          hasVerticalSpacing: false,
          radius: 50,
        ),
        titleSpacing: 0,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InputWidget(
                      hintText: 'Text message',
                      height: 45,
                      textEditingController: _messageController,
                      validator: (String val) {},
                      suffixIcon: const Icon(Icons.chat),
                      fillColor: AppPallete.bottomSheetColor,
                      showBorder: false,
                      borderRadius: 60,
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      final text = _messageController.text;
                      setState(() {
                        _messageController.clear();
                      });
                      context.read<ChatCubit>().sendMessage(
                            text: text,
                            recieverId: widget.uid,
                            sender:
                                context.read<ProfileCubit>().state.userData!,
                          );
                    },
                    mini: true,
                    backgroundColor: AppPallete.blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        50,
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 20,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Text(
          "Chat View",
          style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
            color: AppPallete.whiteColor,
          ),
        ),
      ),
    );
  }
}

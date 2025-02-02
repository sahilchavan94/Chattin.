import 'package:chattin/core/utils/app_pallete.dart';
import 'package:chattin/core/utils/app_spacing.dart';
import 'package:chattin/core/utils/app_theme.dart';
import 'package:chattin/core/utils/dates.dart';
import 'package:chattin/core/widgets/image_dialog.dart';
import 'package:chattin/core/widgets/image_widget.dart';
import 'package:flutter/material.dart';

class ChatContactWidget extends StatelessWidget {
  final String uid;
  final String imageUrl;
  final String displayName;
  final String lastMessage;
  final double? radius;
  final DateTime timeSent;
  final bool? hasVerticalSpacing;
  const ChatContactWidget({
    super.key,
    required this.uid,
    required this.imageUrl,
    required this.displayName,
    required this.lastMessage,
    this.hasVerticalSpacing,
    this.radius,
    required this.timeSent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  showImageDialog(
                    context: context,
                    displayName: displayName,
                    imageUrl: imageUrl,
                    uid: uid,
                  );
                },
                child: ImageWidget(
                  imagePath: imageUrl,
                  width: radius ?? 50,
                  height: radius ?? 50,
                  fit: BoxFit.cover,
                  radius: BorderRadius.circular(60),
                ),
              ),
              horizontalSpacing(16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style:
                        AppTheme.darkThemeData.textTheme.displayLarge!.copyWith(
                      color: AppPallete.whiteColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  verticalSpacing(5),
                  Text(
                    lastMessage.length > 30
                        ? "${lastMessage.substring(0, 25)}..."
                        : lastMessage,
                    style:
                        AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
                      color: AppPallete.greyColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                ],
              ),
              const Spacer(),
              Text(
                DateFormatters.formatDateWithBothDateAndDay(timeSent),
                style: AppTheme.darkThemeData.textTheme.displaySmall!.copyWith(
                  color: AppPallete.greyColor,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis, // Ensure text can overflow
              ),
            ],
          ),
          hasVerticalSpacing == true
              ? verticalSpacing(25)
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:bluebubbles/app/state/chat_state_scope.dart';
import 'package:bluebubbles/app/state/message_state_scope.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatEvent extends StatelessWidget {
  const ChatEvent({
    super.key,
    required this.part,
  });

  final MessagePart part;

  @override
  Widget build(BuildContext context) {
    final message = MessageStateScope.messageOf(context);
    final state = MessageStateScope.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: GestureDetector(
          onLongPress: () {
            const encoder = JsonEncoder.withIndent("     ");
            Map map = message.toMap();
            if (map["dateCreated"] is int) {
              map["dateCreated"] =
                  DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(map["dateCreated"]));
            }
            if (map["dateDelivered"] is int) {
              map["dateDelivered"] = DateFormat("MMMM d, yyyy h:mm:ss a")
                  .format(DateTime.fromMillisecondsSinceEpoch(map["dateDelivered"]));
            }
            if (map["dateRead"] is int) {
              map["dateRead"] =
                  DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(map["dateRead"]));
            }
            if (map["dateEdited"] is int) {
              map["dateEdited"] =
                  DateFormat("MMMM d, yyyy h:mm:ss a").format(DateTime.fromMillisecondsSinceEpoch(map["dateEdited"]));
            }
            String str = encoder.convert(map);
            final unsent =
                part.isUnsent ? message.unsentTextForPart(part.part, fullyUnsent: state.isFullyUnsent) : null;
            final keptByServer = message.unsentContent?.fromServer ?? false;
            showBBDialog(
              context: context,
              title: "Message Info",
              content: SizedBox(
                width: NavigationSvc.width(context) * 3 / 5,
                height: context.height * (unsent != null ? 2 / 5 : 1 / 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // What the unsent part said, ahead of the raw data, when a copy of it was kept
                    if (unsent != null) ...[
                      Text("Unsent message", style: context.theme.textTheme.labelLarge),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: context.height / 6),
                        child: SingleChildScrollView(
                          child: SelectableText(unsent, style: context.theme.textTheme.bodyLarge),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keptByServer ? "Kept by the server" : "Kept on this device",
                        style: context.theme.textTheme.bodySmall!
                            .copyWith(color: context.theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                            color: context.theme.colorScheme.surface,
                            borderRadius: const BorderRadius.all(Radius.circular(10))),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            str,
                            style: context.theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                BBDialogAction(
                  text: "Close",
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            );
          },
          child: Obx(() {
            final chatState = ChatStateScope.maybeOf(context);
            final hasBackground = chatState?.hasCustomWallpaper ?? false;
            final senderName = state.senderDisplayName;
            final text = part.isUnsent
                ? (message.isFromMe!
                    ? "You unsent a message. Others may still see the message on devices where the software hasn't been updated"
                    : "$senderName unsent a message")
                : message.buildGroupEventText(senderName);
            final textColor =
                hasBackground ? context.theme.colorScheme.onSurfaceVariant : context.theme.colorScheme.outline;
            final textWidget = Text(
              text,
              style: context.theme.textTheme.bodySmall!.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            );
            if (!hasBackground) return textWidget;
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: textWidget,
              ),
            );
          }),
        ),
      ),
    );
  }
}

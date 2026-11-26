import 'dart:math';
import 'dart:ui';

import 'package:bluebubbles/app/components/custom_text_editing_controllers.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/misc/bubble_effects.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/misc/tail_clipper.dart';
import 'package:bluebubbles/app/wrappers/bb_scaffold.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/animations/balloon_classes.dart';
import 'package:bluebubbles/app/animations/balloon_rendering.dart';
import 'package:bluebubbles/app/animations/celebration_class.dart';
import 'package:bluebubbles/app/animations/celebration_rendering.dart';
import 'package:bluebubbles/app/animations/fireworks_classes.dart';
import 'package:bluebubbles/app/animations/fireworks_rendering.dart';
import 'package:bluebubbles/app/animations/laser_classes.dart';
import 'package:bluebubbles/app/animations/laser_rendering.dart';
import 'package:bluebubbles/app/animations/love_classes.dart';
import 'package:bluebubbles/app/animations/love_rendering.dart';
import 'package:bluebubbles/app/animations/spotlight_classes.dart';
import 'package:bluebubbles/app/animations/spotlight_rendering.dart';
import 'package:bluebubbles/app/state/message_state.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:get/get.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

void sendEffectAction(
  BuildContext context,
  TickerProvider provider,
  String text,
  String subjectText,
  String? threadOriginatorGuid,
  int? part,
  String? chatGuid,
  Future<void> Function({String? effect}) sendMessage,
  List<Run> textRuns, {
  required Future<void> Function(DateTime date) scheduleMessage,
  required String? Function() scheduleBlockReason,
}) {
  // Effects need the Private API; scheduling only needs the server, so without it the sheet opens on Schedule alone
  final effectsAvailable = SettingsSvc.settings.enablePrivateAPI.value;
  String typeSelected = effectsAvailable ? "bubble" : "schedule";
  SchedulePreset? presetSelected = SchedulePreset.oneHour;
  DateTime? customDate;
  final bubbleEffects = ["slam", "loud", "gentle", "invisible ink"];
  final screenEffects = ["echo", "spotlight", "balloons", "confetti", "love", "lasers", "fireworks", "celebration"];
  String bubbleSelected = "slam";
  String screenSelected = "echo";
  final lead = text.length - text.trimLeft().length;
  text = text.trim();
  // Runs over the trimmed whitespace are cut back to the text, or they'd fall outside it and not be drawn
  final trimmedRuns = <Run>[];
  for (final r in textRuns) {
    final start = max(r.range[0] - lead, 0);
    final end = min(r.range[0] + r.range[1] - lead, text.length);
    if (end > start) trimmedRuns.add(Run(range: [start, end - start], attributes: r.attributes));
  }
  final runs = MentionTextEditingController.attributedRuns(text, trimmedRuns);
  final message = Message(
    text: text,
    subject: subjectText,
    threadOriginatorGuid: threadOriginatorGuid,
    threadOriginatorPart: "${part ?? 0}:0:0",
    expressiveSendStyleId: effectsAvailable ? effectMap["slam"] : null,
    dateCreated: DateTime.now(),
    hasAttachments: false,
    isFromMe: true,
    handleId: 0,
    hasDdResults: true,
    attributedBody: [if (runs.isNotEmpty) AttributedBody(string: text, runs: runs)],
  );
  message.generateTempGuid();
  final previewState = MessageState(message);
  final GlobalKey key = GlobalKey();
  Control animController = Control.stop;
  final FireworkController fireworkController =
      FireworkController(vsync: provider, windowSize: Size(NavigationSvc.width(context), context.height));
  final CelebrationController celebrationController =
      CelebrationController(vsync: provider, windowSize: Size(NavigationSvc.width(context), context.height));
  final ConfettiController confettiController = ConfettiController(duration: const Duration(seconds: 1));
  final BalloonController balloonController =
      BalloonController(vsync: provider, windowSize: Size(NavigationSvc.width(context), context.height));
  final LoveController loveController =
      LoveController(vsync: provider, windowSize: Size(NavigationSvc.width(context), context.height));
  final SpotlightController spotlightController =
      SpotlightController(vsync: provider, windowSize: Size(NavigationSvc.width(context), context.height));
  final LaserController laserController =
      LaserController(vsync: provider, windowSize: Size(NavigationSvc.width(context), context.height));
  // Capture the conversation's theme before pushing the route — if adaptive
  // theming is active, context.theme is already the per-chat theme.
  final capturedTheme = context.theme;
  final capturedIsM3 = ThemeSvc.isMaterialYouActive(context);
  final capturedBubbleExt = capturedTheme.extensions[BubbleColors] as BubbleColors?;
  Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: BBScaffold(
              backgroundColor: kIsDesktop && SettingsSvc.settings.windowEffect.value != WindowEffect.disabled
                  ? capturedTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
                  : Colors.transparent,
              safeAreaLeft: false,
              safeAreaRight: false,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: kIsDesktop && SettingsSvc.settings.windowEffect.value != WindowEffect.disabled ? 0 : 30,
                        sigmaY:
                            kIsDesktop && SettingsSvc.settings.windowEffect.value != WindowEffect.disabled ? 0 : 30),
                    child: Container(
                      color: capturedTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                  StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState) {
                    return Stack(
                      children: [
                        if (screenSelected == "fireworks") Fireworks(controller: fireworkController),
                        if (screenSelected == "celebration") Celebration(controller: celebrationController),
                        if (screenSelected == "balloons") Balloons(controller: balloonController),
                        if (screenSelected == "love") Love(controller: loveController),
                        if (screenSelected == "spotlight") Spotlight(controller: spotlightController),
                        if (screenSelected == "lasers") Laser(controller: laserController),
                        if (screenSelected == "confetti")
                          Align(
                            alignment: Alignment.topCenter,
                            child: ConfettiWidget(
                              confettiController: confettiController,
                              blastDirection: pi / 2,
                              blastDirectionality: BlastDirectionality.explosive,
                              emissionFrequency: 0.35,
                            ),
                          ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                                child: Column(children: [
                              Text(
                                typeSelected == "schedule" ? "Schedule message" : "Send with effect",
                                style: context.theme.textTheme.headlineSmall!,
                              ),
                              if (effectsAvailable)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                                  child: SizedBox(
                                    height: 50,
                                    width: min(NavigationSvc.width(context) - 40, 420),
                                    child: CupertinoSlidingSegmentedControl<String>(
                                      children: {
                                        "bubble": const Text("Bubble"),
                                        "screen": const Text("Screen"),
                                        "schedule": const Text("Schedule"),
                                      },
                                      groupValue: typeSelected,
                                      thumbColor: CupertinoColors.tertiarySystemFill.oppositeLightenOrDarken(20),
                                      backgroundColor: CupertinoColors.tertiarySystemFill,
                                      onValueChanged: (str) {
                                        setState(() {
                                          typeSelected = str ?? "bubble";
                                          // A scheduled message goes out plain, so the preview drops the bubble effect
                                          message.expressiveSendStyleId =
                                              typeSelected == "schedule" ? null : effectMap[bubbleSelected];
                                        });
                                      },
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 20),
                              const Spacer(),
                              if (typeSelected == "bubble")
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 250,
                                        maxWidth: NavigationSvc.width(context),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          children: List.generate(bubbleEffects.length, (index) {
                                            return Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    bubbleSelected = bubbleEffects[index];
                                                    message.expressiveSendStyleId = effectMap[bubbleSelected];
                                                    previewState.triggerBubbleEffect(0);
                                                    if (bubbleSelected == "gentle") {
                                                      animController = Control.playFromStart;
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  width: NavigationSvc.width(context) / 3,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: CupertinoColors.tertiarySystemFill,
                                                    border: Border.fromBorderSide(bubbleSelected == bubbleEffects[index]
                                                        ? BorderSide(
                                                            color: context.theme.colorScheme.primary,
                                                            width: 1.5,
                                                            style: BorderStyle.solid,
                                                          )
                                                        : BorderSide.none),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      bubbleEffects[index].toUpperCase(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      )),
                                ),
                              if (typeSelected == "screen")
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 350,
                                        maxWidth: NavigationSvc.width(context),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          children: List.generate(screenEffects.length, (index) {
                                            return Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: GestureDetector(
                                                onTap: () async {
                                                  setState(() {
                                                    screenSelected = screenEffects[index];
                                                  });
                                                  if (screenSelected == "fireworks" && !fireworkController.isPlaying) {
                                                    fireworkController.windowSize =
                                                        Size(NavigationSvc.width(context), context.height);
                                                    fireworkController.start();
                                                    await Future.delayed(const Duration(seconds: 1));
                                                    fireworkController.stop();
                                                  } else if (screenSelected == "celebration" &&
                                                      !celebrationController.isPlaying) {
                                                    celebrationController.windowSize =
                                                        Size(NavigationSvc.width(context), context.height);
                                                    celebrationController.start();
                                                    await Future.delayed(const Duration(seconds: 1));
                                                    celebrationController.stop();
                                                  } else if (screenSelected == "balloons" &&
                                                      !balloonController.isPlaying) {
                                                    balloonController.windowSize =
                                                        Size(NavigationSvc.width(context), context.height);
                                                    balloonController.start();
                                                    await Future.delayed(const Duration(seconds: 1));
                                                    balloonController.stop();
                                                  } else if (screenSelected == "love" && !loveController.isPlaying) {
                                                    if (key.globalPaintBounds(context) != null) {
                                                      loveController.windowSize =
                                                          Size(NavigationSvc.width(context), context.height);
                                                      loveController.start(Point(
                                                          (key.globalPaintBounds(context)!.left +
                                                                  key.globalPaintBounds(context)!.right) /
                                                              2,
                                                          (key.globalPaintBounds(context)!.top +
                                                                  key.globalPaintBounds(context)!.bottom) /
                                                              2));
                                                      await Future.delayed(const Duration(seconds: 1));
                                                      loveController.stop();
                                                    }
                                                  } else if (screenSelected == "spotlight" &&
                                                      !spotlightController.isPlaying) {
                                                    if (key.globalPaintBounds(context) != null) {
                                                      spotlightController.windowSize =
                                                          Size(NavigationSvc.width(context), context.height);
                                                      spotlightController.start(key.globalPaintBounds(context)!);
                                                      await Future.delayed(const Duration(seconds: 1));
                                                      spotlightController.stop();
                                                    }
                                                  } else if (screenSelected == "lasers" && !laserController.isPlaying) {
                                                    if (key.globalPaintBounds(context) != null) {
                                                      laserController.windowSize =
                                                          Size(NavigationSvc.width(context), context.height);
                                                      laserController.start(key.globalPaintBounds(context)!);
                                                      await Future.delayed(const Duration(seconds: 1));
                                                      laserController.stop();
                                                    }
                                                  } else if (screenSelected == "confetti") {
                                                    confettiController.play();
                                                  }
                                                },
                                                child: Container(
                                                  width: NavigationSvc.width(context) / 3,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: CupertinoColors.tertiarySystemFill,
                                                    border: Border.fromBorderSide(screenSelected == screenEffects[index]
                                                        ? BorderSide(
                                                            color: context.theme.colorScheme.primary,
                                                            width: 1.5,
                                                            style: BorderStyle.solid,
                                                          )
                                                        : BorderSide.none),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      screenEffects[index].toUpperCase(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      )),
                                ),
                              if (typeSelected == "schedule")
                                _SchedulePanel(
                                  presetSelected: presetSelected,
                                  customDate: customDate,
                                  blockReason: scheduleBlockReason() ?? (text.isEmpty ? _emptyScheduleReason : null),
                                  onPresetSelected: (preset) {
                                    setState(() {
                                      presetSelected = preset;
                                      customDate = null;
                                    });
                                  },
                                  onCustomDatePicked: (date) {
                                    setState(() {
                                      presetSelected = null;
                                      customDate = date;
                                    });
                                  },
                                ),
                              const Spacer(),
                              if (text.isNotEmpty || subjectText.isNotEmpty)
                                Theme(
                                  data: capturedTheme.copyWith(
                                    // in case some components still use legacy theming
                                    primaryColor:
                                        capturedBubbleExt?.iMessageBubbleColor ?? capturedTheme.colorScheme.primary,
                                    colorScheme: capturedTheme.colorScheme.copyWith(
                                      primary:
                                          capturedBubbleExt?.iMessageBubbleColor ?? capturedTheme.colorScheme.primary,
                                      onPrimary: capturedBubbleExt?.oniMessageBubbleColor ??
                                          capturedTheme.colorScheme.onPrimary,
                                      surface: capturedIsM3 ? null : capturedBubbleExt?.receivedBubbleColor,
                                      onSurface: capturedIsM3 ? null : capturedBubbleExt?.onReceivedBubbleColor,
                                    ),
                                  ),
                                  child: Builder(builder: (context) {
                                    return Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          key: key,
                                          padding: const EdgeInsets.only(right: 5.0),
                                          child: BubbleEffects(
                                            messageState: previewState,
                                            globalKey: key,
                                            part: 0,
                                              showTail: true,
                                              child: ClipPath(
                                                clipper: TailClipper(
                                                  isFromMe: true,
                                                  showTail: true,
                                                  connectLower: false,
                                                  connectUpper: false,
                                                ),
                                                child: Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth: NavigationSvc.width(context) *
                                                            MessageState.maxBubbleSizeFactor -
                                                        40,
                                                    minHeight: 40,
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15)
                                                      .add(const EdgeInsets.only(right: 10)),
                                                  color: context.theme.colorScheme.primary,
                                                  child: CustomAnimationBuilder<Movie>(
                                                    control: animController,
                                                    tween: MovieTween()
                                                      ..scene(
                                                              begin: Duration.zero,
                                                              duration: const Duration(milliseconds: 1),
                                                              curve: Curves.easeInOut)
                                                          .tween("size", 1.0.tweenTo(1.0))
                                                      ..scene(
                                                              begin: const Duration(milliseconds: 1),
                                                              duration: const Duration(milliseconds: 500),
                                                              curve: Curves.easeInOut)
                                                          .tween("size", 0.0.tweenTo(0.5))
                                                      ..scene(
                                                              begin: const Duration(milliseconds: 1000),
                                                              duration: const Duration(milliseconds: 800),
                                                              curve: Curves.easeInOut)
                                                          .tween("size", 0.5.tweenTo(1.0)),
                                                    duration: const Duration(milliseconds: 1800),
                                                    animationStatusListener: (status) {
                                                      if (status == AnimationStatus.completed) {
                                                        setState(() {
                                                          animController = Control.stop;
                                                        });
                                                      }
                                                    },
                                                    builder: (context, anim, child) {
                                                      final value1 = anim.get("size");
                                                      return Transform.scale(
                                                        scale: value1,
                                                        alignment: Alignment.center,
                                                        child: RichText(
                                                          text: TextSpan(
                                                            children: buildMessageSpans(
                                                              context,
                                                              MessagePart(
                                                                  part: 0,
                                                                  text: message.text,
                                                                  runs: message.attributedBody.firstOrNull?.runs ?? []),
                                                              message,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ));
                                  }),
                                ),
                              const Spacer(),
                              if (typeSelected == "schedule")
                                TextButton(
                                  child: Text(
                                    "Schedule for ${scheduleTimeLabel(customDate ?? presetSelected!.resolve())}",
                                    style: context.theme.textTheme.titleLarge!
                                        .apply(color: context.theme.colorScheme.primary),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Never disabled: a disabled button lets the tap through to the backdrop, which closes
                                  // the sheet, so a blocked schedule says why instead
                                  onPressed: () async {
                                    final blocked =
                                        scheduleBlockReason() ?? (text.isEmpty ? _emptyScheduleReason : null);
                                    if (blocked != null) {
                                      return showSnackbar("Error", blocked, type: SnackbarType.error);
                                    }
                                    // A preset counts from now, not from when it was picked
                                    final date = customDate ?? presetSelected!.resolve();
                                    if (!date.isAfter(DateTime.now())) {
                                      return showSnackbar("Error", "Pick a time in the future!",
                                          type: SnackbarType.error);
                                    }
                                    Navigator.of(context).pop();
                                    await scheduleMessage(date);
                                  },
                                )
                              else
                                TextButton(
                                  child: Text(
                                    typeSelected == "bubble"
                                        ? "Send with $bubbleSelected"
                                        : "Send with $screenSelected",
                                    style: context.theme.textTheme.titleLarge!
                                        .apply(color: context.theme.colorScheme.primary),
                                  ),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await sendMessage(
                                        effect: effectMap[typeSelected == "bubble" ? bubbleSelected : screenSelected]);
                                  },
                                ),
                            ])),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
      fullscreenDialog: true,
      opaque: false,
    ),
  );
}

const _emptyScheduleReason = "Type a message to schedule!";

/// "Today, 3:42 PM", "Tomorrow, 9:13 AM", or the full date further out.
String scheduleTimeLabel(DateTime date) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  if (date.isToday()) return "Today, ${buildTime(date)}";
  if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
    return "Tomorrow, ${buildTime(date)}";
  }
  return buildFullDate(date, useTodayYesterday: false);
}

/// The Schedule tab of the send sheet: quick picks for an hour or a few out and the next 9:13 AM, plus an exact
/// date and time from a calendar. It only picks the time; the sheet's button schedules the message.
class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    required this.presetSelected,
    required this.customDate,
    required this.blockReason,
    required this.onPresetSelected,
    required this.onCustomDatePicked,
  });

  final SchedulePreset? presetSelected;
  final DateTime? customDate;
  final String? blockReason;
  final void Function(SchedulePreset preset) onPresetSelected;
  final void Function(DateTime date) onCustomDatePicked;

  Future<void> _pickCustomDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = customDate ?? now.add(const Duration(hours: 1));
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialEntryMode: kIsDesktop ? DatePickerEntryMode.input : DatePickerEntryMode.calendar,
    );
    if (day == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      initialEntryMode: kIsDesktop ? TimePickerEntryMode.input : TimePickerEntryMode.dial,
    );
    if (time == null) return;

    final date = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (!date.isAfter(DateTime.now())) {
      return showSnackbar("Invalid Date Selection", "Please select a time in the future", type: SnackbarType.error);
    }
    onCustomDatePicked(date);
  }

  Widget _tile(BuildContext context, {
    required String label,
    required String detail,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
    required double width,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemFill,
            border: Border.fromBorderSide(selected
                ? BorderSide(color: context.theme.colorScheme.primary, width: 1.5, style: BorderStyle.solid)
                : BorderSide.none),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: context.theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label.toUpperCase(), textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: context.theme.textTheme.bodySmall!
                          .copyWith(color: context.theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = NavigationSvc.width(context);
    // Two tiles a row on a phone; capped so they don't stretch across a desktop window
    final tileWidth = min(width / 2 - 24, 200.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 350, maxWidth: width),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (blockReason != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    blockReason!,
                    textAlign: TextAlign.center,
                    style: context.theme.textTheme.bodyMedium!.copyWith(color: context.theme.colorScheme.error),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final preset in SchedulePreset.values)
                    _tile(
                      context,
                      label: preset.label,
                      detail: scheduleTimeLabel(preset.resolve()),
                      selected: presetSelected == preset,
                      icon: preset == SchedulePreset.nextMorning ? Icons.wb_sunny_outlined : Icons.schedule,
                      onTap: () => onPresetSelected(preset),
                      width: tileWidth,
                    ),
                  _tile(
                    context,
                    label: "Pick date & time",
                    detail: customDate != null ? scheduleTimeLabel(customDate!) : "Choose from a calendar",
                    selected: customDate != null,
                    icon: Icons.edit_calendar_outlined,
                    onTap: () => _pickCustomDate(context),
                    width: tileWidth * 2 + 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_screen/lock_screen.dart';

void main() {
  testWidgets(
    "test LockScreen",
    (tester) async {
      const operation = "OPERATION";
      final clickCount = ValueNotifier(0);
      final step1 = ProgressStep(progress: 0, message: "STEP1");
      final step2 = ProgressStep(progress: 0.5, message: "STEP2");
      final step3 = ProgressStep(progress: 1, message: "STEP3");
      final step4 = ProgressStep(message: "STEP4");
      final steps = [step1, step2, step3, step4];
      final jobEnded = Completer();

      void testSteps(ProgressStep? currentStep) {
        expect(
          find.text(operation),
          currentStep == null ? findsNothing : findsOneWidget,
        );
        for (final s in steps.where((s) => s.message != null)) {
          expect(
            find.text(s.message!),
            s == currentStep ? findsOneWidget : findsNothing,
          );
        }
        expect(
          find.byType(CircularProgressIndicator),
          currentStep == null ? findsNothing : findsOneWidget,
        );
      }

      await tester.pumpWidget(
        TestWidget(
          operation: operation,
          clickCount: clickCount,
          steps: steps,
          jobEnded: jobEnded,
        ),
      );

      final screen = find.bySubtype<MaterialApp>();
      testSteps(null);
      await tester.tap(screen);
      await tester.pump();
      expect(clickCount.value, 1);
      for (final s in steps) {
        await tester.tap(screen);
        //expect(clickCount.value, 1);
        s.started.complete();
        await tester.pump();
        await s.ended.future;
        testSteps(s);
      }
      await jobEnded.future;
      await tester.pump();
      testSteps(null);
    },
  );
}

class ProgressStep {
  ProgressStep({
    this.progress,
    this.message,
    this.cancelButton,
  });

  final double? progress;
  final String? message;
  final Widget? cancelButton;
  final started = Completer();
  final ended = Completer();
}

class TestWidget extends StatelessWidget {
  const TestWidget({
    required this.operation,
    required this.clickCount,
    required this.steps,
    required this.jobEnded,
    super.key,
  });

  final Iterable<ProgressStep> steps;

  final String operation;

  final ValueNotifier<int> clickCount;

  final Completer jobEnded;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LockScreenWidget(
        child: ScreenContent(
          operation: operation,
          clickCount: clickCount,
          jobEnded: jobEnded,
          steps: steps,
        ),
      ),
    );
  }
}

class ScreenContent extends StatelessWidget {
  const ScreenContent({
    required this.operation,
    required this.clickCount,
    required this.jobEnded,
    required this.steps,
    super.key,
  });

  final String operation;

  final Completer jobEnded;

  final ValueNotifier<int> clickCount;

  final Iterable<ProgressStep> steps;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          child: const Text("RUN"),
          onPressed: () {
            clickCount.value++;
            longTask(context);
          },
        ),
      );

  void longTask(BuildContext context) async {
    final lockScreen = LockScreen.of(context);
    await lockScreen.forJob(
      context,
      operation: operation,
      autoCancel: false,
      job: (updater) async {
        for (final step in steps) {
          await step.started.future;
          updater.setMessage(step.message);
          updater.setCancelButton(step.cancelButton);
          updater.setProgress(step.progress);
          step.ended.complete();
        }
      },
    );
    jobEnded.complete();
  }
}

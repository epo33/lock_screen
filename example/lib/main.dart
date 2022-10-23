import 'package:flutter/material.dart';
import 'package:lock_screen/lock_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.light,
          useMaterial3: true,
          textButtonTheme: const TextButtonThemeData(
            style: ButtonStyle(
              padding: MaterialStatePropertyAll(
                EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const vSpace = SizedBox(height: 32);
    return Scaffold(
      appBar: AppBar(
        title: const Text("LockScreen Demo"),
        actions: [
          IconButton(
            onPressed: () => mustNotBeClickable(context),
            icon: const Icon(Icons.handshake),
          )
        ],
      ),
      body: Center(
          child: Column(
        children: [
          const Spacer(),
          const TaskWidget(Duration(seconds: 1)),
          vSpace,
          const TaskWidget(
            Duration(seconds: 2),
            cancelable: true,
          ),
          vSpace,
          const TaskWidget(Duration(seconds: 3)),
          vSpace,
          TaskWidget(
            const Duration(seconds: 4),
            message: "4s task with custom widget",
            
            widget: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Text("Custom widget"),
            ),
          ),
          vSpace,
          const TaskWidget(
            Duration(seconds: 5),
            cancelable: true,
          ),
          vSpace,
          const TaskWidget(
            Duration(seconds: 10),
            cancelable: true,
          ),
          const Spacer(),
          TextButton(
            onPressed: () => mustNotBeClickable(context),
            child: const Text("Locked during task execution"),
          ),
          const Spacer(),
        ],
      )),
    );
  }

  void mustNotBeClickable(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Can't be clicked during task execution"),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          behavior: SnackBarBehavior.floating,
        ),
      );
}

class TaskWidget extends StatelessWidget {
  const TaskWidget(
    this.duration, {
    this.cancelable = false,
    this.widget,
    this.message,
    super.key,
  });

  final Duration duration;

  final bool cancelable;

  final Widget? widget;

  final String? message;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => doJob(context),
        child: Text(
          message ??
              "${duration.inSeconds}s task${cancelable ? " (cancelable)" : ""}",
        ),
      );

  void doJob(BuildContext context) async {
    await LockScreen.forJob(
      context: context,
      operation: "${duration.inSeconds}s task",
      display: LockScreenDisplay(autoCancel: cancelable),
      job: (display) async {
        var now = DateTime.now();
        final ends = now.add(duration);
        do {
          await Future.delayed(const Duration(milliseconds: 100));
          now = DateTime.now();
          final msDiff = ends.difference(now).inMilliseconds;
          display.copyWith(
            progress: 1 - (msDiff / duration.inMilliseconds),
            message: "Countdown : ${(msDiff / 1000).toStringAsFixed(1)}s",
          );
        } while (now.isBefore(ends));
      },
    );
  }
}

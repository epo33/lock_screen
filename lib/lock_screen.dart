library lock_screen;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_listenable/multi_listenable.dart';

typedef LockScreenErrorHandler = void Function(
    Object error, StackTrace stackTrace);

typedef LockScreenJob<T> = Future<T> Function(LockScreenUpdater updater);

class LockScreenCancel {
  @override
  String toString() => "Canceled";
}

/// An object to launch long operations while blocking the user interface and avoiding
/// unexpected user actions (double tap/clip, ...)
///
/// Usage :
/// ```dart
/// void longOperation( BuildContext context) async {
///   final lockScreen = LockScreen.of( context);
///   await lockScreen.forJob(
///     context,
///     job : (updater) async {
///          // long time actions
///       },
///     );
/// }
/// ```
class LockScreen extends ChangeNotifier {
  LockScreen._();

  static LockScreen of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_InheritedLockScreenWidget>();
    assert(widget != null, "LockScreenWidget not found");
    return widget!.lockScreen;
  }

  static LockScreenErrorHandler? globalErrorHandler;

  double? get progress => _progress;

  String? get message => _message;

  Widget? get showWidget => _showWidget;

  /// Await for the [job] result while locking UI interaction.
  ///
  /// If [showWidget] is specified, it is displayed during [job] execution.
  /// Otherwise, a box of ([width], [height]) dimension is displayed, containing a progress
  /// indicator, the [operation] string (if not null), the [message] string (if not null) and
  /// then [cancelButton] (if not null).
  ///
  /// If [autoCancel] == true and [cancelButton] == null, a default cancel button is displayed.
  ///
  /// The [job] function receive an [LockScreenUpdater] object permitting to change this display
  /// at any moment during [job] execution.
  ///
  /// [job] function call during execution of another job is allowed.
  Future<T> forJob<T>(
    BuildContext context, {
    required LockScreenJob job,
    String? operation,
    String? message,
    double? progress,
    Widget? showWidget,
    Widget? cancelButton,
    double width = 300,
    double height = 200,
    bool autoCancel = false,
    String autoCancelText = "Cancel",
    IconData? autoCancelIcon = Icons.cancel_outlined,
    LockScreenErrorHandler? onError,
  }) async {
    final saveMessage = _message;
    final saveProgress = _progress;
    final saveCancelButton = _cancelButton;
    final saveWidget = _showWidget;
    final saveOperation = _operation;
    final saveWidth = _width;
    final saveHeight = _height;
    final saveFocus = FocusManager.instance.primaryFocus;
    _message = message;
    _progress = progress;
    _cancelButton = cancelButton;
    _showWidget = showWidget;
    _operation = operation;
    _width = width;
    _height = height;
    operation ??= "";
    _locks++;
    _focusNode.requestFocus();
    final updater = LockScreenUpdater._(this);
    if (_cancelButton != null) {
      _cancelButton = TextButton(
        onPressed: () => updater.cancelOperation(),
        child: _cancelButton!,
      );
    } else if (autoCancel) {
      _cancelButton = autoCancelIcon == null
          ? TextButton(
              onPressed: updater.cancelOperation,
              autofocus: true,
              child: Text(autoCancelText),
            )
          : TextButton.icon(
              onPressed: updater.cancelOperation,
              autofocus: true,
              icon: Icon(autoCancelIcon, color: Colors.red),
              label: Text(autoCancelText),
            );
    }
    notifyListeners();
    try {
      return await job(updater);
    } catch (e, s) {
      final handler = onError ?? globalErrorHandler;
      if (e is LockScreenCancel) {
        if (kDebugMode) {
          print("$operation canceled");
        }
        if (_locks > 1) rethrow;
      } else if (handler != null) {
        handler(e, s);
      } else if (kDebugMode) {
        print("$operation$e\n$s");
      }
      rethrow;
    } finally {
      _message = saveMessage;
      _progress = saveProgress;
      _cancelButton = saveCancelButton;
      _showWidget = saveWidget;
      _operation = saveOperation;
      _width = saveWidth;
      _height = saveHeight;
      saveFocus?.requestFocus();
      _locks--;
      notifyListeners();
    }
  }

  void _setMessage(String? value) {
    if (value == message) return;
    _message = value;
    notifyListeners();
  }

  void _setProgress(double? value) {
    value = value?.clamp(0, 1);
    if (value == progress) return;
    _progress = value;
    notifyListeners();
  }

  void _setShowWidget(Widget? value) {
    _showWidget = value;
    notifyListeners();
  }

  void _setCancelButton(Widget? value) {
    _cancelButton = value;
    notifyListeners();
  }

  String? _operation;
  String? _message;
  double? _progress;
  Widget? _showWidget;
  Widget? _cancelButton;
  double _width = 0;
  double _height = 0;
  int _locks = 0;
  final _focusNode = FocusScopeNode();
}

/// Allow lock screen updates during job processing
class LockScreenUpdater {
  LockScreenUpdater._(this.lockScreen);

  final LockScreen lockScreen;

  void progress() {
    if (_stop) throw LockScreenCancel();
  }

  /// Change the message displayed on lock screen
  void setMessage(String? message) {
    progress();
    lockScreen._setMessage(message);
  }

  /// Change the progress indicator displayed on lock screen.
  ///
  /// If [value] is null,
  /// display a progress indicator without percentage value.
  /// If [value] is not null, it is clamped between 0 and 1.
  void setProgress(double? value) {
    progress();
    lockScreen._setProgress(value);
  }

  /// Allow to replace all default lock screen content.
  ///
  /// if [widget] is null, the lock screen display a progress indicator,
  /// the [LockScreen.operation] (if not null), the [LockScreen.message]
  /// (if not null) and the [LockScreen.cancelButton] (if not null).
  ///
  /// If [widget] is not null, the lock screen contains only this widget.
  /// Job cancelation can be done only programatically.
  void showWidget(Widget? widget) {
    progress();
    lockScreen._setShowWidget(widget);
  }

  /// Allow to cancel the current operation.
  ///
  /// If [cancelButton] is null, the operation can't be cancelled by the user.
  /// It could be programatically cancel by calling [cancelOperation] or
  /// by throwing [LockScreenCancel].
  void setCancelButton(Widget? cancelButton) =>
      lockScreen._setCancelButton(cancelButton);

  /// Cancel the current operation
  void cancelOperation() => _stop = true;

  var _stop = false;
}

/// Allow descendants widgets to run long-time operations while locking UI interaction.
///
/// Usage :
/// ```dart
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});

///   @override
///   Widget build(BuildContext context) => MaterialApp(
///         home: LockScreenWidget(child: const HomePage()),
///       );
/// }
/// ```
/// [LockScreenWidget] can be used anywhere in your widget tree but below a [WidgetApp] descendant.
/// During long operation lauched by [LockScreen.of](context).[forJob](), all UI interactions
/// with [child] or its descandant are locked.
class LockScreenWidget extends StatelessWidget {
  LockScreenWidget({
    super.key,
    required this.child,
    this.color = Colors.black,
  });

  final lockScreen = LockScreen._();

  final Widget child;

  final Color color;

  @override
  Widget build(BuildContext context) => _InheritedLockScreenWidget(
        lockScreen,
        child: _ScreenAccessLocker(
          lockScreen: lockScreen,
          color: color,
          child: child,
        ),
      );
}

class _InheritedLockScreenWidget extends InheritedWidget {
  const _InheritedLockScreenWidget(
    this.lockScreen, {
    required super.child,
  });

  final LockScreen lockScreen;

  @override
  bool updateShouldNotify(_InheritedLockScreenWidget oldWidget) => false;
}

class _ScreenAccessLocker extends StatelessWidget {
  const _ScreenAccessLocker({
    required this.lockScreen,
    required this.child,
    required this.color,
  });

  final LockScreen lockScreen;

  final Widget child;

  final Color color;

  @override
  Widget build(BuildContext context) {
    const vSpace = SizedBox(height: 16);

    return Material(
      child: Stack(
        children: [
          child,
          MultiListenableBuilder(
            listenables: [lockScreen],
            builder: (context) => lockScreen._locks > 0
                ? FocusScope(
                    node: lockScreen._focusNode,
                    autofocus: true,
                    child: Listener(
                      behavior: HitTestBehavior.deferToChild,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints.expand(),
                        child: ColoredBox(
                          color: color.withAlpha(64),
                          child: Center(
                            child: lockScreen._showWidget ??
                                Container(
                                  width: lockScreen._width,
                                  height: lockScreen._height,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator.adaptive(
                                        value: lockScreen.progress,
                                      ),
                                      if (lockScreen._operation != null) ...[
                                        vSpace,
                                        Text(lockScreen._operation!,
                                            softWrap: true),
                                      ],
                                      vSpace,
                                      Expanded(
                                        child: lockScreen.message == null
                                            ? const SizedBox.shrink()
                                            : SingleChildScrollView(
                                                child: Text(
                                                  lockScreen.message!,
                                                  softWrap: true,
                                                ),
                                              ),
                                      ),
                                      if (lockScreen._cancelButton != null) ...[
                                        const Divider(height: 32),
                                        lockScreen._cancelButton!,
                                      ],
                                    ],
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

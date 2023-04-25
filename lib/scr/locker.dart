part of lock_screen;

class LockScreen<T> {
  static Future<T?> forJob<T>({
    required BuildContext context,
    required LockScreenJob job,
    LockScreenDisplay display = const _LockScreenDisplay(),
    String? operation,
    LockScreenErrorHandler? onError,
    VoidCallback? whenError,
  }) {
    onError ??= _defaultErrorHandler;
    final locker = LockScreen<T>._(display, operation);
    // Lock all screen interation
    final dialog = _LockScreenDialog(
      lockScreen: locker,
      lockStateChange: locker._notifyChanges,
      display: locker._proxy,
      operation: operation,
    );
    dialog.showLockScreenDialog(context);

    return locker._runJob(context, dialog, job, onError, whenError);
  }

  LockScreenDisplay get display => _display;
  set display(LockScreenDisplay value) {
    _display = value;
    _changed();
  }

  // Private part

  LockScreen._(this._display, this._operation) {
    _proxy = _LockScreenDisplayProxy<T>(this);
  }

  Future<T?> _runJob(
    BuildContext context,
    _LockScreenDialog dialog,
    LockScreenJob job,
    LockScreenErrorHandler onError,
    VoidCallback? whenError,
  ) async {
    final pred = _lockerStack.isEmpty ? null : _lockerStack.last;
    _lockerStack.add(this);
    try {
      pred?._changed();
      return await job(_proxy);
    } catch (e, s) {
      await dialog.close();
      if (whenError != null) whenError();
      if (e is LockScreenCancelError) {
        if (pred != null) rethrow;
        if (kDebugMode) print("$_operation canceled");
      } else {
        if (context.mounted) await onError(context, e, s);
      }
      return null;
    } finally {
      _lockerStack.removeLast();
      dialog.close().ignore();
      pred?._changed();
    }
  }

  void _setDisplay(LockScreenDisplay display) {
    this.display = display;
    _notifyChanges.value++;
  }

  void _changed() => _notifyChanges.value++;

  final String? _operation;

  final _notifyChanges = ValueNotifier(0);

  late LockScreenDisplay _display;

  late final _LockScreenDisplayProxy<T> _proxy;
}

Future<void> _defaultErrorHandler(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) async {
  if (kDebugMode) print("$error\n$stackTrace");
  if (!context.mounted) return;
  return showDialog(
    context: context,
    barrierColor: Colors.white.withOpacity(0.5),
    builder: (context) {
      const textStyle = TextStyle(
        fontSize: 16,
        color: Colors.white,
      );
      return Dialog(
        backgroundColor: Colors.red,
        alignment: Alignment.center,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 0.5 * MediaQuery.of(context).size.width,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 32,
            ),
            child: Text("$error", softWrap: true, style: textStyle),
          ),
        ),
      );
    },
  );
}

final _lockerStack = <LockScreen>[];

part of lock_screen;

class LockScreen<T> {
  static LockScreenErrorHandler? defaultErrorHandler;

  static NavigatorObserver get observer => _ObserveNavigation.create();

  static Future<T?> forJob<T>({
    required BuildContext context,
    required LockScreenJob job,
    LockScreenDisplay display = const _LockScreenDisplay(),
    String? operation,
    LockScreenErrorHandler? onError,
  }) {
    final locker = LockScreen<T>._(display, operation);
    // Lock all screen interation
    final dialog = _LockScreenDialog(
      lockScreen: locker,
      lockStateChange: locker._notifyChanges,
      display: locker._proxy,
      operation: operation,
    );
    dialog.showLockScreenDialog(context);

    return locker._runJob(dialog, job, onError);
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
    _LockScreenDialog dialog,
    LockScreenJob job,
    LockScreenErrorHandler? onError,
  ) async {
    final pred = _lockerStack.isEmpty ? null : _lockerStack.last;
    _lockerStack.add(this);
    try {
      pred?._changed();
      return await job(_proxy);
    } catch (e, s) {
      final handler = onError ?? defaultErrorHandler;
      await dialog.close();
      if (e is LockScreenCancelError) {
        if (pred != null) rethrow;
        if (kDebugMode) {
          print("$_operation canceled");
        }
      } else if (handler != null) {
        final handled = handler(e, s);
        if (handled is Future) await handled;
      } else if (kDebugMode) {
        print(
          "${_operation == null ? "Error while running job" : _operation!} : $e\n$s",
        );
      }
      return null;
    } finally {
      _lockerStack.removeLast();
      await dialog.close();
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

final _lockerStack = <LockScreen>[];

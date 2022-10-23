part of lock_screen;

class LockScreen {
  static LockScreenErrorHandler? defaultErrorHandler;

  static Future forJob({
    required BuildContext context,
    required LockScreenJob job,
    LockScreenDisplay display = const _LockScreenDisplay(),
    String? operation,
    LockScreenErrorHandler? onError,
  }) {
    final locker = LockScreen._(
      context,
      display,
      operation,
    );

    return locker.runJob(job, onError);
  }

  LockScreenDisplay get display => _display;
  set display(LockScreenDisplay value) {
    _display = value;
    _changed();
  }

  // Private part

  LockScreen._(
    this._context,
    this._display,
    this._operation,
  ) {
    _proxy = _LockScreenDisplayProxy(this);
  }

  Future runJob(
    LockScreenJob job,
    LockScreenErrorHandler? onError,
  ) async {
    final pred = _lockerStack.isEmpty ? null : _lockerStack.last;
    _lockerStack.add(this);
    try {
      pred?._changed();
      _showDialog().ignore();
      return await job(_proxy);
    } catch (e, s) {
      final handler = onError ?? defaultErrorHandler;
      if (e is LockScreenCancelError) {
        if (pred != null) rethrow;
        if (kDebugMode) {
          print("$_operation canceled");
        }
      } else if (handler != null) {
        handler(e, s);
      } else if (kDebugMode) {
        print(
          "${_operation == null ? "Error while running job" : _operation!} : $e\n$s",
        );
      }
    } finally {
      _lockerStack.removeLast();
      _mustPopDialog = true;
      _changed();
      pred?._changed();
    }
  }

  void _setDisplay(LockScreenDisplay display) {
    this.display = display;
    _notifyChanges.value++;
  }

  Future<void> _showDialog() {
    return showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder(
        valueListenable: _notifyChanges,
        builder: (context, value, child) {
          if (_mustPopDialog) {
            // Pop the dialog as soon as possible
            Future.delayed(
              const Duration(milliseconds: 0),
              () => Navigator.of(context).pop(),
            );
            // Don't pop twice
            _mustPopDialog = false;
          }
          return _lockerStack.isEmpty || _lockerStack.last != this
              ? const SizedBox.shrink()
              : Dialog(
                  alignment: Alignment.center,
                  child: FocusScope(
                    node: _focusNode,
                    autofocus: true,
                    child: Listener(
                      behavior: HitTestBehavior.deferToChild,
                      child: ValueListenableBuilder(
                        valueListenable: _notifyChanges,
                        builder: (context, _, __) => _dialogContent(context),
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _dialogContent(BuildContext context) {
    final userWidget = display.showWidget;
    final btnCancel = display.cancelButton == LockScreenCancel.none
        ? null
        : _wrapCancelButton(context, display.cancelButton);
    const vSpace = SizedBox(height: 16);

    return userWidget != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              userWidget,
              if (btnCancel != null) const Divider(),
              if (btnCancel != null) btnCancel,
            ],
          )
        : Container(
            width: display.width ?? 300,
            height: display.height,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: (display.height == null)
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator.adaptive(value: display.progress),
                if (_operation != null) ...[
                  vSpace,
                  Text(_operation!, softWrap: true),
                ],
                vSpace,
                _messageWidget(context),
                if (btnCancel != null) ...[
                  const Divider(height: 32),
                  btnCancel,
                ],
              ],
            ),
          );
  }

  Widget _messageWidget(BuildContext context) {
    final msg = display.message;
    if (msg == null) return const SizedBox.shrink();
    final widget = Text(
      display.message!,
      softWrap: true,
    );
    if (display.height == null) return widget;
    return Expanded(
      child: SingleChildScrollView(child: widget),
    );
  }

  Widget _wrapCancelButton(BuildContext context, Widget button) =>
      GestureDetector(
        onTap: () => display = display.abort(),
        child: button,
      );

  void _changed() => _notifyChanges.value++;

  final BuildContext _context;

  final String? _operation;

  final _focusNode = FocusScopeNode();

  final _notifyChanges = ValueNotifier(0);

  late LockScreenDisplay _display;

  late final _LockScreenDisplayProxy _proxy;

  var _mustPopDialog = false;
}

final _lockerStack = <LockScreen>[];

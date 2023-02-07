part of lock_screen;

class _LockScreenDialog {
  _LockScreenDialog({
    required this.lockScreen,
    required this.lockStateChange,
    required this.display,
    this.operation,
  });

  final LockScreen lockScreen;

  final ValueNotifier<int> lockStateChange;

  late LockScreenDisplay display;

  final String? operation;

  Future<dynamic> close() {
    _mustPopDialog = true;
    lockStateChange.value++;
    return _closeCompleter.future;
  }

  void showLockScreenDialog(BuildContext initialContext) {
    final observer = _DialogNavigationObserver(this);

    void restoreNavigatorState(BuildContext context) {
      if (observer.dialogClosed) {
        if (!_completeCalled) {
          _completeCalled = true;
          _closeCompleter.complete();
        }
      } else if (observer.canCloseDialog) {
        Navigator.of(context, rootNavigator: true).pop();
        assert(observer.dialogClosed);
        assert(!_completeCalled);
        _closeCompleter.complete();
        _completeCalled = true;
        observer.dispose();
      }
    }

    showGeneralDialog(
      context: initialContext,
      barrierDismissible: false,
      barrierColor: Colors.white.withOpacity(0.3),
      transitionDuration: Duration.zero,
      useRootNavigator: true,
      pageBuilder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: lockStateChange,
          builder: (context, value, child) {
            if (_mustPopDialog) {
              // Pop the dialog as soon as possible
              Future.microtask(() => restoreNavigatorState(context));
              return const SizedBox.shrink();
            }
            return _lockerStack.isEmpty || _lockerStack.last != lockScreen
                ? const SizedBox.shrink()
                : Dialog(
                    elevation: 8,
                    insetAnimationDuration: Duration.zero,
                    shadowColor: Colors.grey,
                    alignment: Alignment.center,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                      Radius.circular(28.0),
                    )),
                    child: FocusScope(
                      node: _focusNode,
                      autofocus: true,
                      child: Listener(
                        behavior: HitTestBehavior.deferToChild,
                        child: _dialogContent(context),
                      ),
                    ),
                  );
          },
        );
      },
    ).ignore();
  }

  Widget _dialogContent(BuildContext context) {
    const vSpace = SizedBox(height: 16);
    final userWidget = display.showWidget;
    final btnCancel = display.cancelButton == LockScreenCancel.none
        ? null
        : _wrapCancelButton(context, display.cancelButton);

    return userWidget == null
        ? Container(
            width: display.width ?? 360,
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
                if (operation != null) ...[
                  Text(operation!, softWrap: true),
                  vSpace,
                ],
                if (display.progress == null) ...[
                  const CircularProgressIndicator.adaptive(),
                  vSpace,
                ],
                _messageWidget(context),
                if (display.progress != null) ...[
                  vSpace,
                  LinearProgressIndicator(
                    value: display.progress,
                  ),
                ],
                if (btnCancel != null) ...[
                  const Divider(height: 32),
                  btnCancel,
                ],
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              userWidget,
              if (btnCancel != null) const Divider(),
              if (btnCancel != null) btnCancel,
            ],
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

  final _focusNode = FocusScopeNode();

  bool _mustPopDialog = false;
  bool _completeCalled = false;
  final _closeCompleter = Completer();
}

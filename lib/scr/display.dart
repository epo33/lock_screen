part of lock_screen;

abstract class LockScreenDisplay<T> {
  factory LockScreenDisplay({bool autoCancel = false}) => _LockScreenDisplay<T>(
        cancelButton: autoCancel ? const LockScreenCancel() : null,
      );

  double? get progress;

  String? get message;

  Widget? get showWidget;

  LockScreenCancel? get cancelButton;

  bool get aborted;

  double? get width;

  double? get height;

  LockScreenDisplay copyWith({
    double? progress,
    String? message,
    Widget? showWidget,
    LockScreenCancel? cancelButton,
    double? width,
    double? height,
  });

  LockScreenDisplay setProgress(double? progress);

  LockScreenDisplay setMesssage(String? message);

  LockScreenDisplay setShowWidget(Widget? showWidget);

  LockScreenDisplay setCancelButton(LockScreenCancel? cancelButton);

  LockScreenDisplay abort();
}

class _LockScreenDisplay<T> implements LockScreenDisplay<T> {
  const _LockScreenDisplay({
    this.progress,
    this.message,
    this.showWidget,
    this.cancelButton,
    this.width,
    this.height,
    this.aborted = false,
  });

  @override
  final double? progress;

  @override
  final String? message;

  @override
  final Widget? showWidget;

  @override
  final LockScreenCancel? cancelButton;

  @override
  final double? width;

  @override
  final double? height;

  @override
  final bool aborted;

  @override
  LockScreenDisplay copyWith({
    double? progress,
    String? message,
    Widget? showWidget,
    double? width,
    double? height,
    LockScreenCancel? cancelButton,
    T? jobResult,
  }) =>
      _LockScreenDisplay(
        progress: progress ?? this.progress,
        message: message ?? this.message,
        showWidget: showWidget ?? this.showWidget,
        cancelButton: cancelButton ?? this.cancelButton,
        width: width ?? this.width,
        height: height ?? this.height,
        aborted: aborted,
      );

  @override
  LockScreenDisplay setProgress(double? progress) => _LockScreenDisplay(
        progress: progress,
        message: message,
        showWidget: showWidget,
        width: width,
        height: height,
        cancelButton: cancelButton,
        aborted: aborted,
      );

  @override
  LockScreenDisplay setMesssage(String? message) => _LockScreenDisplay(
        progress: progress,
        message: message,
        showWidget: showWidget,
        width: width,
        height: height,
        cancelButton: cancelButton,
        aborted: aborted,
      );

  @override
  LockScreenDisplay setShowWidget(Widget? showWidget) => _LockScreenDisplay(
        progress: progress,
        message: message,
        showWidget: showWidget,
        width: width,
        height: height,
        cancelButton: cancelButton,
        aborted: aborted,
      );

  @override
  LockScreenDisplay setCancelButton(LockScreenCancel? cancelButton) =>
      _LockScreenDisplay(
        progress: progress,
        message: message,
        showWidget: showWidget,
        width: width,
        height: height,
        cancelButton: cancelButton,
        aborted: aborted,
      );

  @override
  LockScreenDisplay abort() => aborted
      ? this
      : _LockScreenDisplay(
          progress: progress,
          message: message,
          showWidget: showWidget,
          width: width,
          height: height,
          cancelButton: cancelButton,
          aborted: true,
        );
}

class _LockScreenDisplayProxy<T> implements LockScreenDisplay<T> {
  const _LockScreenDisplayProxy(this.lockScreen);

  final LockScreen lockScreen;

  @override
  double? get progress => _display.progress?.clamp(0, 1);

  @override
  String? get message => _display.message;

  @override
  Widget? get showWidget => _display.showWidget;

  @override
  LockScreenCancel? get cancelButton => _display.cancelButton;

  @override
  double? get width => _display.width;

  @override
  double? get height => _display.height;

  @override
  bool get aborted => _display.aborted;

  @override
  LockScreenDisplay copyWith({
    double? progress,
    String? message,
    Widget? showWidget,
    double? width,
    double? height,
    LockScreenCancel? cancelButton,
    T? jobResult,
  }) =>
      _setDisplay(
        _display.copyWith(
          progress: progress ?? this.progress,
          message: message ?? this.message,
          showWidget: showWidget ?? this.showWidget,
          width: width,
          height: height,
          cancelButton: cancelButton ?? this.cancelButton,
        ),
      );

  @override
  LockScreenDisplay setProgress(double? progress) => _setDisplay(
        _display.copyWith(
          progress: progress,
          message: message,
          showWidget: showWidget,
          width: width,
          height: height,
          cancelButton: cancelButton,
        ),
      );

  @override
  LockScreenDisplay setMesssage(String? message) => _setDisplay(
        _display.copyWith(
          progress: progress,
          message: message,
          showWidget: showWidget,
          width: width,
          height: height,
          cancelButton: cancelButton,
        ),
      );

  @override
  LockScreenDisplay setShowWidget(Widget? showWidget) => _setDisplay(
        _display.copyWith(
          progress: progress,
          message: message,
          showWidget: showWidget,
          width: width,
          height: height,
          cancelButton: cancelButton,
        ),
      );

  @override
  LockScreenDisplay setCancelButton(LockScreenCancel? cancelButton) =>
      _setDisplay(
        _display.copyWith(
          progress: progress,
          message: message,
          showWidget: showWidget,
          width: width,
          height: height,
          cancelButton: cancelButton,
        ),
      );

  @override
  LockScreenDisplay abort() => aborted
      ? this
      : _setDisplay(
          _LockScreenDisplay(
            progress: progress,
            message: message,
            showWidget: showWidget,
            width: width,
            height: height,
            cancelButton: cancelButton,
            aborted: true,
          ),
        );

  LockScreenDisplay get _display => lockScreen.display;
  LockScreenDisplay _setDisplay(LockScreenDisplay value) {
    lockScreen._setDisplay(value);
    if (aborted) throw LockScreenCancelError();
    return this;
  }
}

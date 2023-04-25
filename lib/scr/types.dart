part of lock_screen;

/// A function called if an error is throw during job execution.
///
/// Not called if the job is canceled.
///
/// Must throw an error to propagate the error to the (eventual) including job.
typedef LockScreenErrorHandler = Future<void> Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
);

typedef LockScreenJob<T> = Future<T> Function(LockScreenDisplay display);

class LockScreenCancelError {
  @override
  String toString() => "Canceled";
}

library lock_screen;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'scr/cancel_button.dart';
part 'scr/display.dart';
part 'scr/locker.dart';

/// A function called if an error is throw during job execution.
///
/// Not called if the job is canceled.
///
/// Must throw an error to propagate the error to the (eventual) including job.
typedef LockScreenErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

typedef LockScreenJob<T> = Future<T> Function(LockScreenDisplay display);

class LockScreenCancelError {
  @override
  String toString() => "Canceled";
}

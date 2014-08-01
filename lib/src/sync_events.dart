part of sync_events;

/**
 * The [AutoResetEvent] is a synchronization event which automatically resets
 * the event after the signal.
 */
class AutoResetEvent extends EventWaitHandle {
  AutoResetEvent(bool signaled) : super(signaled, EventResetMode.AUTO_RESET);
}


/**
 * The [EventResetMode] is used for indicate the reset mode of the events.
 */
class EventResetMode {
  /**
   * Auto reset mode.
   */
  static const EventResetMode AUTO_RESET = const EventResetMode("AUTO_RESET");

  /**
   * Manual reset mode.
   */
  static const EventResetMode MANUAL_RESET = const EventResetMode("MANUAL_RESET"
      );

  /**
   * Name of the event reset mode.
   */
  final String name;

  const EventResetMode(this.name);
}

/**
 * The event wait handle is a synchronization event.
 */
class EventWaitHandle extends WaitHandle {
  List<Completer<bool>> _queue = <Completer<bool>>[];

  EventResetMode _mode;

  bool _signaled = false;

  /**
   * Intializes a new instance of the event wait handle.
   */
  EventWaitHandle(bool signaled, EventResetMode mode) {
    if (signaled == null) {
      throw new ArgumentError("signaled: $signaled");
    }

    if (mode == null) {
      throw new ArgumentError("mode: $mode");
    }

    _mode = mode;
    _signaled = signaled;
  }

  /**
   * Sets the state of the event to nonsignaled.
   */
  void reset() {
    _signaled = false;
  }

  /**
   * Sets the state of the event to signaled.
   */
  void set() {
    if (_mode == EventResetMode.AUTO_RESET) {
      _setAuto();
    } else {
      _setManual();
    }
  }

  /**
   * Waits until the current event wait handle receives a signal, using a
   * duration to specify the time interval.
   */
  Future<bool> waitOne({Duration timeout}) {
    if (timeout == Duration.ZERO) {
      return new Future.value(_signaled);
    }

    if (_signaled) {
      if (_mode == EventResetMode.AUTO_RESET) {
        _signaled = false;
      }

      return new Future.value(true);
    }

    var completer = new Completer<bool>();
    _queue.add(completer);
    if (timeout != null) {
      new Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
    }

    return completer.future;
  }

  void _setAuto() {
    _signaled = true;
    while (_queue.length != 0) {
      var completer = _queue.removeAt(0);
      if (!completer.isCompleted) {
        completer.complete(true);
        _signaled = false;
        break;
      }
    }
  }

  void _setManual() {
    _signaled = true;
    for (var completer in _queue) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }

    _queue.clear();
  }
}

/**
 * The [ManualResetEvent] is a synchronization event which does not resets
 * automatically after the signal.
 */
class ManualResetEvent extends EventWaitHandle {
  ManualResetEvent(bool signaled) : super(signaled, EventResetMode.MANUAL_RESET
      );
}

/**
 *  The wait handle is a synchronization event.
 */
abstract class WaitHandle {
  /**
   * Signals for one event and waiting for a signal from the other event.
   */
  static Future signalAndWait(WaitHandle toSignal, WaitHandle
      toWaitOn, {Duration timeout}) {
    throw new UnimplementedError("WaitHandle.signalAndWait()");
  }

  /**
   * Waits for all of the handles to receive a signal.
   */
  static Future<bool> waitAll(List<WaitHandle> waitHandles, {Duration timeout})
      {
    if (waitHandles == null) {
      throw new ArgumentError("waitHandles: $waitHandles");
    }

    if (waitHandles.length == 0) {
      throw new ArgumentError("The list of wait handles cannot be empty.");
    }

    var completer = new Completer<bool>();
    var length = waitHandles.length;
    var pending = length;
    for (var i = 0; i < length; i++) {
      var waitHandle = waitHandles[i];
      if (waitHandle == null) {
        throw new ArgumentError(
            "The list of wait handles contains illegal elements.");
      }

      var timedOut = false;
      waitHandle.waitOne(timeout: timeout).then((inTime) {
        if (!inTime) {
          timedOut = true;
        }

        if (--pending == 0) {
          if (timedOut) {
            completer.complete(false);
          } else {
            completer.complete(true);
          }
        }
      });
    }

    return completer.future;
  }

  /**
   * Waits for any of the handles to receive a signal and returns the list index
   * of the handle that satisfied the wait.
   */
  static Future<int> waitAny(List<WaitHandle> waitHandles, {Duration timeout}) {
    if (waitHandles == null) {
      throw new ArgumentError("waitHandles: $waitHandles");
    }

    if (waitHandles.length == 0) {
      throw new ArgumentError("The list of wait handles cannot be empty.");
    }

    var completer = new Completer<int>();
    var length = waitHandles.length;
    for (var i = 0; i < length; i++) {
      var waitHandle = waitHandles[i];
      if (waitHandle == null) {
        throw new ArgumentError(
            "The list of wait handles contains illegal elements.");
      }

      waitHandle.waitOne(timeout: timeout).then((inTime) {
        if (!completer.isCompleted) {
          if (inTime) {
            completer.complete(i);
          } else {
            completer.complete(-1);
          }
        }
      });
    }

    return completer.future;
  }

  /**
   * Waits until the current wait handle receives a signal, using a duration to
   * specify the time interval.
   */
  Future<bool> waitOne({Duration timeout});
}

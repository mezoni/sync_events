import "dart:async";
import "package:sync_events/sync_events.dart";
import "package:unittest/unittest.dart";

void main() {
  testAutoResetEventWaitOne();
  testManualResetEventWaitOne();
  testWaitHandleWaitAll();
  testWaitHandleWaitAny();
}

void testAutoResetEventWaitOne() {
  var ready = new AutoResetEvent(false);
  var go = new AutoResetEvent(false);
  String message;
  var messages = <String>["one", "two", "three"];
  var results = [];

  // Sets "ready", waits "go"
  void work() {
    Function loop;
    loop = () {
      ready.set();
      go.waitOne().then((_) {
        if (message == null) {
          return;
        }

        results.add(message);
        Timer.run(loop);
      });
    };

    Timer.run(loop);
  }

  // Start work
  work();

  // Sets "go", waits "ready"
  Future test() {
    var completer = new Completer();
    var counter = messages.length;
    Function loop;
    var index = 0;
    loop = () {
      if (index >= counter) {
        completer.complete();
        return;
      }

      message = messages[index++];
      go.set();
      ready.waitOne().then((_) {
        Timer.run(loop);
      });
    };

    Timer.run(loop);
    return completer.future;
  }

  test().then((_) {
    expect(results, messages, reason: "ARE.waitOne()");
  });
}

void testManualResetEventWaitOne() {
  // ManualResetEvent(false)
  var value1 = false;
  var mre1 = new ManualResetEvent(false);
  mre1.waitOne().then((_) {
    expect(value1, true, reason: "MRE(false) => waitOne()");
  });

  Timer.run(() {
    value1 = true;
    mre1.set();
  });

  // ManualResetEvent(true)
  var value2 = false;
  var mre2 = new ManualResetEvent(true);
  mre2.waitOne().then((_) {
    expect(value2, false, reason: "MRE(true) => waitOne()");
  });

  Timer.run(() {
    value2 = true;
    mre2.set();
  });

  // ManualResetEvent(false), waitOne(timeout)
  var value3 = false;
  var mre3 = new ManualResetEvent(false);
  mre3.waitOne(timeout: new Duration(seconds: 1)).then((inTime) {
    expect(value3, false, reason: "MRE(false) => waitOne(timeout)");
    expect(inTime, false, reason: "MRE(false) => waitOne(timeout)");
  });

  new Timer(new Duration(seconds: 2), () {
    value3 = true;
    mre3.set();
  });

  // ManualResetEvent(true), waitOne(timeout)
  var value4 = false;
  var mre4 = new ManualResetEvent(true);
  mre4.waitOne(timeout: new Duration(seconds: 1)).then((inTime) {
    expect(value3, false, reason: "MRE(true) => waitOne(timeout)");
    expect(inTime, true, reason: "MRE(true) => waitOne(timeout)");
  });

  new Timer(new Duration(seconds: 2), () {
    value4 = true;
    mre4.set();
  });
}

void testWaitHandleWaitAll() {
  // WaitAll
  var count1 = 5;
  var waitHandles1 = <WaitHandle>[];
  for (var i = 0; i < count1; i++) {
    waitHandles1.add(new ManualResetEvent(false));
  }

  WaitHandle.waitAll(waitHandles1).then((waitState) {
    expect(waitState, true, reason: "WaitHandle.waitAll()");
  });

  for (var i = 0; i < count1; i++) {
    var waitHandle = waitHandles1[i];
    waitHandle.set();
  }

  // WaitAll with timeout, timed out
  var count2 = 5;
  var waitHandles2 = <WaitHandle>[];
  for (var i = 0; i < count2; i++) {
    waitHandles2.add(new ManualResetEvent(false));
  }

  WaitHandle.waitAll(waitHandles2, timeout: new Duration(seconds: 1)).then(
      (waitState) {
    expect(waitState, false, reason: "WH.waitAll(), timed out");
  });

  for (var i = 0; i < count2; i++) {
    new Timer(new Duration(seconds: 2), () {
      var waitHandle = waitHandles2[i];
      waitHandle.set();
    });
  }

  // WaitAll with timeout, in time
  var count3 = 5;
  var waitHandles3 = <WaitHandle>[];
  for (var i = 0; i < count3; i++) {
    waitHandles3.add(new ManualResetEvent(false));
  }

  WaitHandle.waitAll(waitHandles3, timeout: new Duration(seconds: 2)).then(
      (waitState) {
    expect(waitState, true, reason: "WH.waitAll(), in time");
  });

  for (var i = 0; i < count3; i++) {
    new Timer(new Duration(seconds: 1), () {
      var waitHandle = waitHandles3[i];
      waitHandle.set();
    });
  }
}


void testWaitHandleWaitAny() {
  // WaitAny
  var count1 = 5;
  var waitHandles1 = <WaitHandle>[];
  for (var i = 0; i < count1; i++) {
    waitHandles1.add(new ManualResetEvent(false));
  }

  WaitHandle.waitAny(waitHandles1).then((index) {
    expect(index, 0, reason: "WaitHandle.waitAny()");
  });

  for (var i = 0; i < count1; i++) {
    var waitHandle = waitHandles1[i];
    waitHandle.set();
  }

  // WaitAny with timeout, timed out
  var count2 = 5;
  var waitHandles2 = <WaitHandle>[];
  for (var i = 0; i < count2; i++) {
    waitHandles2.add(new ManualResetEvent(false));
  }

  WaitHandle.waitAny(waitHandles2, timeout: new Duration(seconds: 1)).then(
      (index) {
    expect(index, -1, reason: "WH.waitAny(), timed out");
  });

  for (var i = 0; i < count2; i++) {
    new Timer(new Duration(seconds: 2), () {
      var waitHandle = waitHandles2[i];
      waitHandle.set();
    });
  }

  // WaitAny with timeout, in time
  var count3 = 5;
  var waitHandles3 = <WaitHandle>[];
  for (var i = 0; i < count3; i++) {
    waitHandles3.add(new ManualResetEvent(false));
  }

  WaitHandle.waitAny(waitHandles3, timeout: new Duration(seconds: 2)).then(
      (index) {
    expect(index, 0, reason: "WH.waitAny(), in time");
  });

  for (var i = 0; i < count3; i++) {
    new Timer(new Duration(seconds: 1), () {
      var waitHandle = waitHandles3[i];
      waitHandle.set();
    });
  }
}

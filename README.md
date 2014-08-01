sync_events
===========

The synchronization events are events that allows easily synchronize operations with shared resources (AutoResetEvent, ManualResetEvent).

The `Ping-Pong` example.

```dart
import "dart:async";
import "package:sync_events/sync_events.dart";

void main() {
  ping();
  pong();
}

var pingEvent = new AutoResetEvent(false);
var pongEvent = new AutoResetEvent(false);

/*
void ping() {
  print("ping");
  busy(new Duration(seconds: 1));
  pingEvent.set();
  await pongEvent.waitOne()
  Timer.run(ping);
}
*/
void ping() {
  print("ping");
  busy(new Duration(seconds: 1));
  pingEvent.set();
  pongEvent.waitOne().then((_) {
    Timer.run(ping);
  });
}

/*
void pong() {
  print("pong");
  busy(new Duration(seconds: 1));
  pongEvent.set();
  await pingEvent.waitOne()
  Timer.run(pong);
}
*/
void pong() {
  print("pong");
  busy(new Duration(seconds: 1));
  pongEvent.set();
  pingEvent.waitOne().then((_) {
    Timer.run(pong);
  });
}

void busy(Duration time) {
  var sw = new Stopwatch();
  sw.start();
  while(true) {
    if(sw.elapsedMicroseconds >= time.inMicroseconds) {
      break;
    }
  }
}
```

The consumption of the shared resources.

```dart
import "package:sync_events/sync_events.dart";
import "dart:async";

void main() {
  var oneSecond = new Duration(seconds: 1);
  var twoSecond = new Duration(seconds: 2);
  var timeLimit = oneSecond;
  var mre = new ManualResetEvent(false);
  fillData(mre, twoSecond);
  consumeData("One", mre);
  consumeData("Two", mre, timeout: timeLimit);
}

List globalData;

Future consumeData(String name, ManualResetEvent mre, {Duration timeout}) {
  print("$name: event.waitOne()");
  return mre.waitOne(timeout: timeout).then((inTime) {
    if (inTime) {
      print("$name: Continue after event.waitOne()");
      print("$name: globalData: $globalData");
    } else {
      print("$name: Timed out: event.waitOne()");
      print("$name: globalData: <unavailable>");
    }
  });
}

Future fillData(ManualResetEvent mre, Duration delay) {
  return new Future(() {
    new Timer(new Duration(seconds: 2), () {
      print("fillData(): filling globalData");
      globalData = [1, 2, 3];
      print("fillData(): event.set()");
      mre.set();
    });
  });
}
```

Output:

```
Observatory listening on http://127.0.0.1:59214
One: event.waitOne()
Two: event.waitOne()
Two: Timed out: event.waitOne()
Two: globalData: <unavailable>
fillData(): filling globalData
fillData(): event.set()
One: Continue after event.waitOne()
One: globalData: [1, 2, 3]
```

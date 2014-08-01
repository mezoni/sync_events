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

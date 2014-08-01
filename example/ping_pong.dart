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

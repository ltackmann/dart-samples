import "dart:async";
import "dart:io";
import '../../handheld/packages/unittest/unittest.dart';

// TODO http://www.dartlang.org/articles/using-future-based-apis/ (Futures.wait + chains)
/// Test http://api.dartlang.org/docs/releases/latest/dart_async.html
void main() {
  group("future -", () {
    test("testing with completion", () {
      var compute = new Compute();    
      var future = compute.sumIt([1, 2, 3]);
      expect(future, completion(equals(6)));
    });
    
    test("testing with expectAsync", () {
      var compute = new Compute();
      compute.sumIt([1, 2, 3]).then(expectAsync1((int sum) {
        expect(sum, equals(6));
      }));
    });
    
    test("return immediatly", () {
      Future<bool> isOnline() => new Future.immediate(true);
      
      expect(isOnline(), completion(equals(true)));
    });
    
    test("convert sync function into async", () {
      bool checkConnection() => false; 
      Future<bool> asyncCheckConnection() => new Future.of(checkConnection);
      
      expect(asyncCheckConnection(), completion(equals(false)));
    });
    
    test("run command after completion", () {
      var hasRun = false;
      var compute = new Compute();
      compute.sumIt([1, 2, 3]).then(expectAsync1((int sum) {
        expect(sum, equals(6));
        hasRun = true;
      })).whenComplete(() {
        expect(hasRun, isTrue);
      });
    });
    
    test("bundle multiple async calls together", () {
    });
  });
  
  group("stream -", () {
    test("construct and consume unicast stream (single-subscriber) stream", () {
      var data = <int>[1,2,3,4,5]; 
      var stream = new Stream<int>.fromIterable(data);  
      expect(stream.isBroadcast, isFalse);
      
      var sum = 0;
      stream.listen((int value) {      
        sum += value;
      }).onDone(() {
        expect(sum, equals(16));
      });  
    });
    
    test("construct and consume broadcast (multiple subscriber) stream", () {
      var data = <int>[1,2,3,4,5]; 
      var stream = (new Stream<int>.fromIterable(data)).asBroadcastStream();  
      expect(stream.isBroadcast, isTrue);
      
      var sumUneven = 0;
      var sumEven = 0;
      
      StreamSubscription<int> subscriber1 = stream.where((value) => value % 2 == 0).listen((int value) => sumEven += value);
      StreamSubscription<int> subscriber2 = stream.where((value) => value % 2 != 0).listen((int value) => sumUneven += value);
      subscriber1.onDone(() => expect(sumEven, equals(6)));  
      subscriber2.onDone(() => expect(sumUneven, equals(9)));  
    });
    
    test("stream transformation", () {
      var data = <int>[1,2,3,4,5]; 
      var stream = new Stream<int>.fromIterable(data);  
      
      var transformer = new StreamTransformer(handleData: (value, sink) {
        // transform the value in the stream
        sink.add(value * -1);
      });
      
      var sum = 0;
      stream.transform(transformer).listen((int value) {
        sum += value;
      }).onDone(() {
        expect(sum, equals(-15));
      });  
    });
    
    solo_test("query stream", () {
      var data = <int>[1,2,3,4,5]; 
      var stream = new Stream<int>.fromIterable(data).asBroadcastStream();  
      
      expect(stream.any((v) => v < 0), completion(isFalse));
      expect(stream.contains(1), completion(isTrue));
      expect(stream.every((v) => v > 0), completion(isTrue));
    });
  });
  
  //TODO StreamConsumer<S, T>
  //TODO StreamSink<T>
  //TODO Sink
}

/** Helpers */
class Compute {
  Future<int> sumIt(List<int> data) {
    var completer = new Completer<int>();
    int sum = data.reduce(0, (a,b) => a+b);
    completer.complete(sum);
    return completer.future;
  }
}

  



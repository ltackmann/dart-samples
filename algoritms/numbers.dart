
import 'package:meta/meta.dart';

/**
 * Represent numbers as a linked list of bits
 */
class Natural implements Comparable<Natural> {
  static const Bit ZeroBit = const Bit("0");
  static const Bit OneBit = const Bit("1");

  static const Natural Zero = const Natural._internal(null, ZeroBit);
  static const Natural One = const Natural._internal(Zero, OneBit);

  final Natural tail;
  final Bit head;

  /**
   *  Represent binary numbers as linked list { tail : head } where the numeric
   *  value is 2 * tail + head (as we are in base two). i.e
   *    {null : 0} = [0] = 0
   *    { {null : 0} : 1 } = [01] = 1
   *    { { {null : 0} : 1 } : 0} = [010] = 2
   */
  const Natural._internal(this.tail, this.head);

  factory Natural(Natural tail, Bit head) {
    if (identical(tail, Zero)) {
        return head == ZeroBit ? Zero : One;
    }
    return new Natural._internal(tail, head);
  }

  // ---------
  // operators
  // ---------

  Natural operator +(Natural other) {
    if (other == null) {
      throw new ArgumentError("null argument in addition");
    }
    return _add(this, other);
  }

  Natural operator *(Natural other) {
    if (other == null) {
        throw new ArgumentError("null argument in multiplication");
    }
    return _multiply(this, other);
  }

  Natural operator ^(Natural exponent) {
    if (exponent == null) {
        throw new ArgumentError("null exponent in power");
    }
    return _power(this, exponent);
  }

  Natural operator -(Natural other) {
    if (other == null) {
        throw new ArgumentError("null argument in subtraction");
    }
    return _subtract(this, other);
  }

  bool operator <(Natural other) { return _compareTo(this, other) < 0; }

  bool operator >( Natural other) { return _compareTo(this, other) > 0; }

  bool operator <=(Natural other) { return _compareTo(this, other) <= 0; }

  bool operator >=( Natural other) { return _compareTo(this, other) >= 0; }

  bool operator ==(Natural other) { return _compareTo(this, other) == 0; }

  // -------
  // methods
  // -------

  @override
  int compareTo(Natural other) { return _compareTo(this, other); }

  @override
  int get hashCode => asInteger;

  int get asInteger {
    if (identical(this, Zero)) {
      return 0;
    }
    return (this.head == ZeroBit ? 0 : 1) + 2 * this.tail.asInteger;
  }

  @override
  String toString() {
    if (identical(this, Zero)) {
      return "0";
    }
    return tail.toString() + head.toString();
  }

  Natural get increment =>_add(this, One);

  Natural get decrement => _subtract(this, One);

  // ----------------
  // internal statics
  // ----------------

   // x + y  = { xtail : xhead } + { ytail : yhead }
   //        = (2 * xtail + xhead) + (2 * ytail + yhead)
   //        = 2 * (xtail + ytail) + (xhead + yhead)
  static Natural _add(Natural x, Natural y) {
    if (identical(x, Zero)) {
        // 0 + y = y
        return y;
    } else if (identical(y, Zero)) {
        // 0 + x = x
        return x;
    } else if (x.head == ZeroBit) {
        // {xtail : 0} + {ytail : yhead}  = 2 * (xtail + ytail) + (0 + yhead)
        //                                = { xtail + ytail : yhead }
        return new Natural(_add(x.tail, y.tail), y.head);
    } else if (y.head == ZeroBit) {
        // {xtail : xhead} + {ytail : 0}  = 2 * (xtail + ytail) + (xhead + 0)
        //                                = { xtail + ytail : xhead }
        return new Natural(_add(x.tail, y.tail), x.head);
    } else {
        // {xtail : 1} + {ytail : 1} = (2 * xtail + 1) + (2 * ytail + 1)
        //                           = 2 * (xtail + ytail) + 2
        //                           = 2 * (xtail + ytail + 1)
        //                           = { xtail + ytail + 1 : 0 }
        return new Natural(_add(_add(x.tail, y.tail), One), ZeroBit);
    }
  }

  // x * y  = { xtail : xhead } * { ytail : yhead }
  static Natural _multiply(Natural x, Natural y) {
    if (identical(x, Zero)) {
      // y * 0 = 0
      return Zero;
    } else if (identical(y, Zero)) {
      // x * 0 = 0
      return Zero;
    } else if (identical(x, One)) {
      // 1 * y = y
      return y;
    } else if (identical(y, One)) {
      // 1 * x = x
      return x;
    } else if (x.head == ZeroBit) {
      // { xtail : 0 } * y  = ( 2 * xtail + 0 ) * y
      //                    = 2 * xtail * y
      //                    = { xtail * y : 0 }
      return new Natural(_multiply(x.tail, y), ZeroBit);
    } else if (y.head == ZeroBit) {
      // x * { ytail : 0 }  = x * ( 2 * ytail + 0 )
      //                    = 2 * x * ytail
      //                    = { x * ytail : 0 }
      return new Natural(_multiply(x, y.tail), ZeroBit);
    } else {
      // x * { ytail : 1 } = x * ( 2 * ytail + 1 )
      //                  = x * 2 * ytail + x
      //                  = 2 * x * ytail + x
      //                  = { x * ytail : 0 } + x
      return _add(new Natural(_multiply(x, y.tail), ZeroBit), x);
    }
  }

  // x^y = x^(2 * ytail + yhead)
  //     = x^ytail * x^ytail * x^yhead
  static Natural _power(Natural x, Natural y) {
    if (identical(y, Zero)) {
      return One;
    } else {
      var p = _power(x, y.tail);
      var result = _multiply(p, p);
      if (y.head == OneBit) {
        result = _multiply(result, x);
      }
      return result;
    }
  }

  //   x - y
  static Natural _subtract(Natural x, Natural y) {
    if (identical(x, y)) {
      // 2-2 = 0
      return Zero;
    } else if (identical(y, Zero)) {
      // x - 0 = x
      return x;
    } else if (identical(x, Zero)) {
      throw new ArgumentError("Cannot subtract greater natural from lesser natural");
    } else if (x.head == y.head) {
        // { xtail : h } - { ytail : h }  = 2 * xtail + h - 2 * ytail - h
        //                                = 2 * (xtail - ytail)
        //                                = { xtail - ytail : 0 }
      return new Natural(_subtract(x.tail, y.tail), ZeroBit);
    } else if (x.head == OneBit) {
      // { xtail : 1 } - { ytail : 0 }  = 2 * xtail + 1 - (2 * ytail + 0)
      //                                = 2 * xtail + 1 - 2 * ytail
      //                                = 2 * (xtail - ytail) + 1
      //                                = { xtail - ytail : 1 }
      return new Natural(_subtract(x.tail, y.tail), OneBit);
    } else {
      // { xtail : 0 } - { ytail : 1 }  = 2 * xtail + 0 - (2 * ytail + 1)
      //                                = 2 * xtail - 2 - 2 * ytail - 1 + 2
      //                                = 2 * (xtail - 1 - ytail) + 1
      //                                = { xtail - 1 - ytail : 1 }
      return new Natural(_subtract(_subtract(x.tail, One), y.tail), OneBit);
    }
  }

  // negative means x < y
  // positive means x > y
  // zero means x == y
  // two nulls are equal
  // otherwise, null is always smaller
  static int _compareTo(Natural x, Natural y) {
    if (identical(x, y)) {
      return 0;
    } else if (x == null) {
      return -1;
    } else if (y == null) {
      return 1;
    } else if (identical(x, Zero)) {
      return -1;
    } else if (identical(y, Zero)) {
      return 1;
    } else if (x.head == y.head) {
      return _compareTo(x.tail, y.tail);
    } else if (x.head == ZeroBit) {
      return _compareTo(x.tail, y.tail) > 0 ? 1 : -1;
    } else {
      return _compareTo(x.tail, y.tail) < 0 ? -1 : 1;
    }
  }
}

class Bit {
  final String value;

  const Bit(this.value);

  String toString() => this.value;
}

main() {
  var zero = Natural.Zero;
  print("zero is $zero [0]");
  var one = Natural.One;
  print("one is $one [01]");

  // addition
  var two = one + one;
  print("addition of 1+1 is $two [010]");
  var three  = two + one;
  print("addition of 2 + 1 is $three [011]");
  var five = three + two;
  print("addition of 3 + 2 is $five [0101]");

  // increment
  print("increment of 1 is ${one.increment}");

  // multiply
  var mult = two * three * five;
  print("multiplication of 2*3*5 is $mult [011110]");

  // power
  var power = two^three;
  print("power of 2^3 is $power [01000]");

  // subtract
  var sub = three - two;
  print("subtraction 3 - 2 is $sub [01]");

  // decrement
  print("decrement of 1 is ${sub.decrement} [0]");

  // <
  print("comparison [1 < 1] is ${one < one}");
  print("comparison [2 < 3] is ${two < three}");
  print("comparison [2 < 1] is ${two < one}");
  print("comparison [2 < null] is ${two < null}");

  // >
  print("comparison [1 > 1] is ${one > one}");
  print("comparison [2 > 3] is ${two > three}");
  print("comparison [2 > 1] is ${two > one}");
  print("comparison [2 > null] is ${two > null}");

  // <=
  print("comparison [1 <= 1] is ${one <= one}");
  print("comparison [2 <= 3] is ${two <= three}");
  print("comparison [2 <= 1] is ${two <= one}");
  print("comparison [2 <= null] is ${two <= null}");

  // >=
  print("comparison [1 >= 1] is ${one >= one}");
  print("comparison [2 >= 3] is ${two >= three}");
  print("comparison [2 >= 1] is ${two >= one}");
  print("comparison [2 >= null] is ${two >= null}");

  //==
  print("comparison [1 == 1] is ${one == one}");
  print("comparison [2 == 3] is ${two == three}");
  print("comparison [2 == 1] is ${two == one}");
  print("comparison [2 == null] is ${two == null}");

  // compareTo
  print("comparison [1 compareTo 1] is ${one.compareTo(one)}");
  print("comparison [2 compareTo 3] is ${two.compareTo(three)}");
  print("comparison [2 compareTo 1] is ${two.compareTo(one)}");
  print("comparison [2 compareTo null] is ${two.compareTo(null)}");

  // hashCode
  print("hashCode [zero] is ${zero.hashCode}");
  print("hashCode [one] is ${one.hashCode}");

  // asInteger
  print("asInteger [two] is ${two.asInteger}");
  print("asInteger [three] is ${three.asInteger}");
  print("asInteger [five] is ${five.asInteger}");
}

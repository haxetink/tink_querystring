package;

import tink.querystring.Builder;
import tink.querystring.Keymaker;

@:asserts
class KeymakerTest {
  final bracket = new BracketKeymaker();
  final dot = new DotKeymaker();
  public function new() {}
  
  public function test() {
    final builder = new Builder<{x:{y:Int, z:Array<Int>}}>();
    
    asserts.assert(builder.stringify({x:{y:1, z:[2]}}) == 'x.y=1&x.z%5B0%5D=2');
    asserts.assert(builder.stringify({x:{y:1, z:[2]}}, bracket) == 'x%5By%5D=1&x%5Bz%5D%5B0%5D=2');
    asserts.assert(builder.stringify({x:{y:1, z:[2]}}, dot) == 'x.y=1&x.z.0=2');
    
    return asserts.done();
  }
}

class BracketKeymaker implements Keymaker {
  public function new() {}
  public function field(name:String, field:String):String return '$name[$field]';
  public function index(name:String, index:Int):String return '$name[$index]';
}

class DotKeymaker implements Keymaker {
  public function new() {}
  public function field(name:String, field:String):String return '$name.$field';
  public function index(name:String, index:Int):String return '$name.$index';
}
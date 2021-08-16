package;

import tink.querystring.Builder;
import haxe.DynamicAccess;

using tink.CoreApi;
using StringTools;

@:asserts
class QueryBuilderTest { 
  
  public function new() {}
  
  public function anon() {
    var b = new Builder<{x:Int, y:{?z:Int}}>();
    var s = b.stringify({x: 1, y: {}});
    asserts.assert(s == 'x=1');
    var s = b.stringify({x: 1, y: {z:2}});
    asserts.assert(s == 'x=1&y.z=2');
    
    return asserts.done();
  }
  
  public function array() {
    var b = new Builder<{x:Array<Int>}>();
    var s = b.stringify({x: []});
    asserts.assert(s == '');
    var s = b.stringify({x: [1]});
    asserts.assert(s == 'x%5B0%5D=1');
    var s = b.stringify({x: [1, 2]});
    asserts.assert(s == 'x%5B0%5D=1&x%5B1%5D=2');
    
    var b = new Builder<{?x:Array<Int>}>();
    var s = b.stringify({x: null});
    asserts.assert(s == '');
    var s = b.stringify({x: []});
    asserts.assert(s == '');
    var s = b.stringify({x: [1]});
    asserts.assert(s == 'x%5B0%5D=1');
    var s = b.stringify({x: [1, 2]});
    asserts.assert(s == 'x%5B0%5D=1&x%5B1%5D=2');
    return asserts.done();
  }
  
  // public function map() {
  //   var b = new Builder<{x:Map<Int, String>}>();
  //   var s = b.stringify({x: [1 => 'foo', 2 => 'bar']});
  //   asserts.assert(s == 'x%5B0%5D=1&x%5B1%5D=2');
    
  //   var b = new Builder<{x:Map<String, Int>}>();
  //   var parsed = b.parse('x[foo]=0&x.bar=1');
  //   asserts.assert(parsed.x['foo'] == 0);
  //   asserts.assert(parsed.x['bar'] == 1);
    
  //   return asserts.done();
  // }
  
  public function dyn() {
    var b = new Builder<{x: Dynamic<String>}>();
    var s = b.stringify({x: {foo: 'foo', bar: 'bar'}});
    asserts.assert(s == 'x.foo=foo&x.bar=bar');
    
    var b = new Builder<{x: Dynamic<Int>}>();
    var s = b.stringify({x: {foo: 1, bar: 2}});
    asserts.assert(s == 'x.foo=1&x.bar=2');
    
    return asserts.done();
  }
  
  public function dynAccess() {
    var b = new Builder<{x: DynamicAccess<String>}>();
    var s = b.stringify({x: {foo: 'foo', bar: 'bar'}});
    asserts.assert(s == 'x.foo=foo&x.bar=bar');
    
    var b = new Builder<{x: DynamicAccess<Int>}>();
    var s = b.stringify({x: {foo: 1, bar: 2}});
    asserts.assert(s == 'x.foo=1&x.bar=2');
    
    return asserts.done();
  }
}
package;

import tink.QueryString;
import tink.url.Portion;
import tink.url.Query;
import tink.querystring.Parser;
import haxe.DynamicAccess;
import haxe.io.Bytes;

using tink.CoreApi;
using StringTools;

@:asserts
class QueryParserTest { 
  
  public function new() {}

  // public function base() {
  //   /*
  //    * The keen observer may notice that the test below tests the implementation - which is why the `@:privateAccess` is there.
  //    * This is not really necessary, but given that the macro generated parsers depend on it,
  //    * it is helpful to test it in isolation, to be able to better locate bugs in the generated parsers.
  //    */
  //   var strings = [
  //     'o%5B0%5D%5Ba%5D = 1 & o%5B1%5D%5Bc%5D = 1 & x.c = 3 & o%5B1%5D%5Bd%5D.x = 2 & o%5B0%5D%5Bb%5D = 2',
  //     'o[0][a]=1 & o[1][c]= 1 & x.c =3 & o[1][d].x= 2& o[0][b] = 2',
  //   ];
  //   for (string in strings) {
  //     var dummy = new ParserBase<Any, Portion, Any>();
      
  //     var exists = @:privateAccess {
  //       dummy.init(Query.parseString(string), function (p) return p.name, function (p) return p.value);
  //       dummy.exists;
  //     }
      
  //     var a = [for (k in exists.keys()) k];
  //     a.sort(Reflect.compare);
      
  //     asserts.assert('o,o[0],o[0][a],o[0][b],o[1],o[1][c],o[1][d],o[1][d].x,x,x.c' == a.join(','));
  //   }
  //   return asserts.done();
  // }

  public function formField() {
    var o:{
      @:formField('foo-bar') var fooBar:Int;
    } = { fooBar: 4 };
    asserts.assert('foo-bar=4' == tink.QueryString.build(o));
    o = tink.QueryString.parse('foo-bar=12');
    asserts.assert(12 == o.fooBar);
    return asserts.done();
  }
  
  public function anon() {
    var p = new Parser<{x:Int, y:{?z:Int}}>();
    var parsed = p.parse('x=1');
    asserts.assert(parsed.x == 1);
    asserts.assert(parsed.y.z == null);
    var parsed = p.parse('x=1&y.z=2');
    asserts.assert(parsed.x == 1);
    asserts.assert(parsed.y.z == 2);
    var parsed = p.parse('x=1&y[z]=2');
    asserts.assert(parsed.x == 1);
    asserts.assert(parsed.y.z == 2);
    return asserts.done();
  }
  
  public function array() {
    var p = new Parser<{x:Array<Int>}>();
    var parsed = p.parse('x[0]=1&x.1=2');
    asserts.assert(parsed.x[0] == 1);
    asserts.assert(parsed.x[1] == 2);
    
    var p = new Parser<{x:Array<Int>}>();
    var parsed = p.parse('');
    asserts.assert(parsed.x.length == 0);
    
    var p = new Parser<{?x:Array<Int>}>();
    var parsed = p.parse('x[0]=1&x.1=2');
    asserts.assert(parsed.x[0] == 1);
    asserts.assert(parsed.x[1] == 2);
    return asserts.done();
  }
  
  public function map() {
    var p = new Parser<{x:Map<Int, String>}>();
    var parsed = p.parse('x[0]=foo&x.1=bar');
    asserts.assert(parsed.x[0] == 'foo');
    asserts.assert(parsed.x[1] == 'bar');
    
    var p = new Parser<{x:Map<String, Int>}>();
    var parsed = p.parse('x[foo]=0&x.bar=1');
    asserts.assert(parsed.x['foo'] == 0);
    asserts.assert(parsed.x['bar'] == 1);
    
    return asserts.done();
  }
  
  public function dyn() {
    var p = new Parser<{x:Dynamic<String>}>();
    var parsed = p.parse('x[foo]=foo&x.bar=bar');
    asserts.assert(parsed.x.foo == 'foo');
    asserts.assert(parsed.x.bar == 'bar');
    
    var p = new Parser<{x:Dynamic<Int>}>();
    var parsed = p.parse('x[foo]=0&x.bar=1');
    asserts.assert(parsed.x.foo == 0);
    asserts.assert(parsed.x.bar == 1);
    
    return asserts.done();
  }
  
  public function dynAccess() {
    var p = new Parser<{x:DynamicAccess<String>}>();
    var parsed = p.parse('x[foo]=foo&x.bar=bar');
    asserts.assert(parsed.x['foo'] == 'foo');
    asserts.assert(parsed.x['bar'] == 'bar');
    
    var p = new Parser<{x:DynamicAccess<Int>}>();
    var parsed = p.parse('x[foo]=0&x.bar=1');
    asserts.assert(parsed.x['foo'] == 0);
    asserts.assert(parsed.x['bar'] == 1);
    
    return asserts.done();
  }
  
  public function bytes() {
    var p = new Parser<{x:Bytes}>();
    var parsed = p.parse('x=QUJDRA');
    asserts.assert(parsed.x.toString() == 'ABCD');
    
    return asserts.done();
  }
  
  public function parse() {
    var o = { date: #if (cpp || cs) new Date(2017,5,5,0,0,0) #else Date.now() #end }; // TODO: cpp/cs precision issue
    var old = o.date.getTime();

    o = tink.QueryString.parse(tink.QueryString.build(o));
    asserts.assert(old == o.date.getTime());
    
    var p = new Parser<Nested>();
    var parsed = p.parse(nestedString);
    asserts.compare(nestedObject, parsed);
    return asserts.done();
  }
  
  static var nestedObject:Nested = { foo: [ { z: .0 }, { x: '100%', z: .1 }, { y: [{i:4}], z: .2 }, { x: 'yo', y: [{i:5}, {i:6}], z: 1.5e100 } ] };
  static var nestedString = 'foo[0].z=.0&foo[1].x=100%25&foo[1].z=.1&foo[2].y[0].i=4&foo[2].z=.2&foo[3].x=yo&foo[3].y[0].i=5&foo[3].y[1].i=6&foo[3].z=1.5e%2B100';
  
  public function facade() {
    var o1 = QueryString.parse((nestedString:Nested)).sure();
    asserts.assert(tink.Json.stringify(nestedObject) == tink.Json.stringify(o1));
    var o2:Nested = QueryString.parse(QueryString.build(o1));
    asserts.assert(tink.Json.stringify(nestedObject) == tink.Json.stringify(o2));
    return asserts.done();
  }
  
  public function enumAbstract() {
    var o = QueryString.parse(('e=aa':{e:MyEnumAbstract})).sure();
    asserts.assert(MyEnumAbstract.A == o.e);
    var o = QueryString.parse(('e=ab':{e:MyEnumAbstract}));
    asserts.assert(!o.isSuccess());
    return asserts.done();
  }

  public function defaultValue() {
    var o:{
      @:default(12) var foo:Int;
    } = QueryString.parse('');
    asserts.assert(12 == o.foo);
    var o:{
      @:default(42) @:optional var foo:Int;
    } = QueryString.parse('');
    asserts.assert(42 == o.foo);
    return asserts.done();
  }

  public function custom() {
    var o = {foo: new Custom(42)}
    var s = QueryString.build(o);
    asserts.assert(s == 'foo=42');
    
    o = QueryString.parse('foo=123');
    asserts.assert(o.foo.i == 123);
    return asserts.done();
  }
}

typedef Nested = { 
  foo: Array<{ 
    ?x: String, 
    ?y:Array<{ i: Int }>, 
    z:Float,
  }> 
}

@:enum
abstract MyEnumAbstract(String) {
  var A = 'aa';
  var B = 'bb';
}


@:queryStringify(v -> v.i)
@:queryParse(i -> new QueryParserTest.Custom(i))
class Custom {
  public final i:Int;
  public function new(i) {
    this.i = i;
  }
}
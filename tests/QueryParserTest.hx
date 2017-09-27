package;
import haxe.unit.TestCase;
import tink.QueryString;
import tink.url.Portion;
import tink.url.Query;
import tink.querystring.Parser;
using tink.CoreApi;
using StringTools;

class QueryParserTest extends TestCase { 

  function testBase() {
    /*
     * The keen observer may notice that the test below tests the implementation - which is why the `@:privateAccess` is there.
     * This is not really necessary, but given that the macro generated parsers depend on it,
     * it is helpful to test it in isolation, to be able to better locate bugs in the generated parsers.
     */
    var strings = [
      'o%5B0%5D%5Ba%5D = 1 & o%5B1%5D%5Bc%5D = 1 & x.c = 3 & o%5B1%5D%5Bd%5D.x = 2 & o%5B0%5D%5Bb%5D = 2',
      'o[0][a]=1 & o[1][c]= 1 & x.c =3 & o[1][d].x= 2& o[0][b] = 2',
    ];
    for (string in strings) {
      var dummy = new ParserBase<Any, Portion, Any>();
      
      var exists = @:privateAccess {
        dummy.init(Query.parseString(string), function (p) return p.name, function (p) return p.value);
        dummy.exists;
      }
      
      var a = [for (k in exists.keys()) k];
      a.sort(Reflect.compare);
      
      assertEquals('o,o[0],o[0][a],o[0][b],o[1],o[1][c],o[1][d],o[1][d].x,x,x.c', a.join(','));
    }
  }

  function testFormField() {
    var o:{
      @:formField('foo-bar') var fooBar:Int;
    } = { fooBar: 4 };
    assertEquals('foo-bar=4', tink.QueryString.build(o));
    o = tink.QueryString.parse('foo-bar=12');
    assertEquals(12, o.fooBar);
  }
  
  function testParse() {
    var o = { date: #if (cpp || cs) new Date(2017,5,5,0,0,0) #else Date.now() #end }; // TODO: cpp/cs precision issue
    var old = o.date.getTime();

    o = tink.QueryString.parse(tink.QueryString.build(o));
    assertEquals(old, o.date.getTime());
    
    var p = new Parser<Nested>();    
    var parsed = p.parse(nestedString);
    assertEquals(tink.Json.stringify(nestedObject), tink.Json.stringify(parsed));
  }
  
  static var nestedObject:Nested = { foo: [ { z: .0 }, { x: '100%', z: .1 }, { y: [{i:4}], z: .2 }, { x: 'yo', y: [{i:5}, {i:6}], z: 1.5e100 } ] };
  static var nestedString = 'foo[0].z=.0&foo[1].x=100%25&foo[1].z=.1&foo[2].y[0].i=4&foo[2].z=.2&foo[3].x=yo&foo[3].y[0].i=5&foo[3].y[1].i=6&foo[3].z=1.5e%2B100';
  
  function testFacade() {
    var o1 = QueryString.parse((nestedString:Nested)).sure();
    assertEquals(tink.Json.stringify(nestedObject), tink.Json.stringify(o1));
    var o2:Nested = QueryString.parse(QueryString.build(o1));
    assertEquals(tink.Json.stringify(nestedObject), tink.Json.stringify(o2));
  }
  
  function testEnumAbstract() {
    var o = QueryString.parse(('e=aa':{e:MyEnumAbstract})).sure();
    assertEquals(MyEnumAbstract.A, o.e);
    var o = QueryString.parse(('e=ab':{e:MyEnumAbstract}));
    assertFalse(o.isSuccess());
  }

  function testJsonExtension() {
    var options = {
      x: 123, y: 'abc'
    }
    var fragment = StringTools.urlEncode(tink.Json.stringify(options));
    var query = 'options=$fragment';
    var gen = QueryString.build(({options: options}: WithJson));
    assertEquals(query, gen);
    var out: WithJson = QueryString.parse(query);
    assertEquals(options.x, out.options.x);
    assertEquals(options.y, out.options.y);
  }
}

typedef Nested = { 
  foo: Array<{ 
    ?x: String, 
    ?y:Array<{ i: Int }>, 
    z:Float,
  }> 
}

typedef WithJson = {
  @:json var options: {
    x: Int, y: String
  }
}

@:enum
abstract MyEnumAbstract(String) {
  var A = 'aa';
  var B = 'bb';
}
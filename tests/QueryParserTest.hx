package;
import haxe.unit.TestCase;
import tink.url.Portion;
import tink.url.Query;
import tink.querystring.Parser;
using tink.CoreApi;
using StringTools;

class QueryParserTest extends TestCase { 

  function testBase() {
    /*
     * The keen observer may notice that the test below tests the implementation.
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
  
  function testParse() {
    var complex:Nested = { foo: [ { z: .0 }, { x: 'hey', z: .1 }, { y: 4, z: .2 }, { x: 'yo', y: 5, z: .3 } ] };
    var p = new Parser<Nested>();    
    var parsed = p.parse('foo[0].z=.0&foo[1].x=hey&foo[1].z=.1&foo[2].y=4&foo[2].z=.2&foo[3].x=yo&foo[3].y=5&foo[3].z=.3');
    assertEquals(tink.Json.stringify(complex), tink.Json.stringify(parsed));
  }
}

typedef Nested = { 
  foo: Array<{ 
    ?x: String, 
    ?y:Int, 
    z:Float 
  }> 
}
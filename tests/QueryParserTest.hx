package;
import haxe.unit.TestCase;
import tink.url.Query;
import tink.querystring.Parser;

class QueryParserTest extends TestCase { 

  function testBase() {
    
    var dummy = new ParserBase();
    dummy.tryParse(Query.parseString('o[0][a]=1 & o[1][c]=1 & x.c=3 & o[1][d].x=2 & o[0][b]=2'));
    var exists = @:privateAccess dummy.exists;
    
    var a = [for (k in exists.keys()) k];
    a.sort(Reflect.compare);
    
    assertEquals('o,o[0],o[0][a],o[0][b],o[1],o[1][c],o[1][d],o[1][d].x,x,x.c', a.join(','));
    
  }
  
  function testParse() {
    var complex:Nested = { foo: [ { z: .0 }, { x: 'hey', z: .1 }, { y: 4, z: .2 }, { x: 'yo', y: 5, z: .3 } ] };
    
    var p = new Parser<String, Nested>();
    var parsed = p.parse(('foo[0].z=.0&foo[1].x=hey&foo[1].z=.1&foo[2].y=4&foo[2].z=.2&foo[3].x=yo&foo[3].y=5&foo[3].z=.3':Query));
    
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
package;

import haxe.unit.TestCase;
import tink.querystring.Builder;

class QueryBuilderTest extends TestCase {

  function testSimple() {
    var builder = new Builder<{ foo: String, bar: Float }>();
    trace(builder.stringify({ foo: 'fo&o', bar: 1.2e250 }));
  }
  
}
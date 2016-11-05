package ;

import haxe.unit.*;

class Run {
  function new() {}
  static var tests:Array<TestCase> = [
    new QueryParserTest(),
  ];
  static function main() {  
    
    var r = new TestRunner();
    for (c in tests)
      r.add(c);
    
    travix.Logger.exit(
      if (r.run()) 0
      else 500
    );
  }

}
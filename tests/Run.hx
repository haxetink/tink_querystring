package ;

import haxe.unit.*;

#if flash
typedef Sys = flash.system.System;
#end

class Run {
  function new() {}
  static var tests:Array<TestCase> = [
    new QueryParserTest(),
    //new QueryComposerTest(),
  ];
  static function main() {  
    
    var r = new TestRunner();
    for (c in tests)
      r.add(c);
    
    if (!r.run())
      Sys.exit(500);
  }

}
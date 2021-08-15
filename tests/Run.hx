package ;

import tink.unit.*;
import tink.testrunner.*;

class Run {
  
  static function main() {
    Runner.run(TestBatch.make([
      new NormalizerTest(),
      new QueryParserTest(),
      new KeymakerTest(),
    ])).handle(Runner.exit);
  }

}
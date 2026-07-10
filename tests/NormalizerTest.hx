package;

import tink.querystring.Normalizer.DefaultNormalizer;
import tink.querystring.Parser.Field;

using tink.CoreApi;

@:asserts
class NormalizerTest {
  public function new() {}
  
  public function test() {
    final normalizer = new DefaultNormalizer();
    final entries = [
      new Named('foo.bar', '1'),
      new Named('foo[baz]', '2'),
      new Named('foo[deep].1', '3'),
      new Named('foo[deep].2', '4'),
      new Named('foo[deep][3]', '5'),
      new Named('foo[deep][4]', '6'),
      new Named('foo[3].y[1].i', '7'),
    ];
    
    final tree = normalizer.normalize(entries.iterator(), e -> e.name, e -> e.value);
    
    asserts.compare([
      'foo' => Field.Sub([
        'bar' => Field.Value('1'),
        'baz' => Field.Value('2'),
        'deep' => Field.Sub([
          '1' => Field.Value('3'),
          '2' => Field.Value('4'),
          '3' => Field.Value('5'),
          '4' => Field.Value('6'),
        ]),
        '3' => Field.Sub([
          'y' => Field.Sub([
            '1' => Field.Sub([
              'i' => Field.Value('7')
            ])
          ])
        ])
      ])
    ], tree, tree.toString());
    
    return asserts.done();
  }
}
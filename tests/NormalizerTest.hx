package;

import tink.querystring.Parser;

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
      'foo' => Sub([
        'bar' => Value('1'),
        'baz' => Value('2'),
        'deep' => Sub([
          '1' => Value('3'),
          '2' => Value('4'),
          '3' => Value('5'),
          '4' => Value('6'),
        ]),
        '3' => Sub([
          'y' => Sub([
            '1' => Sub([
              'i' => Value('7')
            ])
          ])
        ])
      ])
    ], tree, tree.toString());
    
    return asserts.done();
  }
}
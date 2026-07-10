package tink.querystring;

import tink.querystring.Parser.Field;
import tink.querystring.Parser.Tree;

interface Normalizer<Input, Output> {
  function normalize(input:Iterator<Input>, name:Input->String, value:Input->Output):Tree<Output>;
}

class DefaultNormalizer<Input, Output> implements Normalizer<Input, Output> {
  public function new() {}
  
  public function normalize(input:Iterator<Input>, name:Input->String, value:Input->Output):Tree<Output> {
    final root = new Tree();
    for(entry in input) iterate(root, name(entry), value(entry));
    return root;
  }
  
  function iterate(tree:Tree<Output>, key:String, value:Output, depth = 0) {
    if(depth == 0) {
      if(key == '') throw 'empty key';
      
      switch [key.indexOf('['), key.indexOf('.')] {
        case [-1, -1]:
          final field = key;
          
          switch tree[field] {
            case null: tree[field] = Field.Value(value);
            case Field.Value(v) if(v == value): // no-op
            case v: throw 'conflict: $field is already defined as $v';
          }
          
        case [i, -1] | [-1, i]:
          final field = key.substr(0, i);
          
          final sub = switch tree[field] {
            case null: 
              final sub = new Tree();
              tree[field] = Field.Sub(sub);
              sub;
            case Field.Sub(sub):
              sub;
            case v:
              throw 'conflict: $field is already defined as $v';
          }
          iterate(sub, key.substr(i), value, depth + 1);
          
        case [i, j]:
          // TODO: DRY
          final index = i > j ? j : i;
          final field = key.substr(0, index);
          
          final sub = switch tree[field] {
            case null: 
              final sub = new Tree();
              tree[field] = Field.Sub(sub);
              sub;
            case Field.Sub(sub):
              sub;
            case v:
              throw 'conflict: $field is already defined as $v';
          }
          iterate(sub, key.substr(index), value, depth + 1);
      }
      
    } else {
      final bracket = key.charCodeAt(0) == '['.code;
      
      if(bracket) {
        switch [key.indexOf(']['), key.indexOf('].')] {
          case [-1, -1]:
            final field = key.substring(1, key.length - 1);
            switch tree[field] {
              case null: tree[field] = Field.Value(value);
              case v: throw 'conflict: $field is already defined as $v';
            }
            
          case [i, -1] | [-1, i]:
            final field = key.substring(1, i);
            
            final sub = switch tree[field] {
              case null: 
                final sub = new Tree();
                tree[field] = Field.Sub(sub);
                sub;
              case Field.Sub(sub):
                sub;
              case v:
                throw 'conflict: $field is already defined as $v';
            }
            iterate(sub, key.substr(i + 1), value, depth + 1);
            
          case [i, j]:
            final index = i > j ? j : i;
            final field = key.substring(1, index);
            
            final sub = switch tree[field] {
              case null: 
                final sub = new Tree();
                tree[field] = Field.Sub(sub);
                sub;
              case Field.Sub(sub):
                sub;
              case v:
                throw 'conflict: $field is already defined as $v';
            }
            iterate(sub, key.substr(index + 1), value, depth + 1);
        }
      } else {
        switch [key.indexOf('['), key.indexOf('.', 1)] {
          case [-1, -1]:
            final field = key.substr(1);
            switch tree[field] {
              case null: tree[field] = Field.Value(value);
              case v: throw 'conflict: $field is already defined as $v';
            }
            
          case [i, -1] | [-1, i]:
            final field = key.substring(1, i);
            
            final sub = switch tree[field] {
              case null: 
                final sub = new Tree();
                tree[field] = Field.Sub(sub);
                sub;
              case Field.Sub(sub):
                sub;
              case v:
                throw 'conflict: $field is already defined as $v';
            }
            iterate(sub, key.substr(i), value, depth + 1);
            
          case [i, j]:
            final index = i > j ? j : i;
            final field = key.substring(1, index);
            
            final sub = switch tree[field] {
              case null: 
                final sub = new Tree();
                tree[field] = Field.Sub(sub);
                sub;
              case Field.Sub(sub):
                sub;
              case v:
                throw 'conflict: $field is already defined as $v';
            }
            iterate(sub, key.substr(index), value, depth + 1);
        }
      }
      
    }
  }
}

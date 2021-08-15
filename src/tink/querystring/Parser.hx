package tink.querystring;

import tink.core.Error.Pos;

using tink.CoreApi;

@:genericBuild(tink.querystring.macros.GenParser.build())
class Parser<Flow> {}

class ParserBase<Input, Value, Result> { 
  
  var root:Tree<Value>;
  var onError:Callback<{ name:String, reason:String }>;
  var pos:Pos;
  
  public var result(default, null):Outcome<Result, Error>;
  
  public function new(?onError, ?pos) {     
    this.pos = pos;    
    this.onError = switch onError {
      case null: abort;
      case v: v;
    }
  }
  
  function init<A>(input:Iterator<A>, name:A->String, value:A->Value) {
    this.root = new DefaultNormalizer().normalize(input, name, value);
  }
 
  function abort(e)
    throw error('${e.reason} for ${e.name}');

  public function parse(input:Input):Result 
    return throw Error.withData(NotImplemented, 'not implemented', pos);
    
  public function tryParse(input)
    return 
      try Success(parse(input))
      catch (e:Error) Failure(e)
      catch (e:Dynamic) Failure(error('Parse Error', e));

  function attempt<T>(field:String, o:Outcome<T, Error>):Null<T> 
    return switch o {
      case Success(v): v;
      case Failure(e): fail(field, e.message);
    }
    
  function error(reason:String, ?data:Dynamic)
    return Error.withData(UnprocessableEntity, reason, data, pos);
    
  function fail(field:String, reason:String):Dynamic {
    onError.invoke({ name:field, reason: reason });
    return null;
  }
    
  function missing(name:String):Dynamic 
    return fail(name, 'Missing value');
}

@:using(tink.querystring.Parser.FieldTools)
enum Field<V> {
  Sub(sub:Tree<V>);
  Value(v:V);
}

class FieldTools {
  public static function toString<V>(f:Field<V>):String {
    return switch f {
      case Value(v): Std.string(v);
      case Sub(tree): tree.toString();
    }
  }
}

@:forward(exists, keyValueIterator, iterator)
abstract Tree<V>(Map<String, Field<V>>) from Map<String, Field<V>> to Map<String, Field<V>> {
  public inline function new() 
    this = [];
  
  @:arrayAccess
  public inline function get(key:String):Field<V>
    return this[key];
  
  @:arrayAccess
  public inline function set(key:String, value:Field<V>):Field<V>
    return this[key] = value;
  
  public function toString()
    return str('');
  
  function str(indent:String) {
    final buf = new StringBuf();
    buf.add('{\n');
    for(key => value in this)
      switch value {
        case Value(v):
          buf.add(indent + '  $key: "$v",\n');
        case Sub(sub):
          buf.add(indent + '  $key: ${sub.str(indent + '  ')},\n');
      }
    buf.add(indent + '}');
    return buf.toString();
  }
}

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
    // trace(haxe.Json.stringify(key), 1);
    if(depth == 0) {
      if(key == '') return; // this should probably throw
      
      switch [key.indexOf('['), key.indexOf('.')] {
        case [-1, -1]:
          final field = key;
          
          switch tree[field] {
            case null: tree[field] = Value(value);
            case v: throw 'conflict: $field is already defined as $v';
          }
          
        case [i, -1] | [-1, i]:
          final field = key.substr(0, i);
          
          final sub = switch tree[field] {
            case null: 
              final sub = new Tree();
              tree[field] = Sub(sub);
              sub;
            case Sub(sub):
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
              tree[field] = Sub(sub);
              sub;
            case Sub(sub):
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
              case null: tree[field] = Value(value);
              case v: throw 'conflict: $field is already defined as $v';
            }
            
          case [i, -1] | [-1, i]:
            final field = key.substring(1, i);
            
            final sub = switch tree[field] {
              case null: 
                final sub = new Tree();
                tree[field] = Sub(sub);
                sub;
              case Sub(sub):
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
                tree[field] = Sub(sub);
                sub;
              case Sub(sub):
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
              case null: tree[field] = Value(value);
              case v: throw 'conflict: $field is already defined as $v';
            }
            
          case [i, -1] | [-1, i]:
            trace('here');
            final field = key.substring(1, i);
            
            final sub = switch tree[field] {
              case null: 
                final sub = new Tree();
                tree[field] = Sub(sub);
                sub;
              case Sub(sub):
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
                tree[field] = Sub(sub);
                sub;
              case Sub(sub):
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
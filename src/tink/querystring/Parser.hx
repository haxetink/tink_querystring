package tink.querystring;

import tink.core.Error.Pos;
import tink.querystring.Normalizer;
import tink.querystring.Normalizer.DefaultNormalizer;

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
  
  function init<A>(input:Iterator<A>, name:A->String, value:A->Value, ?normalizer:Normalizer<A, Value>) {
    if (normalizer == null)
      normalizer = new DefaultNormalizer();
    this.root = normalizer.normalize(input, name, value);
  }
 
  function abort(e)
    throw error('${e.reason} for ${e.name}');

  public function parse(input:Input, ?normalizer:Normalizer<Dynamic, Value>):Result 
    return throw Error.withData(NotImplemented, 'not implemented', pos);
    
  public function tryParse(input:Input, ?normalizer:Normalizer<Dynamic, Value>)
    return 
      try Success(parse(input, normalizer))
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
  
  public static function getSub<V>(field:Field<V>, substitute = true):Tree<V> {
    return
      if(substitute && field == null)
        new Tree();  // example: for `{x:Array<Int>}` we want to be able to parse an empty input into `{x: []}`
      else switch field {
        case Sub(v): v;
        case Value(_): throw 'unexpected primitive';
      }
  }
  
  public static function getValue<V>(field:Field<V>):V {
    return switch field {
      case Sub(_):  throw 'unexpected object/array';
      case Value(v): v;
    }
  }
  
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

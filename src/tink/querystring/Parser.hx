package tink.querystring;

import tink.core.Error.Pos;

using tink.CoreApi;

@:genericBuild(tink.querystring.macros.GenParser.build())
class Parser<Flow> {}

class ParserBase<Input, Value, Result> { 
  
  var params:Map<String, Value>;//TODO: consider storing a true hierarchy
  var exists:Map<String, Bool>;
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
    this.params = new Map();
    this.exists = new Map();
    
    if (input != null) 
      for (pair in input) {
        var name = name(pair);
        params[name] = value(pair);
        var end = name.length;
        
        while (end > 0) {
          
          name = name.substring(0, end);
          
          if (exists[name]) break;
          
          exists[name] = true;
          
          switch [name.lastIndexOf('[', end), name.lastIndexOf('.', end)] {
            case [a, b] if (a > b): end = a;
            case [_, b]: end = b;
          }
        }
      }
        
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
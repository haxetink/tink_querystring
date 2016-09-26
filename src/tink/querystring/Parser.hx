package tink.querystring;

import tink.core.Error.Pos;

using tink.CoreApi;

@:genericBuild(tink.querystring.macros.GenParser.build())
class Parser<Flow> {}

class ParserBase<Input, Value, Result> { 
  
  var params:Map<String, Value>;//TODO: consider storing a true hierarchy
  var exists:Map<String, Bool>;
  var onError:Error->Void;
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
 
  static function abort(e:Error)
    throw e;

  public function parse(input:Input):Result 
    return throw Error.withData(NotImplemented, 'not implemented', pos);
    
  public function tryParse(input)
    return 
      try Success(parse(input))
      catch (e:Error) Failure(e)
      catch (e:Dynamic) Failure(error('Parse Error', e));
    
  function error(reason:String, ?data:Dynamic)
    return Error.withData(UnprocessableEntity, reason, data, pos);
    
  function fail(reason:String, ?data:Dynamic):Dynamic {
    onError(error(reason, data));
    return null;
  }
    
  function missing(name:String):Dynamic 
    return fail('Missing parameter $name');
}
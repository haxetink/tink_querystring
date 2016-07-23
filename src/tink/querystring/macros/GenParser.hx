package tink.querystring.macros;

import haxe.macro.Context;
import tink.macro.BuildCache;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.typecrawler.Crawler;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using haxe.macro.TypeTools;
using tink.MacroApi;

class GenParser { 
  
  var name:String;
  
  var valueType:Type;
  var resultType:Type;
  var keyType:Type;
  
  var value:ComplexType;
  var result:ComplexType;
  var key:ComplexType;
  
  var pos:Position;
  var _int:Expr;
  var _float:Expr;
  var _string:Expr;
  
  function new(name, keyType, valueType, resultType, pos) {
    this.pos = pos;
    this.name = name;
    
    this.valueType = valueType;
    this.resultType = resultType;
    this.keyType = keyType;
    
    this.value = valueType.toComplex();
    this.result = resultType.toComplex();
    this.key = keyType.toComplex();
    
    this._string = 
      if ((macro ((null:$value):String)).typeof().isSuccess()) 
        prim(macro : String);
      else 
        pos.error('${value.toString()} should be compatible with String');
        
    this._int =
      if ((macro ((null:$value):Int)).typeof().isSuccess())
        prim(macro : Int);
      else
        macro this.parseInt($ { prim(macro : String) } );
        
    this._float =
      if ((macro ((null:$value):Float)).typeof().isSuccess())
        prim(macro : Float);
      else
        macro this.parseFloat(${prim(macro : String)});
  }
  
  public function get() {
    var crawl = Crawler.crawl(resultType, pos, this);
    
    var ret = macro class $name extends tink.querystring.Parser.ParserBase<$key, $value, $result> {
      
      override function doParse() {
        var prefix = '';
        return ${crawl.expr};
      }
      
      override function keyToString(key:$key):String
        return key;
    }
    
    ret.fields = ret.fields.concat(crawl.fields);
    
    return ret;    
  }

  static function buildNew(ctx:BuildContext3) 
    return new GenParser(ctx.name, ctx.type, ctx.type2, ctx.type3, ctx.pos).get();    
  
  static public function build() 
    return BuildCache.getType3('tink.querystring.Parser', buildNew);
    
  public function args():Array<String> 
    return ['prefix'];
    
  public function nullable(e:Expr):Expr 
    return 
      macro 
        if (exists[prefix]) $e;
        else null;
  
  function prim(wanted:ComplexType) 
    return 
      macro 
        if (exists[prefix]) ((params[prefix]:$value):$wanted);
        else missing(prefix); 
    
  public function string():Expr 
    return _string;
    
  public function float():Expr
    return _float;
  
  public function int():Expr 
    return _int;
    
  public function dyn(e:Expr, ct:ComplexType):Expr {
    return throw "not implemented";
  }
  public function dynAccess(e:Expr):Expr {
    return throw "not implemented";
  }
  public function bool():Expr {
    return macro (${string()}) == 'true';
  }
  public function date():Expr {
    return throw "not implemented";
  }
  public function bytes():Expr {
    return throw "not implemented";
  }
  
  public function anon(fields:Array<FieldInfo>, ct:ComplexType):Function {
    var ret = [];
    for (f in fields)
      ret.push( { 
        field: f.name, 
        expr: macro {
          var prefix = switch prefix {
            case '': $v{f.name};
            case v: v + $v{ '.' + f.name};
          }
          ${f.expr};
        } 
      });
    return (macro function (prefix:String):$ct {
      return ${EObjectDecl(ret).at()};
    }).getFunction().sure();
  }
  
  public function array(e:Expr):Expr {
    return macro {
      
      var counter = 0,
          ret = [];
      
      while (true) {
        var prefix = prefix + '[' + counter + ']';
        
        if (exists[prefix]) {
          ret.push($e);
          counter++;
        }
        else break;
      }
      
      ret;
    }
  }
  public function map(k:Expr, v:Expr):Expr {
    return throw "not implemented";
  }
  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr {
    return throw "not implemented";
  }
  public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr> {
    return Some(prim(t.toComplex()));
  }
  public function reject(t:Type):String {
    return 'Cannot parse ${t.toString()}';
  }    
}
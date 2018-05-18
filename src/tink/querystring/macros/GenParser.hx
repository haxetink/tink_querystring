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
using tink.CoreApi;

class GenParser { 
  
  var name:String;
  
  var valueType:Type;
  var resultType:Type;
  var inputType:Type;
  
  var value:ComplexType;
  var result:ComplexType;
  var input:ComplexType;
  
  var pos:Position;
  var _date:Expr;
  var _int:Expr;
  var _float:Expr;
  var _string:Expr;
  var _bool:Expr;
  
  function new(name, rawType:Type, pos) {
    
    this.pos = pos;
    this.name = name;
    this.resultType = 
      switch rawType.reduce() {
        case TFun([{ t: input }, { t: value }], result):
          
          this.inputType = input;
          this.valueType = value;
          
          result;
          
        case TFun([{ t: value }], result):
          
          this.valueType = value;
          
          result;
          
        case result: 
                    
          result;
      }
      
    this.result = resultType.toComplex();
    
    
    if (this.value == null) {
      if (this.valueType == null) {
        this.value = macro : tink.url.Portion;
        this.valueType = value.toType(pos).sure();
      }
      else this.value = this.valueType.toComplex();
    }
      
    if (this.input == null) {
      if (this.inputType == null) {
        this.input = macro : tink.querystring.Pairs<$value>;
        this.inputType = input.toType(pos).sure();
      }
      else this.input = this.inputType.toComplex();
    }
    
    //Now comes the sad part - see tink.Stringly for further rants ...
    this._string = 
      if ((macro ((null:$value):String)).typeof().isSuccess()) 
        prim(macro : String);
      else 
        pos.error('${value.toString()} should be compatible with String');

    function coerce(stringly:Expr, to:ComplexType) 
      return
        switch to {
          case macro : Int, macro : Float, macro : Date:
            var name = 'parse'+to.toString();
            macro this.attempt(prefix, $stringly.$name());
          default:
            macro ($stringly : $to);
        }    
      

    function parsePrimitive(expected:ComplexType) 
      return
        if ((macro ((null:$value):$expected)).typeof().isSuccess())
          prim(macro : Int);
        else if ((macro ((null:$value):tink.Stringly)).typeof().isSuccess())
          coerce(macro ${prim(macro : tink.Stringly)}, expected);
        else
          coerce(macro (${prim(macro : String)} : tink.Stringly), expected);
      
    this._int = parsePrimitive(macro : Int);
    this._float = parsePrimitive(macro : Float);
    this._bool = parsePrimitive(macro : Bool);
    this._date = parsePrimitive(macro : Date);
        
  }
  
  public function get() {
    var crawl = Crawler.crawl(resultType, pos, this);
    
    var ret = macro class $name extends tink.querystring.Parser.ParserBase<$input, $value, $result> {
      
      function getName(p):String return p.name;
      function getValue(p):$value return p.value;
      
      override public function parse(input:$input) {
        var prefix = '';
        this.init(input, getName, getValue);
        return ${crawl.expr};
      }
      
    }
    
    ret.fields = ret.fields.concat(crawl.fields);
    
    return ret;    
  }

  static function buildNew(ctx:BuildContext) 
    return new GenParser(ctx.name, ctx.type, ctx.pos).get();    
  
  static public function build() 
    return BuildCache.getType('tink.querystring.Parser', buildNew);
    
  public function wrap(placeholder:Expr, ct:ComplexType)
    return placeholder.func(['prefix'.toArg(macro : String)], ct);
    
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
    
  public function dyn(e:Expr, ct:ComplexType):Expr 
    return pos.error('Dynamic<T> parsing not implemented');
  
  public function dynAccess(e:Expr):Expr 
    return pos.error('haxe.DynamicAccess<T> parsing not implemented');
  
  public function bool():Expr 
    return _bool;
  
  public function date():Expr 
    return _date;
  
  public function bytes():Expr 
    return pos.errorExpr('Bytes parsing not implemented');
  
  public function anon(fields:Array<FieldInfo>, ct:ComplexType):Expr {
    var ret = [],
        optional = [];
        
    for (f in fields) {
      var formField = switch f.meta.getValues(':formField') {
        case []: f.name;
        case [[v]]: v.getName().sure();
        case v: f.pos.error('more than one @:formField');
      }
      
      var defaultValue = switch f.meta.getValues(':default') {
        case []: None;
        case [[v]]: Some(v);
        case v: f.pos.error('more than one @:default');
      }

      var enter = (macro var prefix = switch prefix {
        case '': $v{formField};
        case v: v + $v{ '.' + formField};
      });

      if (f.optional) 
        optional.push(macro {
          $enter;
          if (exists[prefix])
            ${['__o', f.name].drill()} = ${f.expr};
          else ${switch defaultValue {
            case Some(v): ['__o', f.name].drill().assign(v);
            default: null;
          }};
        })
      else {
        var value = switch defaultValue {
          case Some(v):
            macro if (exists[prefix]) ${f.expr} else $v;
          default: f.expr;
        }
        ret.push({ 
          field: f.name, 
          expr: macro {
            $enter;
            $value;
          } 
        });
      }
    }
      
    return macro {
      var __o:$ct = ${EObjectDecl(ret).at()};
      $b{optional};
      __o;
    }
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
    return pos.error('Map parsing not implemented');
  }
  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr {
    return pos.error('Enum parsing not implemented');
  }
  
  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
    return macro @:pos(pos) {
      var v:$ct = cast $e;
      ${ESwitch(
        macro v, 
        [{expr: macro v, values: names}], 
        macro {
          var list = $a{names};
          throw new tink.core.Error(422, 'Unrecognized enum value: ' + v + '. Accepted values are: ' + tink.Json.stringify(list));
        }
      ).at(pos)}
    }
  }
  
  public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr> {
    return Some(
      macro 
        try ${prim(t.toComplex())}
        catch (e:tink.core.Error) this.fail(prefix, e.message)
        catch (e:Dynamic) this.fail(prefix, Std.string(e))    
    );
  }

  public function reject(t:Type):String {
    return 'Cannot parse ${t.toString()}';
  }
  
  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);

  public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr
    return gen(type, pos);
}
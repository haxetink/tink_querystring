package tink.querystring.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;
import tink.typecrawler.Crawler;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using tink.CoreApi;
using tink.MacroApi;

class GenBuilder {
  var prim:Expr;
  var name:String;
  var pos:Position;
  
  var data:ComplexType;
  var buffer:ComplexType;
  
  var dataType:Type;
  var bufferType:Type;
  
  function new(name, rawType:Type, pos) {
    
    this.name = name;
    this.pos = pos;
    this.prim = macro @:pos(pos) buffer.add(prefix, data);
    
    this.dataType = 
      switch rawType.reduce() {
          
        case TFun([{ t: data }], buffer):
          
          this.bufferType = buffer;
          
          data;
          
        case data: 
                    
          this.bufferType = Context.getType('tink.querystring.Builder.DefaultBuffer');
          data;
      }
    
    this.data = dataType.toComplex();
    this.buffer = bufferType.toComplex();   
  }
  
  public function wrap(placeholder:Expr, ct:ComplexType)
    return placeholder.func(['prefix'.toArg(macro : String), 'buffer'.toArg(buffer), 'data'.toArg(ct)], false);    
    
  public function nullable(e:Expr):Expr
    return macro @:pos(e.pos) if (data != null) $e;
    
  public function string():Expr
    return prim;
    
  public function float():Expr
    return prim;
    
  public function int():Expr
    return prim;
  
  public function bool():Expr
    return prim;
  
  public function dyn(e:Expr, ct:ComplexType):Expr
    return throw 'not implemented';
    
  public function dynAccess(e:Expr):Expr
    return throw 'not implemented';
    
  public function date():Expr
    return prim;
    
  public function bytes():Expr
    return throw 'not implemented';
    
  public function anon(fields:Array<FieldInfo>, ct:ComplexType) {
    
    function info(i:FieldInfo):Expr {
      
      var formField = switch i.meta.getValues(':formField') {
        case []: i.name;
        case [[v]]: v.getName().sure();
        case v: i.pos.error('more than one @:formField');
      }
      
      return macro @:pos(i.pos) {
        var prefix = switch prefix {
          case '': $v{formField};
          case v: v + $v{'.'+formField};
        }
        var data = ${['data', i.name].drill(i.pos)};
        ${i.expr};
      }

    }
    
    return [for (f in fields) info(f)].toBlock();    
  }
    
  public function array(e:Expr):Expr
    return (macro @:pos(e.pos) for (i in 0...data.length) {
      var data = data[i],
          prefix = prefix + '[' + i + ']';
      $e;
    });
    
  public function map(k:Expr, v:Expr):Expr
    return throw 'not implemented';
    
  public function enm(constructors:Array<EnumConstructor>, ct:ComplexType, pos:Position, gen:GenType):Expr
    return throw 'not implemented';
  
  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr
    return e;
    
  public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr>
    return None;
    
  public function reject(t:Type):String
    return 'Unsupported type $t';
  
  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);

  public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr
    return gen(type, pos);
  
  function get() {
    var crawl = Crawler.crawl(dataType, pos, this);
    
    var bufName = switch buffer {
      case TPath(p): p;
      default: pos.error('unsupported buffer type');
    }
    
    var ret = macro class $name {
      
      public function new() {}
      
      public function stringify(data:$data) {
        var prefix = '',
            buffer = new $bufName();//TODO: consider making this a stack variable
        ${crawl.expr};
        return buffer.flush();
      }
      
    }
    
    ret.fields = ret.fields.concat(crawl.fields);
    
    return ret;    
  }  
  static function buildNew(ctx:BuildContext) 
    return new GenBuilder(ctx.name, ctx.type, ctx.pos).get();    
  
  static public function build() 
    return BuildCache.getType('tink.querystring.Builder', buildNew);

  
}
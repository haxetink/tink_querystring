package tink.querystring.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.BuildCache;
import tink.typecrawler.Crawler;
import tink.typecrawler.FieldInfo;
import tink.typecrawler.Generator;

using Lambda;
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
  
  static final CUSTOM_META = ':queryStringify';
  
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
  
  public function enumAbstract(names:Array<Expr>, e:Expr, ct:ComplexType, pos:Position):Expr {
    return switch ct.toType() {
      case Success(TAbstract(_.get() => {type: type}, _)) if(Context.unify(Context.getType('tink.Stringly'), type)):
          var ct = type.toComplex();
          macro buffer.add(prefix, (cast data:$ct));
      case _:
        e;
    }
  }
    
  public function rescue(t:Type, pos:Position, gen:GenType):Option<Expr> {
    var ct = t.toComplex();
    return switch (macro (null:$buffer).add(null, (null:$ct))).typeof() {
      case Success(_): Some(prim);
      case Failure(_): None;
    }
  }
    
  public function reject(t:Type):String
    return '[tink_querystring] Unsupported type $t';
  
  public function shouldIncludeField(c:ClassField, owner:Option<ClassType>):Bool
    return Helper.shouldIncludeField(c, owner);

  public function drive(type:Type, pos:Position, gen:Type->Position->Expr):Expr {
    return switch type.getMeta().fold((current, all:Array<MetadataEntry>) -> all.concat(current.extract(CUSTOM_META)), []) {
      case []:
        gen(type, pos);
      case _[0] => { params: [custom] }:
        var rule:CustomRule =
          switch custom {
            case { expr: EFunction(_, _) }: WithFunction(custom);
            // case { expr: EParenthesis({ expr: ECheckType(_, TPath(path)) }) }: WithClass(path, custom.pos);
            case _ if(custom.typeof().sure().reduce().match(TFun(_, _))): WithFunction(custom);
            // default: WithClass(custom.toString().asTypePath(), custom.pos);
            case _: custom.pos.error('unsupported');
          }
        processCustom(rule, type, drive.bind(_, pos, gen));
      case _[0] => { pos: pos }:
        pos.error('Invalid use of @$CUSTOM_META');
        
    }
  }
  
  function processCustom(c:CustomRule, original:Type, gen:Type->Expr):Expr {
    var original = original.toComplex();
    return switch c {
      case WithFunction(e):
        if (e.expr.match(EFunction(_))) {
          var ret = e.pos.makeBlankType();
          e = macro @:pos(e.pos) ($e:$original->$ret);
        }
        //TODO: the two cases look suspiciously similar
        var rep = (macro @:pos(e.pos) $e((cast null:$original))).typeof().sure();
        return macro @:pos(e.pos) {
          var data = $e(data);
          ${gen(rep)};
        }
    }
  }
  
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
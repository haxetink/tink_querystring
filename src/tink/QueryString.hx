package tink;

import haxe.macro.Expr;

#if macro
using tink.MacroApi;
#end

class QueryString { 
  
  macro static public function parse(source:Expr) 
    return switch source {
      case macro ($e:$t): 
        macro @:pos(source.pos) new tink.querystring.Parser<$t>().tryParse($e);
      default:        
        var t = haxe.macro.Context.getExpectedType().toComplex({ direct: true });
        macro @:pos(source.pos) new tink.querystring.Parser<$t>().parse($source);
    }
  macro static public function build(e:Expr) { 
    var ct = e.typeof().sure().toComplex( { direct:true } );
    return macro @:pos(e.pos) new tink.querystring.Builder<$ct>().stringify($e);
  }
  
}
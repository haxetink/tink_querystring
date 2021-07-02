package tink.querystring.macros;

import haxe.macro.Expr;

enum CustomRule {
//   WithClass(cls:TypePath, pos:Position);
  WithFunction(expr:Expr);
}
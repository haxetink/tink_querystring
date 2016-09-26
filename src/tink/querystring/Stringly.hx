package tink.querystring;
import tink.url.Portion;

using tink.CoreApi;
using StringTools;

/**
 * This particular abstract brings stringliness to Haxe. It is a mess. In particular bools make me cry. 
 * And also some of the code in GenParser is music to the pharyngeal reflex.
 * 
 * Stringliness is a neat idea to allow easily expressing numeric values in human machine interaction, 
 * which leverages the fact that our brains are pretty good at finding out whether something is a number or not. 
 * Computers, however, are not good at processing complex language. They are getting there, but even then they will
 * still be orders of magnitude faster and more reliable when dealing with more rigid representations.
 * 
 * Therefore stringliness should exist only at the periphery of any computer system and not at its very core as it does in the web.
 * But the facts of life are sometimes inescapable and so we must deal with them as best we can.
 */
abstract Stringly(String) from String to String {
   
  static function isNumber(s:String, allowFloat:Bool) {
    
    if (s.length == 0) return false;
    
    var pos = 0,
        max = s.length;
        
    inline function isDigit(code)
      return code ^ 0x30 < 10;//a sharp glimpse at the ASCII table revealed this to me
        
    inline function digits()
      while (pos < max && isDigit(s.fastCodeAt(pos))) pos++;
    
    inline function allow(code)
      return 
        if (pos < max && s.fastCodeAt(pos) == code) pos++ > -1;//always true ... not pretty, but generates much simpler code
        else false;
    
    allow('-'.code);
    digits();
    if (allowFloat && pos < max) {
      if (allow('.'.code))
        digits();
        
      if (allow('e'.code) || allow('E'.code)) {
        allow('+'.code) || allow('-'.code);
        digits();
      }
    }
    
    return pos == max;
  }
  
  @:to public function toString()
    return 
      if (this == null) null;
      else this.urlDecode();
  
  @:to public function toBool()
    return switch this.trim().toLowerCase() {
      case 'false', '0', 'no': false;
      default: true;
    }
    
  @:to public function parseFloat()
    return switch this.trim() {
      case v if (isNumber(v, true)):
        Success((Std.parseFloat(v) : Float));
      case v:
        Failure(new Error(UnprocessableEntity, '$v (encoded as $this) is not a valid float'));
    }
  
  @:to function toFloat()
    return parseFloat().sure();
    
  @:to public function parseInt()
    return switch this.trim() {
      case v if (isNumber(v, false)):
        Success((Std.parseInt(v) : Int));
      case v:
        Failure(new Error(UnprocessableEntity, '$v (encoded as $this) is not a valid integer'));
    }
        
  @:to function toInt()
    return parseInt().sure();
      
  @:from static inline function ofBool(b:Bool):Stringly
    return if (b) 'true' else 'false';
    
  @:from static inline function ofInt(i:Int):Stringly
    return Std.string(i);  
    
  @:from static inline function ofFloat(f:Float):Stringly
    return Std.string(f);
    
  @:from static inline function ofPortion(p:Portion):Stringly
    return p.toString();
    
}
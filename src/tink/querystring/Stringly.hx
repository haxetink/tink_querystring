package tink.querystring;

using tink.CoreApi;
using StringTools;

abstract Stringly(String) from String to String {
   
  static function isNumber(s:String, allowFloat:Bool) {
    
    if (s.length == 0) return false;
    
    var pos = 0,
        max = s.length;
        
    inline function digits()
      while (pos < max && s.fastCodeAt(pos) ^ 0x30 < 10) pos++;//also not too pretty, but leads to compact code
    
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
    
}
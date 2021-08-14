package tink.querystring;

interface Keymaker {
  function field(name:String, field:String):String;
  function index(name:String, index:Int):String;
}

class DefaultKeymaker implements Keymaker {
  public function new() {}
  
  public function field(name:String, field:String):String {
    return switch name {
      case '': field;
      case _: '$name.$field';
    }
  }
    
  public function index(name:String, index:Int):String {
    return '$name[$index]';
  }
}

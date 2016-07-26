package tink.querystring;

import tink.url.*;
using tink.CoreApi;

abstract Pairs<T>(Iterator<Named<T>>) from Iterator<Named<T>> to Iterator<Named<T>> {

  //@:from static function strings(s:String):Pairs<String>
    //return Query.parseString(s);
    
  //@:from static function portionsOfUrl(u:Url):Pairs<Portion>
    //return portions(u.query);
  
  
  @:from static function portions(s:String):Pairs<Portion>
    return Query.parseString(s);
    
  @:from static function portionsOfUrl(u:Url):Pairs<Portion>
    return portions(u.query);
  
}
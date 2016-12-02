package tink.querystring;

import tink.url.*;
using tink.CoreApi;

abstract Pairs<T>(Iterator<Named<T>>) from Iterator<Named<T>> to Iterator<Named<T>> {
  
  @:from static function portions(s:String):Pairs<Portion>
    return (Query.parseString(s) : Iterator<Named<Portion>>);
    
  @:from static function portionsOfUrl(u:Url):Pairs<Portion>
    return portions(u.query);
    
  @:from static function ofIterable<T>(i:Iterable<Named<T>>):Pairs<T>
    return i.iterator();
 
}
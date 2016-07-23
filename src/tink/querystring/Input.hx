package tink.querystring;

import tink.url.*;
using tink.CoreApi;

abstract Input<A>(Iterator<A>) from Iterator<A> to Iterator<A> {
  @:from static public function ofString(s:String):Input<NamedWith<Portion, Portion>> 
  return Query.parseString(s);
    
  @:from static public function ofUrl(u:Url)
    return ofString(u.query);
}
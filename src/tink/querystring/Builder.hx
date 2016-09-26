package tink.querystring;

import tink.url.Portion;
import tink.url.Query;

@:genericBuild(tink.querystring.macros.GenBuilder.build())
class Builder<Flow> { }

class BuilderBase<Data, Buffer> {
  var buffer:Buffer;
}

abstract DefaultBuffer(QueryStringBuilder) {
  public inline function new()
    this = new QueryStringBuilder();
    
  public inline function add(name:Portion, value:Stringly)
    this.add(name, value);
    
  public function flush() 
    return this.toString();//TODO: consider clearing
    
}
# Tinkerbell Querystringmanglingthing

This library provides the means to parse and build query strings - or similar structures - into or from complex Haxe objects in a type-safe reflection-free way.

# Parsing

## Basic Usage

```haxe
typedef Post = {
  title:String, 
  body:String,
  tags:Array<String>,
}

var parser = new tink.querystring.Parser<Post>();
trace(parser.parse('title=Example+Post&body=This+is+an+example&tags[0]=foo&tags[1]=bar'));// { title: 'Example Post', body: { 'This is an example' }, tags: ['foo', 'bar'] }

//Or with outcomes:

trace(parser.tryParse('title=theTitle'))//Failure("Error#422: missing field body")
trace(parser.tryParse('title=theTitle&body=theBody'))//Success({ title: 'theTitle', body: 'theBody', tags: [] })
```

### Understanding the parser

The generated parser is a subclass of this class:
  
```haxe
class ParserBase<Input, Value, Result> {
  public function parse(input:Input):Result;  
  public function tryParse(input:Input):Outcome<Result, Error>;
}
```

To fully specify a parser type, you would use `Parser<Input->Value->Result>`, where `Value` is the type of the individual values found in the input. Much of the time you will not need this level of flexibility. So you can also leave a few things to the default: `Parser<Value->Result>` is a shorthand for `Parser<tink.parser.Pairs<Value>->Value->Result>` and `Parser<Result>` is a shorthand for `Parser<tink.url.Portion->Result>`. 

So in the above example above, we could explicitly define the parser like so:
  
```haxe
var parser = tink.querystring.Parser<tink.querystring.Pairs<tink.url.Portion>->Portion->Post>();
```


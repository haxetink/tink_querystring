# Tinkerbell Querystringmanglingthing

[![Build Status](https://travis-ci.org/haxetink/tink_querystring.svg?branch=master)](https://travis-ci.org/haxetink/tink_querystring)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/haxetink/public)


This library provides the means to parse and build query strings - or similar structures - into or from complex Haxe objects in a type-safe reflection-free way.

# Parsing

## Simple Parsing

```haxe
typedef Post = {
  title:String, 
  body:String,
  tags:Array<String>,
}


//relying on expected type:
var post:Post = tink.QueryString.parse('title=Example+Post&body=This+is+an+example&tags[0]=foo&tags[1]=bar');
trace(post);//{ title: 'Example Post', body: 'This is an example', tags: ['foo', 'bar'] }


//specifying the type
trace(tink.QueryString.parse(('title=Example+Post' : Post)));//Failure("Error#422: missing field body")
trace(tink.QueryString.parse(('title=Example+Post&body=whatever' : Post)));//Success({ title: 'Example Post', body: 'whatever', tags: [] })
```

Note that for the second usage the result is an Outcome, while for the first it is either a value of the expected type, or it throws an exception.

### Parser Details

The `tink.QueryString.parse` macro is really just a helper for generating a `tink.querystring.Parser`. Note that for a single type only one parser is generated in the whole build. The generated parser is a subclass of this class:
  
```haxe
class ParserBase<Input, Value, Result> {
  public function parse(input:Input):Result;  
  public function tryParse(input:Input):Outcome<Result, Error>;
}
```

To fully specify a parser type, you would use `Parser<Input->Value->Result>`, where `Value` is the type of the individual values found in the input. Much of the time you will not need this level of flexibility. So you can also leave a few things to the default: `Parser<Value->Result>` is a shorthand for `Parser<tink.parser.Pairs<Value>->Value->Result>` and `Parser<Result>` is a shorthand for `Parser<tink.url.Portion->Result>`. 

So in the above example above, we could explicitly do everything by hand like so:
  
```haxe
var parser = tink.querystring.Parser<tink.querystring.Pairs<tink.url.Portion>->Portion->Post>();
parser.parse('title=Example+Post&body=This+is+an+example&tags[0]=foo&tags[1]=bar');
```

# Building

## Simple Building

Building querystrings is even simpler (since there's no error handling to be taken care of and the structure of the data is already well defined by the type of the data):

```haxe
trace(tink.QueryString.build({ hello:'world', blabla: [1,2,3] }));//blabla[0]=1&blabla[1]=2&blabla[2]=3&hello=world
```

## Builder Details

... to be documented

# Tinkerbell Querystringmanglingthing

[![Build Status](https://github.com/haxetink/tink_querystring/actions/workflows/ci.yml/badge.svg)](https://github.com/haxetink/tink_querystring/actions)


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
  public function parse(input:Input, ?normalizer:Normalizer<Dynamic, Value>):Result;  
  public function tryParse(input:Input, ?normalizer:Normalizer<Dynamic, Value>):Outcome<Result, Error>;
}
```

To fully specify a parser type, you would use `Parser<Input->Value->Result>`, where `Value` is the type of the individual values found in the input. Much of the time you will not need this level of flexibility. So you can also leave a few things to the default: `Parser<Value->Result>` is a shorthand for `Parser<tink.querystring.Pairs<Value>->Value->Result>` and `Parser<Result>` is a shorthand for `Parser<tink.url.Portion->Result>`. 

So in the above example above, we could explicitly do everything by hand like so:
  
```haxe
var parser = new tink.querystring.Parser<tink.querystring.Pairs<tink.url.Portion>->Portion->Post>();
parser.parse('title=Example+Post&body=This+is+an+example&tags[0]=foo&tags[1]=bar');
```

#### Key flavour (Normalizer)

Nested keys may use mixed dot and bracket notation (`y.z=2` and `y[z]=2` are both accepted). That decomposition is done by a `Normalizer` — by default `DefaultNormalizer`.

`Keymaker` only affects **building**. On the parser side, pass an optional normalizer to `parse` / `tryParse` (the `QueryString.parse` facade does not take one — use `Parser<T>` directly):

```haxe
var parser = new Parser<Post>();
parser.parse(qs); // DefaultNormalizer
parser.parse(qs, new DefaultNormalizer());
parser.tryParse(qs, new DefaultNormalizer());
```

Custom `Normalizer` implementations can change how flat keys become a tree (for example to enforce a single key flavour).
# Building

## Simple Building

Building querystrings is even simpler (since there's no error handling to be taken care of and the structure of the data is already well defined by the type of the data):

```haxe
trace(tink.QueryString.build({ hello:'world', blabla: [1,2,3] }));//blabla[0]=1&blabla[1]=2&blabla[2]=3&hello=world
```

## Builder Details

`QueryString.build` is a macro helper for `tink.querystring.Builder`. You can also use the builder directly and pass a custom `Keymaker`:

```haxe
var builder = new Builder<{x:{y:Int, z:Array<Int>}}>();
builder.stringify({x:{y:1, z:[2]}}); // x.y=1&x.z%5B0%5D=2
builder.stringify({x:{y:1, z:[2]}}, new BracketKeymaker()); // x%5By%5D=1&x%5Bz%5D%5B0%5D=2
```

Field metadata:

- `@:formField('foo-bar')` — use a different wire name than the field name
- `@:default(12)` — value when the field is absent from the input
- `@:queryParse(fn)` / `@:queryStringify(fn)` — custom parse/stringify hooks for a type

Map keys must be implicitly convertible to `tink.Stringly` (`String`, `Int`, `Bool`, `Float`, `Date`, and Stringly-based enum abstracts).

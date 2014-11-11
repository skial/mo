# Mo

> Haitian Creole for Words

The primary goal of Mo is to be a syntax highlighter for Haxe. Its getting
there.

## Whats inside...

Currently the library supports CSS, HTML, Markdown and Haxe syntax parsing. 
There is untested support for Http Headers.
	
## Notes

+ Markdown support is not Common Markdown compliant, _yet_.
+ The HTML lexer also comes with an `abstract` DOMNode/Tools/* implementations for the [Detox] library.

## Installation

1. [hxparse] - `https://github.com/Simn/hxparse development src`
2. mo:
	+ git - `haxelib git mo https://github.com/skial/mo master src`
	+ zip:
		* download - `https://github.com/skial/mo/archive/master.zip`
		* install - `haxelib local master.zip`

[hxparse]: http://github.com/simn/hxparse "Haxe Lexer and Parser Library"
[detox]: https://github.com/jasononeil/detox "A cross-platform library, written in Haxe, that makes working with Xml and the DOM light weight and easy"
	
## Tests

+ [CSS Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/CssParserSpec.hx)
+ [HTML Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/HtmlLexerSpec.hx)
	- [Mo-Detox Tests](https://github.com/skial/uhu-spec/tree/master/src/dtx)
+ [Markdown Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/MarkdownParserSpec.hx)
+ [Haxe Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/HaxeParserSpec.hx)
# Mo

> Haitian Creole for Words

The primary goal of Mo is to be a syntax highlighter for Haxe.

## What inside...

Currently the library supports CSS, HTML, Markdown and Haxe. There is 
partial support for Http Headers.
	
## Notes

+ Markdown support is not Common Markdown compliant, yet.

## Installation

1. [hxparse] - `https://github.com/Simn/hxparse development src`
2. mo:
	+ git - `haxelib git mo https://github.com/skial/mo master src`
	+ zip:
		* download - `https://github.com/skial/mo/archive/master.zip`
		* install - `haxelib local master.zip`

[hxparse]: http://github.com/simn/hxparse "Haxe Lexer and Parser Library"
	
## Tests

+ [CSS Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/CssParserSpec.hx)
+ [HTML Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/HtmlLexerSpec.hx)
+ [Markdown Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/MarkdownParserSpec.hx)
+ [Haxe Tests](https://github.com/skial/uhu-spec/blob/master/src/uhx/lexer/HaxeParserSpec.hx)
# Mo

> Haitian Creole for Words

Mo provides some simple utility files and example lexers.

## Installation

1. [hxparse] - `https://github.com/Simn/hxparse development src`
2. mo - `haxelib git mo https://github.com/skial/mo master src`

[hxparse]: http://github.com/simn/hxparse "Haxe Lexer and Parser Library"
	
## Libraries and Classes built ontop of Mo

+ [mo-css](https://github.com/skial/mo-css) - CSS Lexer.
+ [mo-html](https://github.com/skial/mo-html) - HTML Lexer.
+ [mo-mime](https://github.com/skial/mo-mime) - Mime Lexer.
+ [mo-hxml](https://github.com/skial/mo-hxml) - HXML Lexer.
+ [mo-uri](https://github.com/skial/mo-uri) - Uri Lexer.
+ [MediaType](https://github.com/skial/media-types) - An abstract type, using the Mime Lexer to parse mime/media/internet types. E.g `text/plain; charset=UTF-8`.
+ [HTML Select](https://github.com/skial/jwenn/tree/transfer_uhx/src/uhx/select/html) - An experimental CSS selector engine for the HTML lexer in Mo.
+ [JSON Select](https://github.com/skial/jwenn/blob/transfer_uhx/src/uhx/select/JsonQuery.hx) - An experimental JSON selector engine, inspired by [http://jsonselect.org](https://web.archive.org/web/20150302050508/http://jsonselect.org#overview).
package uhx.lexer;

import haxe.io.Eof;
import byte.ByteData;
import uhx.lexer.CssLexer;

/**
 * ...
 * @author Skial Bainn
 */
class SelectorParser {

	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String):CssSelectors {
		var lexer = new CssLexer(bytes, name);
		var tokens = [];
		
		try while ( true ) {
			tokens.push( lexer.token( CssLexer.selectors ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		// Any Attribute or Pseudo selector without a preceeding selector is treated
		// to have a Universal selector preceeding it. 
		// `[a=1]` becomes `*[a=1]`
		// `:first-child` becomes `*:first-child`
		for (i in 0...tokens.length) switch(tokens[i]) {
			case Attribute(_, _, _) | Pseudo(_, _) | 
			Combinator(Attribute(_, _, _), _, _) | Combinator(Pseudo(_, _), _, _):
				tokens[i] = Combinator(Universal, tokens[i], None);
				
			case _:
				
		}
		
		return tokens.length > 1?Group(tokens):tokens[0];
	}
	
}
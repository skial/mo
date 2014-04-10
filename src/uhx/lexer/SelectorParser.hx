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
		
		return tokens.length > 1?Group(tokens):tokens[0];
	}
	
}
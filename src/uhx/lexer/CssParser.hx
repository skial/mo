package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import uhx.lexer.CssLexer;

/**
 * ...
 * @author Skial Bainn
 */
class CssParser {

	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String):Array<Token<CssKeywords>> {
		var lexer = new CssLexer(bytes, name);
		var tokens = [];
		
		try while ( true ) {
			tokens.push( lexer.token( CssLexer.root ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return tokens;
	}
	
}
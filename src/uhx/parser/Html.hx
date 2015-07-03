package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import uhx.lexer.HtmlLexer;

/**
 * ...
 * @author Skial Bainn
 */
class Html {

	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String):Array<Token<HtmlKeywords>> {
		var lexer = new HtmlLexer(bytes, name);
		var tokens = [];
		
		try while ( true ) {
			tokens.push( lexer.token( HtmlLexer.root ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			
		}
		
		return tokens;
	}
	
}
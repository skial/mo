package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import uhx.lexer.UriLexer;

/**
 * ...
 * @author Skial Bainn
 */
class Uri {

	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String):Array<Token<UriKeywords>> {
		var results = [];
		var lexer = new UriLexer( bytes, name );
		
		try while (true) {
			results.push( lexer.token( UriLexer.root ) );
			
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			trace( e );
		}
		
		return filter( results );
	}
	
	public function filter(tokens:Array<Token<UriKeywords>>) {
		var results = [];
		
		for (token in tokens) switch token {
			case Keyword(Path(children)):
				results = results.concat( filter( children ) );
				
			case _:
				results.push( token );
				
		}
		
		return results;
	}
	
}
package uhx.lexer;

import haxe.io.Eof;
import byte.ByteData;
import uhx.lexer.MimeLexer;

/**
 * ...
 * @author Skial Bainn
 * @see https://en.wikipedia.org/wiki/Internet_media_type
 */
class Mime {

	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String) {
		var lexer = new MimeLexer( bytes, name );
		var tokens = [];
		
		try while (true) {
			tokens.push( lexer.token( MimeLexer.root ) );
			
		} catch (e:Eof) { } catch (e:Dynamic) {
			trace( e );
		}
		
		return tokens;
	}
	
}
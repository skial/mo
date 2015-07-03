package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import hxparse.Ruleset;
import hxparse.UnexpectedChar;

using StringTools;
using uhx.lexer.UriLexer;

/**
 * ...
 * @author Skial Bainn
 */

typedef Tokens = Array<Token<UriKeywords>>;
 
enum UriKeywords {
	Scheme(value:String);
	Host(value:String);
	Auth(user:String, pass:String);
	Port(value:String);
	Path(value:Tokens);
	Directory(value:String);
	File(value:String);
	Extension(value:String);
	Query(name:String, value:String);
	Fragment(value:String);
}
 
class UriLexer extends Lexer {
	
	@:access(hxparse.Lexer) public static var root = Mo.rules( [
	'[^:\\.]+:\\/*' => Keyword(Scheme( lexer.current.substring(0, lexer.current.lastIndexOf( ':' )) )),
	'[^:@]+:[^:@]*+@' => {
		var parts = lexer.current.substring( 0, lexer.current.length - 1 ).split( ':' );
		Keyword(Auth( parts[0], parts[1] ));
	},
	':[0-9]+' => Keyword(Port( lexer.current.substring( 1 ) )),
	'\\?' => lexer.token( root ),
	'&' => lexer.token( root ),
	'[^=\\?&]+=[^&#]*' => {
		var parts = lexer.current.split( '=' );
		Keyword(Query( parts[0], parts[1] ));
	},
	'#[^#]+' => Keyword(Fragment( lexer.current.substring( 1 ) )),
	'[a-zA-Z0-9\\-\\/\\.]+' => {
		var l = new UriLexer( ByteData.ofString( lexer.current ), 'urilexer-path' );
		var r = [];
		try while (true) r.push(l.token( path )) catch (e:Eof) { } catch (e:UnexpectedChar) { trace(e.char,e.pos); } catch (e:Dynamic) { trace(e); };
		Keyword(Path( r ));
	},
	] );
	
	@:access(hxparse.Lexer) public static var path = Mo.rules( [
	'(\\/\\/)?([a-zA-Z0-9\\-]*\\.?[a-zA-Z0-9]+\\.[a-zA-Z\\.]+)+' => Keyword(Host( lexer.current.startsWith( '//' ) ? lexer.current.substring( 2 ) : lexer.current )),
	'\\.[^\\.\\?\\/#&]+' => Keyword(Extension( lexer.current.substring( 1 ) )),
	'\\.\\/' => lexer.token( directory ),
	'\\.\\.\\/' => Keyword(Directory( lexer.current )),
	'[a-zA-Z0-9\\-\\/]+\\.?' => {
		if (lexer.current.endsWith('.')) lexer.pos--;
		var l = new UriLexer( ByteData.ofString( lexer.current ), 'urilexer-directory' );
		var r = [];
		try while (true) r.push(l.token( directory )) catch (e:Eof) { } catch (e:UnexpectedChar) { trace(e.char, e.pos); } catch (e:Dynamic) { trace(e); };
		Keyword(Path( r ));
	},
	] );
	
	@:access(hxparse.Lexer) public static var directory = Mo.rules( [
	'\\/' => lexer.token( directory ),
	'[a-zA-Z0-9\\-]+\\.' => {
		lexer.pos--;
		Keyword(File( lexer.current.substring( 0, lexer.current.length - 1 ) ));
	},
	'[a-zA-Z0-9\\-]+' => Keyword(Directory( lexer.current )),
	] );
	
}
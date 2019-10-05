package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import hxparse.Ruleset;
import hxparse.UnexpectedChar;

using StringTools;

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
 
class Uri extends Lexer implements uhx.mo.RulesCache {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var root:Ruleset<Uri, Token<UriKeywords>> = Mo.rules( [
	'[^:\\.]+:\\/*' => lexer -> Keyword(Scheme( lexer.current.substring(0, lexer.current.lastIndexOf( ':' )) )),
	'[^:@]+:[^:@]*+@' => lexer -> {
		var parts = lexer.current.substring( 0, lexer.current.length - 1 ).split( ':' );
		Keyword(Auth( parts[0], parts[1] ));
	},
	':[0-9]+' => lexer -> Keyword(Port( lexer.current.substring( 1 ) )),
	'\\?' => lexer -> lexer.token( root ),
	'&' => lexer -> lexer.token( root ),
	'[^=\\?&]+=[^&#]*' => lexer -> {
		var parts = lexer.current.split( '=' );
		Keyword(Query( parts[0], parts[1] ));
	},
	'#[^#]+' => lexer -> Keyword(Fragment( lexer.current.substring( 1 ) )),
	'[a-zA-Z0-9\\-\\/\\.\\!]+' => lexer -> {
		var l = new Uri( ByteData.ofString( lexer.current ), 'urilexer-path' );
		var r = [];
		try while (true) r.push(l.token( path )) catch (e:Eof) { } catch (e:UnexpectedChar) { trace(e.char,e.pos); } catch (e:Dynamic) { trace(e); };
		Keyword(Path( r ));
	},
	] );
	
	public static var path:Ruleset<Uri, Token<UriKeywords>> = Mo.rules( [
	'(\\/\\/)?([a-zA-Z0-9\\-]*\\.?[a-zA-Z0-9]+\\.[a-zA-Z\\.]+)+' => lexer -> Keyword(Host( lexer.current.startsWith( '//' ) ? lexer.current.substring( 2 ) : lexer.current )),
	'\\.[^\\.\\?\\/#&]+' => lexer -> Keyword(Extension( lexer.current.substring( 1 ) )),
	'\\.\\/' => lexer -> lexer.token( directory ),
	'\\.\\.\\/' => lexer -> Keyword(Directory( lexer.current )),
	'[a-zA-Z0-9\\-\\/\\!]+\\.?' => lexer -> {
		if (lexer.current.endsWith('.')) @:privateAccess lexer.pos--;
		var l = new Uri( ByteData.ofString( lexer.current ), 'urilexer-directory' );
		var r = [];
		try while (true) r.push(l.token( directory )) catch (e:Eof) { } catch (e:UnexpectedChar) { trace(e.char, e.pos); } catch (e:Dynamic) { trace(e); };
		Keyword(Path( r ));
	},
	] );
	
	public static var directory:Ruleset<Uri, Token<UriKeywords>> = Mo.rules( [
	'\\/' => lexer -> lexer.token( directory ),
	'[a-zA-Z0-9\\-\\!]+\\.' => lexer -> {
		@:privateAccess lexer.pos--;
		Keyword(File( lexer.current.substring( 0, lexer.current.length - 1 ) ));
	},
	'[a-zA-Z0-9\\-\\!]+' => lexer -> Keyword(Directory( lexer.current )),
	] );
	
}
package uhx.lexer;

import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import haxe.ds.StringMap;

using StringTools;

/**
 * ...
 * @author Skial Bainn
 * @see https://en.wikipedia.org/wiki/Internet_media_type
 * ---
 * top-level type name / subtype name [ ; parameters ]
 * top-level type name / [ tree. ] subtype name [ +suffix ] [ ; parameters ]
 */

enum MimeKeywords {
	Toplevel(name:String);
	Tree(name:String);
	Subtype(name:String);
	Suffix(name:String);
	Parameter(name:String, value:String);
}

class Mime extends Lexer {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var root = Mo.rules( [
	'[ \r\n\t]*' => lexer -> lexer.token( root ),
	'[a-zA-Z]+\\/' => lexer -> Keyword( Toplevel( lexer.current.substring(0, lexer.current.length - 1).toLowerCase() ) ),
	'[a-zA-Z]+' => lexer -> Keyword( Subtype( lexer.current ) ),
	'([a-zA-Z0-9\\-]+\\.?)+' => lexer -> Keyword( Tree( lexer.current ) ),
	'\\+[a-zA-Z0-9]+' => lexer -> Keyword( Suffix( lexer.current.substring(1, lexer.current.length) ) ),
	'; +[a-zA-Z0-9\\-]+=[a-zA-Z0-9\\-]+' => lexer -> {
		var pair = lexer.current.substring(1, lexer.current.length).trim().split( '=' );
		Keyword( Parameter( pair[0], pair[1] ) );
	}
	] );
	
}
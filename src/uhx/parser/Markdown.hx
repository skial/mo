package uhx.parser;

import byte.ByteData;
import uhx.lexer.MarkdownParser;

/**
 * ...
 * @author Skial Bainn
 */
class Markdown {
	
	public static function toHTML(text:String):String {
		var parser = new MarkdownParser();
		var tokens = parser.toTokens( ByteData.ofString( text ), 'markdown' );
		var resources = new Map < String, { url:String, title:String } > ();
		parser.filterResources( tokens, resources );
		
		var html = [for (token in tokens) parser.printHTML( token, resources )].join('');
		return html;
	}
	
}
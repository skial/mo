package uhx.lexer;

import hxparse.Lexer;
import haxe.io.Eof;
import hxparse.UnexpectedChar;
import uhx.mo.Token;
import byte.ByteData;
import uhx.mo.TokenDef;
import uhx.lexer.MarkdownLexer;

using Mo;
using StringTools;

/**
 * ...
 * @author Skial Bainn
 */
class MarkdownParser {

	private var result:StringBuf;
	private var lexer:MarkdownLexer;
	
	public function new() {
		
	}
	
	public function filterResources(tokens:Array<Token<MarkdownKeywords>>, map:Map<String, {url:String, title:String}>) {
		for (token in tokens) switch (token.token) {
			case Keyword(Resource(text, url, title)):
				map.set(text.toLowerCase().trim(), { url:url, title:title } );
				
			case Keyword(Paragraph(toks)), Keyword(Blockquote(toks)), Keyword(Item(_, toks)), Keyword(Collection(_, toks)):
				filterResources( toks, map );
				
			case _:
				
		}
	}
	
	public function toTokens(input:ByteData, name:String):Array<Token<MarkdownKeywords>> {
		var results = [];
		
		lexer = new MarkdownLexer( input, name );
		
		try {
			
			while ( true ) {
				var token = lexer.token( MarkdownLexer.root );
				results.push( token );
			}
			
		} catch (e:Dynamic) {
			// rawr
			//trace(name);
			//trace(e);
		}
		
		return results;
	}
	
	public function printHTML(token:Token<MarkdownKeywords>, res:Map<String, { url:String, title:String }>):String {
		var result = '';
		
		switch (token.token) {
			case Dot: 
				result += '.';
				
			case Hyphen(_): 
				result += '-';
				
			case Newline, Carriage:
				result += ' ';
				
			case Space(len): 
				result += [for (i in 0...len) ' '].join('');
				
			case Const(CString(s)): 
				result += s;
				
			case Keyword(Paragraph(tokens)) if (tokens.length > 0):
				var content = [for (token in tokens) printHTML( token, res )].join('');
				if (content != '') result += '<p>$content</p>\n';
				
			case Keyword(Header(_, len, title)):
				result += '<h$len>$title</h$len>';
				
			case Keyword(Italic(_, tokens)):
				result += '<em>' + [for (token in tokens) printHTML( token, res )].join('') + '</em>';
				
			case Keyword(Bold(_, tokens)):
				result += '<strong>' + [for (token in tokens) printHTML( token, res )].join('') + '</strong>';
				
			case Keyword(Strike(tokens)):
				result += '<del>' + [for (token in tokens) printHTML( token, res )].join('') + '</del>';
				
			case Keyword(Collection(ordered, tokens)):
				var l = ordered?'ol':'ul';
				result += '<$l>' + [for (token in tokens) printHTML( token, res )].join('') + '</$l>';
				
			case Keyword(Item(_, tokens)):
				result += '<li>' + [for (token in tokens) printHTML( token, res )].join('') + '</li>';
				
			case Keyword(Link(ref, text, url, title)) if (!ref):
				result += '<a href="$url"';
				result += title == '' ? ' ' : ' title="$title"';
				result += '>$text</a>';
				
			case Keyword(Link(ref, text, url, title)) if (ref):
				trace( text, url, title );
				var key = url.toLowerCase().trim();
				var res = res.exists( key ) ? res.get( key ) : { url:'', title:'' };
				
				url = res.url;
				title = res.title;
				
				result += '<a href="$url"';
				result += title == '' ? ' ' : ' title="$title"';
				result += '>$text</a>';
				
			case Keyword(Image(ref, text, url, title)) if (!ref):
				result += '<img src="$url" alt="$text"';
				result += title == '' ? ' ' : ' title="$title"';
				result += ' />';
				
			case Keyword(Code(fenced, lang, code)):
				result += '<code';
				result += (lang != '' ? ' language="$lang"' : '') + '>';
				result += code;
				result += '</code>';
				
			case Keyword(Blockquote(tokens)):
				result += '<blockquote>' + [for (token in tokens) printHTML( token, res )].join('') + '</blockquote>';
				
			case Keyword(Horizontal(_)):
				result += '<hr />';
				
			case _:
		}
		
		return result;
	}
}
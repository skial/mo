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
using haxe.io.Path;

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
			
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			// rawr
			//trace(name);
			trace(e);
			untyped trace(input.readString(0,input.length).substring(lexer.pos));
		}
		
		return results;
	}
	
	public function printHTML(token:Token<MarkdownKeywords>, res:Map<String, { url:String, title:String }>):String {
		var result = '';
		
		switch (token.token) {
			case Dot: 
				result += '.';
				
			case Tilde: 
				result += '~';
				
			case Hyphen(len): 
				result += [for (i in 0...len) '-'].join('');
				
			case Newline, Carriage:
				result += ' ';
				
			case Space(len): 
				result += [for (i in 0...len) ' '].join('');
				
			case Const(CString(s)): 
				result += s;
				
			case Keyword(Paragraph(tokens)) if (tokens.length > 0):
				var content = [for (token in tokens) printHTML( token, res )].join('');
				if (content != '') result += '<p>$content</p>';
				
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
				
			case Keyword(Link(false, text, url, title)):
				result += '<a href="$url"';
				result += title == '' ? ' ' : ' title="$title"';
				result += '>$text</a>';
				
			case Keyword(Link(true, text, url, title)):
				var key = url.toLowerCase().trim();
				
				if (res.exists( key )) {
					var res = res.get( key );
					
					url = res.url;
					title = res.title;
					
					result += '<a href="$url"';
					result += title == '' ? ' ' : ' title="$title"';
					result += '>$text</a>';
				} else {
					result += '[$text]';
				}
				
			case Keyword(Image(false, text, url, title)):
				var hasYoutube = text.indexOf( 'youtube' ) > -1;
				var hasVimeo = text.indexOf( 'vimeo' ) > -1;
				
				if (hasYoutube) {
					var parts = text.split(' ');
					var width = '';
					var height = '';
					
					if (parts.length > 1 && parts[parts.length - 1].indexOf('x') != -1) {
						parts = parts[parts.length - 1].split('x');
						width = ' width="${parts[0]}"';
						height = ' height="${parts[1]}"';
						
					}
					
					url = 'www.youtube.com/embed/$url'.normalize();
					result += '<iframe$width$height src="//$url" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>';
					
				} else if (hasVimeo) {
					var parts = text.split(' ');
					var width = '';
					var height = '';
					
					if (parts.length > 1 && parts[parts.length - 1].indexOf('x') != -1) {
						parts = parts[parts.length - 1].split('x');
						width = ' width="${parts[0]}"';
						height = ' height="${parts[1]}"';
						
					}
					
					url = 'player.vimeo.com/video/$url'.normalize();
					result += '<iframe$width$height src="//$url" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>';
					
				} else if (!url.endsWith('mp4')) {
					result += '<img src="$url" alt="$text"';
					result += title == '' ? ' ' : ' title="$title"';
					result += ' />';
					
				} else {
					var parts = text.split(' ');
					var width = '';
					var height = '';
					
					if (parts.length > 1 && parts[parts.length - 1].indexOf('x') != -1) {
						var bits = parts.pop().split('x');
						width = ' width="${bits[0]}"';
						height = ' height="${bits[1]}"';
						text = parts.join(' ');
						
					}
					
					result += '<video$width$height controls="" loop="" alt="$text"' + (title == '' ? ' ' : ' title="$title"') + '>';
					result += '\r\n\t<source src="$url" type="video/mp4" />';
					result += '\r\n</video>';
					
				}
				
			case Keyword(Image(true, text, url, title)):
				var key = url.toLowerCase().trim();
				
				if (res.exists( key )) {
					var res = res.get( key );
					
					url = res.url;
					title = res.title;
					
					result += '<img src="$url" alt="$text"';
					result += title == '' ? ' ' : ' title="$title"';
					result += ' />';
				} else {
					result += '[$text]';
				}
				
			case Keyword(Code(fenced, lang, code)):
				result += (fenced ? '<pre>' : '') + '<code';
				result += (lang != '' ? ' language="$lang"' : '') + '>';
				result += code.replace('<', '&lt;').replace('>', '&gt;');
				result += '</code>' + (fenced ? '</pre>' : '');
				
			case Keyword(Blockquote(tokens)):
				result += '<blockquote>' + [for (token in tokens) printHTML( token, res )].join('') + '</blockquote>';
				
			case Keyword(Horizontal(_)):
				result += '<hr />';
				
			case _:
		}
		
		return result;
	}
}
package uhx.lexer;

import hxparse.Lexer;
import haxe.io.Eof;
import hxparse.UnexpectedChar;
import uhx.mo.Token;
import byte.ByteData;
import uhx.mo.TokenDef;
import uhx.lexer.MarkdownLexer;
import unifill.Utf32;

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
			trace(name, e);
		}
		
		return results;
	}
	
	/*public function printString(token:Token<MarkdownKeywords>):String {
		return switch(token.token) {
			case Dot: '.';
			case Newline: '\n';
			case Carriage: '\r';
			case Tab(len): [for (i in 0...len) '\t'].join('');
			case Space(len): [for (i in 0...len) ' '].join('');
			case Keyword(Header(alt, len, title)):
				if (!alt) {
					[for (i in 0...len) '#'].join('') + ' $title';
				} else {
					'$title\n' + (len == 1 ? '===' : '---');
				}
				
			case Keyword(Italic(under, toks)): 
				(under?'_':'*') + 
				[for (tok in toks) printString(tok)].join('') + 
				(under?'_':'*');
				
			case Keyword(Bold(under, toks)): 
				(under?'__':'**') + 
				[for (tok in toks) printString(tok)].join('') + 
				(under?'__':'**');
				
			case Keyword(Strike(toks)): 
				'~~' + [for (tok in toks) printString(tok)].join('') + '~~';
				
			case Keyword(Blockquote(toks)): 
				'> ' + [for (tok in toks) printString(tok)].join('');
				
			/*case Keyword(Item(char, toks)):
				'$char ' + [for (tok in toks) printString(tok)].join('');*/
				
			/*case Keyword(Collection(_, items)): 
				//'' + [for (item in items) printString(item)].join('');
				
			case Keyword(Image(ref, text, url, title)):
				'![$text]' + (ref?'[$title]':'($url' + (title == ''?'':' "$title"') + ')');
				
			case Keyword(Link(ref, text, url, title)):
				'[$text]' + (ref?'[$title]':'($url' + (title == ''?'':' "$title"') + ')');
				
			case Keyword(Code(fenced, language, code)):
				(fenced?'```':'`') +
				language +
				(fenced?'\n':'') +
				code +
				(fenced?'\n':'') +
				(fenced?'```':'`');
				
			case Keyword(Horizontal): '===\n';
			case Const(CString(s)): s;
			case _: 
				trace( token.token );
				'';
		}
	}
	
	/*public function printHTML(token:Token<MarkdownKeywords>):String {
		var css = token.token.toCSS();
		var result = '';
		
		switch( token.token ) {
			case Dot: result = '.';
			case Hyphen: result = '-';
			case Carriage: result = '\r';
			case Newline: result = '\n';
			case Const(CString(v)): 
				result = '$v';
				
			case Keyword(Header(_, length, title)):
				result = '<h$length>$title</h$length>\r\n\r\n';
				
			case Keyword(Italic(_, tokens)):
				result = '<em>' +
				[for (token in tokens) printHTML( token )].join('') +
				'</em>';
				
			case Keyword(Bold(_, tokens)):
				result = '<strong>' +
				[for (token in tokens) printHTML( token )].join('') +
				'</strong>';
				
			case Keyword(Strike(tokens)):
				result = '<del>' +
				[for (token in tokens) printHTML( token )].join('') +
				'</del>';
				
			/*case Keyword(Item(_, tokens)):
				result = '<li>' +
				[for (token in tokens) printHTML( token ).rtrim()].join('') +
				'</li>\r\n';*/
				
			/*case Keyword(Collection(ordered, items)):
				/*result = (ordered?'<ol>\r\n':'<ul>') +
				[for (item in items) printHTML( item )].join('') +
				(ordered?'</ol>':'</ul>');*/
				
			/*case Keyword(Link(ref, text, url, title)):
				result = '<a href="$url"' + 
				(title == ''?'':' title="$title"') +
				'>$text</a>';
				
			case Keyword(Image(ref, text, url, title)):
				result = '<img src="$url" alt="$text"' + 
				(title == ''?'':' title="$title"') +
				'/>';
				
			case Keyword(Code(fenced, language, code)):
				result = if (fenced) {
					'<pre lang="' + (language == ''?'no-highlight':language) + '">';
				} else {
					'';
				}
				
				result += '<code>$code</code>';
				result += if (fenced) '</pre>' else '';
				
			case Keyword(Blockquote(tokens)):
				result = '<blockquote>' +
				[for (token in tokens) printHTML( token )].join('') +
				'</blockquote>';
				
			case Keyword(Horizontal): result = '<hr>';
			case Keyword(Break): result = '<br />';
			case _:
				result = printString( token );
				
		}
		
		return result;
	}*/
	
}
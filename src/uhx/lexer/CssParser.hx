package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import uhx.lexer.CssLexer;

using Mo;
using StringTools;

/**
 * ...
 * @author Skial Bainn
 */
class CssParser {

	public function new() {
		
	}
	
	public function toTokens(bytes:ByteData, name:String):Array<Token<CssKeywords>> {
		var lexer = new CssLexer(bytes, name);
		var tokens = [];
		
		try while ( true ) {
			tokens.push( lexer.token( CssLexer.root ) );
		} catch (e:Eof) {
			
		} catch (e:Dynamic) {
			untyped console.log( lexer.input.readString( lexer.curPos().pmin, lexer.curPos().pmax ) );
		}
		
		return tokens;
	}
	
	public function printHTML(token:Token<CssKeywords>, ?tag:String = 'span'):String {
		var css = token.token.toCSS();
		var result = '<$tag class="$css">' +
		(switch (token.token) {
			case Keyword( RuleSet(s, t) ):
				var css = s.toCSS();
				'<$tag class="$css">' + printSelector( s ) + '</$tag>'
				+ '<$tag class="brace open"> {\r\n</$tag>'
				+ [for (i in t) '\t' + printHTML( i )].join('\r\n')
				+ '<$tag class="brace close">\r\n}</$tag>';
				
			case Keyword( AtRule(n, q, t) ):
				'@$n'
				+ '(' + printMediaQuery( q ) + ') <$tag class="brace open">{\r\n</$tag>'
				+ [for (i in t) '\t' + printHTML( i )].join('\r\n')
				+ '<$tag class="brace close">\r\n}</$tag>';
				
			case Keyword( Declaration(n, v) ):
				'<$tag>$n</$tag><$tag class="colon">: </$tag><$tag>$v</$tag>';
				
			case _: '<wbr>&shy;' + printString( token );
		})
		+ '</$tag>';
		
		return result;
	}
	
	public function printString(token:Token<CssKeywords>, compress:Bool = false):String {
		var result = '';
		var tab = '\t';
		var space = ' ';
		var newline = '\r\n';
		
		if (compress) {
			tab = space = newline = '';
		}
		
		switch (token.token) {
			case BraceOpen:
				result = '{';
				
			case BraceClose:
				result = '}';
				
			case Semicolon:
				result = ';';
				
			case Colon:
				result = ':';
				
			case Hash:
				result = '#';
				
			case Comma:
				result = ',';
				
			case Comment(c):
				result = '/*$c*/';
				
			case Keyword( RuleSet(s, t) ):
				result += printSelector( s, compress );
				result += '$space{$newline';
				result += [for (i in t) '$tab' + printString( i, compress)].join( newline );
				result += '$newline}';
				
			case Keyword( AtRule(n, q, t) ):
				result = '@$n';
				result += ' ' + printMediaQuery( q, compress ) + ' {$newline';
				result += [for (i in t) '$tab' + printString( i, compress ).replace(compress? '': '\n', compress? '' : '\n\t')].join( newline );
				result += '$newline}';
				
			case Keyword( Declaration(n, v) ):
				result = '$n:$space$v;';
				
			case _:
				
		}
		
		return result;
	}
	
	public function printSelector(token:CssSelectors, compress:Bool = false):String {
		var result = '';
		var tab = '\t';
		var space = ' ';
		var newline = '\r\n';
		
		if (compress) {
			tab = space = newline = '';
		}
		
		switch (token) {
			case Group(s):
				for (i in s) switch (i) {
					case _:
						if (result != '' && !i.match( Attribute(_, _, _) )) {
							result += ',$newline';
						}
						result += printSelector( i, compress );
						
				}
				
			case Type(n):
				result = n;
				
			case Universal:
				result = '*';
				
			case Attribute(n, t, v):
				result = '[$n' + printAttributeType( t ) + '$v]';
				
			case Class(n):
				if (n.length > 0) {
					result = '.' + [for (i in n) '$i'].join('.');
				}
				
			case ID(n):
				result = '#$n';
				
			case Pseudo(n, e):
				result = ':$n' + e == ''? '' : '($e)';
				
			case Combinator(s, n, t):
				result = printSelector( s, compress );
				result += ' ' + printCombinatorType( t ) + ' ';
				result += printSelector( n, compress );
				
			/*case Expr(t):
				result = '(' + [for (i in t) printSelector( i )].join(', ') + ')';*/
				
			case _:
				
		}
		
		return result;
	}
	
	public function printAttributeType(token:AttributeType):String {
		var result = '';
		
		switch (token) {
			case Name(v):
				result = v;
				
			case Value(v):
				result = v;
				
			case Exact:
				result = '=';
				
			case List:
				result = '~=';
				
			case DashList:
				result = '|=';
				
			case Prefix:
				result = '^=';
				
			case Suffix:
				result = '$=';
				
			case Contains:
				result = '*=';
				
			case _:
				
		}
		
		return result;
	}
	
	public function printCombinatorType(token:CombinatorType):String {
		var result = '';
		
		switch (token) {
			case Child:
				result = '>';
				
			case Descendant:
				result = ' ';
				
			case Adjacent:
				result = '+';
				
			case General:
				result = '~';
				
			case _:
				
		}
		
		return result;
	}
	
	public function printMediaQuery(token:CssMedia, compress:Bool = false):String {
		var result = '';
		var tab = '\t';
		var space = ' ';
		var newline = '\r\n';
		
		if (compress) {
			tab = space = newline = '';
		}
		
		switch (token) {
			case Only:
				result = 'only';
				
			case Not:
				result = 'not';
				
			case Feature(n, v):
				result = n;
				if (v != '') {
					result += ':$space$v';
				}
				
			case Group(q) if(q.length > 0):
				result = [for (i in q) printMediaQuery( i, compress )].join(' ');
				
			case Expr(t) if(t.length > 0):
				result = '(' + [for (i in t) printMediaQuery( i, compress )].join('$space') + ')';
				
			case _:
				
		}
		
		return result;
	}
	
}
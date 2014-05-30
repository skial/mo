package uhx.lexer;

import haxe.io.Eof;
import uhx.mo.Token;
import byte.ByteData;
import uhx.lexer.CssLexer;

using Mo;

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
			trace( e );
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
	
	public function printString(token:Token<CssKeywords>):String {
		var result = '';
		
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
				result += printSelector( s );
				result += ' {\r\n';
				result += [for (i in t) '\t' + printString( i )].join('\r\n');
				result += '\r\n}';
				
			case Keyword( AtRule(n, q, t) ):
				result = '@$n';
				result += '(' + printMediaQuery( q ) + ') {\r\n';
				result += [for (i in t) '\t' + printString( i )].join('\r\n');
				result += '\r\n}';
				
			case Keyword( Declaration(n, v) ):
				result = '$n: $v;';
				
			case _:
				
		}
		
		return result;
	}
	
	public function printSelector(token:CssSelectors):String {
		var result = '';
		
		switch (token) {
			case Group(s):
				for (i in s) switch (i) {
					case _:
						if (result != '' && !i.match( Attribute(_, _, _) )) {
							result += ',\r\n';
						}
						result += printSelector( i );
						
				}
				
			case Type(n):
				result = n;
				
			case Universal:
				result = '*';
				
			case Attribute(n, t, v):
				result = '[$n' + printAttributeType( t ) + '$v]';
				
			case Class(n):
				result = [for (i in n) '.$i'].join('');
				
			case ID(n):
				result = '#$n';
				
			case Pseudo(n, e):
				result = ':$n' + e == ''? '' : '($e)';
				
			case Combinator(s, n, t):
				result = printSelector( s );
				result += ' ' + printCombinatorType( t ) + ' ';
				result += printSelector( n );
				
			case Expr(t):
				result = '(' + [for (i in t) printSelector( i )].join(', ') + ')';
				
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
	
	public function printMediaQuery(token:CssMedia):String {
		var result = '';
		
		switch (token) {
			case Only:
				result = 'only';
				
			case Not:
				result = 'not';
				
			case Feature(n, v):
				
			case Group(q):
				
			case Expr(t):
				
			case _:
				
		}
		
		return result;
	}
	
}
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
				printSelectorHTML( s )
				+ ' {\r\n'
				+ [for (i in t) '\t' + printHTML( i )].join('\r\n')
				+ '\r\n}';
				
			case Keyword( AtRule(n, q, t) ):
				'@$n'
				+ '(' + printMediaQueryHTML( q ) + ') {\r\n'
				+ [for (i in t) '\t' + printHTML( i )].join('\r\n')
				+ '\r\n}';
				
			case Keyword(_): printString( token );
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
				result += printSelectorHTML( s );
				result += ' {\r\n';
				result += [for (i in t) '\t' + printString( i )].join('\r\n');
				result += '\r\n}';
				
			case Keyword( AtRule(n, q, t) ):
				result = '@$n';
				result += '(' + printMediaQueryHTML( q ) + ') {\r\n';
				result += [for (i in t) '\t' + printString( i )].join('\r\n');
				result += '\r\n}';
				
			case Keyword( Declaration(n, v) ):
				result = '$n: $v;';
				
			case _:
				
		}
		
		return result;
	}
	
	public function printSelectorHTML(token:CssSelectors):String {
		var result = '';
		
		switch (token) {
			case Group(s):
				for (i in s) switch (i) {
					case _:
						if (result != '' && !i.match( Attribute(_, _, _) )) {
							result += ',\r\n';
						}
						result += printSelectorHTML( i );
						
				}
				
			case Type(n):
				result = n;
				
			case Universal:
				result = '*';
				
			case Attribute(n, t, v):
				result = '[$n' + printAttributeTypeHTML( t ) + '$v]';
				
			case Class(n):
				result = [for (i in n) '.$i'].join('');
				
			case ID(n):
				result = '#$n';
				
			case Pseudo(n, e):
				result = ':$n' + e == ''? '' : '($e)';
				
			case Combinator(s, n, t):
				result = printSelectorHTML( s );
				result += ' ' + printCombinatorType( t ) + ' ';
				result += printSelectorHTML( n );
				
			case Expr(t):
				result = '(' + [for (i in t) printSelectorHTML( i )].join(', ') + ')';
				
			case _:
				
		}
		
		return result;
	}
	
	public function printAttributeTypeHTML(token:AttributeType):String {
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
	
	public function printMediaQueryHTML(token:CssMedia):String {
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
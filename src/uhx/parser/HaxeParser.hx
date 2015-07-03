package uhx.lexer;

import byte.ByteData;
import haxe.io.Eof;
import haxe.rtti.Meta;
import hxparse.Parser;
import hxparse.ParserBuilder;
import uhx.mo.Token;
import uhx.lexer.HaxeLexer.HaxeKeywords;

using Mo;
using StringTools;

/**
 * ...
 * @author Skial Bainn
 */
class HaxeParser {

	private var result:StringBuf;
	private var lexer:HaxeLexer;
	
	public function new() {
		
	}
	
	public function toTokens(input:ByteData, name:String):Array<Token<HaxeKeywords>> {
		var results = [];
		
		lexer = new HaxeLexer( input, name );
		
		try {
			
			while ( true ) {
				var token = lexer.token( HaxeLexer.root );
				results.push( token );
			}
			
		} catch (e:Dynamic) { }
		
		return results;
	}
	
	public function printString(token:Token<HaxeKeywords>):String {
		return switch( token ) {
			case At: '@';
			case Dot: '.';
			case Colon: ':';
			case Arrow: '->';
			case Comma: ',';
			case Question: '?';
			case Semicolon: ';';
			case Newline: '\n';
			case Carriage: '\r';
			case BracketOpen: '[';
			case BracketClose: ']';
			case BraceOpen: '{';
			case BraceClose: '}';
			case ParenthesesOpen: '(';
			case ParenthesesClose: ')';
			case Tab(n): [for (i in 0...n) '\t'].join('');
			case Space(n): [for (i in 0...n) ' '].join('');
			case Const(CInt(v)): v;
			case Const(CFloat(v)): v;
			case Const(CString(v)): '"$v"';
			case Const(CIdent(v)): v;
			case Unop(OpIncrement): '++';
			case Unop(OpDecrement): '--';
			case Unop(OpNot): '!';
			case Unop(OpNegBits): '~';
			case Binop(OpAdd): '+';
			case Binop(OpMult): '*';
			case Binop(OpDiv): '/';
			case Binop(OpSub): '-';
			case Binop(OpAssign): '=';
			case Binop(OpEq): '==';
			case Binop(OpNotEq): '!=';
			case Binop(OpGt): '>';
			case Binop(OpGte): '>=';
			case Binop(OpLt): '<';
			case Binop(OpLte): '<=';
			case Binop(OpAnd): '&';
			case Binop(OpOr): '|';
			case Binop(OpXor): '^';
			case Binop(OpBoolAnd): '&&';
			case Binop(OpBoolOr): '||';
			case Binop(OpShl): '<<';
			case Binop(OpShr): '>>';
			case Binop(OpUShr): '>>>';
			case Binop(OpMod): '%';
			case Binop(OpInterval): '...';
			case Binop(OpArrow): '=>';
			case Keyword(kwd): Std.string( kwd ).toLowerCase();
			case Conditional(s): '#' + s;
			case Dollar(s): '$';
			case Interval(s): s;
			case Comment(c): '/*$c*/';
			case CommentLine(c): '//$c';
			case _: '';
		}
	}
	
	public function printHTML(token:Token<HaxeKeywords>, ?tag:String = 'span'):String {
		var css = token.toCSS();
		var result = '<$tag class="$css">' + 
		
		( switch( token ) {
			case Carriage: '';
			case Const(CString(v)): '"$v"'.htmlEscape();
			case Keyword(kwd): printString( token );
			case _: printString( token ).htmlEscape();
		} )
		
		+ '</$tag>';
		
		return result;
	}
	
}
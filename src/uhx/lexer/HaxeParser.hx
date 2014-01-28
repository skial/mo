package uhx.lexer;

import byte.ByteData;
import haxe.io.Eof;
import haxe.rtti.Meta;
import hxparse.Parser;
import hxparse.ParserBuilder;
import uhx.mo.Token;
import uhx.mo.TokenDef;
import uhx.lexer.HaxeLexer.HaxeKeywords;

using Mo;

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
		return switch( token.token ) {
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
		var css = token.token.toCSS();
		
		var result = '<$tag class="$css">' + 
		
		( switch( token.token ) {
			case Const(CString(v)): '"$v"'.htmlify();
			case _: printString( token );
		} )
		
		+ '</$tag>';
		
		return result;
	}
	
	/*public function toHTML(tokens:Array<Token<HaxeKeywords>>):String {
		result = new StringBuf();
		
		result.add('<pre><code class="language haxe">');
		
		for (token in tokens) {
			
			var name = try token.token.toCSS() catch (_e:Dynamic) '';
			
			switch( token.token ) {
				case At: add( '@', name );
				case Dot: add( '.', name );
				case Colon: add( ':', name );
				case Arrow: add( '->', name );
				case Comma: add( ',', name );
				case Question: add( '?', name );
				case Semicolon: add( ';', name );
				case Newline: add( '\n', name );
				case Carriage: add( '\r', name );
				case BracketOpen: add( '[', name );
				case BracketClose: add( ']', name );
				case BraceOpen: add( '{', name );
				case BraceClose: add( '}', name );
				case ParenthesesOpen: add( '(', name );
				case ParenthesesClose: add( ')', name );
				case Tab(n): for (i in 0...n) add( '\t', name );
				case Space(n): add( [for (i in 0...n) ' '].join(''), name );
				case Const(CInt(v)): add( v, name );
				case Const(CFloat(v)): add( v, name );
				case Const(CString(v)): add( '"$v"'.htmlify(), name ); // TODO need to escape all characters. StringTools::htmlEscape doesnt escape `\t`
				case Const(CIdent(v)): add( v, name );
				case Unop(OpIncrement): add( '++', name );
				case Unop(OpDecrement): add( '--', name );
				case Unop(OpNot): add( '!', name );
				case Unop(OpNegBits): add( '~', name );
				case Binop(OpAdd): add( '+', name );
				case Binop(OpMult): add( '*', name );
				case Binop(OpDiv): add( '/', name );
				case Binop(OpSub): add( '-', name );
				case Binop(OpAssign): add( '=', name );
				case Binop(OpEq): add( '==', name );
				case Binop(OpNotEq): add( '!=', name );
				case Binop(OpGt): add( '>', name );
				case Binop(OpGte): add( '>=', name );
				case Binop(OpLt): add( '<', name );
				case Binop(OpLte): add( '<=', name );
				case Binop(OpAnd): add( '&', name );
				case Binop(OpOr): add( '|', name );
				case Binop(OpXor): add( '^', name );
				case Binop(OpBoolAnd): add( '&&', name );
				case Binop(OpBoolOr): add( '||', name );
				case Binop(OpShl): add( '<<', name );
				case Binop(OpShr): add( '>>', name );
				case Binop(OpUShr): add( '>>>', name );
				case Binop(OpMod): add( '%', name );
				case Binop(OpInterval): add( '...', name );
				case Binop(OpArrow): add( '=>', name );
				case Keyword(kwd): add( Std.string( kwd ).toLowerCase(), name );
				case Conditional(s): add( '#' + s, name );
				case Dollar(s): add( '$' + s, name );
				case Interval(s): add( s, name );
				case Comment(c): add( '/*$c*///', name );
				/*case CommentLine(c): add( '//$c', name );
				case _: 
			}
			
		}
		
		result.add('</code></pre>');
		
		return result.toString();
	}*/
	
	/*private function add(v:String, ?cls:String = '') {
		if (cls != '') cls = ' $cls';
		result.add( '<span class="token$cls">$v</span>' );
	}*/
	
}
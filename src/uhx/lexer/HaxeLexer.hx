package uhx.lexer;

import haxe.io.Eof;
import hxparse.RuleBuilder;
import uhx.mo.Token;
import byte.ByteData;
import hxparse.Lexer;
import uhx.mo.TokenDef;

enum HaxeKeywords {
	Function;
	@entry Class;
	Var;
	If;
	Else;
	While;
	Do;
	For;
	Break;
	Continue;
	Return;
	Extends;
	Implements;
	Import;
	Switch;
	Case;
	Default;
	Static;
	Public;
	Private;
	Try;
	Catch;
	New;
	This;
	Throw;
	Extern;
	Enum;
	In;
	Interface;
	Untyped;
	Cast;
	Override;
	Typedef;
	Dynamic;
	Package;
	Inline;
	Using;
	Null;
	True;
	False;
	Abstract;
	Macro;
}

/**
 * ...
 * @author Skial Bainn
 */
class HaxeLexer extends Lexer implements RuleBuilder {

	public function new(content:ByteData, name:String) {
		super( content, name );
	}
	
	public static var buf = new StringBuf();
	static var ident = "_*[a-z][a-zA-Z0-9_]*|_+|_+[0-9][_a-zA-Z0-9]*";
	static var idtype = "_*[A-Z][a-zA-Z0-9_]*";
	
	public static var keywords = @:mapping(0) HaxeKeywords;
	
	public static function mk<T>(lex:Lexer, tok:TokenDef<T>):Token<T> {
		return new Token<T>(tok, lex.curPos());
	}
	
	public static var root = Mo.rules( [
		'\n' => mk(lexer, Newline),
		'\r' => mk(lexer, Carriage),
		'\t*' => mk(lexer, Tab(lexer.current.length)),
		' *' => mk(lexer, Space(lexer.current.length)),
		"0x[0-9a-fA-F]+" => mk(lexer, Const(CInt(lexer.current))),
		"[0-9]+" => mk(lexer, Const(CInt(lexer.current))),
		"[0-9]+\\.[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
		"\\.[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
		"[0-9]+[eE][\\+\\-]?[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
		"[0-9]+\\.[0-9]*[eE][\\+\\-]?[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
		"[0-9]+\\.\\.\\." => mk(lexer, Interval(lexer.current.substr(0,-3))),
		"//[^\n\r]*" => mk(lexer, CommentLine(lexer.current.substr(2))),
		"+\\+" => mk(lexer, Unop(OpIncrement)),
		"--" => mk(lexer, Unop(OpDecrement)),
		"~" => mk(lexer, Unop(OpNegBits)),
		"%=" => mk(lexer, Binop(OpAssignOp(OpMod))),
		"&=" => mk(lexer, Binop(OpAssignOp(OpAnd))),
		"|=" => mk(lexer, Binop(OpAssignOp(OpOr))),
		"^=" => mk(lexer, Binop(OpAssignOp(OpXor))),
		"+=" => mk(lexer, Binop(OpAssignOp(OpAdd))),
		"-=" => mk(lexer, Binop(OpAssignOp(OpSub))),
		"*=" => mk(lexer, Binop(OpAssignOp(OpMult))),
		"/=" => mk(lexer, Binop(OpAssignOp(OpDiv))),
		"<<=" => mk(lexer, Binop(OpAssignOp(OpShl))),
		"==" => mk(lexer, Binop(OpEq)),
		"!=" => mk(lexer, Binop(OpNotEq)),
		"<=" => mk(lexer, Binop(OpLte)),
		"&&" => mk(lexer, Binop(OpBoolAnd)),
		"|\\|" => mk(lexer, Binop(OpBoolOr)),
		"<<" => mk(lexer, Binop(OpShl)),
		"->" => mk(lexer, Arrow),
		"\\.\\.\\." => mk(lexer, Binop(OpInterval)),
		"=>" => mk(lexer, Binop(OpArrow)),
		"!" => mk(lexer, Unop(OpNot)),
		"<" => mk(lexer, Binop(OpLt)),
		">" => mk(lexer, Binop(OpGt)),
		";" => mk(lexer, Semicolon),
		":" => mk(lexer, Colon),
		"," => mk(lexer, Comma),
		"\\." => mk(lexer, Dot),
		"%" => mk(lexer, Binop(OpMod)),
		"&" => mk(lexer, Binop(OpAnd)),
		"|" => mk(lexer, Binop(OpOr)),
		"^" => mk(lexer, Binop(OpXor)),
		"+" => mk(lexer, Binop(OpAdd)),
		"*" => mk(lexer, Binop(OpMult)),
		"/" => mk(lexer, Binop(OpDiv)),
		"-" => mk(lexer, Binop(OpSub)),
		"=" => mk(lexer, Binop(OpAssign)),
		"[" => mk(lexer, BracketOpen),
		"]" => mk(lexer, BracketClose),
		"{" => mk(lexer, BraceOpen),
		"}" => mk(lexer, BraceClose),
		"\\(" => mk(lexer, ParenthesesOpen),
		"\\)" => mk(lexer, ParenthesesClose),
		"?" => mk(lexer, Question),
		"@" => mk(lexer, At),
		'"' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string) catch (e:Eof) throw e;
			mk(lexer, Const(CString(buf.toString())));
		},
		"'" => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string2) catch (e:Eof) throw e;
			mk(lexer, Const(CString(buf.toString())));
		},
		'/\\*' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(comment) catch (e:Eof) throw e;
			mk(lexer, Comment(buf.toString()));
		},
		"#" + ident => mk(lexer, Conditional(lexer.current.substr(1))),
		"$" + ident => mk(lexer, Dollar(lexer.current.substr(1))),
		ident => {
			var kwd = keywords.get(lexer.current);
			if (kwd != null)
				mk(lexer, Keyword(kwd));
			else
				mk(lexer, Const(CIdent(lexer.current)));
		},
		idtype => mk(lexer, Const(CIdent(lexer.current))),
	] );
	
	public static var string = Mo.rules( [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string);
		},
		"\\\\n" => {
			buf.add("\n");
			lexer.token(string);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string);
		},
		"\\\\\"" => {
			buf.add('"');
			lexer.token(string);
		},
		'"' => lexer.curPos().pmax,
		"[^\\\\\"]+" => {
			buf.add(lexer.current);
			lexer.token(string);
		}
	] );
	
	public static var string2 = Mo.rules( [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string2);
		},
		"\\\\n" =>  {
			buf.add("\n");
			lexer.token(string2);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string2);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string2);
		},
		'\\\\\'' => {
			buf.add('"');
			lexer.token(string2);
		},
		"'" => lexer.curPos().pmax,
		'[^\\\\\']+' => {
			buf.add(lexer.current);
			lexer.token(string2);
		}
	] );
	
	public static var comment = Mo.rules( [
		"*/" => lexer.curPos().pmax,
		"*" => {
			buf.add("*");
			lexer.token(comment);
		},
		"[^\\*]" => {
			buf.add(lexer.current);
			lexer.token(comment);
		}
	] );
	
}